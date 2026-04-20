#!make

actionlint: ## Run actionlint on GitHub Actions workflows
	$(call log-info,run actionlint)
	@$(MAKE) --stop --no-print-directory run-pre-commit-step step=actionlint files=${files}

call-graphs: ## Generate call graphs for commands
	@COMMANDS="runserver automata run_data run_easy_mile_websocket_client run_mobile_thinking_mqtt_client \
		run_navya_websocket_client run_ohmio_websocket_server rqscheduler rqworker run_core_logic_worker \
		run_websocket_server"; \
	ARGS=""; \
	for cmd in $$COMMANDS; do \
		ARGS="$$ARGS -n $$cmd"; \
	done; \
	${__run_quality_cmd} bash -c "python /scripts/dev_call_graph.py command -f $$ARGS"

css: ## Lint CSS files
	$(call log-info,run csslint)
	@$(MAKE) --stop --no-print-directory run-pre-commit-step step=csslint files=${files}

django-upgrade: ## Run django-upgrade
	$(call log-info,run django-upgrade)
	@$(MAKE) --stop --no-print-directory run-pre-commit-step step=django-upgrade files=${files}

format-code: update-pre-commit-repos ## Format code with all formatters
	$(call log-info,format code)
	@git pull --rebase --autostash
	@$(MAKE) --stop --no-print-directory --quiet actionlint || true
	@$(MAKE) --stop --no-print-directory --quiet setup-cfg-fmt || true
	@$(MAKE) --stop --no-print-directory --quiet format-dockerfiles || true
	@$(MAKE) --stop --no-print-directory --quiet yaml-sorter || true
	@$(MAKE) --stop --no-print-directory --quiet css || true
	@$(MAKE) --stop --no-print-directory --quiet django-upgrade files=${files} || true
	@$(MAKE) --stop --no-print-directory --quiet mypy files=${files} || true
	@$(MAKE) --stop --no-print-directory --quiet ruff-format files=${files} || true
	@$(MAKE) --stop --no-print-directory --quiet ruff-check files=${files} || true
	@$(MAKE) --stop --no-print-directory --quiet interrogate || true
	@$(MAKE) --stop --no-print-directory --quiet tests-reports target_tests=${files}

format-dockerfiles: ## Format Dockerfiles
	$(call log-info,format Dockerfiles)
	@$(MAKE) --stop --no-print-directory run-pre-commit-step step=format-dockerfiles files=${files}

# graphs: call-graphs database-schema migrations-schema docker-viz ## Generate all graphs
graphs: database-schema migrations-schema docker-viz ## Generate all graphs

hadolint: check-defined-dockerfile_name ## Run hadolint on a Dockerfile => [dockerfile_name={name}]
	$(call log-info,run hadolint on ${dockerfile_name}.Dockerfile)
	@docker run --rm -i -v ${PWD}/.config/.hadolint.yaml:/bin/hadolint.yaml -e XDG_CONFIG_HOME=/bin hadolint/hadolint < docker/dockerfiles/${dockerfile_name}.Dockerfile
	@docker run --rm -i -v ${PWD}/.config/.hadolint.yaml:/bin/hadolint.yaml -e XDG_CONFIG_HOME=/bin -e HADOLINT_FORMAT=json hadolint/hadolint < docker/dockerfiles/${dockerfile_name}.Dockerfile > reports/hadolint/${dockerfile_name}.json

interrogate: ## Run interrogate docstring coverage checker
	$(call log-info,run interrogate)
	@$(MAKE) --stop --no-print-directory run-pre-commit-step step=interrogate

mypy: ## Run mypy type checker
	$(call log-info,run mypy)
	$(call run_quality,bash -c "MYPY_PATH=padam_av mypy --pretty --install-types --config-file=setup.cfg --html-report=/reports/mypy-html/ --junit-xml=/reports/mypy.xml $(shell if [ -z ${files} ]; then echo '.'; else echo ${files}; fi)")

ruff-check: ## Run ruff linter with auto-fix
	$(call log-info,run ruff)
	$(call run_quality,bash -c "ruff check --fix --unsafe-fixes --config=pyproject.toml --output-format=full $(shell if [ -z ${files} ]; then echo '.'; else echo ${files}; fi)")

ruff-format: ## Run ruff code formatter
	$(call log-info,run ruff format)
	$(call run_quality,bash -c "ruff format --config=pyproject.toml $(shell if [ -z ${files} ]; then echo '.'; else echo ${files}; fi)")

run-pre-commit-step: check-defined-step ## Run specific pre-commit step => [step=*step id*]
	$(call log-info,run pre-commit ${step})
	@$(PRE_COMMIT_CMD) run ${step} $(shell if [ ! -z "${files}" ]; then echo --files ${files}; else echo "--all-files" ; fi)

setup-cfg-fmt: ## Format setup.cfg
	$(call log-info,format setup.cfg)
	@$(MAKE) --stop --no-print-directory run-pre-commit-step step=setup-cfg-fmt files=${files}

update-pre-commit-repos: ## Update pre-commit hooks
	$(call log-info,update pre-commit hooks)
	@$(PRE_COMMIT_CMD) autoupdate --bleeding-edge

yaml-sorter: ## Run yaml-sorter
	$(call log-info,run yaml-sorter)
	@$(MAKE) --stop --no-print-directory run-pre-commit-step step=yaml-sorter files=${files}
