#!/usr/bin/env bash
# archive-obsolete-repos.sh
# Archive les 9 repos déjà dans _archived/ local mais pas archivés GitHub-side
# Ajoute aussi les repos découverts via gh repo list --all comme legacy présumés
#
# Prérequis: gh auth login valide
# Usage: ./archive-obsolete-repos.sh [--dry-run]

set -uo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Repos déjà dans _archived/ local (connus)
ARCHIVED_LOCAL=(
  Al-Cu
  django_evolve
  django-struct
  dj-custom_struct_app
  foodle-test
  framewok42
  gae-toolbox-2
  izeberg-test
  test-figma-to-gh
)

# Legacy présumés découverts via gh repo list --all (à archiver par défaut)
LEGACY_UNKNOWN=(
  Balsa
  django-test
  unixpackage
  unixpackage.github.io
  42_save
)

# Obsolètes confirmés explicitement par l'utilisateur
USER_CONFIRMED_OBSOLETE=(
  DJango-CustomeCommands   # confirmé 2026-04-20 par user
)

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"

archive_repo() {
  local repo=$1
  local reason=$2

  if $DRY_RUN; then
    echo "[DRY-RUN] gh api -X PATCH /repos/chrysa/$repo -f archived=true  # $reason"
    # En dry-run on signale aussi le mv local potentiel
    if [[ -d "$CHRYSA_ROOT/$repo" && ! -d "$CHRYSA_ROOT/_archived/$repo" ]]; then
      echo "[DRY-RUN] mv $CHRYSA_ROOT/$repo $CHRYSA_ROOT/_archived/"
    fi
    return 0
  fi

  # Check already archived
  local is_archived
  is_archived=$(gh api "/repos/chrysa/$repo" --jq '.archived' 2>/dev/null || echo "?")

  if [[ "$is_archived" == "true" ]]; then
    echo "📦 chrysa/$repo déjà archivé"
  elif [[ "$is_archived" == "?" ]]; then
    echo "❌ chrysa/$repo non accessible"
    return 1
  else
    echo "→ Archiving chrysa/$repo ($reason)..."
    if gh api -X PATCH "/repos/chrysa/$repo" -f archived=true --silent; then
      echo "  ✅ archived GitHub-side"
    else
      echo "  ❌ failed"
      return 1
    fi
  fi

  # Déplacement local vers _archived/ si présent et pas déjà archivé localement
  if [[ -d "$CHRYSA_ROOT/$repo" && ! -d "$CHRYSA_ROOT/_archived/$repo" ]]; then
    mkdir -p "$CHRYSA_ROOT/_archived"
    # Auto-rollback des changements non committés — on archive de toute façon
    local dirty
    dirty=$(cd "$CHRYSA_ROOT/$repo" && git status --porcelain 2>/dev/null | wc -l)
    if [[ "$dirty" -gt 0 ]]; then
      echo "  🧹 $repo a $dirty fichiers modifiés — rollback avant archive"
      (cd "$CHRYSA_ROOT/$repo" && git checkout -- . 2>/dev/null && git clean -fd 2>/dev/null) || true
    fi
    mv "$CHRYSA_ROOT/$repo" "$CHRYSA_ROOT/_archived/"
    echo "  ✅ moved local to _archived/"
  fi
  return 0
}

echo "=== Batch 1 · repos _archived/ local ==="
for repo in "${ARCHIVED_LOCAL[@]}"; do
  archive_repo "$repo" "dans _archived/ local"
done

echo ""
echo "=== Batch 2 · legacy inconnus ==="
for repo in "${LEGACY_UNKNOWN[@]}"; do
  archive_repo "$repo" "legacy inconnu"
done

echo ""
echo "=== Batch 3 · obsolètes confirmés user ==="
for repo in "${USER_CONFIRMED_OBSOLETE[@]}"; do
  archive_repo "$repo" "obsolète confirmé user"
done

echo ""
echo "✅ Done"
