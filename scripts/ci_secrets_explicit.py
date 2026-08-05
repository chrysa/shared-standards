"""Replace `secrets: inherit` with the explicit list the callee actually declares (CI-021).

`secrets: inherit` hands a reusable workflow the caller's **entire** secret store — a CI
workflow that only needs a Sonar token receives the deploy credentials too. Annexe
`CI-CD.md` (CI-021) bans it: a caller passes, by name, exactly the secrets the callee
declares.

The mapping is never guessed. For each `secrets: inherit` the script:

1. finds the `uses:` of the job that carries it,
2. reads that workflow **at the ref the caller pins**, and
3. emits one line per secret declared in its `on.workflow_call.secrets` block.

It refuses to touch a file when the answer cannot be read:

* the callee declares nothing — either the `inherit` is noise, or the callee reads an
  undeclared secret (its own defect). Removing the inherit would break it silently, which
  is exactly the failure `chrysa/github-actions#241` fixed for `release.yml`.
* the callee is third-party, or its ref cannot be resolved.

`GITHUB_TOKEN` is never emitted: GitHub grants it to the callee automatically, so passing
it is redundant, and it is not declarable as a `workflow_call` secret anyway.

Usage:
    python ci_secrets_explicit.py                 # audit: what would change, and why not
    python ci_secrets_explicit.py --apply [repo…] # open one PR per repo

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
BRANCH = "ci/explicit-secrets"
LEDGER = pathlib.Path(__file__).resolve().parent.parent / "compliance" / "branch-policy.json"

# A trailing comment is common on this line (`# pragma: allowlist secret`, or a note
# explaining why inherit was needed) — without it in the pattern the whole file is
# silently skipped and reads as "nothing to do". Any comment block immediately above
# that argues for the inherit is dropped with it: left behind, it documents the
# opposite of what the file now does.
RE_INHERIT = re.compile(
    r"(?P<lead>(?:^[ ]+#[^\n]*\n)*)"
    r"^(?P<indent>[ ]+)secrets:[ ]*inherit[ ]*(?:#[^\n]*)?$",
    re.M,
)
RE_REUSABLE = re.compile(
    r"uses:\s*(?P<owner>[\w.-]+)/(?P<repo>[\w.-]+)/(?P<path>\.github/workflows/[\w.-]+\.ya?ml)"
    r"@(?P<ref>[\w.\-/]+)"
)


def gh(args: list[str], stdin: str | None = None, attempts: int = 4) -> tuple[int, str, str]:
    """Run `gh`, retrying a throttled call — a rate-limited read is a hole in the
    measurement, not an answer."""
    for attempt in range(attempts):
        done = subprocess.run(["gh", *args], capture_output=True, text=True, input=stdin)
        if done.returncode == 0:
            return 0, done.stdout, done.stderr
        if "404" in done.stderr or "Not Found" in done.stderr:
            return done.returncode, done.stdout, done.stderr
        if attempt < attempts - 1:
            time.sleep(5 * (attempt + 1))
    return done.returncode, done.stdout, done.stderr


def read(repo: str, path: str, ref: str | None = None) -> tuple[str | None, str]:
    query = f"repos/{repo}/contents/{path}" + (f"?ref={ref}" if ref else "")
    code, body, err = gh(["api", query, "-H", "Accept: application/vnd.github.raw"])
    if code == 0:
        return body, "ok"
    if "404" in err or "Not Found" in err:
        return None, "absent"
    return None, err.strip().splitlines()[0][:80] if err else "error"


def declared_secrets(text: str) -> list[str] | None:
    """Secret names in the callee's `workflow_call` contract, or None if unparseable."""
    try:
        document = yaml.safe_load(text)
    except yaml.YAMLError:
        return None
    if not isinstance(document, dict):
        return None
    # PyYAML resolves the bare key `on:` to the boolean True.
    triggers = document.get("on", document.get(True)) or {}
    call = (triggers or {}).get("workflow_call") or {}
    secrets = call.get("secrets") or {}
    if not isinstance(secrets, dict):
        return []
    return [name for name in secrets if name != "GITHUB_TOKEN"]


def resolve(caller_text: str, position: int) -> tuple[str, str, str] | None:
    """(repo, path, ref) of the reusable workflow whose job carries this `secrets: inherit`.

    Searched backwards from the inherit, because `uses:` sits above it in the job block.
    """
    matches = [m for m in RE_REUSABLE.finditer(caller_text) if m.start() < position]
    if not matches:
        return None
    last = matches[-1]
    return f"{last.group('owner')}/{last.group('repo')}", last.group("path"), last.group("ref")


def rewrite(text: str, names: list[str], indent: str, span: tuple[int, int]) -> str:
    step = indent + "    "
    lines = [f"{indent}secrets:"] + [f"{step}{n}: ${{{{ secrets.{n} }}}}" for n in names]
    return text[: span[0]] + "\n".join(lines) + text[span[1]:]


def keeps_lead(lead: str) -> str:
    """Keep the comment block above the inherit, unless it argues for it.

    The decision is per *block*, never per line: these notes run over several lines, and
    dropping only the line containing the word leaves a truncated sentence that still reads
    as an argument for what the file no longer does.
    """
    if not lead:
        return ""
    if "inherit" in lead.lower():
        return ""
    return lead


