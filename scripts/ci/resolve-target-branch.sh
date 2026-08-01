#!/usr/bin/env bash
# Resolve a target repo's default branch for the distribution job.
# An archived repo is read-only: pushing a sync branch returns 403 and would fail the
# whole run over a repo nobody can update — skip it here instead.
# Inputs: TARGET_REPO (owner/name), GH_TOKEN. Outputs: skip | branch.
set -euo pipefail

meta="$(gh api "repos/${TARGET_REPO}" --jq '[.default_branch, .archived] | @tsv')"
branch="$(echo "$meta" | cut -f1)"
archived="$(echo "$meta" | cut -f2)"

if [[ "$archived" == "true" ]]; then
    echo "::warning::${TARGET_REPO} is archived on GitHub — skipping. Set status:archived in repos.yml."
    echo "skip=true" >>"$GITHUB_OUTPUT"
    exit 0
fi

if [[ -z "$branch" ]]; then
    echo "::error::could not resolve default branch for ${TARGET_REPO}"
    exit 1
fi

echo "Target ${TARGET_REPO} default branch: $branch"
echo "branch=$branch" >>"$GITHUB_OUTPUT"
