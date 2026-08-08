#!/usr/bin/env bash
# clone-profile.sh — clone only the fleet repos a given role needs (Rain-devkit "profile" model).
#
# A front dev never clones Helm charts; an infra dev never clones the React apps.
# The profile → membership map lives in repos.yml under `profiles:` (source of truth,
# hand-tuned). This script resolves it and shallow-clones the missing repos into a
# workspace dir. It NEVER writes a `.env` and never touches secrets (see AG-005).
#
# Usage:
#   clone-profile.sh <profile> [--dir DIR] [--dry-run] [--org ORG] [--depth N]
#   clone-profile.sh --list                 # show profiles and their members
#
#   PROFILE ∈ full | front | back | ai | infra | lib | config   (see repos.yml `profiles:`)
#
# Examples:
#   clone-profile.sh front --dir ~/work/chrysa
#   clone-profile.sh full  --dry-run
#
# Exit: 0 ok · 2 bad args / repos.yml missing · 3 unknown profile
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOS_YML="${REPOS_YML:-$STD_ROOT/repos.yml}"

ORG="${CHRYSA_ORG:-chrysa}"
DIR="."
DEPTH="1"
DRY=0
PROFILE=""
LIST=0

die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit "${2:-2}"; }
info() { printf '\033[36m•\033[0m %s\n' "$*"; }
ok() { printf '\033[32m✓\033[0m %s\n' "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) shift; DIR="${1:?--dir needs a path}" ;;
    --org) shift; ORG="${1:?--org needs a value}" ;;
    --depth) shift; DEPTH="${1:?--depth needs a value}" ;;
    --dry-run) DRY=1 ;;
    --list) LIST=1 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \?//'; exit 0 ;;
    -*) die "unknown flag: $1" ;;
    *) PROFILE="$1" ;;
  esac
  shift
done

[ -f "$REPOS_YML" ] || die "repos.yml not found: $REPOS_YML"

# Extract the `profiles:` block members for a profile name.
# Block shape in repos.yml:
#   profiles:
#     front: [dashboard, my-resume, ...]
#     back:  [ai-aggregator, ...]
profile_members() {
  awk -v want="$1" '
    /^profiles:/ { inblk=1; next }
    inblk && /^[a-zA-Z]/ { inblk=0 }          # left the block (next top-level key)
    inblk {
      line=$0
      sub(/^[[:space:]]+/, "", line)
      if (line ~ /^#/ || line == "") next     # skip comments / blank lines
      # match "name: [ ... ]" or "name:" continued — we only support inline lists here
      if (line ~ "^" want ":") {
        sub("^" want ":[[:space:]]*", "", line)
        gsub(/[][]/, "", line)
        gsub(/,/, " ", line)
        print line
      }
    }
  ' "$REPOS_YML"
}

profile_names() {
  awk '
    /^profiles:/ { inblk=1; next }
    inblk && /^[a-zA-Z]/ { inblk=0 }
    inblk {
      line=$0; sub(/^[[:space:]]+/, "", line)
      if (line ~ /^#/ || line == "") next
      if (line ~ /:/) { sub(/:.*/, "", line); print line }
    }
  ' "$REPOS_YML"
}

if [ "$LIST" -eq 1 ]; then
  printf '\n  Profiles (from %s):\n\n' "$REPOS_YML"
  for p in $(profile_names); do
    printf '  \033[36m%-8s\033[0m %s\n' "$p" "$(profile_members "$p")"
  done
  printf '\n'
  exit 0
fi

[ -n "$PROFILE" ] || die "missing profile — try: $(basename "$0") --list"

# `full` = every status:dev repo (delegates to the existing source-of-truth script).
if [ "$PROFILE" = "full" ]; then
  MEMBERS="$("$SCRIPT_DIR/list-dev-repos.sh" --lines 2>/dev/null | tr '\n' ' ')"
else
  MEMBERS="$(profile_members "$PROFILE")"
  [ -n "${MEMBERS// /}" ] || die "unknown or empty profile: $PROFILE (see --list)" 3
fi

info "profile=$PROFILE  org=$ORG  dir=$DIR  depth=$DEPTH"
[ "$DRY" -eq 1 ] && info "DRY-RUN — nothing will be cloned"

mkdir -p "$DIR"
cloned=0 skipped=0
for repo in $MEMBERS; do
  [ -n "$repo" ] || continue
  dest="$DIR/$repo"
  if [ -d "$dest/.git" ]; then
    skipped=$((skipped + 1))
    info "skip (exists): $repo"
    continue
  fi
  if [ "$DRY" -eq 1 ]; then
    info "would clone: $ORG/$repo -> $dest"
    continue
  fi
  if gh repo clone "$ORG/$repo" "$dest" -- --depth "$DEPTH" >/dev/null 2>&1; then
    cloned=$((cloned + 1)); ok "cloned: $repo"
  else
    printf '\033[33m!\033[0m clone failed (skipping): %s\n' "$repo" >&2
  fi
done

printf '\n'
ok "profile '$PROFILE': cloned=$cloned skipped=$skipped"
printf '  \033[33mNote:\033[0m no .env written. Inject config at runtime (env / secret store) — AG-005.\n\n'
