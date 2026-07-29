#!/usr/bin/env bash
# distribute-standards.sh · Push the chrysa shared standards into ONE target repo.
# Source: chrysa/shared-standards/scripts/distribute-standards.sh
#
# This is the single entry point used by the distribute-standards GitHub Action
# (one matrix job per repo) and runnable locally against any repo checkout.
#
# Composes, idempotently:
#   1. CLAUDE.md standards      inline the transverse standards CONTENT into a managed
#                              `<!-- chrysa:standards:start/end -->` block (create file if absent).
#                              The block is self-contained — NO `.chrysa/` copy, no `@import`.
#   2. Legacy migration        remove any old `.chrysa/standards-import` block + the vendored
#                              `.chrysa/STANDARDS.md` file left by the previous mechanism.
#   3. Shared skills           .claude/skills/*            -> <repo>/.claude/skills/   (managed copies)
#   4. Shared agents+commands  templates/claude/{agents,commands}/* -> <repo>/.claude/
#   5. Workflows + lint/quality + pre-commit  -> delegate to apply-repo-standard.sh
#
# Managed paths are overwritten on every run. Repo-specific content in CLAUDE.md is preserved;
# only the delimited standards block is touched.
#
# Usage:
#   distribute-standards.sh <repo_path>              # apply
#   distribute-standards.sh --dry-run <repo_path>    # preview, no writes
#   distribute-standards.sh --check <repo_path>      # report drift, exit 1 if any
#   distribute-standards.sh --no-apply <repo_path>   # skip apply-repo-standard.sh delegation
#   distribute-standards.sh --standards-only <repo>  # only the CLAUDE.md block + legacy purge
#
# Exit: 0 ok (or no drift) · 1 drift found (--check) / error · 2 repo absent
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

STANDARDS_SRC="$STD_ROOT/standards/STANDARDS.chrysa.md"
# SKILLS_SRC = the transverse DevEx skills authored HERE, fanned out to every repo.
# Intentionally NOT chrysa-skills: that is a separate load-on-demand library
# (functional/identity/specialty, ~61 skills) NOT wired into distribution — fanning it
# out would push identity/persona skills to every repo. Keep transverse skills here;
# chrysa-skills stays standalone. See fleet consolidation notes.
SKILLS_SRC="$STD_ROOT/.claude/skills"
AGENTS_SRC="$STD_ROOT/templates/claude/agents"
COMMANDS_SRC="$STD_ROOT/templates/claude/commands"
CLAUDE_TPL="$STD_ROOT/templates/CLAUDE.md"

MARK_START='<!-- chrysa:standards:start · managed by distribute-standards.sh · DO NOT EDIT -->'
MARK_END='<!-- chrysa:standards:end -->'

# Legacy artefacts from the vendored-copy mechanism (removed on migration).
OLD_MARK_START='<!-- chrysa:standards-import:start -->'
OLD_MARK_END='<!-- chrysa:standards-import:end -->'
OLD_VENDOR='.chrysa/STANDARDS.md'

DRY_RUN=false
CHECK=false
NO_APPLY=false
STANDARDS_ONLY=false
TARGET_REPO=""

for arg in "$@"; do
    case "$arg" in
        --dry-run)        DRY_RUN=true ;;
        --check)          CHECK=true ;;
        --no-apply)       NO_APPLY=true ;;
        --standards-only) STANDARDS_ONLY=true; NO_APPLY=true ;;
        -h|--help)  sed -n '2,30p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)          [[ -z "$TARGET_REPO" ]] && TARGET_REPO="$arg" ;;
    esac
done

log()  { echo "[$(date +%H:%M:%S)] $*"; }
ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*"; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

DRIFT=0
mark_drift() { DRIFT=1; }

