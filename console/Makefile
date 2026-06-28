# makefile-tier: fullstack
.PHONY: help install dev api web build test test-cov lint format typecheck ci clean \
        pre-commit docker-up docker-down docker-test e2e \
        web-build web-lint web-typecheck quality-gate-baseline quality-gate-verify

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

install:  ## Install backend + frontend deps
	uv pip install -e '.[dev]'
	cd web && pnpm install

api:  ## Run the FastAPI backend (JSON API)
	standards-console

web:  ## Run the Vite dev server (proxies /api to the backend)
	cd web && pnpm dev

dev: api  ## Alias for `api`

build: web-build  ## Build the SPA into standards_console/web_dist/

web-build:  ## Build the React SPA
	cd web && pnpm build

test:  ## Run backend + frontend unit tests
	uv run pytest
	cd web && pnpm test

test-cov:  ## Run backend tests with coverage gate
	uv run pytest --cov=standards_console --cov-report=term-missing

lint:  ## Lint both stacks
	uv run ruff check .
	cd web && pnpm lint

web-lint:  ## Lint the frontend
	cd web && pnpm lint

format:  ## Auto-format the backend
	uv run ruff format standards_console tests

typecheck:  ## Typecheck both stacks
	uv run mypy standards_console
	cd web && pnpm exec tsc -b

web-typecheck:  ## Typecheck the frontend
	cd web && pnpm exec tsc -b

ci: lint typecheck test-cov web-build  ## Full local CI (lint + types + tests + build)

pre-commit: lint typecheck  ## Lightweight pre-commit gate

clean:  ## Remove caches and build artifacts
	rm -rf .pytest_cache .mypy_cache .ruff_cache .coverage \
		standards_console/web_dist web/dist web/*.tsbuildinfo

docker-up:  ## Start the console container
	docker compose up -d --build

docker-down:  ## Stop the console container
	docker compose down

docker-test:  ## Run the test suite inside the container
	docker compose run --rm console pytest

e2e:  ## Placeholder for Playwright E2E (tracked separately)
	@echo "E2E suite not yet implemented (see DECISIONS.md D-0005)."

quality-gate-baseline:  ## Record baseline metrics
	@echo "Use the root shared-standards quality-gate tooling."

quality-gate-verify:  ## Verify no regression since baseline
	@echo "Use the root shared-standards quality-gate tooling."
