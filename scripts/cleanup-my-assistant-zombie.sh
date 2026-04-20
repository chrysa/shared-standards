#!/usr/bin/env bash
# cleanup-my-assistant-zombie.sh
# Cleanup du repo my-assistant qui est .git sans remote, 79 fichiers zombie
# Option H1 appliquée par défaut : archive local (déplacement vers _archived/)
#
# Usage: ./cleanup-my-assistant-zombie.sh [--force]

set -uo pipefail

CHRYSA_ROOT="/home/anthony/Documents/perso/projects/chrysa"
SOURCE="$CHRYSA_ROOT/my-assistant"
DEST="$CHRYSA_ROOT/_archived/my-assistant-orphan-$(date +%Y%m%d)"

FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

if [[ ! -d "$SOURCE" ]]; then
  echo "✅ $SOURCE n'existe pas, rien à faire"
  exit 0
fi

# Vérification préalable
echo "=== Vérifications pré-cleanup ==="
echo "Path: $SOURCE"
cd "$SOURCE" || exit 1

remote=$(git remote get-url origin 2>/dev/null || echo "NO_REMOTE")
last_commit=$(git log -1 --format="%H %cr" 2>/dev/null || echo "AUCUN COMMIT")
file_count=$(find . -type f -not -path "./.git/*" | wc -l)

echo "  Remote      : $remote"
echo "  Last commit : $last_commit"
echo "  File count  : $file_count"
echo ""

# Check crucial content
echo "=== Scanning pour fichiers critiques ==="
echo "Fichiers .py :"
find . -type f -name "*.py" -not -path "./.git/*" | head -10
echo ""
echo "Fichiers .md :"
find . -type f -name "*.md" -not -path "./.git/*" | head -5
echo ""
echo "Configs critiques :"
find . -maxdepth 2 -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.toml" -o -name ".env*" -o -name "requirements*" \) -not -path "./.git/*" | head -10

echo ""
echo "=== Décision ==="
echo "Mode H1 : archive local dans _archived/"
echo "Source : $SOURCE"
echo "Dest   : $DEST"

if ! $FORCE; then
  read -p "Continuer ? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Annulé"
    exit 0
  fi
fi

echo ""
echo "→ Déplacement..."
mkdir -p "$CHRYSA_ROOT/_archived"
mv "$SOURCE" "$DEST"
echo "✅ my-assistant archivé dans $DEST"
echo ""
echo "→ Pour supprimer définitivement plus tard :"
echo "  rm -rf \"$DEST\""
