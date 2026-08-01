#!/usr/bin/env bash
# Emit the distribute-standards job matrix (repo list + count) to $GITHUB_OUTPUT.
# Input: ONLY_FILTER — comma-separated repo subset, empty for every status:dev repo.
set -euo pipefail

repos="$(scripts/list-dev-repos.sh --json --only "${ONLY_FILTER:-}")"
count="$(echo "$repos" | tr ',' '\n' | grep -c '"' || true)"

{
    echo "matrix={\"repo\":$repos}"
    echo "count=$count"
} >>"$GITHUB_OUTPUT"

echo "Targeting $count repo(s): $repos"
