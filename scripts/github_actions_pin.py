"""Keep the fleet's `chrysa/github-actions` pins on a single, current tag.

Consumers reference the reusable workflows by tag
(`uses: chrysa/github-actions/.github/workflows/<wf>.yml@<tag>`). When a repo lags
behind, it keeps running an old version of the gate: the v1.4.x quality-gate, for
instance, invokes `make quality-gate-verify` with no guard and fails with
`No rule to make target` on every repo that is not onboarded — a red check that
reports nothing about the code.

Audits, or opens one PR per repo moving every pin to the target tag.

Usage:
    python github_actions_pin.py                      # audit against the latest tag
    python github_actions_pin.py --target v1.6.0      # audit against an explicit tag
    python github_actions_pin.py --apply              # open the PRs
    python github_actions_pin.py --apply repo…        # restrict to named repos

Exit: 0 fleet aligned / sweep clean · 1 drift or failures · 2 usage error.
"""

from __future__ import annotations

import argparse
import base64
import json
import pathlib
import re
import subprocess
import sys

OWNER = "chrysa"
ACTIONS_REPO = "chrysa/github-actions"
BRANCH = "ci/bump-github-actions"
WORKFLOW_DIR = ".github/workflows"
LEDGER = pathlib.Path(__file__).resolve().parent.parent / "compliance" / "branch-policy.json"

PIN = re.compile(r"(chrysa/github-actions[^@\s'\"]*@)(v?[\w.\-]+)")


def gh(args: list[str], stdin: str | None = None) -> tuple[int, str, str]:
    done = subprocess.run(["gh", *args], capture_output=True, text=True, input=stdin)
    return done.returncode, done.stdout, done.stderr


def latest_tag() -> str | None:
    code, out, _ = gh(["api", f"repos/{ACTIONS_REPO}/tags", "-q", ".[0].name"])
    return out.strip() if code == 0 and out.strip() else None


def read(repo: str, path: str) -> tuple[str | None, str]:
    """(content, status) with status in {ok, absent, <error>} — a throttled read is
    never reported as 'this repo has nothing'."""
    code, body, err = gh(["api", f"repos/{OWNER}/{repo}/contents/{path}",
                          "-H", "Accept: application/vnd.github.raw"])
    if code == 0:
        return body, "ok"
    if "404" in err or "Not Found" in err:
        return None, "absent"
    return None, err.strip().splitlines()[0][:90] if err else "error"


def workflows(repo: str) -> tuple[list[str], str]:
    code, out, err = gh(["api", f"repos/{OWNER}/{repo}/contents/{WORKFLOW_DIR}", "-q", ".[].name"])
    if code == 0:
        return [w for w in out.split() if w.endswith((".yml", ".yaml"))], "ok"
    if "404" in err or "Not Found" in err:
        return [], "absent"
    return [], err.strip().splitlines()[0][:90] if err else "error"


def commit(repo: str, path: str, content: str, message: str) -> str:
    full = f"{OWNER}/{repo}"
    code, blob, _ = gh(["api", f"repos/{full}/contents/{path}?ref={BRANCH}", "-q", ".sha"])
    if code != 0:
        return f"blob not found: {path}"
    payload = json.dumps({
        "message": message,
        "content": base64.b64encode(content.encode()).decode(),
        "sha": blob.strip(),
        "branch": BRANCH,
    })
    code, _, err = gh(["api", f"repos/{full}/contents/{path}", "-X", "PUT", "--input", "-"],
                      stdin=payload)
    return "" if code == 0 else f"commit failed: {err.strip().splitlines()[0][:80]}"


