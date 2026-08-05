"""Pin third-party GitHub Actions by commit SHA (CI-010).

A tag is a mutable pointer: whoever owns the action can move it, and every workflow that
references it then runs different code with the caller's token in scope. Annexe `CI-010`
therefore requires a 40-character commit SHA, with the human version kept in a trailing
comment so the pin stays readable and Dependabot can still bump it.

The SHA is resolved from the GitHub API, never guessed:

    uses: actions/checkout@v5.0.0
    →  uses: actions/checkout@08c6903cd8c0fde910a37f88322edcfb5dd907a8 # v5.0.0

Deliberately left alone:

* **internal actions** (`chrysa/*`) — `CI-011` pins those by tag on purpose, so the fleet
  moves deliberately when a shared action is released;
* **local actions** (`./.github/actions/...`) — no ref to pin;
* **branch refs** (`@main`, `@master`) — pinning the branch's current tip would silently
  freeze a moving target at an arbitrary point; that is a decision, not a mechanical fix;
* anything whose ref cannot be resolved.

Usage:
    python ci_pin_actions_sha.py                 # audit
    python ci_pin_actions_sha.py --apply [repo…] # open one PR per repo

Exit: 0 nothing to do · 1 findings or failures · 2 usage error.
"""

from __future__ import annotations

import argparse
import functools
import json
import pathlib
import re
import subprocess
import sys
import time

OWNER = "chrysa"
WORKFLOW_DIR = ".github/workflows"
BRANCH = "ci/pin-actions-sha"
LEDGER = pathlib.Path(__file__).resolve().parent.parent / "compliance" / "branch-policy.json"

RE_USES = re.compile(
    r"(?P<head>uses:[ ]*)(?P<owner>[\w.-]+)/(?P<repo>[\w.-]+)(?P<path>(?:/[\w.-]+)*)"
    r"@(?P<ref>[\w.\-/]+)(?P<tail>[ ]*(?:#[^\n]*)?)"
)
RE_SHA = re.compile(r"^[0-9a-f]{40}$")


def gh(args: list[str], stdin: str | None = None, attempts: int = 4) -> tuple[int, str, str]:
    for attempt in range(attempts):
        done = subprocess.run(["gh", *args], capture_output=True, text=True, input=stdin)
        if done.returncode == 0:
            return 0, done.stdout, done.stderr
        if "404" in done.stderr or "Not Found" in done.stderr:
            return done.returncode, done.stdout, done.stderr
        if attempt < attempts - 1:
            time.sleep(5 * (attempt + 1))
    return done.returncode, done.stdout, done.stderr


@functools.cache
def resolve(action: str, ref: str) -> str | None:
    """Commit SHA a tag points at. Annotated tags dereference to their commit."""
    code, out, _ = gh(["api", f"repos/{action}/git/ref/tags/{ref}",
                       "-q", ".object.sha + \" \" + .object.type"])
    if code != 0:
        return None
    sha, _, kind = out.strip().partition(" ")
    if kind == "tag":
        code, out, _ = gh(["api", f"repos/{action}/git/tags/{sha}", "-q", ".object.sha"])
        if code != 0:
            return None
        sha = out.strip()
    return sha if RE_SHA.match(sha) else None


def pin(text: str) -> tuple[str, list[str]]:
    """(patched workflow, reasons a reference was left alone)."""
    skipped: list[str] = []

    def replace(match: re.Match[str]) -> str:
        action = f"{match.group('owner')}/{match.group('repo')}"
        ref = match.group("ref")
        if match.group("owner") == OWNER:
            return match.group(0)          # CI-011 pins internal actions by tag
        if RE_SHA.match(ref):
            return match.group(0)
        if not ref.startswith("v") or not any(c.isdigit() for c in ref):
            skipped.append(f"{action}@{ref}: branch or non-version ref — needs a decision")
            return match.group(0)
        sha = resolve(action, ref)
        if not sha:
            skipped.append(f"{action}@{ref}: tag not resolvable")
            return match.group(0)
        return (f"{match.group('head')}{action}{match.group('path')}@{sha} # {ref}")

    patched = RE_USES.sub(replace, text)
    return patched, skipped


