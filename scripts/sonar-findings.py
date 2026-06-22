#!/usr/bin/env python3
"""sonar-findings.py — emit a findings JSON of SonarCloud BLOCKER/CRITICAL issues per repo.

Source: chrysa/shared-standards/scripts/sonar-findings.py

Queries the SonarCloud REST API (sonarcloud.io, org `chrysa`) for unresolved issues of the
given severities, grouped into ONE consolidated entry per active dev repo. Output matches the
shape consumed by file-compliance-issues.sh:

    { "<repo>": { "title": str, "body": markdown, "counts": {critical,high,medium,low} }, ... }

Pipe the output into file-compliance-issues.sh to open one idempotent issue per repo:

    python3 scripts/sonar-findings.py --out docs/audits/sonar-findings-YYYYMMDD.json
    bash scripts/file-compliance-issues.sh --findings=docs/audits/sonar-findings-YYYYMMDD.json \
         --labels=sonar,chore

Auth: SONAR_TOKEN env var (read-only; HTTP GET only — safe to run on host).

Usage:
    sonar-findings.py [--severities=BLOCKER,CRITICAL] [--only=repo,repo] [--out=PATH]

Exit: 0 ok · 1 error · 2 missing dependency/token
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict

API = "https://sonarcloud.io/api"
ORG = os.environ.get("CHRYSA_ORG", "chrysa")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STD_ROOT = os.path.dirname(SCRIPT_DIR)

# SonarCloud severity -> file-compliance-issues.sh counts bucket.
SEV_BUCKET = {"BLOCKER": "critical", "CRITICAL": "high", "MAJOR": "medium", "MINOR": "low",
              "INFO": "low"}
MAX_DETAIL_ROWS = 50  # cap per-rule example detail in the issue body


def _stderr(msg: str) -> None:
    print(msg, file=sys.stderr)


def _api_get(path: str, params: dict, token: str) -> dict:
    url = f"{API}/{path}?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url)
    # SonarCloud accepts the token as HTTP Basic username with empty password.
    auth = base64.b64encode(f"{token}:".encode()).decode()
    req.add_header("Authorization", f"Basic {auth}")
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode())


def list_dev_repos(only: str | None) -> list[str]:
    cmd = [os.path.join(SCRIPT_DIR, "list-dev-repos.sh"), "--lines"]
    if only:
        cmd += ["--only", only]
    out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    return [r.strip() for r in out.splitlines() if r.strip()]


def project_key_map(token: str) -> dict[str, str]:
    """Lowercased Sonar project key -> real key (keys diverge from repo case)."""
    keys: dict[str, str] = {}
    page = 1
    while True:
        d = _api_get("components/search_projects",
                     {"organization": ORG, "ps": 200, "p": page}, token)
        for c in d.get("components", []):
            keys[c["key"].lower()] = c["key"]
        paging = d.get("paging", {})
        if paging.get("pageIndex", page) * paging.get("pageSize", 200) >= paging.get("total", 0):
            break
        page += 1
    return keys


def fetch_issues(key: str, severities: str, token: str) -> list[dict]:
    issues: list[dict] = []
    page = 1
    while True:
        d = _api_get("issues/search",
                     {"componentKeys": key, "resolved": "false", "severities": severities,
                      "ps": 500, "p": page}, token)
        issues.extend(d.get("issues", []))
        total = d.get("total", 0)
        if page * 500 >= total or not d.get("issues"):
            break
        page += 1
    return issues


def short_component(comp: str) -> str:
    """`chrysa_repo:api/foo.py` -> `api/foo.py`."""
    return comp.split(":", 1)[1] if ":" in comp else comp


def build_entry(repo: str, key: str, issues: list[dict], severities: str) -> dict:
    counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
    by_rule: dict[str, dict] = defaultdict(
        lambda: {"type": "", "severity": "", "count": 0, "example": ""})
    for it in issues:
        counts[SEV_BUCKET.get(it.get("severity", "MINOR"), "low")] += 1
        r = by_rule[it.get("rule", "?")]
        r["count"] += 1
        r["type"] = it.get("type", "")
        # Keep the highest-severity example (BLOCKER ranks above CRITICAL).
        if r["severity"] != "BLOCKER":
            r["severity"] = it.get("severity", "")
        if not r["example"]:
            loc = short_component(it.get("component", ""))
            line = it.get("line")
            r["example"] = f"{loc}:{line}" if line else loc

    deep = (f"https://sonarcloud.io/project/issues?id={urllib.parse.quote(key)}"
            f"&resolved=false&severities={severities}")
    total = len(issues)

    lines = [
        f"SonarCloud reports **{total}** unresolved `{severities}` finding(s) for "
        f"[`{key}`]({deep}).",
        "",
        "_Auto-filed from the SonarCloud API. One consolidated issue per repo; "
        "resolve findings in SonarCloud and they drop off on the next run._",
        "",
        "| Rule | Type | Severity | Count | Example |",
        "| --- | --- | --- | --- | --- |",
    ]
    rows = sorted(by_rule.items(), key=lambda kv: -kv[1]["count"])
    for rule, r in rows[:MAX_DETAIL_ROWS]:
        lines.append(
            f"| `{rule}` | {r['type']} | {r['severity']} | {r['count']} | `{r['example']}` |")
    if len(rows) > MAX_DETAIL_ROWS:
        lines.append("")
        lines.append(f"_…and {len(rows) - MAX_DETAIL_ROWS} more rule(s); "
                     f"see the [full list on SonarCloud]({deep})._")
    lines += ["", f"**Triage in SonarCloud:** {deep}"]

    return {
        "title": "SonarCloud: blocker & critical findings",
        "body": "\n".join(lines),
        "counts": counts,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--severities", default="BLOCKER,CRITICAL")
    ap.add_argument("--only", default=None, help="comma-separated repo subset")
    ap.add_argument("--out", default=None, help="write JSON here (default: stdout)")
    args = ap.parse_args()

    token = os.environ.get("SONAR_TOKEN")
    if not token:
        _stderr("SONAR_TOKEN not set"); return 2

    repos = list_dev_repos(args.only)
    keymap = project_key_map(token)

    findings: dict[str, dict] = {}
    skipped_noproj, skipped_clean = [], []
    for repo in repos:
        key = keymap.get(f"{ORG}_{repo}".lower())
        if not key:
            skipped_noproj.append(repo); continue
        issues = fetch_issues(key, args.severities, token)
        if not issues:
            skipped_clean.append(repo); continue
        findings[repo] = build_entry(repo, key, issues, args.severities)
        c = findings[repo]["counts"]
        _stderr(f"  {repo:35} {len(issues):4} findings "
                f"(blocker={c['critical']} critical={c['high']})")

    payload = json.dumps(findings, indent=2, ensure_ascii=False)
    if args.out:
        os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(payload + "\n")
        _stderr(f"\nwrote {args.out}")
    else:
        print(payload)

    _stderr(f"\nrepos with findings: {len(findings)} · clean: {len(skipped_clean)} · "
            f"no Sonar project: {len(skipped_noproj)}")
    if skipped_noproj:
        _stderr("  no project: " + ", ".join(skipped_noproj))
    return 0


if __name__ == "__main__":
    sys.exit(main())
