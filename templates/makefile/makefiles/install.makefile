.PHONY: install install-python install-node install-hooks

install: install-python install-node install-hooks ## Install all dependencies

install-python: ## Install Python deps via poetry or pip
	@if [ -f pyproject.toml ]; then \
		command -v poetry >/dev/null && poetry install || $(PYTHON) -m pip install -e . ; \
	elif [ -f requirements.txt ]; then \
		$(PYTHON) -m pip install -r requirements.txt ; \
	else \
		echo "no Python project detected — skip" ; \
	fi

install-node: ## Install Node deps via pnpm/yarn/npm
	@if [ -f pnpm-lock.yaml ]; then pnpm install ; \
	elif [ -f yarn.lock ];       then yarn install ; \
	elif [ -f package-lock.json ];then npm ci ; \
	elif [ -f package.json ];    then pnpm install ; \
	else echo "no Node project detected — skip" ; fi

install-hooks: ## Install pre-commit hooks
	@command -v pre-commit >/dev/null && pre-commit install || echo "pre-commit not installed — skip"
