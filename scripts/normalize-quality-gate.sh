#!/bin/bash
# Normalize quality gate setup for a repository
# Usage: ./scripts/normalize-quality-gate.sh <repo-path> [--force]

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <repo-path> [--force]"
    echo "Example: $0 /path/to/repo"
    exit 1
fi

REPO_PATH="$1"
FORCE="${2:-}"

if [ ! -d "$REPO_PATH" ]; then
    echo "❌ Repository not found: $REPO_PATH"
    exit 1
fi

if [ ! -d "$REPO_PATH/.git" ]; then
    echo "❌ Not a git repository: $REPO_PATH"
    exit 1
fi

REPO_NAME=$(basename "$REPO_PATH")
cd "$REPO_PATH"

echo "🔧 Normalizing quality gate setup for: $REPO_NAME"
echo ""

# Detect repo type (Python/Node/Mixed)
REPO_TYPE="mixed"
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    REPO_TYPE="python"
fi
if [ -f "package.json" ]; then
    REPO_TYPE="node"
fi

echo "📊 Repo type detected: $REPO_TYPE"
echo ""

# Check existing files
SKIP_COUNT=0
if [ -f ".quality-gate.json" ] && [ -z "$FORCE" ]; then
    echo "⏭️  .quality-gate.json already exists (use --force to overwrite)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
fi

if [ -f "scripts/quality_gate.py" ] && [ -z "$FORCE" ]; then
    echo "⏭️  scripts/quality_gate.py already exists (use --force to overwrite)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
fi

if [ -f ".github/workflows/quality-gate-check.yml" ] && [ -z "$FORCE" ]; then
    echo "⏭️  .github/workflows/quality-gate-check.yml already exists (use --force to overwrite)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
fi

if [ -f "makefiles/quality-gate.Makefile" ] && [ -z "$FORCE" ]; then
    echo "⏭️  makefiles/quality-gate.Makefile already exists (use --force to overwrite)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
fi

if [ "$SKIP_COUNT" -eq 4 ] && [ -z "$FORCE" ]; then
    echo ""
    echo "✅ All quality-gate files already present"
    exit 0
fi

echo ""
echo "📝 Creating quality gate files..."
echo ""

# Create directories
mkdir -p scripts .github/workflows makefiles

# Create quality_gate.py
echo "  ✏️  Creating scripts/quality_gate.py..."
cat > scripts/quality_gate.py << 'EOF'
#!/usr/bin/env python3
"""Quality Gate Verification Script"""

import json
import subprocess
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, Tuple