def sweep_repo(repo: str, target: str, apply: bool) -> tuple[str, str]:
    """Returns (state, detail) with state in {ok, drift, patched, absent, error}."""
    names, status = workflows(repo)
    if status == "absent":
        return "absent", ""
    if status != "ok":
        return "error", status

    stale: dict[str, str] = {}
    for name in names:
        body, status = read(repo, f"{WORKFLOW_DIR}/{name}")
        if status != "ok":
            if status == "absent":
                continue
            return "error", status
        if PIN.search(body) and any(m.group(2) != target for m in PIN.finditer(body)):
            stale[name] = PIN.sub(lambda m: m.group(1) + target, body)

    if not stale:
        return "ok", ""
    if not apply:
        return "drift", ", ".join(sorted(stale))

    full = f"{OWNER}/{repo}"
    code, sha, _ = gh(["api", f"repos/{full}/git/ref/heads/develop", "-q", ".object.sha"])
    if code != 0:
        return "error", "no develop branch"
    gh(["api", f"repos/{full}/git/refs", "-X", "POST",
        "-f", f"ref=refs/heads/{BRANCH}", "-f", f"sha={sha.strip()}"])

    message = (f"ci: pin chrysa/github-actions at {target}\n\n"
               "An older tag keeps running an older gate — the v1.4.x quality-gate\n"
               "invokes `make quality-gate-verify` unguarded and fails on any repo\n"
               "that is not onboarded, reporting nothing about the code.")
    for name, patched in sorted(stale.items()):
        error = commit(repo, f"{WORKFLOW_DIR}/{name}", patched, message)
        if error:
            return "error", error

    body = (f"Moves every `chrysa/github-actions` pin to **{target}**.\n\n"
            "An older tag keeps running an older gate. `v1.4.x` of `quality-gate-check.yml` "
            "invokes `make quality-gate-verify` with no guard and fails with "
            "`No rule to make target` on any repo that is not onboarded — a red check that "
            "says nothing about the code. `v1.6.0` also skips `pip install -e .` for a "
            "tooling-only `pyproject.toml` and only enables the npm cache when a lockfile "
            "exists.\n\nSwept from `chrysa/shared-standards` (`scripts/github_actions_pin.py`).")
    code, _, err = gh(["pr", "create", "-R", full, "--base", "develop", "--head", BRANCH,
                       "--title", f"ci: pin chrysa/github-actions at {target}", "--body", body])
    if code != 0 and "already exists" not in err:
        return "error", f"pr failed: {err.strip().splitlines()[0][:80]}"
    return "patched", ", ".join(sorted(stale))


# sweep_repo() state -> (report line, tally bucket). A new state is a new row here,
# not a new branch in main() (standards: prefer a lookup table to a state machine).
STATE_REPORT: dict[str, tuple[str, str | None]] = {
    "ok": ("ok {repo}", None),
    "absent": ("·  {repo} · no workflows", None),
    "drift": ("⚠  {repo} · {detail}", "drift"),
    "patched": ("✅ {repo} · {detail}", "drift"),
}
_UNKNOWN_STATE = ("❌ {repo} · {detail}", "failure")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="open PRs instead of auditing")
    parser.add_argument("--target", help="tag to pin (default: the latest github-actions tag)")
    parser.add_argument("repos", nargs="*", help="restrict to these repos")
    args = parser.parse_args()

    target = args.target or latest_tag()
    if not target:
        print("cannot resolve the target tag", file=sys.stderr)
        return 2
    print(f"target: {target}\n")

    repos = args.repos
    if not repos:
        if not LEDGER.exists():
            print(f"ledger not found: {LEDGER}", file=sys.stderr)
            return 2
        repos = [row["repo"] for row in json.loads(LEDGER.read_text())["repos"]]

    drift, failures = [], []
    for repo in repos:
        state, detail = sweep_repo(repo, target, args.apply)
        template, bucket = STATE_REPORT.get(state, _UNKNOWN_STATE)
        print(template.format(repo=repo, detail=detail))
        if bucket == "drift":
            drift.append(repo)
        elif bucket == "failure":
            failures.append((repo, detail))

    print(f"\nchecked={len(repos)} drift={len(drift)} failures={len(failures)}")
    return 1 if (failures or (drift and not args.apply)) else 0


if __name__ == "__main__":
    sys.exit(main())
