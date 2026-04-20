#!make
check-directory-exists = @if [ ! -d "$(1)" ]; then $(call log-error,"Directory $(1) does not exist"); exit 1; fi

check-file-exists = @if [ ! -f "$(1)" ]; then $(call log-error,"File $(1) does not exist"); exit 1; fi

docker-container-exists = $(shell docker ps -a -q --filter "name=$(1)")

docker-image-exists = $(shell docker images -q --filter "reference=$(1)")

log-error = @echo "Error: $(1)" >&2

log-info = @echo "Make: $(1)"

log-success = @echo "Success: $(1)"

__check_defined = $(if $(value $1),,$(error Undefined $1$(if $2, ($2))$(if $(value @),required by target $@)))

define check_defined
	@$(strip $(foreach 1,$1,$(call __check_defined,$1,$(strip $(value 2)))))
endef

define check_file_exists
	@$(if $(wildcard $(1)),,$(error File $(1) does not exist))
endef

define check_required_vars
	@$(foreach var,$(1),$(if $($(var)),,$(error Variable $(var) is required)))
endef

define check_service_exists
	@$(if $(filter $(1),$(SERVICES)),,$(error Service $(1) does not exist. Available services: $(SERVICES)))
endef

define docker_build
	@${DOCKER_COMPOSE_CMD} build $(DOCKER_BUILD_ARGS) $(1)
endef

define docker_down
	@${DOCKER_COMPOSE_CMD} down $(1)
endef

define docker_exec
	@${DOCKER_COMPOSE_CMD} exec $(1)
endef

define docker_run
	@${DOCKER_COMPOSE_CMD} run ${DOCKER_RUN_ARGS} $(DOCKER_RUN_ARGS_EXTRA) $(1)
endef

define docker_up
	@${DOCKER_COMPOSE_CMD} --profile $(1) up $(2)
endef

define generate_html_report
	@mkdir -p ${OUTDATED_REPORTS_DIR}/$(1)
	$(call run_docker,$(1),"pip install pip-audit pip-html >/dev/null 2>&1 || true && ${OUTDATED_JSON_CMD} | pip-html > /reports/pip-outdated/$(1)/outdated.html") || echo "Error: Service $(1) unavailable or command failed"
	@if [ -f ${OUTDATED_REPORTS_DIR}/$(1)/outdated.html ]; then \
		echo "HTML report generated in ${OUTDATED_REPORTS_DIR}/$(1)/outdated.html"; \
	fi
endef

define generate_json_report
	@mkdir -p ${OUTDATED_REPORTS_DIR}/$(1)
	$(call run_docker,$(1),"${OUTDATED_JSON_CMD} > /reports/pip-outdated/$(1)/outdated.json") || echo "Error: Service $(1) unavailable or command failed"
	@if [ -f ${OUTDATED_REPORTS_DIR}/$(1)/outdated.json ]; then \
		echo "JSON report generated in ${OUTDATED_REPORTS_DIR}/$(1)/outdated.json"; \
		echo "Summary of outdated packages:"; \
		if [ -s ${OUTDATED_REPORTS_DIR}/$(1)/outdated.json ]; then \
			cat ${OUTDATED_REPORTS_DIR}/$(1)/outdated.json | grep -E '"name"|"version"|"latest_version"' | \
			sed 's/"name": "/Package: /g' | \
			sed 's/"version": "/Current version: /g' | \
			sed 's/"latest_version": "/Latest version: /g' | \
			sed 's/",//g' | sed 's/"//g' | \
			paste -d " " - - - | sort; \
		else \
			echo "No outdated packages"; \
		fi; \
	fi
endef

define log_external_repo
	@docker compose -f "$(2)/docker-compose.yml" logs --follow $(1)
endef

define run_db_command
	@${__run_cmd} --name AV-database-$(1) --entrypoint='python' --env DJANGO_LOG_LEVEL=ERROR ${__database_entrypoint_service_name} manage.py $(2)
endef

define run_django_command
	@${__run_cmd} --name AV-$(1) --entrypoint='python' --env DJANGO_LOG_LEVEL=$(if $(2),$(2),ERROR) $(if $(3),$(3),${__database_entrypoint_service_name}) manage.py $(4)
endef

define run_docker
	${DOCKER_COMPOSE_CMD} run ${DOCKER_RUN_COMMON_ARGS} $(1) -c "$(2)"
endef

define run_outdated_check
	@service_name=$(if $(1),$(1),${__dev_service_name}); \
	cmd=$(if $(2),$(2),${OUTDATED_CMD}); \
	$(call run_docker,$$service_name,$$cmd) || echo "Service $$service_name is not available. You may need to start it first."
endef

define run_external_repo
	@echo "Running $(1) on branch: $(shell if [ -z "$(3)" ]; then echo "develop"; else echo "$(3)"; fi)" ; \
	if [ -d "$(2)" ] ; then \
		echo "Update $(1) repo" ; \
		git -C "$(2)" checkout $(shell if [ -z "$(3)" ]; then echo "develop"; else echo "$(3)"; fi) ; \
		git -C "$(2)" add . ; \
		git -C "$(2)" pull --autostash --rebase ; \
		echo "Start $(1)" ; \
		$(MAKE) -C $(2) --stop --no-print-directory $(shell echo $(4)); \
	else \
		echo "The '$(2)' folder does not exist"; \
		exit 1; \
	fi
endef

define run_quality
	@${__run_quality_cmd} $(1)
endef

define run_test
	@${__docker_compose_project_base_command} --profile tests up -d database redis
	@${__run_test_cmd} $(1)
endef

define run_test_with_coverage
	@${__docker_compose_project_base_command} --profile tests up -d database redis
	@${__run_test_cmd} --coverage-html --coverage-xml $(1)
endef

define run_test_with_reports
	@mkdir -p ${tests_required_files_and_folder}
	@${__docker_compose_project_base_command} --profile tests up -d database redis
	@${__run_test_cmd} --coverage-html --coverage-xml --tests-html --tests-xml $(1)
endef

define stop_external_repo
	@echo 'Stopping $(1) ...'
	@if [ ! -z "$(shell docker compose -f "$(2)/docker-compose.yml" ps --quiet --filter status=running $(1))" ]; then \
		$(MAKE) -C $(2) down ; \
	fi
endef
