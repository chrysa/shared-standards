#!/usr/bin/env bash
# validate-repos-runtime.sh · Enforce the container-runtime classification in repos.yml.
# Source: chrysa/shared-standards/scripts/validate-repos-runtime.sh
#
# CI gate for EXECUTION_STANDARD §6.1: every repo entry must declare a `runtime:` with a
# value from the allowed set. Keeps the policy self-sustaining — a new repo cannot be added
# without classifying how it runs. Self-contained (parses repos.yml only; no fleet checkout).
#
# Usage: bash validate-repos-runtime.sh
# Exit: 0 all entries valid · 1 missing/invalid runtime · 2 repos.yml missing
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOS_YML="${REPOS_YML:-$STD_ROOT/repos.yml}"
VALID='container exempt:lib exempt:config exempt:native pending'

[[ -f "$REPOS_YML" ]] || { echo "repos.yml not found: $REPOS_YML" >&2; exit 2; }

# Emit "name <runtime-or-MISSING>" per entry: print the pending name when a new `- name:`
# arrives before a runtime line was seen.
errors=0
while read -r name runtime; do
    if [[ -z "$runtime" || "$runtime" == "MISSING" ]]; then
        echo "✗ $name: no runtime: field"; ((errors++)); continue
    fi
    case " $VALID " in
        *" $runtime "*) ;;
        *) echo "✗ $name: invalid runtime '$runtime' (allowed: $VALID)"; ((errors++)) ;;
    esac
done < <(awk '
    $1=="-" && $2=="name:" { if (n != "") print n, (rt=="" ? "MISSING" : rt); n=$3; rt="" }
    $1=="runtime:"         { rt=$2 }
    END                    { if (n != "") print n, (rt=="" ? "MISSING" : rt) }
' "$REPOS_YML")

if [[ "$errors" -eq 0 ]]; then
    echo "✓ repos.yml: every entry has a valid runtime classification"
    exit 0
fi
echo "FAILED: $errors classification error(s)" >&2
exit 1