class QualityGate:
    CONFIG_FILE = ".quality-gate.json"
    BASELINE_FILE = ".quality-gate-baseline.json"

    def __init__(self):
        self.config_path = Path(self.CONFIG_FILE)
        self.baseline_path = Path(self.BASELINE_FILE)
        if not self.config_path.exists():
            print(f"❌ Configuration file not found: {self.CONFIG_FILE}")
            sys.exit(1)
        with open(self.config_path) as f:
            self.config = json.load(f)

    def _run(self, cmd: str) -> Tuple[int, str]:
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=300)
            return result.returncode, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return 124, "Command timed out after 300s"
        except Exception as e:
            return 127, f"Error: {e}"

    def _parse_coverage(self, output: str) -> float:
        for line in output.split('\n'):
            if 'coverage' in line.lower():
                for word in line.split():
                    if word.endswith('%'):
                        try:
                            return float(word.rstrip('%'))
                        except ValueError:
                            continue
        return -1.0

    def _parse_passed_tests(self, output: str) -> int:
        for line in output.split('\n'):
            if 'passed' in line:
                parts = line.split()
                for i, part in enumerate(parts):
                    if 'passed' in part and i > 0:
                        try:
                            return int(parts[i-1])
                        except (ValueError, IndexError):
                            continue
        return 0

    def _parse_warning_count(self, output: str) -> int:
        for line in output.split('\n'):
            if 'warning' in line.lower():
                try:
                    count = int(line.split()[0])
                    return count
                except (ValueError, IndexError):
                    continue
        return 0

    def _parse_error_count(self, output: str) -> int:
        for line in output.split('\n'):
            if 'error' in line.lower():
                try:
                    count = int(line.split()[0])
                    return count
                except (ValueError, IndexError):
                    continue
        return 0

    def _run_gate(self, gate_name: str, cmd: str) -> Dict[str, Any]:
        print(f"  🔍 {gate_name}...", end=" ", flush=True)
        exit_code, output = self._run(cmd)
        result = {"command": cmd, "exit_code": exit_code, "output": output, "timestamp": datetime.now().isoformat()}

        if gate_name == "Tests":
            result["metric"] = self._parse_passed_tests(output)
            result["metric_name"] = "passed_tests"
        elif gate_name == "Coverage":
            result["metric"] = self._parse_coverage(output)
            result["metric_name"] = "coverage_percentage"
        elif gate_name == "Lint":
            result["metric"] = self._parse_warning_count(output)
            result["metric_name"] = "warning_count"
        elif gate_name == "Types":
            result["metric"] = self._parse_error_count(output)
            result["metric_name"] = "error_count"
        elif gate_name == "Build":
            result["metric"] = 0 if exit_code == 0 else 1
            result["metric_name"] = "build_status"

        print(f"OK ({result.get('metric', 'N/A')})")
        return result

    def baseline(self):
        print("\n📋 Recording Quality Gate Baseline\n")
        baseline_data = {"recorded_at": datetime.now().isoformat(), "gates": {}}
        gates = [
            ("Tests", self.config["commands"].get("tests", "make test")),
            ("Coverage", self.config["commands"].get("coverage", "make test-coverage")),
            ("Lint", self.config["commands"].get("lint", "make lint")),
            ("Types", self.config["commands"].get("types", "make type-check")),
            ("Build", self.config["commands"].get("build", "make build")),
        ]
        for gate_name, cmd in gates:
            result = self._run_gate(gate_name, cmd)
            baseline_data["gates"][gate_name] = result
        with open(self.baseline_path, 'w') as f:
            json.dump(baseline_data, f, indent=2)
        print(f"\n✅ Baseline saved\n")
        return True

    def verify(self) -> bool:
        print("\n🔍 Verifying Quality Gates\n")
        if not self.baseline_path.exists():
            print(f"❌ Baseline not found. Run 'make quality-gate-baseline' first\n")
            return False
        with open(self.baseline_path) as f:
            baseline = json.load(f)
        gates = [
            ("Tests", self.config["commands"].get("tests", "make test"), "≥"),
            ("Coverage", self.config["commands"].get("coverage", "make test-coverage"), "≥"),
            ("Lint", self.config["commands"].get("lint", "make lint"), "="),
            ("Types", self.config["commands"].get("types", "make type-check"), "≤"),
            ("Build", self.config["commands"].get("build", "make build"), "="),
        ]
        print("Results:"); print("-" * 60)
        all_passed = True
        for gate_name, cmd, check_type in gates:
            current = self._run_gate(gate_name, cmd)
            baseline_gate = baseline["gates"][gate_name]
            baseline_metric = baseline_gate.get("metric", 0)
            current_metric = current.get("metric", 0)
            passed = (check_type == "=" and current_metric == baseline_metric) or \
                     (check_type == "≥" and current_metric >= baseline_metric) or \
                     (check_type == "≤" and current_metric <= baseline_metric)
            status = "✅" if passed else "❌"
            print(f"{status} {gate_name:12} {baseline_metric} {check_type} {current_metric}")
            if not passed:
                all_passed = False
        print("-" * 60)
        if all_passed:
            print("\n✅ All gates passed\n")
            return True
        else:
            print("\n❌ Regression detected\n")
            return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python quality_gate.py [baseline|verify]")
        sys.exit(1)
    command = sys.argv[1].lower()
    gate = QualityGate()
    if command == "baseline":
        sys.exit(0 if gate.baseline() else 1)
    elif command == "verify":
        sys.exit(0 if gate.verify() else 1)
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF
chmod +x scripts/quality_gate.py

# Create .quality-gate.json based on repo type
echo "  ✏️  Creating .quality-gate.json (type: $REPO_TYPE)..."

