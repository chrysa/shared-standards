#!make

check-docs-conf: ## Check Sphinx configuration
	$(call log-info,check if sphinx is configured)
	@if [ ! -f docs/sphinx/source/conf.py ]; then \
		${__run_cmd_no_deps} ${__docs_service_name} bash -c "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && sphinx-quickstart -q -p 'Padam Av' -a 'Av-team' --sep -v '${PADAM_AV_APP_VERSION}' /docs/sphinx ; python /scripts/generate_sphinx_config.py"; \
	fi

docs: check-docs-conf ## Generate Sphinx documentation
	$(call log-info,run sphinx build)
	@${__run_cmd_no_deps} --entrypoint "bash" ${__docs_service_name} -c "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && sphinx-apidoc -o /docs/sphinx/source /code && sphinx-multiversion /docs/sphinx/source /docs/sphinx/build/html"
