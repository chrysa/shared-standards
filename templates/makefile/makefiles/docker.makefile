.PHONY: docker-build docker-up docker-down docker-logs docker-push docker-shell

IMAGE     ?= ghcr.io/chrysa/$(PROJECT)
TAG       ?= local
PLATFORMS ?= linux/amd64,linux/arm64

docker-build: ## Build Docker image (local arch)
	$(DOCKER) build -t $(IMAGE):$(TAG) \
		--label org.opencontainers.image.source=$$(git config --get remote.origin.url) \
		--label org.opencontainers.image.revision=$$(git rev-parse HEAD) \
		--label org.opencontainers.image.created=$$(date -u +%Y-%m-%dT%H:%M:%SZ) \
		.

docker-build-multiarch: ## Build multi-arch (buildx) — requires qemu
	$(DOCKER) buildx build --platform $(PLATFORMS) -t $(IMAGE):$(TAG) --push .

docker-push: ## Push image to registry
	$(DOCKER) push $(IMAGE):$(TAG)

docker-up: ## Bring up docker-compose stack
	$(COMPOSE) up -d

docker-down: ## Stop docker-compose stack
	$(COMPOSE) down

docker-logs: ## Tail logs
	$(COMPOSE) logs -f --tail=100

docker-shell: ## Shell into the app container
	$(COMPOSE) exec app /bin/bash || $(COMPOSE) exec app /bin/sh
