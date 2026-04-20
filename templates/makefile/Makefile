# Makefile — entry point. Includes modular makefiles from makefiles/
# Pattern inspired by padam-av (gold standard in the chrysa ecosystem).
.DEFAULT_GOAL := help
SHELL := /bin/bash

# Project vars — override per repo
PROJECT      ?= $(notdir $(CURDIR))
PYTHON       ?= python3
NODE         ?= node
DOCKER       ?= docker
COMPOSE      ?= docker compose

# Include all modular makefiles
-include makefiles/*.makefile

.PHONY: help
help:
	@echo "$(PROJECT) — available targets:"
	@grep -hE '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*?##"}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

.PHONY: all
all: install lint test build ## install → lint → test → build

.PHONY: clean
clean: ## Remove build artifacts and caches
	rm -rf dist/ build/ .pytest_cache/ .mypy_cache/ .ruff_cache/ coverage.xml htmlcov/ node_modules/.cache/ 2>/dev/null || true
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
