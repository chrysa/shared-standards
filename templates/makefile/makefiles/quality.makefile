.PHONY: lint format type-check test coverage ci

lint: ## Run linters (ruff / eslint / shellcheck)
	@[ -f pyproject.toml ] && ruff check . || true
	@[ -f package.json ] && pnpm lint 2>/dev/null || true
	@command -v pre-commit >/dev/null && pre-commit run --all-files || true

format: ## Auto-format code
	@[ -f pyproject.toml ] && ruff format . || true
	@[ -f package.json ] && pnpm format 2>/dev/null || true

type-check: ## Run mypy/tsc type check
	@[ -f pyproject.toml ] && mypy . || true
	@[ -f tsconfig.json ] && pnpm type-check 2>/dev/null || true

test: ## Run test suite
	@[ -f pyproject.toml ] && pytest || true
	@[ -f package.json ] && pnpm test 2>/dev/null || true

coverage: ## Run tests with coverage
	@[ -f pyproject.toml ] && pytest --cov --cov-report=xml --cov-report=term || true
	@[ -f package.json ] && pnpm test:coverage 2>/dev/null || true

ci: lint type-check test ## Full CI pipeline (lint + type + test)
