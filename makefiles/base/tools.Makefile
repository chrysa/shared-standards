#!make

clean: ## Clean project temporary files
	@rm -rf reports/*
	@rm -rf docs/graphs/*
	@rm -rf docker/entrypoints/bootstraped/*
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} +

create-docs-required-folders:
	@mkdir -p docs/graphs docs/sphinx

create-project-required-folders:
	$(call log-info,create project required folders)
	@mkdir -p ${project_required_files_and_folder}

create-quality-required-folders:
	$(call log-info,create quality required folders)
	@mkdir -p ${quality_required_files_and_folder}

create-tests-required-folders:
	$(call log-info,create tests required folders)
	@mkdir -p ${tests_required_files_and_folder}

secrets-bootstrap: ## Ensure secrets bootstrap prerequisites are met (no-op, handled by secrets.yaml)
	@true

generate-env-file: secrets-bootstrap ## Generate .env from project variables and YAML secrets
	$(call log-info,generate env file for ${cmd})
	@echo "BOOTSTRAPED_FILE=${BOOTSTRAPED_FILE}\n\
	COMPOSE_PROFILES=$(shell ${__docker_compose_project_base_command} config --profiles | xargs | sed 's/ /,/g')\n\
	DATABASE_NAME=${DATABASE_NAME}\n\
	DJANGO_SUPERUSER_EMAIL=${DJANGO_SUPERUSER_EMAIL}\n\
	DJANGO_SUPERUSER_PASSWORD=${DJANGO_SUPERUSER_PASSWORD}\n\
	DJANGO_SUPERUSER_USERNAME=${DJANGO_SUPERUSER_USERNAME}\n\
	ENVIRONMENT=local\n\
	FRONT_BASE_URL=${FRONT_BASE_URL}\n\
	GIT_BRANCH=${GIT_BRANCH}\n\
	GIT_BRANCH_LONG=${GIT_BRANCH_LONG}\n\
	PADAM_AV_BACK_IMAGE=${__dev_image}\n\
	PADAM_AV_BACKEND_IMAGE=${__backend_image}\n\
	PADAM_AV_PRODUCTION_IMAGE=${__prod_image}\n\
	PADAM_AV_PROTOBUF_IMAGE=${__protobuf_image}\n\
	PALOMATA_API_URL=''\n\
	RELEASE_NAME=${GIT_BRANCH_LONG}" > .env
	@if [ -f "${SECRETS_YAML_FILE}" ]; then \
		while IFS= read -r line; do \
			cleaned_line=$$(printf "%s" "$$line" | sed -E 's/[[:space:]]+#.*$$//'); \
			if [ -z "$$cleaned_line" ] || ! printf "%s" "$$cleaned_line" | grep -Eq '^[[:space:]]*[A-Za-z0-9_-]+:[[:space:]]*'; then \
				continue; \
			fi; \
			key=$$(printf "%s" "$$cleaned_line" | sed -E 's/^[[:space:]]*([^:]+):[[:space:]]*(.*)$$/\1/' | tr '[:lower:]' '[:upper:]' | tr '-' '_'); \
			value=$$(printf "%s" "$$cleaned_line" | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*(.*)$$/\1/' | sed -E "s/^'(.*)'$$/\\1/; s/^\"(.*)\"$$/\\1/"); \
			value=$$(printf "%s" "$$value" | tr -d '\015' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$$//'); \
			if [ "$$key" = "LOCAL_LOGSTASH" ]; then \
				continue; \
			fi; \
			if ! awk -F '=' -v key="$$key" '$$1 == key {found=1} END {exit found ? 0 : 1}' .env; then \
				echo "$$key=$$value" >> .env; \
			fi; \
		done < "${SECRETS_YAML_FILE}"; \
	else \
		echo "Warning: Secrets file '${SECRETS_YAML_FILE}' not found. Skipping secrets injection into .env." >&2; \
		exit 1; \
	fi
	@sort .env -o .env

help: ## Display this help message
	@echo "==================================================================="
	@echo "🚗 Padam AV - Autonomous Vehicle Management System"
	@echo "==================================================================="
	@echo ""
	@echo "Available commands (sorted alphabetically):"
	@echo ""
	@tmp_file=$$(mktemp); \
	for file in $$(find makefiles padam_av/apps -name "*.Makefile" -type f 2>/dev/null); do \
		if [ -f "$$file" ]; then \
			filename=$$(basename "$$file" .Makefile); \
			category_name=$$(echo "$$filename" | sed 's/-/ /g' | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $$i=toupper(substr($$i,1,1)) tolower(substr($$i,2))}1'); \
			emoji="📁"; \
			case "$$filename" in \
				backoffice) emoji="🖥️ "; category_name="Backoffice" ;; \
				build) emoji="🏗️ "; category_name="Build" ;; \
				database) emoji="💾"; category_name="Database" ;; \
				docker) emoji="🐳"; category_name="Docker" ;; \
				frontend) emoji="🌐"; category_name="Frontend" ;; \
				functions) continue ;; \
				git) emoji="�"; category_name="Git" ;; \

				mobile-thinking) emoji="📱"; category_name="Mobile Thinking" ;; \
				navya) emoji="🚐"; category_name="Navya" ;; \
				palomata) emoji="🦜"; category_name="Palomata" ;; \
				project) emoji="📦"; category_name="Project" ;; \
				quality) emoji="🔍"; category_name="Quality" ;; \
				tests) emoji="🧪"; category_name="Tests" ;; \
				tools) emoji="🛠️ "; category_name="Tools" ;; \
				variables) continue ;; \
				*) emoji="❓"; category_name=$$filename ;; \
			esac; \
			commands=$$(grep -E '^[a-zA-Z_-]+:.*?## .*$$' "$$file" 2>/dev/null | grep -v "^help:" | wc -l); \
			if [ $$commands -gt 0 ]; then \
				echo "$$category_name|$$emoji|$$file" >> "$$tmp_file"; \
			fi; \
		fi; \
	done; \
	sort "$$tmp_file" | while IFS='|' read -r category_name emoji file; do \
		echo "$$emoji $$category_name:"; \
		grep -E '^[a-zA-Z_-]+:.*?## .*$$' "$$file" | grep -v "^help:" | \
		awk 'BEGIN {FS = ":.*?## "}; {print $$1 "|||" $$2}' | \
		sort -t'|' -k1,1 | \
		awk 'BEGIN {FS = "\\|\\|\\|"}; { \
			split($$2, parts, " => "); \
			desc = parts[1]; \
			args = parts[2]; \
			if (args != "") { \
				printf "  \033[36m%-30s\033[0m %-40s \033[33m%s\033[0m\n", $$1, desc, args; \
			} else { \
				printf "  \033[36m%-30s\033[0m %s\n", $$1, desc; \
			} \
		}'; \
		echo ""; \
	done; \
	rm -f "$$tmp_file"
	@echo ""
	@echo "📝 USAGE EXAMPLES:"
	@echo "  make dev					  # Start development server"
	@echo "  make tests				      # Run all tests"
	@echo "  make format-code			  # Format code with all tools"
	@echo "  make docker-build			  # Build Docker images"
	@echo "  make migrate				  # Apply database migrations"
	@echo ""
	@echo "💡 TIPS:"
	@echo "  • Use 'make help-%' for detailed help on a specific command"
	@echo "  • Commands accept parameters shown in yellow brackets []"
	@echo "  • Example: make tests target_test=apps/mission/tests/"
	@echo ""
	@echo "==================================================================="

help-%: ## Show detailed help for a specific command
	@echo "==================================================================="
	@echo "Detailed help for: \033[36m$*\033[0m"
	@echo "==================================================================="
	@echo ""
	@grep -A 3 -B 1 "^$*:" $$(find makefiles -name "*.Makefile" -type f) 2>/dev/null | head -20 || echo "❌ Command '$*' not found"
	@echo ""
	@echo "To see all commands: make help"
	@echo "==================================================================="

project-help: ## Display Django management commands
	@${__run_cmd_no_deps} --entrypoint='python' --env DJANGO_LOG_LEVEL=ERROR ${__dev_service_name} manage.py help

help-%: ## Show detailed help for a specific command
	@echo "==================================================================="
	@echo "Detailed help for: \033[36m$*\033[0m"
	@echo "==================================================================="
	@echo ""
	@grep -A 3 -B 1 "^$*:" $$(find makefiles -name "*.Makefile" -type f) 2>/dev/null | head -20 || echo "❌ Command '$*' not found"
	@echo ""
	@echo "To see all commands: make help"
	@echo "==================================================================="

pre-rules:
	@set -e ; \
	commands="$(filter-out %=%,$(MAKECMDGOALS))"; \
	for command in $${commands}; do \
		if ! grep -qE "^$${command}:.*" $(MAKEFILE_LIST); then \
			echo "Error: rule '$${command}' does not exist in Makefile." >&2; \
			exit 1; \
		fi; \
		makefile_file=$$(grep -l "^$${command}:.*" makefiles/*.Makefile padam_av/apps/**/*.Makefile 2>/dev/null | head -1); \
		if [ -z "$$makefile_file" ]; then \
			continue; \
		fi; \
		case "$$makefile_file" in \
			makefiles/backoffice.Makefile|makefiles/frontend.Makefile|makefiles/functions.Makefile|makefiles/tools.Makefile|makefiles/variables.Makefile|padam_av/apps/provider/**/palomata/**/*.Makefile) \
				true ;; \
			makefiles/docker.Makefile) \
				$(MAKE) --stop --no-print-directory --quiet generate-env-file cmd=$${command} ;; \
			makefiles/database.Makefile) \
				$(MAKE) --stop --no-print-directory --quiet generate-env-file create-docs-required-folders create-project-required-folders docker-build-if-not-exist image=${__dev_image} service_name=${__database_entrypoint_service_name} cmd=$${command} ;; \
			makefiles/frontend.Makefile|makefiles/project.Makefile|padam_av/apps/provider/**/*.Makefile) \
				$(MAKE) --stop --no-print-directory --quiet generate-env-file  docker-build-if-not-exist create-project-required-folders image=${__dev_image} service_name=${__dev_service_name} cmd=$${command} ;; \
			makefiles/docs.Makefile) \
				$(MAKE) --stop --no-print-directory --quiet generate-env-file create-docs-required-folders docker-build-if-not-exist image=${__dev_image} service_name=${__dev_service_name} cmd=$${command} ;; \
			makefiles/quality.Makefile) \
				$(MAKE) --stop --no-print-directory --quiet generate-env-file create-docs-required-folders create-quality-required-folders docker-build-if-not-exist image=${__dev_image} service_name=${__dev_service_name} cmd=$${command} ;; \
			makefiles/tests.Makefile) \
				$(MAKE) --stop --no-print-directory --quiet generate-env-file create-tests-required-folders docker-build-if-not-exist image=${__dev_image} service_name=${__dev_service_name} cmd=$${command} ;; \
			*|makefiles/guidelines.Makefile) \
				true ;; \
		esac; \
	done
