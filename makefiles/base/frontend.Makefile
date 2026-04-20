#!make
run-front: ## Start frontend => [branch_name={branch}]
	$(call log-info,run front on branch ${branch_name})
	$(call run_external_repo,Front,${FRONT_FOLDER},${branch_name}, up)

stop-front: ## Stop frontend
	$(call stop_external_repo,Front,${FRONT_FOLDER})
