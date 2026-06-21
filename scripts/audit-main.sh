#!/bin/bash

AUDIT_DIR="${AUDIT_DIR:-$(mktemp -d)}"
REPOS_FILE="$AUDIT_DIR/repos.txt"
RESULTS_FILE="$AUDIT_DIR/audit_results.json"

# Fetch repos list
gh repo list chrysa --limit 200 --json name,defaultBranchRef,visibility,isArchived \
  | jq -r '.[] | select(.isArchived==false) | "\(.name)|\(.defaultBranchRef.name)|\(.visibility)"' > "$REPOS_FILE"

total_repos=$(wc -l < "$REPOS_FILE")
echo "Total repos: $total_repos" >&2

# Archetype classification from shared-standards/repos.yml (source of truth, main branch).
# No-package archetypes (runtime exempt:config | status non-dev) ship no pip/npm package
# and have nothing to release, so pyproject/tests/release.yml are NOT required for them
# (EXECUTION_STANDARD §2 archetype exemption).
REPOS_YML="$AUDIT_DIR/repos_main.yml"
gh api repos/chrysa/shared-standards/contents/repos.yml --jq '.content' 2>/dev/null | base64 -d > "$REPOS_YML"
repo_runtime() { awk -v R="$1" '$1=="-"&&$2=="name:"{c=$3} c==R&&$1=="runtime:"{print $2;exit}' "$REPOS_YML"; }
repo_status()  { awk -v R="$1" '$1=="-"&&$2=="name:"{c=$3} c==R&&$1=="status:"{print $2;exit}'  "$REPOS_YML"; }

# Initialize results as array
echo "[]" > "$RESULTS_FILE"

error_repos_list=""
row_count=0
conformant_count=0

