#!make
# GitHub Actions Workflows Testing & Management

workflows-act-install: ## Install act (GitHub Actions local simulator)
	@if ! command -v act &> /dev/null; then \
		echo "Installing act..." ; \
		curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash ; \
		echo "✓ act installed successfully" ; \
	else \
		echo "✓ act is already installed: $$(act --version)" ; \
	fi

workflows-act-check: ## Check if act is installed
	@if command -v act &> /dev/null; then \
		echo "✓ act is installed: $$(act --version)" ; \
	else \
		echo "✗ act is NOT installed. Run: make workflows-act-install" ; \
		exit 1 ; \
	fi
	@if ! (docker ps &> /dev/null || sudo docker ps &> /dev/null); then \
		echo "⚠ Warning: Docker is not accessible" ; \
		echo "  To fix: sudo usermod -aG docker $$USER or enable Docker access" ; \
	fi

workflows-list: ## List all workflow files
	@echo "Available workflows:" ; \
	find .github/workflows -name "*.yml" -type f | sed 's|.github/workflows/||' | sed 's|.yml||' | sort

workflows-lint: ## Lint all workflow files with actionlint
	@if ! command -v actionlint &> /dev/null; then \
		echo "Installing actionlint..." ; \
		go install github.com/rhysd/actionlint/cmd/actionlint@latest ; \
	fi ; \
	echo "Linting workflows..." ; \
	actionlint .github/workflows/*.yml || true

workflows-test: check-defined-workflow ## Test single workflow locally => workflow={workflow_name} [event=push|pull_request]
	@echo "Testing workflow: ${workflow}" ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	if [ -z "${event}" ]; then \
		act push -W .github/workflows/${workflow}.yml . ; \
	else \
		act ${event} -W .github/workflows/${workflow}.yml . ; \
	fi

workflows-test-event: check-defined-workflow check-defined-event ## Test workflow with specific event => workflow={workflow_name} event={push|pull_request|schedule|workflow_dispatch}
	@echo "Testing workflow '${workflow}' with event '${event}'..." ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	act ${event} -W .github/workflows/${workflow}.yml . || \
	(echo "" ; echo "💡 List available jobs:" ; act ${event} -W .github/workflows/${workflow}.yml --list ; exit 1)

workflows-jobs-list: check-defined-workflow ## List all jobs in a workflow => workflow={workflow_name} [event=push]
	@echo "Available jobs in ${workflow}:" ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	if [ -z "${event}" ]; then \
		act push -W .github/workflows/${workflow}.yml --list ; \
	else \
		act ${event} -W .github/workflows/${workflow}.yml --list ; \
	fi

workflows-test-push-develop: ## Simulate push to develop branch
	@echo "Simulating push to develop branch..." ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	echo '{"ref":"refs/heads/develop","repository":{"default_branch":"develop"}}' > /tmp/push-event.json && \
	act push -W .github/workflows/full-analysis.yml -e /tmp/push-event.json . ; \
	rm -f /tmp/push-event.json

workflows-test-pr-opened: ## Simulate PR opened event
	@echo "Simulating PR opened event..." ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	printf '{"action":"opened","pull_request":{"number":1,"head":{"ref":"feature-branch"},"base":{"ref":"develop"}}}' > /tmp/pr-event.json && \
	act pull_request -W .github/workflows/full-analysis.yml -e /tmp/pr-event.json . ; \
	rm -f /tmp/pr-event.json

workflows-test-all: ## Test all workflows locally (requires Docker)
	@echo "Testing all workflows..." ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	echo "Note: This may take a while and requires significant disk space" ; \
	echo "" ; \
	echo "Available workflows and jobs:" ; \
	act push --list 2>/dev/null || (echo "💡 Run 'docker ps' to check if Docker is running" ; exit 1) ; \
	echo "" ; \
	echo "Run individual workflows with: make workflows-test workflow={workflow_name}"

workflows-test-rebuild: ## Clear act cache and rebuild test environment
	@echo "Clearing act cache..." ; \
	rm -rf ~/.cache/act 2>/dev/null || true ; \
	echo "✓ Cache cleared. Next test will rebuild environment."

workflows-test-debug: check-defined-workflow ## Test workflow with debug logging => workflow={workflow_name}
	@echo "Testing workflow with debug: ${workflow}" ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	act -W .github/workflows/${workflow}.yml --verbose .

workflows-test-full-analysis: ## Test full-analysis workflow (comprehensive test)
	@echo "Testing full-analysis workflow..." ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	echo '{"ref":"refs/heads/develop"}' > /tmp/event.json && \
	act push -W .github/workflows/full-analysis.yml -e /tmp/event.json . ; \
	rm -f /tmp/event.json

workflows-test-lint-migrations: ## Test lint-migrations workflow
	@echo "Testing lint-migrations workflow..." ; \
	$(MAKE) --stop --no-print-directory workflows-act-check ; \
	echo '{"ref":"refs/heads/develop"}' > /tmp/event.json && \
	act push -W .github/workflows/lint-migrations.yml -e /tmp/event.json . ; \
	rm -f /tmp/event.json

workflows-validate-syntax: ## Validate YAML syntax of all workflows
	@echo "Validating workflow YAML syntax..." ; \
	for file in .github/workflows/*.yml; do \
		echo "Checking $$file..." ; \
		python3 -c "import yaml; yaml.safe_load(open('$$file'))" || exit 1 ; \
	done ; \
	echo "✓ All workflows have valid YAML syntax"

workflows-docker-check: ## Check if Docker is running
	@if docker ps &> /dev/null; then \
		echo "✓ Docker is running: $$(docker --version)" ; \
	else \
		echo "✗ Docker is NOT running" ; \
		echo "  To fix:" ; \
		echo "  - Linux: sudo systemctl start docker" ; \
		echo "  - macOS: open /Applications/Docker.app" ; \
		echo "  - Windows: Start Docker Desktop from Start Menu" ; \
		exit 1 ; \
	fi

workflows-docker-start: ## Start Docker daemon (Linux only)
	@if [ "$$(uname)" = "Linux" ]; then \
		echo "Starting Docker daemon..." ; \
		sudo systemctl start docker && echo "✓ Docker started" ; \
	else \
		echo "Use your system's usual method to start Docker" ; \
	fi

workflows-help: ## Display workflow testing commands
	@echo "GitHub Actions Workflow Testing Commands:" ; \
	echo "" ; \
	echo "🚀 Setup:" ; \
	echo "  make workflows-act-install     - Install act locally" ; \
	echo "  make workflows-docker-check    - Check if Docker is running" ; \
	echo "  make workflows-docker-start    - Start Docker (Linux only)" ; \
	echo "" ; \
	echo "📋 Information:" ; \
	echo "  make workflows-list            - List all workflows" ; \
	echo "  make workflows-jobs-list workflow={name} - List jobs in workflow" ; \
	echo "  make workflows-validate-syntax - Validate YAML syntax" ; \
	echo "  make workflows-lint            - Lint workflows with actionlint" ; \
	echo "" ; \
	echo "🧪 Testing:" ; \
	echo "  make workflows-test workflow={name}              - Test workflow (default: push event)" ; \
	echo "  make workflows-test workflow={name} event={type} - Test with specific event" ; \
	echo "  make workflows-test-event workflow={name} event={type} - Alias for above" ; \
	echo "  make workflows-test-debug workflow={name}        - Test with debug output" ; \
	echo "  make workflows-test-all                          - Test all workflows" ; \
	echo "" ; \
	echo "📦 Preset Tests:" ; \
	echo "  make workflows-test-full-analysis    - Test full-analysis workflow" ; \
	echo "  make workflows-test-lint-migrations  - Test lint-migrations workflow" ; \
	echo "  make workflows-test-push-develop     - Simulate push to develop" ; \
	echo "  make workflows-test-pr-opened        - Simulate PR opened" ; \
	echo "" ; \
	echo "🧹 Maintenance:" ; \
	echo "  make workflows-test-rebuild          - Clear act cache and rebuild" ; \
	echo "" ; \
	echo "💡 Tips:" ; \
	echo "  - Use 'event=push pull_request schedule' for different event types" ; \
	echo "  - Docker must be running: make workflows-docker-check" ; \
	echo "  - View available jobs: make workflows-jobs-list workflow=lint-migrations" ; \
	echo ""