if [ "$REPO_TYPE" = "python" ]; then
    cat > .quality-gate.json << 'EOF'
{
  "description": "Quality gate configuration for Python project",
  "commands": {
    "tests": "make tests",
    "coverage": "make tests-cov",
    "lint": "make lint",
    "types": "make type-check",
    "build": "make build"
  },
  "thresholds": {
    "tests": {"type": "count", "operator": "≥"},
    "coverage": {"type": "percentage", "operator": "≥"},
    "lint": {"type": "count", "operator": "=", "value": 0},
    "types": {"type": "count", "operator": "≤"},
    "build": {"type": "exit_code", "operator": "=", "value": 0}
  }
}
EOF
elif [ "$REPO_TYPE" = "node" ]; then
    cat > .quality-gate.json << 'EOF'
{
  "description": "Quality gate configuration for Node.js project",
  "commands": {
    "tests": "npm test",
    "coverage": "npm run test:coverage",
    "lint": "npm run lint",
    "types": "npm run type-check",
    "build": "npm run build"
  },
  "thresholds": {
    "tests": {"type": "count", "operator": "≥"},
    "coverage": {"type": "percentage", "operator": "≥"},
    "lint": {"type": "count", "operator": "=", "value": 0},
    "types": {"type": "count", "operator": "≤"},
    "build": {"type": "exit_code", "operator": "=", "value": 0}
  }
}
EOF
else
    cat > .quality-gate.json << 'EOF'
{
  "description": "Quality gate configuration for mixed project",
  "commands": {
    "tests": "make test",
    "coverage": "make test-coverage",
    "lint": "make lint",
    "types": "make type-check",
    "build": "make build"
  },
  "thresholds": {
    "tests": {"type": "count", "operator": "≥"},
    "coverage": {"type": "percentage", "operator": "≥"},
    "lint": {"type": "count", "operator": "=", "value": 0},
    "types": {"type": "count", "operator": "≤"},
    "build": {"type": "exit_code", "operator": "=", "value": 0}
  }
}
EOF
fi

# Create GitHub Actions workflow
echo "  ✏️  Creating .github/workflows/quality-gate-check.yml..."
cat > .github/workflows/quality-gate-check.yml << 'EOF'
---
name: Quality Gate Check

on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - main
      - master
      - develop
  push:
    branches:
      - main
      - master

permissions:
  contents: read
  checks: write
  statuses: write

jobs:
  quality-gate:
    runs-on: ubuntu-latest
    name: No-Regression Quality Gates

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Set up Node.js (if needed)
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
        continue-on-error: true

      - name: Install dependencies
        run: |
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
          if [ -f package.json ]; then npm ci; fi

      - name: Run quality gate verification
        id: quality-gate
        run: |
          make quality-gate-verify || exit_code=$?
          exit ${exit_code:-0}

      - name: Report quality gate status
        if: always()
        run: |
          if [ ${{ steps.quality-gate.outcome }} == 'success' ]; then
            echo "✅ All quality gates passed"
            exit 0
          else
            echo "❌ Quality gate regression detected"
            exit 1
          fi
EOF

# Create Make targets
echo "  ✏️  Creating makefiles/quality-gate.Makefile..."
cat > makefiles/quality-gate.Makefile << 'EOF'
.PHONY: quality-gate-baseline quality-gate-verify

quality-gate-baseline: ## Record baseline metrics for regression detection
	@python scripts/quality_gate.py baseline

quality-gate-verify: ## Verify no regression since baseline
	@python scripts/quality_gate.py verify
EOF

echo ""
echo "✅ Quality gate files created:"
echo "   • scripts/quality_gate.py"
echo "   • .quality-gate.json"
echo "   • .github/workflows/quality-gate-check.yml"
echo "   • makefiles/quality-gate.Makefile"
echo ""
echo "📋 Next steps:"
echo "   1. Review .quality-gate.json and adjust Make commands if needed"
echo "   2. Test: make quality-gate-baseline"
echo "   3. Verify: make quality-gate-verify"
echo "   4. Commit: git add -A && git commit -m 'chore: add quality gate setup'"
echo ""