def process(repo: str) -> tuple[dict[str, str], list[str]]:
    """(patched files, human-readable skips)."""
    code, listing, _ = gh(["api", f"repos/{OWNER}/{repo}/contents/{WORKFLOW_DIR}", "-q", ".[].name"])
    if code != 0:
        return {}, [f"{repo}: cannot list workflows"]

    patches: dict[str, str] = {}
    skips: list[str] = []
    for name in listing.split():
        if not name.endswith((".yml", ".yaml")):
            continue
        text, status = read(f"{OWNER}/{repo}", f"{WORKFLOW_DIR}/{name}")
        if status != "ok" or text is None:
            if status != "absent":
                skips.append(f"{repo}/{name}: unreadable ({status})")
            continue

        patched = text
        while True:
            match = RE_INHERIT.search(patched)
            if not match:
                break
            target = resolve(patched, match.start())
            if not target:
                skips.append(f"{repo}/{name}: no reusable `uses:` above the inherit")
                break
            callee_repo, callee_path, ref = target
            if not callee_repo.startswith(f"{OWNER}/"):
                skips.append(f"{repo}/{name}: third-party callee {callee_repo} — left alone")
                break
            callee_text, callee_status = read(callee_repo, callee_path, ref)
            if callee_text is None:
                skips.append(f"{repo}/{name}: callee unreadable at {ref} ({callee_status})")
                break
            names = declared_secrets(callee_text)
            if names is None:
                skips.append(f"{repo}/{name}: callee {callee_path} does not parse")
                break
            if not names:
                skips.append(
                    f"{repo}/{name}: {callee_path}@{ref} declares no secret — "
                    "fix the callee first, removing the inherit would break it silently"
                )
                break
            start = match.start() + len(keeps_lead(match.group("lead")))
            patched = (patched[: match.start()] + keeps_lead(match.group("lead"))
                       + rewrite(patched, names, match.group("indent"),
                                 (start, match.end()))[start:])

        if patched != text:
            patches[name] = patched
    return patches, skips


def open_pull_request(repo: str, patches: dict[str, str]) -> str:
    full = f"{OWNER}/{repo}"
    code, sha, _ = gh(["api", f"repos/{full}/git/ref/heads/develop", "-q", ".object.sha"])
    if code != 0:
        return "no develop branch"
    base = sha.strip()
    gh(["api", f"repos/{full}/git/refs", "-X", "POST",
        "-f", f"ref=refs/heads/{BRANCH}", "-f", f"sha={base}"])

    message = ("ci: pass secrets explicitly instead of `secrets: inherit` (CI-021)\n\n"
               "`inherit` hands the callee the caller's entire secret store. Each secret\n"
               "below is one the called workflow declares in its workflow_call contract.")
    tree = json.dumps({
        "base_tree": base,
        "tree": [{"path": f"{WORKFLOW_DIR}/{n}", "mode": "100644", "type": "blob", "content": c}
                 for n, c in sorted(patches.items())],
    })
    code, tree_sha, err = gh(
        ["api", f"repos/{full}/git/trees", "-X", "POST", "--input", "-", "-q", ".sha"], stdin=tree)
    if code != 0:
        return f"tree failed: {err.strip().splitlines()[0][:70]}"
    commit = json.dumps({"message": message, "tree": tree_sha.strip(), "parents": [base]})
    code, commit_sha, err = gh(
        ["api", f"repos/{full}/git/commits", "-X", "POST", "--input", "-", "-q", ".sha"],
        stdin=commit)
    if code != 0:
        return f"commit failed: {err.strip().splitlines()[0][:70]}"
    code, _, err = gh(["api", f"repos/{full}/git/refs/heads/{BRANCH}", "-X", "PATCH",
                       "-f", f"sha={commit_sha.strip()}", "-F", "force=true"])
    if code != 0:
        return f"ref update failed: {err.strip().splitlines()[0][:70]}"

    body = ("`secrets: inherit` hands the called workflow the **entire** secret store of this "
            "repository — a CI job that needs a Sonar token also receives the deploy "
            "credentials, and nothing at the call site says which secrets are actually used. "
            "Annexe [`CI-021`](https://github.com/chrysa/shared-standards/blob/main/standards/"
            "annexes/CI-CD.md) bans it.\n\n"
            "Each secret listed here is read from the called workflow's own `workflow_call` "
            "contract — nothing is guessed. `GITHUB_TOKEN` is deliberately absent: GitHub "
            "grants it to the callee automatically.")
    code, _, err = gh(["pr", "create", "-R", full, "--base", "develop", "--head", BRANCH,
                       "--title", "ci: pass secrets explicitly instead of `secrets: inherit`",
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

    changed, failures, all_skips = 0, [], []
    for repo in repos:
        patches, skips = process(repo)
        all_skips += skips
        for skip in skips:
            print(f"⚠  {skip}")
        if not patches:
            continue
        changed += len(patches)
        print(f"{'✅' if args.apply else '·'}  {repo}: {', '.join(sorted(patches))}")
        if args.apply:
            error = open_pull_request(repo, patches)
            if error:
                failures.append((repo, error))
                print(f"❌ {repo}: {error}")

    print(f"\nfiles {'patched' if args.apply else 'to patch'}: {changed} · "
          f"skipped: {len(all_skips)} · failures: {len(failures)}")
    return 1 if (changed or all_skips or failures) else 0


if __name__ == "__main__":
    sys.exit(main())
