#!/usr/bin/env bash
# apply-branch-policy.sh · Bring a repo (or the fleet) onto the chrysa branch model.
# Source: chrysa/shared-standards/scripts/apply-branch-policy.sh
#
# Standard (standards/STANDARDS.chrysa.md, "Branch model"):
#   `main` = production, protected (PR only, no force-push, no deletion).
#   `develop` = default branch and integration target for every feature PR.
#   `main` is fed only by a PR from `develop` (or a `hotfix/`); production ships on release.
#
# Idempotent, three steps per repo:
#   1. create `develop` from the current default branch when it is missing;
#   2. set `develop` as the repository default branch;
#   3. protect `main`: pull request required, force-push and deletion blocked.
#
# `enforce_admins` stays FALSE on purpose (see setup-branch-protection.sh): a solo owner
# cannot approve their own PR, and enforce_admins=true also disables `gh pr merge --admin`.
# Required approving reviews are 0 for the same reason — the gate is "a PR exists", not
# "someone else reviewed it".
#
# Usage:
#   bash apply-branch-policy.sh <repo> [...]        # named repos
#   bash apply-branch-policy.sh --all               # all status:dev repos (repos.yml)
#   bash apply-branch-policy.sh --all-remote        # every non-archived chrysa repo
#   bash apply-branch-policy.sh --all --dry-run     # print the plan, change nothing
# Env: GH_TOKEN (or an authenticated `gh`), CHRYSA_OWNER (default: chrysa).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWNER="${CHRYSA_OWNER:-chrysa}"
DRY_RUN=false
ALL=false
ALL_REMOTE=false
REPOS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)    DRY_RUN=true ;;
        --all)        ALL=true ;;
        --all-remote) ALL_REMOTE=true ;;
        -h|--help)    sed -n '2,26p' "$0" | sed 's/^# \?//'; exit 0 ;;
        -*)           echo "unknown arg: $1" >&2; exit 2 ;;
        *)            REPOS+=("$1") ;;
    esac
    shift
done

if $ALL_REMOTE; then
    mapfile -t REPOS < <(gh repo list "$OWNER" --limit 300 --no-archived --json name -q '.[].name' | sort)
elif $ALL; then
    mapfile -t REPOS < <(bash "$SCRIPT_DIR/list-dev-repos.sh" --lines)
fi

[ "${#REPOS[@]}" -gt 0 ] || { echo "usage: $0 <repo>... | --all | --all-remote" >&2; exit 2; }

PROTECTION_PAYLOAD='{
  "required_status_checks": null,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "enforce_admins": false,
  "allow_force_pushes": false,
  "allow_deletions": false
}'

failed=0
for repo in "${REPOS[@]}"; do
    full="$OWNER/$repo"
    default="$(gh api "repos/$full" -q .default_branch 2>/dev/null)" || {
        echo "❌ $full · unreachable"; failed=$((failed + 1)); continue
    }
    echo "── $full (default: $default)"

    # 1. develop exists, branched from the current default.
    if gh api "repos/$full/branches/develop" >/dev/null 2>&1; then
        echo "   develop · already exists"
    elif $DRY_RUN; then
        echo "   [dry-run] would create develop from $default"
    else
        sha="$(gh api "repos/$full/git/ref/heads/$default" -q .object.sha 2>/dev/null)"
        if [ -z "$sha" ]; then
            echo "   ⚠ develop · no commit on $default (empty repo) — skipped"
        elif gh api "repos/$full/git/refs" -X POST -f ref=refs/heads/develop -f sha="$sha" >/dev/null 2>&1; then
            echo "   develop · created from $default@${sha:0:7}"
        else
            echo "   ❌ develop · creation failed"; failed=$((failed + 1)); continue
        fi
    fi

    # 2. develop is the default branch.
    if [ "$default" = "develop" ]; then
        echo "   default · already develop"
    elif $DRY_RUN; then
        echo "   [dry-run] would set default branch to develop"
    elif gh api "repos/$full" -X PATCH -f default_branch=develop >/dev/null 2>&1; then
        echo "   default · switched to develop"
    else
        echo "   ❌ default · switch failed"; failed=$((failed + 1))
    fi

    # 3. main exists (production branch) and is protected.
    has_main=true
    if ! gh api "repos/$full/branches/main" >/dev/null 2>&1; then
        has_main=false
        if $DRY_RUN; then
            echo "   [dry-run] would create main from develop"
        else
            sha="$(gh api "repos/$full/git/ref/heads/develop" -q .object.sha 2>/dev/null)"
            if [ -z "$sha" ]; then
                echo "   ⚠ main · no develop commit to branch from — skipped"
            elif gh api "repos/$full/git/refs" -X POST -f ref=refs/heads/main -f sha="$sha" >/dev/null 2>&1; then
                echo "   main · created from develop@${sha:0:7}"
                # The branches endpoint lags a freshly created ref by a moment; trust the
                # creation instead of re-probing and reporting a false "absent".
                has_main=true
            else
                echo "   ❌ main · creation failed"; failed=$((failed + 1)); continue
            fi
        fi
    fi

    if ! $has_main; then
        echo "   main · absent — nothing to protect"
    elif $DRY_RUN; then
        echo "   [dry-run] would protect main (PR required, no force-push, no deletion)"
    else
        prot_err="$(gh api "repos/$full/branches/main/protection" -X PUT \
                        --input - <<<"$PROTECTION_PAYLOAD" 2>&1 >/dev/null)"
        if [ -z "$prot_err" ]; then
            echo "   main · protected (PR required · no force-push · no deletion)"
        elif grep -q 'Upgrade to GitHub Pro' <<<"$prot_err"; then
            # Branch protection on a PRIVATE repo needs a paid plan. Not a repo defect:
            # the owner either upgrades the plan or makes the repo public.
            echo "   ⚠ main · protection unavailable (private repo on a free plan)"
        else
            echo "   ❌ main · protection failed: ${prot_err%%$'\n'*}"; failed=$((failed + 1))
        fi
    fi
done

if [ "$failed" -gt 0 ]; then
    echo "done with $failed failure(s)" >&2
    exit 1
fi
echo "done · ${#REPOS[@]} repo(s)"
