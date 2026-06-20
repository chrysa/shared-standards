#!/bin/bash

AUDIT_DIR="/home/anthony/.claude/jobs/4c5579d6/tmp"
REPOS_FILE="$AUDIT_DIR/repos.txt"
RESULTS_FILE="$AUDIT_DIR/audit_results.json"

# Fetch repos list
gh repo list chrysa --limit 200 --json name,defaultBranchRef,visibility,isArchived \
  | jq -r '.[] | select(.isArchived==false) | "\(.name)|\(.defaultBranchRef.name)|\(.visibility)"' > "$REPOS_FILE"

total_repos=$(wc -l < "$REPOS_FILE")
echo "Total repos: $total_repos" >&2

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
  
  # Check required files
  gaps=()
  
  # CORE requirements
  [[ ! "$found" =~ \|CLAUDE\.md ]] && gaps+=("CLAUDE.md")
  [[ ! "$found" =~ \|README\.md ]] && gaps+=("README.md")
  [[ ! "$found" =~ \|Makefile ]] && gaps+=("Makefile")
  [[ ! "$found" =~ (\||/)pyproject\.toml ]] && [[ ! "$found" =~ (\||/)package\.json ]] && gaps+=("(pyproject.toml|package.json)")
  [[ ! "$found" =~ \|CHANGELOG\.md ]] && gaps+=("CHANGELOG.md")
  [[ ! "$found" =~ \|cliff\.toml ]] && gaps+=("cliff.toml")
  [[ ! "$found" =~ \|GitVersion\.yml ]] && gaps+=("GitVersion.yml")
  [[ ! "$found" =~ \|opencode\.json ]] && gaps+=("opencode.json")
  [[ ! "$found" =~ \|\.pre-commit-config\.yaml ]] && gaps+=(".pre-commit-config.yaml")
  [[ $has_workflows -eq 0 ]] && gaps+=(".github/workflows/*.yml")
  [[ $has_tests -eq 0 ]] && gaps+=("tests/")
  
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
  
  # WORKFLOW-specific
  [[ ! "$found" =~ \|\.github/workflows/release\.yml ]] && gaps+=("workflows/release.yml")
  
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