def open_pull_request(repo: str, patches: dict[str, str]) -> str:
    full = f"{OWNER}/{repo}"
    code, sha, _ = gh(["api", f"repos/{full}/git/ref/heads/develop", "-q", ".object.sha"])
    if code != 0:
        return "no develop branch"
    base = sha.strip()
    gh(["api", f"repos/{full}/git/refs", "-X", "POST",
        "-f", f"ref=refs/heads/{BRANCH}", "-f", f"sha={base}"])

    tree = json.dumps({
        "base_tree": base,
        "tree": [{"path": f"{WORKFLOW_DIR}/{n}", "mode": "100644", "type": "blob", "content": c}
                 for n, c in sorted(patches.items())],
    })
    code, tree_sha, err = gh(
        ["api", f"repos/{full}/git/trees", "-X", "POST", "--input", "-", "-q", ".sha"], stdin=tree)
    if code != 0:
        return f"tree failed: {err.strip().splitlines()[0][:70]}"

    message = ("ci: pin third-party actions by commit SHA (CI-010)\n\n"
               "A tag is a mutable pointer — its owner can move it, and every workflow\n"
               "referencing it then runs different code with this repo's token in scope.\n"
               "The version stays in a trailing comment so Dependabot can still bump it.")
    commit = json.dumps({"message": message, "tree": tree_sha.strip(), "parents": [base]})
    code, commit_sha, err = gh(
        ["api", f"repos/{full}/git/commits", "-X", "POST", "--input", "-", "-q", ".sha"],
        stdin=commit)
    if code != 0:
        return f"commit failed: {err.strip().splitlines()[0][:70]}"
    # An empty tree means the patch produced nothing; opening the PR anyway yields a
    # zero-diff pull request that merges cleanly and changes nothing.
    code, parent_tree, _ = gh(["api", f"repos/{full}/git/commits/{base}", "-q", ".tree.sha"])
    if code == 0 and parent_tree.strip() == tree_sha.strip():
        return "produced no change — refusing to open an empty PR"
    code, _, err = gh(["api", f"repos/{full}/git/refs/heads/{BRANCH}", "-X", "PATCH",
                       "-f", f"sha={commit_sha.strip()}", "-F", "force=true"])
    if code != 0:
        return f"ref update failed: {err.strip().splitlines()[0][:70]}"

    body = (
        "Third-party actions are now pinned by 40-character commit SHA, with the version "
        "kept in a trailing comment (annexe "
        "[`CI-010`](https://github.com/chrysa/shared-standards/blob/main/standards/annexes/"
        "CI-CD.md)).\n\n"
        "A tag is a **mutable pointer**: whoever owns the action can move it, and every "
        "workflow referencing it then runs different code — with this repository's token in "
        "scope. Pinning by SHA is what makes a supply-chain change visible in a diff instead "
        "of silent.\n\n"
        "Each SHA was resolved from the GitHub API, never guessed. Left alone on purpose: "
        "`chrysa/*` actions (`CI-011` pins those by tag so the fleet moves deliberately), "
        "local `./.github/actions/…` references, and branch refs — freezing a moving target "
        "at an arbitrary tip is a decision, not a mechanical fix.\n\n"
        "The trailing comment keeps Dependabot able to bump these."
    )
    code, _, err = gh(["pr", "create", "-R", full, "--base", "develop", "--head", BRANCH,
                       "--title", "ci: pin third-party actions by commit SHA (CI-010)",
                       "--body", body])
    if code != 0 and "already exists" not in err:
        return f"pr failed: {err.strip().splitlines()[0][:70]}"
    return ""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("repos", nargs="*")
    args = parser.parse_args()

    repos = args.repos
    if not repos:
        if not LEDGER.exists():
            print(f"ledger not found: {LEDGER}", file=sys.stderr)
            return 2
        repos = [row["repo"] for row in json.loads(LEDGER.read_text())["repos"]]

    pinned, failures, skips = 0, [], 0
    for repo in repos:
        code, listing, _ = gh(["api", f"repos/{OWNER}/{repo}/contents/{WORKFLOW_DIR}",
                               "-q", ".[].name"])
        if code != 0:
            continue
        patches: dict[str, str] = {}
        for name in listing.split():
            if not name.endswith((".yml", ".yaml")):
                continue
            code, text, err = gh(["api", f"repos/{OWNER}/{repo}/contents/{WORKFLOW_DIR}/{name}",
                                  "-H", "Accept: application/vnd.github.raw"])
            if code != 0:
                if "404" not in err:
                    failures.append((repo, f"{name}: unreadable"))
                continue
            patched, reasons = pin(text)
            for reason in reasons:
                skips += 1
                print(f"⚠  {repo}/{name}: {reason}")
            if patched != text:
                patches[name] = patched
        if not patches:
            continue
        pinned += len(patches)
        print(f"{'✅' if args.apply else '·'}  {repo}: {', '.join(sorted(patches))}")
        if args.apply:
            error = open_pull_request(repo, patches)
            if error:
                failures.append((repo, error))
                print(f"❌ {repo}: {error}")

    print(f"\nfiles {'pinned' if args.apply else 'to pin'}: {pinned} · "
          f"left alone: {skips} · failures: {len(failures)}")
    return 1 if (pinned or failures) else 0


if __name__ == "__main__":
    sys.exit(main())
