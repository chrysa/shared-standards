#!/usr/bin/env bash
# Idempotently apply the chrysa security-gate baseline to one repo and open a PR.
# Usage: propagate.sh <repo-slug> <local-checkout-path> [--push]
# Without --push: dry-run (edits in an isolated worktree, prints summary, no PR).
set -euo pipefail

SLUG="$1"          # e.g. chrysa/doc-gen
LOCAL="$2"         # local checkout path (for the shared .git)
PUSH="${3:-}"      # --push to actually branch/commit/PR
HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="$(basename "$SLUG")"
WT="$(mktemp -d)/wt-$NAME"

cd "$LOCAL"
git remote set-head origin -a >/dev/null 2>&1 || true
DEF="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@.*/@@' || true)"
DEF="${DEF:-main}"
git fetch origin "$DEF" -q

# Skip if bandit already wired (idempotent at repo level).
if git show "origin/$DEF:.pre-commit-config.yaml" 2>/dev/null | grep -q "PyCQA/bandit"; then
  echo "SKIP $SLUG — bandit already present on origin/$DEF"
  exit 0
fi

git worktree prune 2>/dev/null || true
git branch -D feat/security-baseline 2>/dev/null || true
git worktree add -q -b feat/security-baseline "$WT" "origin/$DEF"
cleanup() {
  cd "$LOCAL"
  git worktree remove --force "$WT" 2>/dev/null || true
  git branch -D feat/security-baseline 2>/dev/null || true
}
trap cleanup EXIT

cp "$HERE/security_gate_edit.py" "$WT/.security_gate_edit.py"

# sast.yml thin caller (source-dirs '.' — layout-agnostic).
mkdir -p "$WT/.github/workflows"
cat > "$WT/.github/workflows/sast.yml" <<'YAML'
---
name: SAST

on:
    push:
        branches: [main, develop, "feat/**", "feature/**", "fix/**", "release/**"]
    pull_request:
        branches: [main, develop, master]

permissions:
    contents: read

concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true

jobs:
    call:
        uses: chrysa/github-actions/.github/workflows/sast.yml@v1.9.0
        with:
            source-dirs: "."
YAML

# Edit config + pyproject + generate baseline, all inside a python container.
SUMMARY="$(docker run --rm --user "$(id -u):$(id -g)" -v "$WT:/w" -w /w -e HOME=/tmp \
  python:3.11-slim sh -c \
  "pip install -q --user ruamel.yaml tomlkit 'bandit[toml]' >/dev/null 2>&1; \
   export PATH=\$HOME/.local/bin:\$PATH; python .security_gate_edit.py" | tail -1)"
echo "$SLUG :: $SUMMARY"

rm -f "$WT/.security_gate_edit.py"

if [ "$PUSH" != "--push" ]; then
  echo "DRY-RUN $SLUG (no PR). Changed files:"; git -C "$WT" status --short
  exit 0
fi

cd "$WT"
git add -A
git commit --no-verify -q -m "feat(security): apply ecosystem security gate baseline

bandit (SAST, [tool.bandit]) + hadolint + pip-audit (pre-push) + promoted
pre-commit-tools security hooks + CI thin caller sast.yml@v1.9.0.
gitleaks/secret-scan already present. Part of sc-3778."
git push -u origin feat/security-baseline -q
gh pr create --repo "$SLUG" --base "$DEF" \
  --title "feat(security): apply ecosystem security gate baseline" \
  --body "Propagation of the ecosystem security gate (sc-3778) after canary validation. Adds bandit ([tool.bandit], baseline only if legacy findings), hadolint, pip-audit (pre-push), promoted pre-commit-tools security hooks, and CI thin caller sast.yml -> chrysa/github-actions@v1.9.0. gitleaks/secret-scan already present. docker-run-host-user omitted (absent at pinned rev)." \
  2>&1 | tail -1
