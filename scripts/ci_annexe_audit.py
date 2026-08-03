"""Audit the fleet against annexe CI (`standards/annexes/CI-CD.md`), and fix what is safe.

Checks the mechanisable rules of the annexe on every workflow of every repo:

    CI-010  third-party actions pinned by commit SHA
    CI-011  internal shared actions pinned by tag, never @main / @master
    CI-020  permissions declared
    CI-021  secrets: inherit banned
    CI-022  untrusted ${{ github.event.* }} interpolated into a run: block
    CI-030  timeout-minutes on every job
    CI-031  concurrency group on PR-triggered workflows

`--apply` fixes only what is deterministic and reversible — the concurrency group and the
job timeout. Everything else (a permission set, a secret list, an unpinned third-party
action) is a judgement call that belongs to a human: the script reports it, never guesses it.

Usage:
    python ci_annexe_audit.py                  # fleet scorecard
    python ci_annexe_audit.py --details        # one line per violation
    python ci_annexe_audit.py --apply [repo…]  # open the safe-fix PRs

Exit: 0 clean · 1 violations found · 2 usage error.
"""

from __future__ import annotations

import argparse
import base64
import collections
import json
import pathlib
import re
import subprocess
import sys

OWNER = "chrysa"
WORKFLOW_DIR = ".github/workflows"
BRANCH = "ci/annexe-conformance"
LEDGER = pathlib.Path(__file__).resolve().parent.parent / "compliance" / "branch-policy.json"
REPORT = pathlib.Path(__file__).resolve().parent.parent / "compliance" / "ci-annexe.json"

INTERNAL = ("chrysa/",)
# Deploy/release pipelines must queue, never cancel — CI-031.
DEPLOY_HINTS = ("deploy", "release", "publish", "promote", "cd")
DEFAULT_TIMEOUT = 30

RE_USES = re.compile(r"^\s*(?:-\s*)?uses:\s*([^\s#]+)", re.M)
RE_JOB = re.compile(r"^(?P<indent>\s{2,})(?P<name>[A-Za-z0-9_-]+):\s*$", re.M)
RE_UNTRUSTED = re.compile(
    r"\$\{\{\s*github\.event\.(?:pull_request\.(?:title|body|head\.ref|head\.label)"
    r"|issue\.(?:title|body)|comment\.body|review\.body|head_commit\.message"
    r"|client_payload\.[\w.]+)\s*\}\}"
)


def gh(args: list[str], stdin: str | None = None) -> tuple[int, str, str]:
    done = subprocess.run(["gh", *args], capture_output=True, text=True, input=stdin)
    return done.returncode, done.stdout, done.stderr


def api_text(path: str) -> tuple[str | None, str]:
    """(body, status) with status in {ok, absent, <error>} — a throttled read is never
    reported as 'this repo has nothing'."""
    code, body, err = gh(["api", path, "-H", "Accept: application/vnd.github.raw"])
    if code == 0:
        return body, "ok"
    if "404" in err or "Not Found" in err:
        return None, "absent"
    return None, err.strip().splitlines()[0][:90] if err else "error"


def workflow_names(repo: str) -> tuple[list[str], str]:
    code, out, err = gh(["api", f"repos/{OWNER}/{repo}/contents/{WORKFLOW_DIR}", "-q", ".[].name"])
    if code == 0:
        return [n for n in out.split() if n.endswith((".yml", ".yaml"))], "ok"
    if "404" in err or "Not Found" in err:
        return [], "absent"
    return [], err.strip().splitlines()[0][:90] if err else "error"


def is_deploy(name: str, text: str) -> bool:
    stem = name.rsplit(".", 1)[0].lower()
    return any(h in stem for h in DEPLOY_HINTS) or "environment:" in text


def job_blocks(text: str) -> list[tuple[str, str]]:
    """(job name, block) for each entry under a top-level `jobs:` mapping."""
    start = re.search(r"^jobs:\s*$", text, re.M)
    if not start:
        return []
    body = text[start.end():]
    matches = list(RE_JOB.finditer(body))
    top = min((m.group("indent") for m in matches), key=len, default=None)
    if top is None:
        return []
    jobs = [m for m in matches if m.group("indent") == top]
    blocks = []
    for i, m in enumerate(jobs):
        end = jobs[i + 1].start() if i + 1 < len(jobs) else len(body)
        blocks.append((m.group("name"), body[m.start():end]))
    return blocks


