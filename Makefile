# makefile-tier: lib
.PHONY: help install dev test test-cov test-scripts docker-test lint format typecheck build clean pre-commit ci gen-agent-views spec-plan-gate-report

help:
	@echo "Available targets:"
	@echo "  install     Install pre-commit hooks"
	@echo "  lint        Run pre-commit hooks"
	@echo "  pre-commit  Run all pre-commit checks"
	@echo "  gen-agent-views  Regenerate agent views from the standards canon"
	@echo "  dev         No dev server — shared-standards is a documentation repo"
	@echo "  test        No tests — shared-standards is a documentation repo"
	@echo "  build       No build artefact — shared-standards is a documentation repo"

install:
	pre-commit install

# Regenerate every agent view (slim CLAUDE.md core, standards/rules/<domain>.md, AGENTS.md,
# .github/copilot-instructions.md) from the canon. The agent-views-drift gate verifies it.
gen-agent-views: ## Regenerate the agent views from standards/STANDARDS.chrysa.md
	python3 -m scripts.gen_agent_views

dev:
	@echo "No dev server — shared-standards is a documentation-only repo"

test:
	@echo "No tests — shared-standards is a documentation-only repo"

test-cov:
	@echo "No tests — shared-standards is a documentation-only repo"

# Host-native tests for the canonical scripts (quality_gate parser, pre-commit-merge).
# These run as host tools (pre-commit invokes them without Docker), so they are tested on
# the host and their coverage travels to Sonar next to the console coverage — otherwise a
# scripts/ change is counted as 0% new-code coverage.
test-scripts: ## Run the scripts test suite with coverage (host)
	python3 -m coverage run --include='scripts/quality_gate.py,scripts/pre-commit-merge.py,scripts/pyproject-ruff-merge.py,scripts/gen_agent_views.py,scripts/pii/*.py' -m pytest tests/scripts tests/pii tests/test_pyproject_ruff_merge.py tests/test_pre_commit_merge_exclude.py -q
	python3 -m coverage xml -o scripts-coverage.xml

# The console app lives in console/ and its suite runs in Docker. CI's `make docker-test` builds its
# dev image, runs the suite in-container, and emits a repo-root coverage.xml whose
# paths are rewritten so SonarCloud (analysing from the repo root) can map them.
docker-test: ## Run the console test suite in Docker; emit repo-root coverage.xml
	docker build -f console/Dockerfile --target dev -t chrysa/standards-console:test console
	docker run --rm chrysa/standards-console:test \
		sh -c "pytest -q --cov=standards_console --cov-report=xml:/tmp/coverage.xml >&2 && cat /tmp/coverage.xml" \
		> coverage.xml
	python3 scripts/rewrite-coverage-paths.py coverage.xml console/standards_console

lint:
	pre-commit run --all-files

format:
	pre-commit run --all-files || true

typecheck:
	@echo "No typecheck — shared-standards is a documentation-only repo"

build:
	@echo "No build artefact — shared-standards is a documentation-only repo"

clean:
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

pre-commit:
	pre-commit run --all-files

ci: lint typecheck test ## Run the repo CI gate (lint + typecheck + test)
	@echo "CI gate passed."

# ── Quality Gates ──────────────────────────────────────────────────────────────

quality-gate-baseline: ## Record baseline metrics for regression detection
	@python3 scripts/quality_gate.py baseline

quality-gate-verify: ## Verify no regression since baseline
	@python3 scripts/quality_gate.py verify

# ── Spec->Plan enforcement gate (ADR D-0011) ───────────────────────────────────

spec-plan-gate-report: ## Kill-test report from reports/.spec-plan-gate.log
	@python3 scripts/spec_plan_gate_report.py
