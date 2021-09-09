.PHONY: help build dev

# Docker image name and tag
IMAGE:=kobel/mathematics-notebook
TAG?=latest
# Shell that make should use
SHELL:=bash
# Can export DOCKER=podman in parent environment
DOCKER:=docker

help:
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@grep -E '^[a-zA-Z0-9_%/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: DARGS?=
build: ## Make the latest build of the image
	DOCKER_BUILDKIT=1 $(DOCKER) build $(DARGS) --rm=false -t $(IMAGE):$(TAG) .
deploy: DARGS?=
deploy: ## Make the latest build of the image
	$(DOCKER) build $(DARGS) --rm --force-rm -t $(IMAGE):$(TAG) .

dev: ARGS?=
dev: DARGS?=
dev: PORT?=8888
dev: ## Make a container from a tagged image image
	$(DOCKER) run -it --rm -p $(PORT):8888 $(DARGS) $(REPO) $(ARGS)

.PHONY: up
up: ## Launch JupyterLab with token=x
	$(DOCKER) run --rm -p 8888:8888 --name kobel_mathematics_notebook $(IMAGE):$(TAG) jupyter lab --LabApp.token=''

.PHONY: build-fast
build-fast: DARGS?=
build-fast: ## Make the latest build of the image. `stack build --fast` (-O0) so that the build doesn't exceed the 50 minute Travis timeout.
	$(DOCKER) build --build-arg STACK_ARGS=--fast $(DARGS) --rm --force-rm -t $(IMAGE):$(TAG) .

