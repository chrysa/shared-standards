#!/usr/bin/env bash
# makefile-classify.sh · Sourceable helper — classify a repo into a chrysa
# Makefile tier (EXECUTION_STANDARD.md §1) and the base-makefile template it
# should derive from.
#
# Source: chrysa/shared-standards/scripts/lib/makefile-classify.sh
# Logic ported from chrysa/audit-standards.sh (language / app-vs-lib / django).
#
# Usage (sourced):
#   source "$(dirname "$0")/lib/makefile-classify.sh"
#   read -r tier template < <(classify_makefile /path/to/repo)
#
# Output (one line, tab-separated): "<tier>\t<template>"
#   tier     ∈ lib | python-app | fullstack | infra
#   template ∈ Makefile.python | Makefile.with-sub-folder | Makefile.basic
#
# Read-only: never writes, never clones.

# Detect frontend presence (drives the fullstack tier).
_mk_has_frontend() {
    local repo="$1"
    [[ -d "$repo/frontend" || -d "$repo/web" || -d "$repo/client" || -d "$repo/ui" ]] && return 0
    # A package.json that pulls a UI framework, anywhere shallow in the tree.
    local pj
    while IFS= read -r pj; do
        grep -Eqs '"(react|vue|svelte|@angular/core|vite|next)"' "$pj" && return 0
    done < <(find "$repo" -maxdepth 2 -name package.json 2>/dev/null)
    return 1
}

# Detect backend presence (drives the structural fullstack check).
_mk_has_backend() {
    local repo="$1"
    [[ -d "$repo/backend" || -d "$repo/api" || -d "$repo/server" ]] && return 0
    return 1
}

# Echo "<tier>\t<template>" for the repo at $1.
classify_makefile() {
    local repo="$1"
    local lang="other" is_django=0 has_compose=0 has_dockerfile=0

    # Structural fullstack monorepo (backend + frontend in subdirs, manifests not
    # at root): e.g. discordium, sport-intelligence-hub — the §1 fullstack refs.
    if _mk_has_backend "$repo" && _mk_has_frontend "$repo"; then
        printf '%s\t%s\n' "fullstack" "Makefile.with-sub-folder"
        return
    fi

    [[ -f "$repo/pyproject.toml" || -f "$repo/setup.py" || -f "$repo/setup.cfg" ]] && lang="python"
    if [[ -f "$repo/package.json" ]]; then
        [[ "$lang" == "python" ]] && lang="poly" || lang="node"
    fi

    if grep -riqsE '(^|[^a-z])django' "$repo/pyproject.toml" 2>/dev/null; then is_django=1; fi
    [[ -n "$(find "$repo" -maxdepth 3 -name manage.py 2>/dev/null | head -1)" ]] && is_django=1

    [[ -f "$repo/Dockerfile" ]] && has_dockerfile=1
    [[ -f "$repo/docker-compose.yml" || -f "$repo/docker-compose.yaml" ]] && has_compose=1

    local app=0
    [[ $has_dockerfile -eq 1 && $has_compose -eq 1 ]] && app=1

    local tier template

    case "$lang" in
        python|poly)
            if { [[ "$lang" == "poly" ]] || _mk_has_frontend "$repo"; } && [[ $app -eq 1 ]]; then
                tier="fullstack"; template="Makefile.with-sub-folder"
            elif [[ $app -eq 1 ]]; then
                tier="python-app"; template="Makefile.python"
            else
                tier="lib"; template="Makefile.python"
            fi
            ;;
        node)
            if [[ $app -eq 1 ]] || _mk_has_frontend "$repo"; then
                tier="fullstack"; template="Makefile.with-sub-folder"
            else
                tier="lib"; template="Makefile.basic"
            fi
            ;;
        *)
            # infra / helm / GAS / vscode-ext / config-only repos.
            tier="infra"; template="Makefile.basic"
            ;;
    esac

    # Silence unused-var lint in shells that flag it; is_django reserved for
    # future django-specific template selection.
    : "$is_django"

    printf '%s\t%s\n' "$tier" "$template"
}
