#!make

tests: ## Run tests => [target_test={target_test}] [markers="{marker_list}"]
	$(call log-info,tests ${target_test} ${markers})
	@$(call run_test,$(shell if [ ! -z "${target_test}" ]; then echo "${target_test}"; fi) $(shell if [ ! -z "${markers}" ]; then echo "--markers \`echo ${markers} | sed -E 's/,//g'\`"; fi))

tests-debug: ## Run tests with pdb on fail => [target_test={target_test}]
	$(call log-info,tests pdb)
	@$(call run_test,${target_test} -- --pdb)

tests-extra-command: ## Run test with custom pytest options => [target_test={target_test}] [command={extra_parameter_list}]
	@$(call run_test,${target_test} -- ${command})

tests-failfast: ## Run tests and stop on first fail => [target_test={target_test}] [markers="{marker_list}"]
	$(call log-info,tests failfast ${markers})
	@$(call run_test,--failfast ${target_test} $(shell if [ ! -z "${target_test}" ]; then echo "${target_test}"; fi) $(shell if [ ! -z "${markers}" ]; then echo "--markers \`echo ${markers} | sed -E 's/,/ /g'\`"; fi) -- --failed-first  --pytest-durations=0 -p no:warnings --tb=long --showlocals)

tests-failfast-html-reports: ## Run tests with failfast and generate HTML reports => [target_test={target_test}]
	$(call log-info,tests fail continue first error and generate html reports)
	@$(call run_test_with_reports,--failfast ${target_test})

tests-help: ## Display all test commands
	@$(call run_test,--verbosity 0 --help)

tests-last-failed: ## Run last failed tests first
	$(call log-info,tests last failed)
	@$(call run_test,--failfast -- --last-failed --failed-first ${target_test})

tests-marker-list: ## List pytest markers
	$(call log-info,list markers)
	@$(call run_test,-- --markers)

tests-parallel: ## Run tests in parallel => [target_test={target_test}] [workers={number}]
	$(call log-info,tests parallel with ${workers} workers)
	@$(call run_test,$(shell if [ ! -z "${target_test}" ]; then echo "${target_test}"; fi) --parallel=$(shell if [ -z "${workers}" ]; then echo "auto"; else echo "${workers}"; fi))

tests-reports: ## Generate test coverage reports
	$(call log-info,generate test coverage reports)
	@$(call run_test_with_reports,${target_test})
