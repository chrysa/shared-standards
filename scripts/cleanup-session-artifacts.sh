#!/usr/bin/env bash
# cleanup-session-artifacts.sh
# Déplace les fichiers session datés (YYYY-MM-DD) hors racine chrysa/
# vers _session_archive/YYYY-MM-DD/ pour garder la racine propre.
#
# Non destructif : déplacement, pas suppression. Annulable via `mv` inverse.
#
# Usage :
#   bash cleanup-session-artifacts.sh              # interactif (confirme par lot)
#   bash cleanup-session-artifacts.sh --dry-run
#   bash cleanup-session-artifacts.sh --yes

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
DRY_RUN=false
AUTO_YES=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --yes|-y)  AUTO_YES=true ;;
    esac
done

cd "$CHRYSA_ROOT" || exit 1

# Lib commune
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" || { echo "❌ _lib.sh introuvable"; exit 1; }
export AUTO_YES

# ─── Fichiers à garder ABSOLUMENT ─────────────────────────
KEEP_PATTERNS=(
    "TASKS.md"
    "chrysa-bootstrap.sh"
    "cross-project-issues.sh"
    "portfolio.html"
    "portfolio-public.html"
)

is_kept() {
    local f=$1
    for p in "${KEEP_PATTERNS[@]}"; do
        [[ "$f" == "$p" ]] && return 0
    done
    return 1
}

# ─── Détection fichiers session datés ─────────────────────
# Pattern : contient YYYY-MM-DD dans le nom
mapfile -t dated_files < <(ls -1 *.md *.sh *.svg *.csv *.html 2>/dev/null | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" || true)

# Fichiers UPPERCASE audit au nom générique (pas de date mais style audit)
mapfile -t audit_files < <(ls -1 *.md 2>/dev/null | grep -E "^[A-Z_]+\.md$" || true)

# Merge + dedup + filter keeps
all_candidates=()
for f in "${dated_files[@]}" "${audit_files[@]}"; do
    [[ -z "$f" ]] && continue
    is_kept "$f" && continue
    all_candidates+=("$f")
done
# dedup
mapfile -t all_candidates < <(printf '%s\n' "${all_candidates[@]}" | awk '!seen[$0]++')

if [[ ${#all_candidates[@]} -eq 0 ]]; then
    echo "✅ Aucun artefact session à archiver · racine déjà propre"
    exit 0
fi

echo -e "${c_blue}═══════════════════════════════════${c_reset}"
echo -e "${c_blue}  Cleanup session artefacts${c_reset}"
echo -e "${c_blue}═══════════════════════════════════${c_reset}"
echo ""
echo "${#all_candidates[@]} fichiers candidats :"
for f in "${all_candidates[@]}"; do
    date_str=$(echo "$f" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}" | head -1)
    [[ -z "$date_str" ]] && date_str="undated"
    printf "  %-50s → _session_archive/%s/\n" "$f" "$date_str"
done

echo ""
if ! confirm "Procéder à l'archivage ?"; then
    echo "Abandon."
    exit 0
fi

for f in "${all_candidates[@]}"; do
    date_str=$(echo "$f" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}" | head -1)
    [[ -z "$date_str" ]] && date_str="undated"
    dest_dir="_session_archive/$date_str"

    if $DRY_RUN; then
        echo "  [DRY-RUN] mv '$f' '$dest_dir/'"
    else
        mkdir -p "$dest_dir"
        mv "$f" "$dest_dir/"
        echo "  ✓ $f → $dest_dir/"
    fi
done

echo ""
$DRY_RUN && echo -e "${c_yellow}Dry-run : aucune modif réelle${c_reset}" || echo -e "${c_green}✅ ${#all_candidates[@]} fichiers archivés${c_reset}"

# Stats finales
echo ""
echo "Racine actuelle (hors dirs repos + _archived + _session_archive) :"
ls -1 *.md *.sh *.svg *.csv *.html 2>/dev/null | head -20