# Guarantee the file ends with exactly ONE newline and no trailing blank lines.
# The managed block itself is clean, but repo-specific tail content or a template
# can leave a stray blank line at EOF; without this the sync-standards CI commit
# fights end-of-file-fixer and the push is rejected. $() strips all trailing
# newlines; printf re-adds exactly one. Apply-mode only (never in --check/--dry-run).
normalize_eof() {
    local f="$1"
    [[ -f "$f" ]] || return 0
    local content; content="$(cat "$f")"
    printf '%s\n' "$content" > "$f"
}

# The managed block = start marker + standards body (source minus its leading HTML
# header comment) + end marker. Written to $1.
build_block() {
    local out="$1"
    { printf '%s\n' "$MARK_START"
      # Drop the leading HTML header comment: lines 1..first line whose start is `-->`
      # (the closer sits on its own line), then any leading blanks.
      sed '1,/^-->/d' "$STANDARDS_SRC" | sed '/./,$!d'
      printf '%s\n' "$MARK_END"
    } > "$out"
}

# Copy src -> dest if content differs. Honors --dry-run / --check.
deploy_file() {
    local src="$1" dest="$2"
    [[ -f "$src" ]] || { warn "source missing: $src · skip"; return 0; }
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
        return 0
    fi
    if $CHECK;   then warn "drift: $dest"; mark_drift; return 0; fi
    if $DRY_RUN; then info "[dry-run] would write $dest"; mark_drift; return 0; fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest" && ok "wrote $dest"
}

# Mirror every file under a source dir into a dest dir (managed copies).
deploy_dir() {
    local src="$1" dest="$2"
    [[ -d "$src" ]] || { warn "source dir missing: $src · skip"; return 0; }
    local f rel
    while IFS= read -r -d '' f; do
        rel="${f#"$src"/}"
        deploy_file "$f" "$dest/$rel"
    done < <(find "$src" -type f -print0)
}

# Remove the legacy vendored copy + old import block (migration from the old mechanism).
purge_legacy() {
    local repo="$1" claude="$2"
    # 1. Vendored .chrysa/STANDARDS.md (+ empty .chrysa dir).
    if [[ -f "$repo/$OLD_VENDOR" ]]; then
        if $CHECK;   then warn "drift: legacy $OLD_VENDOR present"; mark_drift;
        elif $DRY_RUN; then info "[dry-run] would remove $repo/$OLD_VENDOR"; mark_drift;
        else rm -f "$repo/$OLD_VENDOR"; rmdir "$repo/.chrysa" 2>/dev/null; ok "removed legacy $OLD_VENDOR"; fi
    fi
    # 2. Old import block in CLAUDE.md.
    [[ -f "$claude" ]] && grep -qF "$OLD_MARK_START" "$claude" || return 0
    if $CHECK;   then warn "drift: legacy import block in $claude"; mark_drift; return 0; fi
    if $DRY_RUN; then info "[dry-run] would strip legacy import block in $claude"; mark_drift; return 0; fi
    local tmp; tmp="$(mktemp)"
    awk -v s="$OLD_MARK_START" -v e="$OLD_MARK_END" '
        $0==s {skip=1; next} $0==e {skip=0; next} !skip {print}' "$claude" > "$tmp"
    mv "$tmp" "$claude"
    ok "stripped legacy import block in $claude"
}

