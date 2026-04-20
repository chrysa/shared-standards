#!make

docker-build: ## Build services => [service_name="{service_name}"]
	$(call log-info,docker build ${service_name})
	@${__docker_compose_project_base_command} build --pull --no-cache --compress --force-rm ${service_name}

docker-build-if-not-exist: check-defined-image check-defined-service_name ## Check and build if image doesn't exist
	$(call log-info,check if service ${service_name} image exist)
	@if [ -z "$(shell docker images -q --filter "reference=${image}")" ]; then \
		echo "${image} is missing waiting for building ..."; \
		$(MAKE) --stop --no-print-directory docker-build service_name=${service_name}; \
	else \
		echo "${image} founded"; \
	fi

docker-config: ## Display Docker Compose configuration => [profile={profile}] [service_name={service}]
	$(call log-info,docker config)
	@${__docker_compose_project_base_command} $(shell if [ ! -z "${profile}"]; then echo "--profile ${profile}"; fi) config ${service_name}

docker-down: ## Stop all services and clean up resources
	$(call log-info,docker down)
	@${__docker_compose_project_base_command} down
	@$(MAKE) --stop --no-print-directory stop-backoffice
	@$(MAKE) --stop --no-print-directory stop-front

docker-get-service-health: check-defined-service_name ## Get service health status => [service_name={service}]
	$(call log-info,get ${service_name} health)
	@docker inspect --format "{{json .State.Health }}" ${service_name} | jq

docker-images: ## List Docker images => [service_name={service}]
	@${__docker_compose_project_base_command} images ${service_name}

docker-logs: check-defined-service_name ## Display service logs => [service_name={service_name}]
	$(call log-info,logs ${service_name})
	@${__docker_compose_project_base_command} logs --timestamps ${service_name}

docker-logs-f: check-defined-service_name ## Display logs in real-time => [service_name={service_name}]
	$(call log-info,logs with follow ${service_name})
	@${__docker_compose_project_base_command} logs --timestamps --follow ${service_name}

docker-login-docker-hub:
	$(call log-info,login to docker hub)
	@docker login

docker-login-harbor:
	$(call log-info,connect to harbor.tech.padam.io with SSO, go to profil and generate a token as password)
	@docker login harbor.tech.padam.io

docker-login: docker-login-docker-hub docker-login-harbor

docker-prune: docker-stop ## Remove all Docker resources associated with project
	$(call log-info,docker prune)
	@rm -rf docker/entrypoints/bootstraped
	@${__docker_compose_project_base_command} down --volumes --rmi all
	@docker network prune -f
	@docker volume prune -f

docker-ps: ## List all containers
	$(call log-info,docker ps)
	@${__docker_compose_project_base_command} ps --all

docker-rebuild-service: check-defined-service_name ## Rebuild specific service => [service_name={service}]
	$(call log-info,rebuild-service ${service_name})
	@${__docker_compose_project_base_command} rm --stop --force --volumes ${service_name}
	@$(MAKE) --stop --no-print-directory docker-build service_name=${service_name}

docker-remove: ## Remove specific container => [service_name={service}]
	$(call log-info,remove ${service_name})
	@${__docker_compose_project_base_command} rm --force --stop --volumes ${service_name}

docker-restart-service: check-defined-service_name ## Restart specific service => [service_name={service}]
	$(call log-info,restart ${service_name})
	@${__docker_compose_project_base_command} restart ${service_name}

docker-run: ## Run service => [service_name={service_name}]
	$(call log-info,docker run ${service_name})
	@${__docker_compose_project_base_command} run ${DOCKER_RUN_ARGS} ${service_name}

docker-run-detach: ## Start services in background => [service_name={service_name}]
	$(call log-info,docker run detach ${service_name})
	@${__docker_compose_project_base_command} run --detach ${service_name}

docker-stop: ## Stop Docker services => [service_name={service}]
	$(call log-info,docker stop)
	@${__docker_compose_project_base_command} stop ${service_name}

docker-up: ## Start services => [service_name="{service_name}"] [profile={profile}]
	$(call log-info,up ${service_name})
	@${__docker_compose_project_base_command} $(shell if [ ! -z "${profile}" ]; then echo "--profile ${profile}"; else echo "--profile dev"; fi) up --wait --no-log-prefix ${service_name}

docker-up-detach: ## Start services in background => [service_name={service_name}] [profile={profile}]
	$(call log-info,up detach ${service_name})
	@${__docker_compose_project_base_command} $(shell if [ ! -z "${profile}" ]; then echo "--profile ${profile}"; else echo "--profile dev"; fi) up --detach ${service_name}

docker-viz: ## Visualize Docker Compose configuration
	@${__docker_compose_project_base_command} config | docker run --rm -i pmsipilot/docker-compose-viz render -m image --output-file=/tmp/docker.png --force && xdg-open /tmp/docker.png
