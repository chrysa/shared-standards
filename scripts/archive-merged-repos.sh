#!/usr/bin/env bash
# archive-merged-repos.sh
# Archive les repos fusionnés selon ADRs actés
#
# ADR-0010: pre-commit-hooks-changelog → pre-commit-tools
# ADR-0011: linkendin-resume + my-resume → resume (frozen, ADR-0025)
# ADR-0014: RÉVOQUÉ par ADR-0026 → windows-autonome + agent-config restent séparés (Socle)
# ADR-0015: doc-gen → CodeDoc AI (CONFLIT avec ADR-0024 → séparation, donc pas d'archive)
#
# Prérequis: gh auth login + vérification que repos cibles contiennent bien le code fusionné
# Usage: ./archive-merged-repos.sh [--dry-run]

set -uo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Paires (repo, ADR, target_repo)
# NOTE: windows-autonome + agent-config NE sont PAS listés ici (ADR-0026 révoque ADR-0014)
declare -A MERGED
MERGED=(
  [pre-commit-hooks-changelog]="ADR-0010:pre-commit-tools"
  [linkendin-resume]="ADR-0011:resume"
  # [windows-autonome]="ADR-0014:chrysa-workstation"  # RÉVOQUÉ par ADR-0026
  # [agent-config]="ADR-0014:chrysa-workstation"       # RÉVOQUÉ par ADR-0026
  # [doc-gen]="ADR-0015:CodeDoc-AI"                    # BLOQUÉ par ADR-0024 (séparation)
)

archive_merged() {
  local repo=$1
  local info=$2
  local adr=${info%%:*}
  local target=${info##*:}

  # Check target exists
  if ! gh api "/repos/chrysa/$target" --silent >/dev/null 2>&1; then
    echo "⚠️  Target chrysa/$target n'existe pas encore → skip $repo (pas sûr de la fusion)"
    return 1
  fi

  # Check already archived
  local is_archived
  is_archived=$(gh api "/repos/chrysa/$repo" --jq '.archived' 2>/dev/null || echo "?")

  if [[ "$is_archived" == "true" ]]; then
    echo "📦 chrysa/$repo déjà archivé ($adr)"
    return 0
  fi

  if $DRY_RUN; then
    echo "[DRY-RUN] archive chrysa/$repo ($adr → $target)"
    return 0
  fi

  echo "→ Archiving chrysa/$repo ($adr, fusionné dans $target)..."
  if gh api -X PATCH "/repos/chrysa/$repo" -f archived=true --silent; then
    echo "  ✅ archived"
    # Déplacer localement (avec auto-rollback des changements non committés)
    local local_path="/home/anthony/Documents/perso/projects/chrysa/$repo"
    if [[ -d "$local_path" && ! -d "$local_path/../_archived/$repo" ]]; then
      local dirty
      dirty=$(cd "$local_path" && git status --porcelain 2>/dev/null | wc -l)
      if [[ "$dirty" -gt 0 ]]; then
        echo "  🧹 $repo a $dirty fichiers modifiés — rollback avant archive"
        (cd "$local_path" && git checkout -- . 2>/dev/null && git clean -fd 2>/dev/null) || true
      fi
      mv "$local_path" "$local_path/../_archived/"
      echo "  ✅ moved local to _archived/"
    fi
    return 0
  else
    echo "  ❌ failed"
    return 1
  fi
}

for repo in "${!MERGED[@]}"; do
  archive_merged "$repo" "${MERGED[$repo]}"
done

echo ""
echo "✅ Done"
echo ""
echo "ℹ️  ADRs en vigueur pour ce script :"
echo "   - ADR-0010 : pre-commit-hooks-changelog → pre-commit-tools (fusionné)"
echo "   - ADR-0011 + ADR-0025 : linkendin-resume → resume (frozen)"
echo "   - ADR-0014 : RÉVOQUÉ par ADR-0026 · windows-autonome + agent-config restent séparés en Socle"
echo "   - ADR-0015 / ADR-0024 : doc-gen séparé de CodeDoc AI → pas d'archive"
