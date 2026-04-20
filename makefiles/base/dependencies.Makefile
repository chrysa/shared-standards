#!make

# ============================================================================
# DEPENDENCY CHECK TARGETS
# ============================================================================

check-dependencies: ## Verify all project dependencies are present (tools)
	$(call log-info,checking all project dependencies)
	@errors=0; \
	$(MAKE) --stop --no-print-directory check-dependencies-tools || errors=$$((errors + 1)); \
	echo ""; \
	if [ $$errors -eq 0 ]; then \
		echo "\033[1;32m✅ All dependencies are present — project is ready to run.\033[0m"; \
	else \
		echo "\033[1;31m❌ $$errors dependency check(s) failed — fix the issues above before running the project.\033[0m"; \
		exit 1; \
	fi

check-dependencies-tools: ## Verify required system tools are installed (git, docker, pip, pre-commit, gh)
	$(call log-info,checking system tools)
	@echo "\033[1;36m=== System Tools ===\033[0m"; \
	errors=0; \
	for tool in $(REQUIRED_SYSTEM_TOOLS); do \
		if command -v $$tool >/dev/null 2>&1; then \
			echo "  \033[1;32m✅\033[0m $$tool ($$($$tool --version 2>&1 | head -1))"; \
		else \
			echo "  \033[1;31m❌\033[0m $$tool — not found"; \
			errors=$$((errors + 1)); \
		fi; \
	done; \
	if command -v docker >/dev/null 2>&1; then \
		if docker compose version >/dev/null 2>&1; then \
			echo "  \033[1;32m✅\033[0m docker compose ($$(docker compose version 2>&1 | head -1))"; \
		else \
			echo "  \033[1;31m❌\033[0m docker compose plugin — not found"; \
			errors=$$((errors + 1)); \
		fi; \
		if docker info >/dev/null 2>&1; then \
			echo "  \033[1;32m✅\033[0m docker daemon — running"; \
		else \
			echo "  \033[1;31m❌\033[0m docker daemon — not running"; \
			errors=$$((errors + 1)); \
		fi; \
	fi; \
	if [ $$errors -gt 0 ]; then \
		echo ""; \
		echo "\033[1;31m  $$errors system tool(s) missing or unavailable.\033[0m"; \
		exit 1; \
	fi

install-dependencies: ## Install missing system tools via apt (git, docker, pip, pre-commit, gh)
	$(call log-info,installing missing system tools)
	@echo "\033[1;36m=== Installing missing system tools ===\033[0m"; \
	missing=""; \
	for mapping in $(REQUIRED_SYSTEM_TOOLS_APT_PACKAGES); do \
		tool=$$(echo $$mapping | cut -d'=' -f1); \
		package=$$(echo $$mapping | cut -d'=' -f2); \
		if ! command -v $$tool >/dev/null 2>&1; then \
			echo "  \033[1;33m⚠️\033[0m  $$tool not found — will install $$package"; \
			missing="$$missing $$package"; \
		else \
			echo "  \033[1;32m✅\033[0m $$tool already installed"; \
		fi; \
	done; \
	if [ -n "$$missing" ]; then \
		echo ""; \
		echo "\033[1;34mRunning: sudo apt-get install -y$$missing\033[0m"; \
		sudo apt-get update -qq && sudo apt-get install -y $$missing; \
		echo ""; \
		echo "\033[1;32m✅ Installation complete.\033[0m"; \
	else \
		echo ""; \
		echo "\033[1;32m✅ All tools already installed — nothing to do.\033[0m"; \
	fi

# ============================================================================

outdated: ## Check outdated Python packages for the tests service (default)
	$(call log-info,checking outdated Python packages for service ${__tests_service_name})
	@echo "\033[1;36m=== Outdated packages for ${__tests_service_name} ===\033[0m"
	$(call run_outdated_check,${__tests_service_name},${OUTDATED_CMD})

