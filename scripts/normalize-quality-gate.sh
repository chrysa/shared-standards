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

if { [ -f "makefiles/quality-gate.Makefile" ] || [ -f "makefiles/quality-gate.makefile" ]; } && [ -z "$FORCE" ]; then
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
"""Quality Gate Verification Script.

Machine-readable output lines:
- GATE_RESULT|<Gate>|PASS|...
- GATE_RESULT|<Gate>|FAIL|...
- OVERALL_RESULT|PASS
- OVERALL_RESULT|FAIL
"""

import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Tuple


class QualityGate:
    CONFIG_FILE = ".quality-gate.json"
    BASELINE_FILE = ".quality-gate-baseline.json"
    LAST_REPORT_FILE = ".quality-gate-last-report.json"

    def __init__(self) -> None:
        self.config_path = Path(self.CONFIG_FILE)
        self.baseline_path = Path(self.BASELINE_FILE)
        self.last_report_path = Path(self.LAST_REPORT_FILE)

        if not self.config_path.exists():
            print(f"ERROR: configuration file not found: {self.CONFIG_FILE}")
            sys.exit(1)

        with open(self.config_path, "r", encoding="utf-8") as handle:
            self.config = json.load(handle)

        self.gates = [
            ("Tests", "tests", "passed_tests", "≥", "make test"),
            ("Coverage", "coverage", "coverage_percentage", "≥", "make test-coverage"),
            ("Lint", "lint", "warning_count", "=", "make lint"),
            ("Types", "types", "error_count", "≤", "make type-check"),
            ("Build", "build", "build_status", "=", "make build"),
            ("Secrets", "security_secrets", "secret_count", "=", "detect-secrets scan --all-files 2>&1 || true"),
            ("VulnDeps", "security_vulns", "vuln_count", "≤", "pip-audit 2>&1 || npm audit --audit-level=high 2>&1 || true"),
        ]

    def _run(self, cmd: str) -> Tuple[int, str]:
        try:
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=600,
            )
            return result.returncode, (result.stdout or "") + (result.stderr or "")
        except subprocess.TimeoutExpired:
            return 124, "Command timed out after 600 seconds"
        except Exception as exc:
            return 127, f"Execution error: {exc}"

    def _parse_passed_tests(self, output: str) -> int:
        patterns = [
            r"(\d+)\s+passed",
            r"passed\s*=\s*(\d+)",
        ]
        for pattern in patterns:
            match = re.search(pattern, output, flags=re.IGNORECASE)
            if match:
                return int(match.group(1))
        return 0

    def _parse_coverage(self, output: str) -> float:
        for line in output.splitlines():
            if any(token in line.lower() for token in ["total", "coverage", "covered"]):
                for value in re.findall(r"(\d+(?:\.\d+)?)%", line):
                    try:
                        return float(value)
                    except ValueError:
                        continue
        return -1.0

    def _parse_warning_count(self, output: str) -> int:
        match = re.search(r"(\d+)\s+warnings?", output, flags=re.IGNORECASE)
        if match:
            return int(match.group(1))
        return 0

    def _parse_error_count(self, output: str) -> int:
        match = re.search(r"(\d+)\s+errors?", output, flags=re.IGNORECASE)
        if match:
            return int(match.group(1))
        return 0

    def _parse_secret_count(self, output: str) -> int:
        try:
            d = json.loads(output)
            return sum(len(v) for v in d.get("results", {}).values())
        except (json.JSONDecodeError, AttributeError, ValueError):
            pass
        match = re.search(r"secrets?\s+found[:\s]+(\d+)", output, re.IGNORECASE)
        if match:
            return int(match.group(1))
        return 0

    def _parse_vuln_count(self, output: str) -> int:
        match = re.search(r"found\s+(\d+)\s+vulnerabilit", output, re.IGNORECASE)
        if match:
            return int(match.group(1))
        count = len(re.findall(r"(?:GHSA|CVE)-\S+", output))
        if count:
            return count
        if re.search(r"no\s+known\s+vulnerabilit", output, re.IGNORECASE):
            return 0
        return 0

    def _parse_metric(self, gate_name: str, exit_code: int, output: str) -> Any:
        if gate_name == "Tests":
            return self._parse_passed_tests(output)
        if gate_name == "Coverage":
            return self._parse_coverage(output)
        if gate_name == "Lint":
            return self._parse_warning_count(output)
        if gate_name == "Types":
            return self._parse_error_count(output)
        if gate_name == "Build":
            return 0 if exit_code == 0 else 1
        if gate_name == "Secrets":
            return self._parse_secret_count(output)
        if gate_name == "VulnDeps":
            return self._parse_vuln_count(output)
        return None

    def _compare(self, current: Any, target: Any, operator: str) -> bool:
        if operator == "=":
            return current == target
        if operator == "≥":
            return current >= target
        if operator == "≤":
            return current <= target
        if operator == ">=":
            return current >= target
        if operator == "<=":
            return current <= target
        return False

    def _run_gate(self, gate_name: str, key: str, metric_name: str, default_cmd: str) -> Dict[str, Any]:
        cmd = self.config.get("commands", {}).get(key, default_cmd)
        print(f"RUN_GATE|{gate_name}|{cmd}")
        exit_code, output = self._run(cmd)
        metric = self._parse_metric(gate_name, exit_code, output)
        return {
            "gate": gate_name,
            "command": cmd,
            "exit_code": exit_code,
            "metric_name": metric_name,
            "metric": metric,
            "timestamp": datetime.now().isoformat(),
            "output": output,
        }

    def _write_report(self, report: Dict[str, Any]) -> None:
        with open(self.last_report_path, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)

    def baseline(self) -> bool:
        print("BASELINE|START")
        baseline_data: Dict[str, Any] = {
            "recorded_at": datetime.now().isoformat(),
            "gates": {},
            "valid": True,
        }

        all_ok = True
        for gate_name, key, metric_name, _default_op, default_cmd in self.gates:
            result = self._run_gate(gate_name, key, metric_name, default_cmd)
            baseline_data["gates"][gate_name] = result
            if result["exit_code"] != 0:
                all_ok = False
                baseline_data["valid"] = False
            status = "PASS" if result["exit_code"] == 0 else "FAIL"
            print(
                f"GATE_RESULT|{gate_name}|{status}|metric={result['metric']}|"
                f"exit={result['exit_code']}|mode=baseline"
            )

        with open(self.baseline_path, "w", encoding="utf-8") as handle:
            json.dump(baseline_data, handle, indent=2)

        report = {
            "mode": "baseline",
            "overall": "PASS" if all_ok else "FAIL",
            "baseline_file": str(self.baseline_path),
            "gates": baseline_data["gates"],
        }
        self._write_report(report)

        if all_ok:
            print("OVERALL_RESULT|PASS")
            return True

        print("OVERALL_RESULT|FAIL")
        print("ERROR: baseline contains failing gates; fix quality checks before using this baseline")
        return False

    def verify(self) -> bool:
        print("VERIFY|START")
        if not self.baseline_path.exists():
            report = {
                "mode": "verify",
                "overall": "FAIL",
                "reason": "missing_baseline",
                "baseline_file": str(self.baseline_path),
            }
            self._write_report(report)
            print("OVERALL_RESULT|FAIL")
            print("ERROR: baseline file not found; run quality-gate-baseline first")
            return False

        with open(self.baseline_path, "r", encoding="utf-8") as handle:
            baseline = json.load(handle)

        baseline_valid = bool(baseline.get("valid", True))
        all_passed = True
        gate_reports: List[Dict[str, Any]] = []

        for gate_name, key, metric_name, default_op, default_cmd in self.gates:
            current = self._run_gate(gate_name, key, metric_name, default_cmd)
            baseline_gate = baseline.get("gates", {}).get(gate_name, {})

            threshold_cfg = self.config.get("thresholds", {}).get(key, {})
            operator = str(threshold_cfg.get("operator", default_op))
            baseline_metric = baseline_gate.get("metric", 0)
            target = threshold_cfg.get("value", baseline_metric)
            current_metric = current.get("metric", 0)

            passed = True
            reason = "ok"

            if not baseline_valid:
                passed = False
                reason = "invalid_baseline"
            elif current.get("exit_code", 1) != 0:
                passed = False
                reason = "command_failed"
            else:
                try:
                    passed = self._compare(current_metric, target, operator)
                    if not passed:
                        reason = "metric_regression"
                except Exception:
                    passed = False
                    reason = "comparison_error"

            if not passed:
                all_passed = False

            status = "PASS" if passed else "FAIL"
            print(
                f"GATE_RESULT|{gate_name}|{status}|baseline={baseline_metric}|"
                f"target={target}|current={current_metric}|op={operator}|"
                f"exit={current.get('exit_code', 1)}|reason={reason}"
            )

            gate_reports.append(
                {
                    "gate": gate_name,
                    "status": status,
                    "reason": reason,
                    "operator": operator,
                    "baseline_metric": baseline_metric,
                    "target": target,
                    "current_metric": current_metric,
                    "exit_code": current.get("exit_code", 1),
                    "metric_name": metric_name,
                    "command": current.get("command", ""),
                }
            )

        report = {
            "mode": "verify",
            "overall": "PASS" if all_passed else "FAIL",
            "baseline_file": str(self.baseline_path),
            "generated_at": datetime.now().isoformat(),
            "gates": gate_reports,
        }
        self._write_report(report)

        if all_passed:
            print("OVERALL_RESULT|PASS")
            return True

        print("OVERALL_RESULT|FAIL")
        return False


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python3 quality_gate.py [baseline|verify]")
        sys.exit(1)

    command = sys.argv[1].strip().lower()
    quality_gate = QualityGate()

    if command == "baseline":
        sys.exit(0 if quality_gate.baseline() else 1)
    if command == "verify":
        sys.exit(0 if quality_gate.verify() else 1)

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
    "tests": "make test",
    "coverage": "make test-cov",
    "lint": "make lint",
    "types": "make type-check",
    "build": "make build",
    "security_secrets": "detect-secrets scan --all-files 2>&1 || true",
    "security_vulns": "pip-audit 2>&1 || true"
  },
  "thresholds": {
    "tests": {"type": "count", "operator": "≥"},
    "coverage": {"type": "percentage", "operator": "≥"},
    "lint": {"type": "count", "operator": "=", "value": 0},
    "types": {"type": "count", "operator": "≤"},
    "build": {"type": "exit_code", "operator": "=", "value": 0},
    "security_secrets": {"type": "count", "operator": "=", "value": 0},
    "security_vulns": {"type": "count", "operator": "≤"}
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
    "build": "npm run build",
    "security_secrets": "detect-secrets scan --all-files 2>&1 || true",
    "security_vulns": "npm audit --audit-level=high 2>&1 || true"
  },
  "thresholds": {
    "tests": {"type": "count", "operator": "≥"},
    "coverage": {"type": "percentage", "operator": "≥"},
    "lint": {"type": "count", "operator": "=", "value": 0},
    "types": {"type": "count", "operator": "≤"},
    "build": {"type": "exit_code", "operator": "=", "value": 0},
    "security_secrets": {"type": "count", "operator": "=", "value": 0},
    "security_vulns": {"type": "count", "operator": "≤"}
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
    "build": "make build",
    "security_secrets": "detect-secrets scan --all-files 2>&1 || true",
    "security_vulns": "pip-audit 2>&1 || npm audit --audit-level=high 2>&1 || true"
  },
  "thresholds": {
    "tests": {"type": "count", "operator": "≥"},
    "coverage": {"type": "percentage", "operator": "≥"},
    "lint": {"type": "count", "operator": "=", "value": 0},
    "types": {"type": "count", "operator": "≤"},
    "build": {"type": "exit_code", "operator": "=", "value": 0},
    "security_secrets": {"type": "count", "operator": "=", "value": 0},
    "security_vulns": {"type": "count", "operator": "≤"}
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

      - name: Install security tools
        run: pip install detect-secrets pip-audit 2>/dev/null || true

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
	@python3 scripts/quality_gate.py baseline

quality-gate-verify: ## Verify no regression since baseline
	@python3 scripts/quality_gate.py verify
EOF

# Also create lowercase variant for repos that only include *.makefile
cp makefiles/quality-gate.Makefile makefiles/quality-gate.makefile

# If root Makefile does not include makefiles/, add direct fallback targets
if [ -f "Makefile" ]; then
    set +e
    make -n quality-gate-baseline >/dev/null 2>&1
    HAS_TARGET=$?
    set -e

    if [ "$HAS_TARGET" -ne 0 ]; then
        echo "  ✏️  Appending fallback targets to root Makefile..."
        cat >> Makefile << 'EOF'

# ── Quality Gates ──────────────────────────────────────────────────────────────

quality-gate-baseline: ## Record baseline metrics for regression detection
	@python3 scripts/quality_gate.py baseline

quality-gate-verify: ## Verify no regression since baseline
	@python3 scripts/quality_gate.py verify
EOF
    fi
fi

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
