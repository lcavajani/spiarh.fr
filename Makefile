RUNTIME           := $(shell which docker 2>/dev/null || which podman)
REPO_ROOT         := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DATE              := $(shell date +'%Y%m%d')
GIT_REV           := $(shell git rev-parse HEAD | head -c 12)
EFFECTIVE_VERSION := $(DATE)-$(GIT_REV)

REGISTRY          ?= r.spiarh.fr
DOCSY_IMAGE       := $(REGISTRY)/docsy:latest
FROM_IMAGE        := $(REGISTRY)/nginx:1.18.0-r1
IMAGE             := $(REGISTRY)/hugo-spiarh:$(EFFECTIVE_VERSION)

.PHONY: build-site
build-site:
	@$(RUNTIME) run --rm -v $(REPO_ROOT):/app $(DOCSY_IMAGE) -v

.PHONY: serve
serve:
	@$(RUNTIME) run -ti --name $(EFFECTIVE_VERSION) --rm -p 1313:1313 -v $(REPO_ROOT):$(REPO_ROOT) --workdir $(REPO_ROOT) $(DOCSY_IMAGE) serve --watch --bind 0.0.0.0

.PHONY: serve-daemon
serve-daemon:
	@$(RUNTIME) run --name $(EFFECTIVE_VERSION) -d -p 1313:1313 -v $(REPO_ROOT):$(REPO_ROOT) --workdir $(REPO_ROOT) $(DOCSY_IMAGE) serve --watch --bind 0.0.0.0

.PHONY: stop
stop:
	@$(RUNTIME) stop $(EFFECTIVE_VERSION)
	@$(RUNTIME) rm $(EFFECTIVE_VERSION)

.PHONY: login
login:
	@$(RUNTIME) login --username $(REGISTRY_USERNAME) --password $(REGISTRY_PASSWORD) $(REGISTRY)

.PHONY: build-image
build-image:
	@$(RUNTIME) build --build-arg FROM_IMAGE=$(FROM_IMAGE) -t $(IMAGE) .

.PHONY: push-image
push-image:
	@$(RUNTIME) push $(IMAGE)

.PHONY: run-image
run-image:
	@$(RUNTIME) run -ti --rm -p 8080:8080 $(IMAGE)
