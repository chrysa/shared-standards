#!/usr/bin/env bash
# bootstrap-new-repo.sh — configure a new chrysa repo from shared-standards.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/chrysa/shared-standards/main/scripts/bootstrap-new-repo.sh | bash -s -- --type python --name dev-nexus
#
# Or locally:
#   ./bootstrap-new-repo.sh --type python --name dev-nexus
#
# Options:
#   --type      python | node | mixed  (required)
#   --name      repo slug              (required)
#   --apply     actually modify files  (default: dry-run)
#   --standards path to shared-standards checkout (default: fetch from github)
set -euo pipefail

TYPE=""
NAME=""
APPLY=false
STANDARDS=""
STANDARDS_REPO="https://github.com/chrysa/shared-standards"
STANDARDS_REF="${STANDARDS_REF:-main}"

while [ $# -gt 0 ]; do
    case "$1" in
        --type)      TYPE="$2";      shift 2 ;;
        --name)      NAME="$2";      shift 2 ;;
        --apply)     APPLY=true;     shift   ;;
        --standards) STANDARDS="$2"; shift 2 ;;
        -h|--help)   grep '^#' "$0" | head -30; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

[ -z "$TYPE" ] && { echo "--type required (python|node|mixed)" >&2; exit 1; }
[ -z "$NAME" ] && { echo "--name required" >&2; exit 1; }

case "$TYPE" in python|node|mixed) ;; *) echo "invalid --type $TYPE" >&2; exit 1 ;; esac

# ── Resolve standards checkout ───────────────────────────────────────────────
if [ -z "$STANDARDS" ]; then
    STANDARDS="$(mktemp -d)/shared-standards"
    echo "→ cloning shared-standards into $STANDARDS (ref=$STANDARDS_REF)"
    git clone --depth 1 --branch "$STANDARDS_REF" "$STANDARDS_REPO" "$STANDARDS" >/dev/null
fi

[ -d "$STANDARDS/templates" ] || { echo "templates/ not found in $STANDARDS" >&2; exit 1; }

# ── Dry-run helper ───────────────────────────────────────────────────────────
copy() {
    local src="$1" dst="$2"
    if $APPLY; then
        mkdir -p "$(dirname "$dst")"
        cp -n "$src" "$dst" && echo "  cp $src → $dst" || echo "  skip (exists): $dst"
    else
        [ -e "$dst" ] && echo "  DRY skip (exists): $dst" || echo "  DRY cp $src → $dst"
    fi
}

echo "→ Bootstrapping $NAME (type=$TYPE, apply=$APPLY)"

# ── Files applied to all types ───────────────────────────────────────────────
echo "→ common templates"
copy "$STANDARDS/templates/pre-template/.pre-commit-config.yaml" .pre-commit-config.yaml
copy "$STANDARDS/templates/compose/docker-compose.yml"            docker-compose.yml
copy "$STANDARDS/templates/compose/.env.example"                  .env.example
copy "$STANDARDS/templates/makefile/Makefile"                     Makefile
for f in install quality docker; do
    copy "$STANDARDS/templates/makefile/makefiles/${f}.makefile" "makefiles/${f}.makefile"
done
copy "$STANDARDS/templates/CODEOWNERS"                            CODEOWNERS
copy "$STANDARDS/templates/pr-template.md"                        .github/pull_request_template.md
copy "$STANDARDS/templates/copilot-instructions.md"               .github/copilot-instructions.md

# ── Type-specific files ──────────────────────────────────────────────────────
case "$TYPE" in
    python)
        copy "$STANDARDS/templates/dockerfile/Dockerfile.python"   Dockerfile
        copy "$STANDARDS/templates/gitignore/.gitignore.python"   .gitignore
        ;;
    node)
        copy "$STANDARDS/templates/dockerfile/Dockerfile.node"    Dockerfile
        copy "$STANDARDS/templates/gitignore/.gitignore.node"     .gitignore
        ;;
    mixed)
        copy "$STANDARDS/templates/dockerfile/Dockerfile.python"   Dockerfile.python
        copy "$STANDARDS/templates/dockerfile/Dockerfile.node"     Dockerfile.node
        cat "$STANDARDS/templates/gitignore/.gitignore.python" \
            "$STANDARDS/templates/gitignore/.gitignore.node" > .gitignore.tmp 2>/dev/null || true
        $APPLY && mv -n .gitignore.tmp .gitignore || echo "  DRY merge gitignore"
        ;;
esac

# ── Caller CI workflow ───────────────────────────────────────────────────────
echo "→ caller CI workflow"
if $APPLY; then
    mkdir -p .github/workflows
    case "$TYPE" in
        python|mixed)
            cat > .github/workflows/ci.yml <<EOF
---
name: CI
on:
  pull_request:
  push: { branches: [main, develop] }
jobs:
  ci:
    uses: chrysa/shared-standards/.github/workflows/ci-python.yml@main
    with:
      python-version: "3.14"
      coverage-threshold: 85
    secrets:
      SONAR_TOKEN: \${{ secrets.SONAR_TOKEN }}
EOF
            ;;
        node)
            cat > .github/workflows/ci.yml <<EOF
---
name: CI
on:
  pull_request:
  push: { branches: [main, develop] }
jobs:
  ci:
    uses: chrysa/shared-standards/.github/workflows/ci-node.yml@main
    with:
      node-version: "25"
      coverage-threshold: 80
    secrets:
      SONAR_TOKEN: \${{ secrets.SONAR_TOKEN }}
EOF
            ;;
    esac
    echo "  wrote .github/workflows/ci.yml"
else
    echo "  DRY create .github/workflows/ci.yml calling shared-standards ci-$TYPE"
fi

echo ""
echo "✅ Done."
$APPLY || echo "⚠️  Dry-run only. Re-run with --apply to modify files."
echo ""
echo "Next steps:"
echo "  1. Review the generated files"
echo "  2. Replace REPLACE-ME / REPLACE_ME markers in Dockerfile"
echo "  3. pre-commit install"
echo "  4. make install"
echo "  5. git add . && git commit -m 'chore: bootstrap from shared-standards'"