# Ensure the managed inline standards block exists + is current in <repo>/CLAUDE.md.
inject_standards() {
    local repo="$1"
    local claude="$repo/CLAUDE.md"
    local block; block="$(mktemp)"; build_block "$block"

    purge_legacy "$repo" "$claude"

    # Create CLAUDE.md from template (or minimal stub) if absent.
    if [[ ! -f "$claude" ]]; then
        if $CHECK;   then warn "drift: $claude absent (would be created)"; mark_drift; rm -f "$block"; return 0; fi
        if $DRY_RUN; then info "[dry-run] would create $claude with standards block"; mark_drift; rm -f "$block"; return 0; fi
        if [[ -f "$CLAUDE_TPL" ]]; then cp "$CLAUDE_TPL" "$claude"; else printf '# CLAUDE.md — %s\n' "$(basename "$repo")" > "$claude"; fi
        printf '\n' >> "$claude"; cat "$block" >> "$claude"; normalize_eof "$claude"
        ok "created $claude with standards block"; rm -f "$block"; return 0
    fi

    # Block already present — refresh only if content differs.
    if grep -qF "$MARK_START" "$claude"; then
        local cur; cur="$(mktemp)"
        awk -v s="$MARK_START" -v e="$MARK_END" '
            $0==s {inb=1} inb {print} $0==e {inb=0}' "$claude" > "$cur"
        if cmp -s "$cur" "$block"; then rm -f "$cur" "$block"; return 0; fi
        if $CHECK;   then warn "drift: $claude standards block stale"; mark_drift; rm -f "$cur" "$block"; return 0; fi
        if $DRY_RUN; then info "[dry-run] would refresh standards block in $claude"; mark_drift; rm -f "$cur" "$block"; return 0; fi
        local tmp; tmp="$(mktemp)"
        awk -v s="$MARK_START" -v e="$MARK_END" -v bf="$block" '
            $0==s {while ((getline line < bf) > 0) print line; close(bf); skip=1; next}
            $0==e {skip=0; next}
            !skip {print}' "$claude" > "$tmp"
        mv "$tmp" "$claude"; normalize_eof "$claude"
        ok "refreshed standards block in $claude"; rm -f "$cur" "$block"; return 0
    fi

    # Block missing entirely — append it.
    if $CHECK;   then warn "drift: $claude missing standards block"; mark_drift; rm -f "$block"; return 0; fi
    if $DRY_RUN; then info "[dry-run] would append standards block to $claude"; mark_drift; rm -f "$block"; return 0; fi
    printf '\n' >> "$claude"; cat "$block" >> "$claude"; normalize_eof "$claude"
    ok "appended standards block to $claude"; rm -f "$block"
}

main() {
    local repo="$TARGET_REPO"
    [[ -n "$repo" ]]   || { err "Usage: $0 [--dry-run|--check|--no-apply] <repo_path>"; exit 1; }
    repo="$(cd "$repo" 2>/dev/null && pwd)" || { err "$TARGET_REPO absent"; exit 2; }
    [[ -d "$repo/.git" ]] || warn "$(basename "$repo"): not a git repo (continuing)"

    log "═══ distribute-standards · $(basename "$repo") ═══"

    # 1. + 2. Inline standards block in CLAUDE.md (+ legacy migration).
    inject_standards "$repo"

    if $STANDARDS_ONLY; then
        if $CHECK; then
            if [[ "$DRIFT" -eq 0 ]]; then ok "no drift"; exit 0; else warn "drift detected"; exit 1; fi
        fi
        log "done (standards-only)"; return 0
    fi

    # 3. Shared skills (managed copies).
    deploy_dir "$SKILLS_SRC" "$repo/.claude/skills"

    # 4. Shared agents + commands (managed copies).
    deploy_dir "$AGENTS_SRC" "$repo/.claude/agents"
    deploy_dir "$COMMANDS_SRC" "$repo/.claude/commands"

    # 5. Workflows + lint/quality + pre-commit — reuse the existing apply layer.
    if $NO_APPLY; then
        info "apply-repo-standard.sh · skipped (--no-apply)"
    else
        local apply="$SCRIPT_DIR/apply-repo-standard.sh" flags=""
        $DRY_RUN && flags="--dry-run"
        $CHECK   && flags="--check"
        if [[ -f "$apply" ]]; then
            bash "$apply" $flags "$repo" || { warn "apply-repo-standard returned non-zero"; mark_drift; }
        else
            warn "apply-repo-standard.sh missing · workflows/config layer skipped"
        fi
    fi

    if $CHECK; then
        if [[ "$DRIFT" -eq 0 ]]; then ok "no drift"; exit 0; else warn "drift detected"; exit 1; fi
    fi
    log "done"
}

main
