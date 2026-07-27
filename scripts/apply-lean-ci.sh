#!/usr/bin/env bash
# apply-lean-ci.sh — migrate a chrysa repo to the generalized lean CI + add the
# makefile-tier marker, in one PR. Dry-run by default; pass --apply to execute
# (branch + commit + push + PR + squash --admin merge).
#
# Usage: apply-lean-ci.sh [--apply] <repo> <tier> <ci-type> <typecheck-paths>
#   ci-type: app   -> ci-python-app.yml (runs `make docker-test`)
#            lib   -> ci-python.yml (plain pytest matrix; needs <package> == typecheck pkg)
#            none  -> tier marker only (no ci.yml change)
#
# Run from the chrysa workspace root (dir containing the repo checkouts).
set -euo pipefail

APPLY=0
[ "${1:-}" = "--apply" ] && { APPLY=1; shift; }
REPO="${1:?repo}"; TIER="${2:?tier}"; CITYPE="${3:?ci-type}"; TYPECHECK="${4:-.}"
ROOT="$(pwd)"
D="$ROOT/$REPO"
[ -d "$D" ] || { echo "SKIP $REPO: not checked out"; exit 0; }

# --- compute ci.yml caller content (if any) ---
gen_app() {
cat <<EOF
---
# Thin caller of the generalized chrysa lean CI (compose-backed app).
# Gate = pre-commit; reports -> Sonar; tests via make docker-test; sonar.
# Auto-versioning stays in release.yml (GitVersion).

name: CI

on:
    pull_request:
        branches: [main]
    push:
        branches: [main, "feat/**", "fix/**", "chore/**", "ci/**"]
    workflow_dispatch:

permissions:
    contents: read
    checks: write
    pull-requests: write

concurrency:
    group: ci-\${{ github.ref }}
    cancel-in-progress: true

jobs:
    ci:
        uses: chrysa/github-actions/.github/workflows/ci-python-app.yml@main
        with:
            sources: "."
            typecheck-paths: $TYPECHECK
            project-key: chrysa_$REPO
            project-name: $REPO
            sonar-sources: "."
        secrets: inherit
EOF
}

# --- mutate working tree ---
cd "$D"
git stash -q 2>/dev/null || true
git checkout main -q 2>/dev/null || git checkout master -q
BASE=$(git rev-parse --abbrev-ref HEAD)
git fetch origin "$BASE" -q 2>/dev/null || true
git reset --hard "origin/$BASE" -q 2>/dev/null || true

CHANGED=""
# 1) makefile-tier marker (line 1) if Makefile exists and lacks it
if [ -f Makefile ] && ! head -2 Makefile | grep -q '# makefile-tier:'; then
  printf '# makefile-tier: %s\n%s' "$TIER" "$(cat Makefile)" > Makefile.tmp && mv Makefile.tmp Makefile
  CHANGED="$CHANGED Makefile"
fi
# 2) ci.yml caller
if [ "$CITYPE" = "app" ]; then
  mkdir -p .github/workflows; gen_app > .github/workflows/ci.yml; CHANGED="$CHANGED .github/workflows/ci.yml"
fi

if [ -z "$CHANGED" ]; then echo "NOCHANGE $REPO (tier=$TIER ci=$CITYPE)"; exit 0; fi

echo "PLAN $REPO: tier=$TIER ci=$CITYPE typecheck=$TYPECHECK changed=[$CHANGED ]"
if [ "$APPLY" = "0" ]; then git checkout -- . 2>/dev/null || true; exit 0; fi

# actionlint the caller if written
if echo "$CHANGED" | grep -q ci.yml; then
  docker run --rm -v "$D":/r -w /r rhysd/actionlint:latest .github/workflows/ci.yml >/dev/null 2>&1 \
    || { echo "ACTIONLINT FAIL $REPO"; git checkout -- .; exit 1; }
fi

git checkout -b chore/adopt-lean-ci -q 2>/dev/null || git checkout chore/adopt-lean-ci -q
git add $CHANGED
git commit --no-verify -q -m "chore: adopt chrysa standards — makefile-tier + lean CI

Add '# makefile-tier: $TIER' marker (docs/MAKEFILE-STANDARD.md) and, for code repos,
a thin caller of the reusable lean CI (chrysa/github-actions). Auto-versioning
unchanged (release.yml/GitVersion)."
git push --no-verify -u origin chore/adopt-lean-ci -q 2>&1 | tail -1
gh pr create -R "chrysa/$REPO" --base "$BASE" --head chore/adopt-lean-ci \
  --title "chore: adopt chrysa standards (makefile-tier + lean CI)" \
  --body "Adds the \`# makefile-tier: $TIER\` marker (docs/MAKEFILE-STANDARD.md) and a thin caller of the reusable lean CI where applicable. Auto-versioning unchanged." 2>&1 | tail -1
sleep 2
gh pr merge chore/adopt-lean-ci -R "chrysa/$REPO" --squash --admin --delete-branch 2>&1 | tail -1
echo "DONE $REPO"
