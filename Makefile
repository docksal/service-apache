# Load test variables
-include tests/env_make

# Allow using a different docker binary
DOCKER ?= docker

# Force BuildKit mode for builds
# See https://docs.docker.com/buildx/working-with-buildx/
DOCKER_BUILDKIT=1

IMAGE ?= docksal/apache
VERSION ?= 2.4
UPSTREAM_IMAGE ?= httpd:2.4.52-alpine
BUILD_IMAGE_TAG ?= $(IMAGE):$(VERSION)-build
NAME = docksal-apache-$(VERSION)

# Make it possible to pass arguments to Makefile from command line
# https://stackoverflow.com/a/6273809/1826109
ARGS = $(filter-out $@,$(MAKECMDGOALS))

.EXPORT_ALL_VARIABLES:

.PHONY: build test push shell run start stop logs clean

default: build

build:
	$(DOCKER) build -t $(BUILD_IMAGE_TAG) --build-arg UPSTREAM_IMAGE=$(UPSTREAM_IMAGE) --build-arg VERSION=$(VERSION) .

test:
	IMAGE=$(BUILD_IMAGE_TAG) NAME=$(NAME) VERSION=$(VERSION) ./tests/test.bats

push:
	$(DOCKER) push $(BUILD_IMAGE_TAG)

shell: clean
	$(DOCKER) run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG) /bin/bash

run: clean
	$(DOCKER) run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG)

start: clean
	$(DOCKER) run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG)

stop:
	$(DOCKER) stop $(NAME)

logs:
	$(DOCKER) logs $(NAME)

logs-follow:
	$(DOCKER) logs -f $(NAME)

debug: build start logs-follow

clean:
	$(DOCKER) rm -vf $(NAME) || true

# Make it possible to pass arguments to Makefile from command line
# https://stackoverflow.com/a/6273809/1826109
%:
	@:
