# makefile-tier: lib
.PHONY: help install dev test test-cov lint format typecheck build clean pre-commit

help:
	@echo "Available targets:"
	@echo "  install     Install pre-commit hooks"
	@echo "  lint        Run pre-commit hooks"
	@echo "  pre-commit  Run all pre-commit checks"
	@echo "  dev         No dev server — shared-standards is a documentation repo"
	@echo "  test        No tests — shared-standards is a documentation repo"
	@echo "  build       No build artefact — shared-standards is a documentation repo"

install:
	pre-commit install

dev:
	@echo "No dev server — shared-standards is a documentation-only repo"

test:
	@echo "No tests — shared-standards is a documentation-only repo"

test-cov:
	@echo "No tests — shared-standards is a documentation-only repo"

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

# ── Quality Gates ──────────────────────────────────────────────────────────────

quality-gate-baseline: ## Record baseline metrics for regression detection
	@python3 scripts/quality_gate.py baseline

quality-gate-verify: ## Verify no regression since baseline
	@python3 scripts/quality_gate.py verify
