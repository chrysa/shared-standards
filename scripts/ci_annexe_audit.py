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
# `\s` also matches the preceding newline, which inflated the measured indent of the first
# job by one and made the min-indent selection pick a nested key instead. Indentation is
# spaces.
RE_JOB = re.compile(r"^(?P<indent>[ ]{2,})(?P<name>[A-Za-z0-9_-]+):[ \t]*$", re.M)
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


def file_indent(text: str) -> str:
    """The file's own nesting step (2 or 4 spaces).

    A block written at 4 spaces inside a 2-space file is valid YAML but fails `yamllint`
    (`wrong indentation: expected 2 but found 4`), which turns a conformance fix into a red
    lint job.

    The step is measured under `jobs:`, never from the first indented line of the file: on a
    key-sorted workflow the concurrency block *this script wrote* can sit at the top, so the
    naive reading measures our own output and happily keeps a wrong indentation forever.
    """
    jobs = re.search(r"^jobs:\s*$", text, re.M)
    body = text[jobs.end():] if jobs else text
    for line in body.splitlines():
        match = re.match(r"^( +)\S", line)
        if match:
            return match.group(1)
    return "  "


def concurrency_block(text: str, cancel: str) -> str:
    step = file_indent(text)
    return ("concurrency:\n"
            f"{step}group: ${{{{ github.workflow }}}}-${{{{ github.ref }}}}\n"
            f"{step}cancel-in-progress: {cancel}\n\n")


def reindent_concurrency(text: str) -> str:
    """Re-indent a concurrency block this script wrote at the wrong nesting step."""
    step = file_indent(text)
    pattern = re.compile(
        r"^concurrency:\n"
        r"[ ]+group: \$\{\{ github\.workflow \}\}-\$\{\{ github\.ref \}\}\n"
        r"[ ]+cancel-in-progress: (?P<cancel>true|false)\n",
        re.M,
    )
    return pattern.sub(
        lambda m: ("concurrency:\n"
                   f"{step}group: ${{{{ github.workflow }}}}-${{{{ github.ref }}}}\n"
                   f"{step}cancel-in-progress: {m.group('cancel')}\n"),
        text,
    )


def is_deploy(name: str, text: str) -> bool:
    stem = name.rsplit(".", 1)[0].lower()
    return any(h in stem for h in DEPLOY_HINTS) or "environment:" in text


def job_blocks(text: str) -> list[tuple[str, str]]:
    """(job name, block) for each entry under a top-level `jobs:` mapping."""
    # `\s*$` in multiline mode swallows the newline *and* the next line's indentation, so
    # the first job key lost its indent and never matched RE_JOB — the parser then locked
    # onto whatever came next (often a trigger under `on:` on a key-sorted file).
    start = re.search(r"^jobs:[ \t]*$", text, re.M)
    if not start:
        return []
    body = text[start.end():]
    # Stop at the next top-level key: on a key-sorted workflow `jobs:` can come first, and
    # everything after it — `on:`, `permissions:` — would otherwise be read as more jobs.
    next_top = re.search(r"^\S", body, re.M)
    if next_top:
        body = body[: next_top.start()]
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


def dedupe_timeouts(text: str) -> str:
    """Drop a repeated `timeout-minutes:` line left by the first sweep.

    That sweep replaced a `runs-on:` line globally with a count of 1, so on a file whose jobs
    share the same runner the insertion landed on the *first* job once per sibling — producing
    a duplicate YAML key, which actionlint rejects outright. It also hit jobs that already
    declared a timeout, leaving two different values; the repo's own value wins, since it was
    chosen for that job and the swept one is only a default.
    """

    def keep_one(match: re.Match[str]) -> str:
        indent = match.group("indent")
        values = re.findall(r"timeout-minutes:[ ]*(\d+)", match.group(0))
        chosen = next((v for v in values if int(v) != DEFAULT_TIMEOUT), values[0])
        return f"{indent}timeout-minutes: {chosen}\n"

    return re.sub(
        r"^(?P<indent>[ ]+)timeout-minutes:[ ]*\d+[ ]*\n"
        r"(?:(?P=indent)timeout-minutes:[ ]*\d+[ ]*\n)+",
        keep_one,
        text,
        flags=re.M,
    )


def fix(text: str, name: str) -> str | None:
    """Deterministic fixes only: concurrency group (CI-031) and job timeout (CI-030)."""
    patched = dedupe_timeouts(text)

    if re.search(r"^\s*pull_request(_target)?:", patched, re.M) and not re.search(
        r"^concurrency:", patched, re.M
    ):
        cancel = "false" if is_deploy(name, patched) else "true"
        block = concurrency_block(patched, cancel)
        anchor = re.search(r"^jobs:\s*$", patched, re.M)
        if anchor:
            patched = patched[:anchor.start()] + block + patched[anchor.start():]
    else:
        patched = reindent_concurrency(patched)

    # Rebuild the file block by block. A global `str.replace` cannot work here: sibling jobs
    # share the exact same `runs-on: ubuntu-latest` line, so every insertion would land on the
    # first occurrence and the later jobs would silently keep no timeout at all.
    blocks = job_blocks(patched)
    if blocks:
        head = patched[: patched.index(blocks[0][1])]
        rebuilt = [head]
        for _, block in blocks:
            if "timeout-minutes:" not in block and not ("uses:" in block and "steps:" not in block):
                runs_on = re.search(r"^(\s*)runs-on:.*$", block, re.M)
                if runs_on:
                    indent, line = runs_on.group(1), runs_on.group(0)
                    block = block.replace(
                        line, f"{line}\n{indent}timeout-minutes: {DEFAULT_TIMEOUT}", 1
                    )
            rebuilt.append(block)
        patched = "".join(rebuilt)

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
    unread: list[str] = []
    for name in names:
        text, status = api_text(f"repos/{OWNER}/{repo}/contents/{WORKFLOW_DIR}/{name}")
        if status == "absent":
            continue
        if text is None:
            # One throttled read used to abort the whole repo, so every file after it went
            # uncounted and the fleet total read *lower* than reality — an audit that
            # under-reports is worse than one that fails. Record it and keep going.
            unread.append(name)
            continue
        found = inspect(text, name)
        if found:
            violations[name] = found
        if apply:
            patched = fix(text, name)
            if patched:
                patches[name] = patched
    if unread:
        return violations, patches, f"{len(unread)} file(s) unreadable: {', '.join(unread[:3])}"
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