def inspect(text: str, name: str) -> list[str]:
    """Rule ids violated by one workflow file."""
    found = []
    for match in RE_USES.finditer(text):
        ref = match.group(1).strip("'\"")
        if ref.startswith("./"):
            continue
        pin = ref.split("@")[1] if "@" in ref else ""
        internal = ref.startswith(INTERNAL)
        if internal:
            if not pin.startswith("v"):
                found.append("CI-011")
        elif not re.fullmatch(r"[0-9a-f]{40}", pin):
            found.append("CI-010")
    if not re.search(r"^\s*permissions:", text, re.M):
        found.append("CI-020")
    if re.search(r"secrets:\s*inherit", text):
        found.append("CI-021")
    for block in re.findall(r"run:\s*\|?[\s\S]{0,600}", text):
        if RE_UNTRUSTED.search(block):
            found.append("CI-022")
            break
    for _, block in job_blocks(text):
        if "uses:" in block and "steps:" not in block:
            continue  # a job that only calls a reusable workflow inherits its timeout
        if "timeout-minutes:" not in block:
            found.append("CI-030")
            break
    if re.search(r"^\s*pull_request(_target)?:", text, re.M) and not re.search(
        r"^concurrency:", text, re.M
    ):
        found.append("CI-031")
    return sorted(set(found))


def fix(text: str, name: str) -> str | None:
    """Deterministic fixes only: concurrency group (CI-031) and job timeout (CI-030)."""
    patched = text

    if re.search(r"^\s*pull_request(_target)?:", patched, re.M) and not re.search(
        r"^concurrency:", patched, re.M
    ):
        cancel = "false" if is_deploy(name, patched) else "true"
        block = ("concurrency:\n"
                 "    group: ${{ github.workflow }}-${{ github.ref }}\n"
                 f"    cancel-in-progress: {cancel}\n\n")
        anchor = re.search(r"^jobs:\s*$", patched, re.M)
        if anchor:
            patched = patched[:anchor.start()] + block + patched[anchor.start():]

    for job_name, block in job_blocks(patched):
        if "timeout-minutes:" in block or ("uses:" in block and "steps:" not in block):
            continue
        runs_on = re.search(r"^(\s*)runs-on:.*$", block, re.M)
        if not runs_on:
            continue
        indent = runs_on.group(1)
        line = runs_on.group(0)
        patched = patched.replace(line, f"{line}\n{indent}timeout-minutes: {DEFAULT_TIMEOUT}", 1)

    return patched if patched != text else None


def commit_tree(repo: str, base_sha: str, files: dict[str, str], message: str) -> str:
    """One commit for every patched file, via the git trees API.

    The contents API costs one commit (and one round trip) per file; a repo with twenty
    workflows would burn twenty writes and produce twenty commits for one logical change.
    """
    full = f"{OWNER}/{repo}"
    tree = json.dumps({
        "base_tree": base_sha,
        "tree": [{"path": p, "mode": "100644", "type": "blob", "content": c}
                 for p, c in sorted(files.items())],
    })
    code, out, err = gh(["api", f"repos/{full}/git/trees", "-X", "POST", "--input", "-", "-q", ".sha"],
                        stdin=tree)
    if code != 0:
        return f"tree failed: {err.strip().splitlines()[0][:80]}"
    payload = json.dumps({"message": message, "tree": out.strip(), "parents": [base_sha]})
    code, out, err = gh(["api", f"repos/{full}/git/commits", "-X", "POST", "--input", "-", "-q", ".sha"],
                        stdin=payload)
    if code != 0:
        return f"commit failed: {err.strip().splitlines()[0][:80]}"
    code, _, err = gh(["api", f"repos/{full}/git/refs/heads/{BRANCH}", "-X", "PATCH",
                       "-f", f"sha={out.strip()}", "-F", "force=true"])
    return "" if code == 0 else f"ref update failed: {err.strip().splitlines()[0][:80]}"


