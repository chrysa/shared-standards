#!/usr/bin/env bash
# canonical.sh · Shared helpers for canonical-file conformance tooling.
#
# Source: chrysa/shared-standards/scripts/lib/canonical.sh
#
# A "canonical file" is a config artifact whose single source of truth lives in
# shared-standards (e.g. GitVersion.yml, cliff.toml) and must be byte-identical
# across the fleet. These helpers let the audit / sync / drift-gate scripts share
# one definition of "are two copies the same" and "which repos are in scope".
#
# Identity is the git blob SHA (`git hash-object`): the exact hash GitHub returns
# for a file's contents, so a repo's API `.sha` can be compared without fetching
# or decoding the bytes. Two copies are identical iff their blob SHAs match.

# Print the git blob SHA of a local file (its content identity). Empty on miss.
canonical_blob_sha() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    git hash-object "$file"
}

# Print the dev-repo names from repos.yml (status: dev only — non-dev / archived
# / alias repos are out of scope for canonical-file conformance).
dev_repos() {
    local repos_yml="$1"
    awk '$1=="-" && $2=="name:"{n=$3} $1=="status:" && $2=="dev"{print n}' "$repos_yml"
}

# Echo a remote repo file's git blob SHA via the GitHub API, or "" if absent
# (404) or on any error. Output is validated to be a 40-hex blob SHA so an API
# error body can never leak through as a bogus "hash".
# $1 = repo name (under chrysa/), $2 = path in repo.
remote_blob_sha() {
    local repo="$1" path="$2" sha
    sha="$(gh api "repos/chrysa/$repo/contents/$path" --jq '.sha' 2>/dev/null)"
    [[ "$sha" =~ ^[0-9a-f]{40}$ ]] && printf '%s' "$sha"
}

# Echo a remote repo file's decoded contents via the GitHub API, or "" if absent.
# Used only when classification needs to inspect content (e.g. GitVersion mode).
remote_file_content() {
    local repo="$1" path="$2" b64
    b64="$(gh api "repos/chrysa/$repo/contents/$path" --jq '.content' 2>/dev/null)" || return 1
    [[ -n "$b64" ]] || return 1
    base64 -d <<<"$b64" 2>/dev/null
}
