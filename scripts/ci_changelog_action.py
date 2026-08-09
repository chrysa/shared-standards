"""Move repos off an inlined git-cliff call and onto `chrysa/github-actions/changelog`.

Annexe `CI-004`: the second occurrence of the same CI logic is an extraction order. The
call is inlined in 42 workflows across the fleet.

Beyond the duplication, the inlined form hides a correctness trap. `git-cliff --latest`
describes the newest tag **present in the graph**, which is right only when the workflow is
triggered *by* a tag push. In a release job that computes a version, generates the notes,
and creates the tag afterwards, the tag does not exist yet — so the notes published under
`vN` describe `vN-1`, silently, on every release. The shared action takes the computed
version and passes it as `--tag`.

This script only migrates the **mechanical** case: an `orhun/git-cliff-action` step whose
version expression can be read off the workflow. It refuses everything else, because a
wrong guess here publishes wrong release notes rather than failing:

* tag-triggered workflows — `--latest` is already correct, nothing to fix;
* a CLI invocation (`run: git-cliff …`) — the surrounding shell has to be rewritten by hand;
* no resolvable version expression;
* a step output consumed in a way the script cannot rewire.

Usage:
    python ci_changelog_action.py                 # audit
    python ci_changelog_action.py --apply [repo…] # open one PR per repo

Exit: 0 nothing to do · 1 findings or failures · 2 usage error.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
import time

import yaml

OWNER = "chrysa"
WORKFLOW_DIR = ".github/workflows"
BRANCH = "ci/use-changelog-action"
ACTION_REF = "chrysa/github-actions/changelog@v1.8.0"
LEDGER = pathlib.Path(__file__).resolve().parent.parent / "compliance" / "branch-policy.json"

RE_CLIFF_STEP = re.compile(
    r"(?P<indent>[ ]*)(?:- |)(?:[^\n]*\n\1[ ]+)*?[^\n]*orhun/git-cliff-action@[^\n]*\n"
    r"(?:\1[ ]+[^\n]*\n)*"
)
# The version the release is cutting, in the forms the fleet actually uses.
RE_VERSION = re.compile(
    r"\$\{\{\s*(?:needs\.[\w-]+\.outputs\.semVer|env\.GitVersion_SemVer"
    r"|steps\.[\w-]+\.outputs\.semVer)\s*\}\}"
)


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


def read(repo: str, path: str) -> tuple[str | None, str]:
    code, body, err = gh(["api", f"repos/{repo}/contents/{path}",
                          "-H", "Accept: application/vnd.github.raw"])
    if code == 0:
        return body, "ok"
    if "404" in err or "Not Found" in err:
        return None, "absent"
    return None, err.strip().splitlines()[0][:80] if err else "error"


def tag_triggered(text: str) -> bool:
    """True when the workflow runs on a tag push — `--latest` is correct there."""
    try:
        document = yaml.safe_load(text)
    except yaml.YAMLError:
        return False
    if not isinstance(document, dict):
        return False
    triggers = document.get("on", document.get(True)) or {}
    push = (triggers or {}).get("push") or {}
    return isinstance(push, dict) and "tags" in push


def migrate(text: str) -> tuple[str | None, str]:
    """(patched workflow, reason it was refused)."""
    if tag_triggered(text):
        return None, "tag-triggered — `--latest` already describes the released tag"
    if "orhun/git-cliff-action" not in text:
        return None, "git-cliff invoked from the shell — needs a hand rewrite"

    match = RE_CLIFF_STEP.search(text)
    if not match:
        return None, "git-cliff step shape not recognised"
    step = match.group(0)

    versions = RE_VERSION.findall(text)
    if not versions:
        return None, "no resolvable version expression in the workflow"

    indent = match.group("indent")
    keys = re.search(r"^(?P<dash>[ ]*-[ ]+)", step)
    lead = keys.group("dash") if keys else indent
    body = " " * len(lead)

    identifier = re.search(r"^[ \t-]*id:[ ]*(?P<id>[\w-]+)[ ]*$", step, re.M)
    id_line = f"{body}id: {identifier.group('id')}\n" if identifier else f"{body}id: changelog\n"
    condition = re.search(r"^[ \t-]*if:[ ]*(?P<cond>[^\n]+)$", step, re.M)
    if_line = f"{body}if: {condition.group('cond')}\n" if condition else ""

    replacement = (
        f"{lead}name: Generate changelog\n"
        f"{id_line}{if_line}"
        f"{body}uses: {ACTION_REF}\n"
        f"{body}with:\n"
        f"{body}    version: {versions[0]}\n"
    )
    patched = text[: match.start()] + replacement + text[match.end():]

    # A body read from a file the step no longer writes would publish the committed
    # changelog instead of the generated notes — refuse rather than half-migrate.
    if "body_path:" in patched:
        return None, "release body read from a file — rewire body_path to the step output first"
    return patched, ""


def commit_file(full: str, base: str, name: str, content: str) -> tuple[str, str]:
    """Build a tree + commit for one workflow file; returns (commit_sha, error).

    A non-empty error string stops the caller — including the deliberate refusal to open a
    zero-diff pull request when the tree is identical to the base.
    """
    tree = json.dumps({
        "base_tree": base,
        "tree": [{"path": f"{WORKFLOW_DIR}/{name}", "mode": "100644",
                  "type": "blob", "content": content}],
    })
    code, tree_sha, err = gh(
        ["api", f"repos/{full}/git/trees", "-X", "POST", "--input", "-", "-q", ".sha"], stdin=tree)
    if code != 0:
        return "", f"tree failed: {err.strip().splitlines()[0][:70]}"
    if tree_sha.strip() == base:
        return "", "produced no change — refusing to open an empty PR"

    message = ("ci: use the shared changelog action instead of inlining git-cliff\n\n"
               "The inlined --latest describes the newest tag in the graph; this job\n"
               "creates the tag after generating the notes, so they described the\n"
               "previous release. The action receives the computed version as --tag.")
    commit = json.dumps({"message": message, "tree": tree_sha.strip(), "parents": [base]})
    code, commit_sha, err = gh(
        ["api", f"repos/{full}/git/commits", "-X", "POST", "--input", "-", "-q", ".sha"],
        stdin=commit)
    if code != 0:
        return "", f"commit failed: {err.strip().splitlines()[0][:70]}"
    return commit_sha.strip(), ""


def open_pull_request(repo: str, name: str, content: str) -> str:
    full = f"{OWNER}/{repo}"
    code, sha, _ = gh(["api", f"repos/{full}/git/ref/heads/develop", "-q", ".object.sha"])
    if code != 0:
        return "no develop branch"
    base = sha.strip()
    gh(["api", f"repos/{full}/git/refs", "-X", "POST",
        "-f", f"ref=refs/heads/{BRANCH}", "-f", f"sha={base}"])

    commit_sha, error = commit_file(full, base, name, content)
    if error:
        return error
    code, _, err = gh(["api", f"repos/{full}/git/refs/heads/{BRANCH}", "-X", "PATCH",
                       "-f", f"sha={commit_sha}", "-F", "force=true"])
    if code != 0:
        return f"ref update failed: {err.strip().splitlines()[0][:70]}"

    body = (
        "This workflow inlined the git-cliff call — annexe `CI-004` makes the second "
        "occurrence an extraction order, and the fleet had 42 copies.\n\n"
        "It also fixes a correctness bug. The job creates the release tag **after** "
        "generating the notes, so `--latest` — which describes the newest tag *present in "
        "the graph* — described the **previous** release. Silently, every time.\n\n"
        f"`{ACTION_REF}` takes the version this workflow already computes and passes it as "
        "`--tag`, tying the notes to the release actually being cut (annexe `CI-045`).\n\n"
        "Repos whose release workflow is triggered *by* a tag push are deliberately left "
        "alone: the tag is already in the graph there, so `--latest` is correct."
    )
    code, _, err = gh(["pr", "create", "-R", full, "--base", "develop", "--head", BRANCH,
                       "--title", "ci: use the shared changelog action instead of inlining git-cliff",
                       "--body", body])
    if code != 0 and "already exists" not in err:
        return f"pr failed: {err.strip().splitlines()[0][:70]}"
    return ""


def migratable_workflows(
    repo: str,
) -> tuple[list[tuple[str, str]], list[tuple[str, str]], list[str]]:
    """([(file, patched text)], [(file, refusal reason)], [read-failure details]) for one repo."""
    code, listing, _ = gh(["api", f"repos/{OWNER}/{repo}/contents/{WORKFLOW_DIR}",
                           "-q", ".[].name"])
    if code != 0:
        return [], [], []
    candidates: list[tuple[str, str]] = []
    refusals: list[tuple[str, str]] = []
    read_failures: list[str] = []
    for name in listing.split():
        if not name.endswith((".yml", ".yaml")):
            continue
        text, status = read(f"{OWNER}/{repo}", f"{WORKFLOW_DIR}/{name}")
        if text is None:
            if status != "absent":
                read_failures.append(f"{name}: {status}")
            continue
        if "git-cliff" not in text and "git_cliff" not in text:
            continue
        patched, reason = migrate(text)
        if patched is None:
            refusals.append((name, reason))
        else:
            candidates.append((name, patched))
    return candidates, refusals, read_failures


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

    migrated, refused, failures = 0, 0, []
    for repo in repos:
        candidates, refusals, read_failures = migratable_workflows(repo)
        failures.extend((repo, detail) for detail in read_failures)
        for name, reason in refusals:
            refused += 1
            print(f"⚠  {repo}/{name}: {reason}")
        for name, patched in candidates:
            migrated += 1
            print(f"{'✅' if args.apply else '·'}  {repo}/{name}")
            if args.apply:
                error = open_pull_request(repo, name, patched)
                if error:
                    failures.append((repo, error))
                    print(f"❌ {repo}: {error}")

    print(f"\n{'migrated' if args.apply else 'migratable'}: {migrated} · "
          f"left alone: {refused} · failures: {len(failures)}")
    return 1 if (migrated or failures) else 0


if __name__ == "__main__":
    sys.exit(main())