def sweep(repo: str, apply: bool) -> tuple[dict[str, list[str]], dict[str, str], str]:
    """(violations by file, patches by file, error)."""
    names, status = workflow_names(repo)
    if status == "absent":
        return {}, {}, ""
    if status != "ok":
        return {}, {}, status

    violations: dict[str, list[str]] = {}
    patches: dict[str, str] = {}
    for name in names:
        text, status = api_text(f"repos/{OWNER}/{repo}/contents/{WORKFLOW_DIR}/{name}")
        if status == "absent":
            continue
        if text is None:
            return violations, {}, status
        found = inspect(text, name)
        if found:
            violations[name] = found
        if apply:
            patched = fix(text, name)
            if patched:
                patches[name] = patched
    return violations, patches, ""


def open_pull_request(repo: str, patches: dict[str, str]) -> str:
    full = f"{OWNER}/{repo}"
    code, sha, _ = gh(["api", f"repos/{full}/git/ref/heads/develop", "-q", ".object.sha"])
    if code != 0:
        return "no develop branch"
    gh(["api", f"repos/{full}/git/refs", "-X", "POST",
        "-f", f"ref=refs/heads/{BRANCH}", "-f", f"sha={sha.strip()}"])

    message = ("ci: concurrency group and job timeouts (annexe CI-030, CI-031)\n\n"
               "A job with no timeout holds a runner until the platform cap; a PR workflow\n"
               "with no concurrency group leaves a queue of superseded runs behind every\n"
               "push. Deploy and release workflows queue instead of cancelling.")
    error = commit_tree(repo, sha.strip(),
                        {f"{WORKFLOW_DIR}/{n}": c for n, c in patches.items()}, message)
    if error:
        return error

    body = ("Applies the two deterministic rules of annexe "
            "[`CI-CD.md`](https://github.com/chrysa/shared-standards/blob/main/standards/annexes/CI-CD.md):\n\n"
            f"- **CI-030** — every job declares `timeout-minutes:` (set to {DEFAULT_TIMEOUT}, "
            "raise it where the job legitimately runs longer). Without it a hung job holds a "
            "runner until the platform cap.\n"
            "- **CI-031** — every PR-triggered workflow declares a concurrency group. "
            "Superseded PR runs are cancelled; **deploy and release workflows queue instead** "
            "(`cancel-in-progress: false`) — cancelling a deployment mid-flight is worse than "
            "queueing it.\n\n"
            "The remaining findings (permissions, `secrets: inherit`, action pinning) are "
            "judgement calls and are reported by `scripts/ci_annexe_audit.py`, never guessed.")
    code, _, err = gh(["pr", "create", "-R", full, "--base", "develop", "--head", BRANCH,
                       "--title", "ci: concurrency group and job timeouts (annexe CI-030, CI-031)",
                       "--body", body])
    if code != 0 and "already exists" not in err:
        return f"pr failed: {err.strip().splitlines()[0][:80]}"
    return ""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="open the safe-fix PRs")
    parser.add_argument("--details", action="store_true", help="one line per violating file")
    parser.add_argument("repos", nargs="*")
    args = parser.parse_args()

    repos = args.repos
    if not repos:
        if not LEDGER.exists():
            print(f"ledger not found: {LEDGER}", file=sys.stderr)
            return 2
        repos = [row["repo"] for row in json.loads(LEDGER.read_text())["repos"]]

    totals: collections.Counter[str] = collections.Counter()
    by_repo: dict[str, dict[str, list[str]]] = {}
    failures = []
    for repo in repos:
        violations, patches, error = sweep(repo, args.apply)
        if error:
            failures.append((repo, error)); print(f"❌ {repo} · {error}"); continue
        by_repo[repo] = violations
        for rules in violations.values():
            totals.update(rules)
        flag = "ok" if not violations else f"{len(violations)} file(s)"
        print(f"{'ok' if not violations else '⚠ '} {repo:38} {flag}")
        if args.details:
            for name, rules in sorted(violations.items()):
                print(f"      {name:42} {', '.join(rules)}")
        if args.apply and patches:
            error = open_pull_request(repo, patches)
            print(f"   {'✅ PR opened' if not error else '❌ ' + error} ({len(patches)} file(s))")
            if error:
                failures.append((repo, error))

    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({"repos": by_repo, "totals": dict(totals)}, indent=1) + "\n")
    print(f"\nviolations by rule: {dict(totals.most_common())}")
    print(f"report: {REPORT}")
    return 1 if (totals or failures) else 0


if __name__ == "__main__":
    sys.exit(main())
