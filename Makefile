# makefile-tier: lib
.PHONY: help install dev test test-cov docker-test lint format typecheck build clean pre-commit

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

# The only executable code lives in console/. CI's `make docker-test` builds its
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

# ── Quality Gates ──────────────────────────────────────────────────────────────

quality-gate-baseline: ## Record baseline metrics for regression detection
	@python3 scripts/quality_gate.py baseline

quality-gate-verify: ## Verify no regression since baseline
	@python3 scripts/quality_gate.py verify