while IFS='|' read -r repo_name default_branch visibility; do
  ((row_count++))
  printf "\r[%d/%d] %s" "$row_count" "$total_repos" "$repo_name" >&2

  # Fetch tree for repo (suppress errors for empty repos)
  tree_output=$(gh api "repos/chrysa/$repo_name/git/trees/$default_branch?recursive=1" 2>/dev/null | jq -r '.tree[].path // empty' || true)

  if [ -z "$tree_output" ]; then
    error_repos_list="$error_repos_list$repo_name"$'\n'
    continue
  fi

  # Build set of found files
  found=""
  has_workflows=0
  has_tests=0
  has_ci=0

  while IFS= read -r path; do
    found="$found|$path"
    [[ "$path" =~ ^\.github/workflows/.*\.yml$ ]] && has_workflows=1
    [[ "$path" =~ (^|/)tests?/ || "$path" =~ (^|/)test_.*\.py$ || "$path" =~ \.test\. || "$path" =~ _test\.(py|go|ts|js)$ ]] && has_tests=1
    [[ "$path" =~ ^\.github/workflows/(ci|.*ci.*\.yml)$ ]] && has_ci=1
  done <<< "$tree_output"

  # Archetype: no-package repos (config/meta or non-dev) are exempt from
  # pyproject/tests/release.yml (EXECUTION_STANDARD §2 archetype exemption).
  runtime=$(repo_runtime "$repo_name")
  status=$(repo_status "$repo_name")
  has_manifest=false
  [[ "$found" =~ (\||/)pyproject\.toml || "$found" =~ (\||/)package\.json ]] && has_manifest=true
  no_package=false
  # config/meta repos + non-dev ship no package. exempt:native repos are package-optional
  # (a native script bundle has no manifest; a native CLI may); only exempt the manifest-less ones.
  [[ "$runtime" == "exempt:config" || "$status" == "non-dev" ]] && no_package=true
  [[ "$runtime" == "exempt:native" ]] && ! $has_manifest && no_package=true

  # non-dev (config/static, skip CI+Docker): require ONLY README + .gitignore
  # (+ LICENSE for public). The full dev toolchain (CLAUDE/Makefile/cliff/CI/...) is N/A.
  if [[ "$status" == "non-dev" ]]; then
    gaps=()
    [[ ! "$found" =~ \|README\.md ]] && gaps+=("README.md")
    [[ ! "$found" =~ \|\.gitignore ]] && gaps+=(".gitignore")
    [[ "$visibility" == "PUBLIC" && ! "$found" =~ \|LICENSE ]] && gaps+=("LICENSE")
    gap_count=${#gaps[@]}
    [[ $gap_count -eq 0 ]] && ((conformant_count++))
    gap_json=$(printf '%s\n' "${gaps[@]}" | jq -Rs . | jq -s . | tr -d '\n')
    result="{\"name\":\"$repo_name\",\"branch\":\"$default_branch\",\"visibility\":\"$visibility\",\"gap_count\":$gap_count,\"gaps\":$gap_json}"
    current=$(cat "$RESULTS_FILE")
    echo "$current" | jq --argjson r "$result" '. += [$r]' > "$RESULTS_FILE"
    continue
  fi

  # Check required files
  gaps=()

  # CORE requirements
  [[ ! "$found" =~ \|CLAUDE\.md ]] && gaps+=("CLAUDE.md")
  [[ ! "$found" =~ \|README\.md ]] && gaps+=("README.md")
  [[ ! "$found" =~ \|Makefile ]] && gaps+=("Makefile")
  if ! $no_package; then
    [[ ! "$found" =~ (\||/)pyproject\.toml ]] && [[ ! "$found" =~ (\||/)package\.json ]] && gaps+=("(pyproject.toml|package.json)")
  fi
  [[ ! "$found" =~ \|CHANGELOG\.md ]] && gaps+=("CHANGELOG.md")
  [[ ! "$found" =~ \|cliff\.toml ]] && gaps+=("cliff.toml")
  [[ ! "$found" =~ \|GitVersion\.yml ]] && gaps+=("GitVersion.yml")
  [[ ! "$found" =~ \|opencode\.json ]] && gaps+=("opencode.json")
  [[ ! "$found" =~ \|\.pre-commit-config\.yaml ]] && gaps+=(".pre-commit-config.yaml")
  [[ $has_workflows -eq 0 ]] && gaps+=(".github/workflows/*.yml")
  if ! $no_package; then
    [[ $has_tests -eq 0 ]] && gaps+=("tests/")
  fi

  # PUBLIC repos need LICENSE
  if [[ "$visibility" == "PUBLIC" ]]; then
    [[ ! "$found" =~ \|LICENSE ]] && gaps+=("LICENSE")
  fi

  # HYGIENE files
  [[ ! "$found" =~ \|\.gitignore ]] && gaps+=(".gitignore")
  [[ ! "$found" =~ \|\.gitattributes ]] && gaps+=(".gitattributes")
  [[ ! "$found" =~ \|\.editorconfig ]] && gaps+=(".editorconfig")
  [[ ! "$found" =~ \|\.github/dependabot\.yml ]] && gaps+=(".github/dependabot.yml")
  [[ ! "$found" =~ \|\.github/CODEOWNERS ]] && gaps+=(".github/CODEOWNERS")
  [[ ! "$found" =~ \|CONTRIBUTING\.md ]] && gaps+=("CONTRIBUTING.md")
  [[ ! "$found" =~ \|AGENTS\.md ]] && gaps+=("AGENTS.md")

  # CANONICAL
  [[ ! "$found" =~ \.chrysa/STANDARDS\.md ]] && gaps+=(".chrysa/STANDARDS.md")

  # WORKFLOW-specific (no-package archetypes have nothing to release)
  if ! $no_package; then
    [[ ! "$found" =~ \|\.github/workflows/release\.yml ]] && gaps+=("workflows/release.yml")
  fi

  gap_count=${#gaps[@]}
  [[ $gap_count -eq 0 ]] && ((conformant_count++))

  # Build JSON result
  gap_json=$(printf '%s\n' "${gaps[@]}" | jq -Rs . | jq -s . | tr -d '\n')

  result=$(cat <<RESULT
{"name":"$repo_name","branch":"$default_branch","visibility":"$visibility","gap_count":$gap_count,"gaps":$gap_json}
RESULT
)

  current=$(cat "$RESULTS_FILE")
  echo "$current" | jq --argjson r "$result" '. += [$r]' > "$RESULTS_FILE"

done < "$REPOS_FILE"

echo "" >&2
echo "Conformant: $conformant_count / $total_repos"

# Save error list if any
if [ -n "$error_repos_list" ]; then
  echo "$error_repos_list" > "$AUDIT_DIR/error-repos.txt"
fi

echo "Results saved to $RESULTS_FILE"