outdated-%: ## Check outdated Python packages for a specific service
	$(call log-info,checking outdated Python packages for service $*)
	@echo "\033[1;36m=== Outdated packages for $* ===\033[0m"
	$(call run_outdated_check,$*,${OUTDATED_CMD})

outdated-all: ## Check outdated Python packages for all services
	$(call log-info,checking outdated Python packages for all services)
	@echo "\033[1;36m===== Checking outdated packages for all services =====\033[0m"
	@for service in ${SERVICES}; do \
		echo "\n\033[1;34m=> Service: $$service\033[0m"; \
		$(call run_outdated_check,$$service,${OUTDATED_CMD}); \
	done
	@echo "\n\033[1;36m===== Check completed =====\033[0m"

outdated-audit: ## Check security vulnerabilities in Python packages for the tests service (default)
	$(call log-info,security audit of Python packages for service ${__tests_service_name})
	@echo "\033[1;36m=== Security audit for ${__tests_service_name} ===\033[0m"
	$(call run_outdated_check,${__tests_service_name},${OUTDATED_AUDIT_CMD})

outdated-audit-%: ## Check security vulnerabilities in Python packages for a specific service
	$(call log-info,security audit of Python packages for service $*)
	@echo "\033[1;36m=== Security audit for $* ===\033[0m"
	$(call run_outdated_check,$*,${OUTDATED_AUDIT_CMD})

outdated-audit-all: ## Check security vulnerabilities in Python packages for all services
	$(call log-info,security audit of Python packages for all services)
	@echo "\033[1;36m===== Running security audit for all services =====\033[0m"
	@for service in ${SERVICES}; do \
		echo "\n\033[1;34m=> Service: $$service\033[0m"; \
		$(call run_outdated_check,$$service,${OUTDATED_AUDIT_CMD}); \
	done
	@echo "\n\033[1;36m===== Audit completed =====\033[0m"

outdated-json: ## Generate a JSON report of outdated Python packages for the tests service (default)
	$(call log-info,generating JSON report of outdated Python packages for service ${__tests_service_name})
	$(call generate_json_report,${__tests_service_name})

outdated-json-%: ## Generate a JSON report of outdated Python packages for a specific service
	$(call log-info,generating JSON report of outdated Python packages for service $*)
	$(call generate_json_report,$*)

outdated-json-all: ## Generate JSON reports of outdated Python packages for all services
	$(call log-info,generating JSON reports of outdated Python packages for all services)
	@echo "\033[1;36m===== Generating JSON reports for all services =====\033[0m"
	@mkdir -p ${OUTDATED_REPORTS_DIR}
	@for service in ${SERVICES}; do \
		echo "\n\033[1;34m=> Service: $$service\033[0m"; \
		mkdir -p ${OUTDATED_REPORTS_DIR}/$$service; \
		${DOCKER_COMPOSE_CMD} run ${DOCKER_RUN_COMMON_ARGS} $$service -c "${OUTDATED_JSON_CMD} > /reports/pip-outdated/$$service/outdated.json" 2>/dev/null || \
		echo "\033[1;33mService $$service is not available. Skipping...\033[0m"; \
		if [ -f ${OUTDATED_REPORTS_DIR}/$$service/outdated.json ] && [ -s ${OUTDATED_REPORTS_DIR}/$$service/outdated.json ]; then \
			echo "Summary of outdated packages:"; \
			cat ${OUTDATED_REPORTS_DIR}/$$service/outdated.json | grep -E '"name"|"version"|"latest_version"' | \
			sed 's/"name": "/Package: /g' | \
			sed 's/"version": "/Current version: /g' | \
			sed 's/"latest_version": "/Latest version: /g' | \
			sed 's/",//g' | sed 's/"//g' | \
			paste -d " " - - - | sort; \
		elif [ -f ${OUTDATED_REPORTS_DIR}/$$service/outdated.json ]; then \
			echo "No outdated packages"; \
		fi; \
	done
	@echo "\n\033[1;36m===== Reports generated in ${OUTDATED_REPORTS_DIR}/ =====\033[0m"
