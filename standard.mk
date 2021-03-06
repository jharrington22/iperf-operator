# Validate variables in project.mk exist
ifndef QUAY_IMAGE_REGISTRY
$(error QUAY_IMAGE_REGISTRY is not set; check project.mk file)
endif
ifndef DOCKER_IMAGE_REGISTRY
$(error DOCKER_IMAGE_REGISTRY is not set; check project.mk file)
endif
ifndef IMAGE_REPOSITORY
$(error IMAGE_REPOSITORY is not set; check project.mk file)
endif
ifndef IMAGE_NAME
$(error IMAGE_NAME is not set; check project.mk file)
endif
ifndef VERSION_MAJOR
$(error VERSION_MAJOR is not set; check project.mk file)
endif
ifndef VERSION_MINOR
$(error VERSION_MINOR is not set; check project.mk file)
endif

# Generate version and tag information from inputs
COMMIT_NUMBER=$(shell git rev-list `git rev-list --parents HEAD | egrep "^[a-f0-9]{40}$$"`..HEAD --count)
CURRENT_COMMIT=$(shell git rev-parse --short=8 HEAD)
OPERATOR_VERSION=$(VERSION_MAJOR).$(VERSION_MINOR).$(COMMIT_NUMBER)-$(CURRENT_COMMIT)

CONTAINER_ENGINE=$(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)

QUAY_OPERATOR_IMAGE_URI=$(QUAY_IMAGE_REGISTRY)/$(IMAGE_REPOSITORY)/$(IMAGE_NAME):v$(OPERATOR_VERSION)
QUAY_OPERATOR_IMAGE_URI_LATEST=$(QUAY_IMAGE_REGISTRY)/$(IMAGE_REPOSITORY)/$(IMAGE_NAME):latest

DOCKER_OPERATOR_IMAGE_URI=$(DOCKER_IMAGE_REGISTRY)/$(IMAGE_REPOSITORY)/$(IMAGE_NAME):v$(OPERATOR_VERSION)
DOCKER_OPERATOR_IMAGE_URI_LATEST=$(DOCKER_IMAGE_REGISTRY)/$(IMAGE_REPOSITORY)/$(IMAGE_NAME):latest

OPERATOR_DOCKERFILE ?=build/Dockerfile

BINFILE=build/_output/bin/$(OPERATOR_NAME)
MAINPACKAGE=./cmd/manager
GOENV=GOOS=linux GOARCH=amd64 CGO_ENABLED=0
GOFLAGS=-gcflags="all=-trimpath=${GOPATH}" -asmflags="all=-trimpath=${GOPATH}"

TESTTARGETS := $(shell go list -e ./... | egrep -v "/(vendor)/")
# ex, -v
TESTOPTS :=

ALLOW_DIRTY_CHECKOUT?=false

default: gobuild

.PHONY: clean
clean:
	rm -rf ./build/_output

.PHONY: isclean
sclean:
	@(test "$(ALLOW_DIRTY_CHECKOUT)" != "false" || test 0 -eq $$(git status --porcelain | wc -l)) || (echo "Local git checkout is not clean, commit changes and try again." && exit 1)

.PHONY: build
build: isclean envtest
	$(CONTAINER_ENGINE) build . -f $(OPERATOR_DOCKERFILE) -t $(QUAY_OPERATOR_IMAGE_URI)
	$(CONTAINER_ENGINE) tag $(QUAY_OPERATOR_IMAGE_URI) $(QUAY_OPERATOR_IMAGE_URI_LATEST)
	$(CONTAINER_ENGINE) tag $(QUAY_OPERATOR_IMAGE_URI) $(DOCKER_OPERATOR_IMAGE_URI_LATEST)
	$(CONTAINER_ENGINE) tag $(QUAY_OPERATOR_IMAGE_URI) $(DOCKER_OPERATOR_IMAGE_URI)

.PHONY: push
push: quay docker

.PHONY: quay
quay:
	$(CONTAINER_ENGINE) push $(QUAY_OPERATOR_IMAGE_URI)
	$(CONTAINER_ENGINE) push $(QUAY_OPERATOR_IMAGE_URI_LATEST)

.PHONY: docker
docker:
	$(CONTAINER_ENGINE) push $(DOCKER_OPERATOR_IMAGE_URI)
	$(CONTAINER_ENGINE) push $(DOCKER_OPERATOR_IMAGE_URI_LATEST)

.PHONY: gocheck
gocheck: ## Lint code
	gofmt -s -l $(shell go list -f '{{ .Dir }}' ./... ) | grep ".*\.go"; if [ "$$?" = "0" ]; then gofmt -s -d $(shell go list -f '{{ .Dir }}' ./... ); exit 1; fi
	go vet ./cmd/... ./pkg/...

.PHONY: gobuild
gobuild: gocheck gotest ## Build binary
	${GOENV} go build ${GOFLAGS} -o ${BINFILE} ${MAINPACKAGE}

.PHONY: gotest
gotest:
	go test $(TESTOPTS) $(TESTTARGETS)

.PHONY: envtest
envtest:
	@# test that the env target can be evaluated, required by osd-operators-registry
	@eval $$($(MAKE) env --no-print-directory) || (echo 'Unable to evaulate output of `make env`.  This breaks osd-operators-registry.' && exit 1)

.PHONY: test
test: envtest gotest

.PHONY: env
.SILENT: env
env: isclean
	echo OPERATOR_NAME=$(OPERATOR_NAME)
	echo OPERATOR_NAMESPACE=$(OPERATOR_NAMESPACE)
	echo OPERATOR_VERSION=$(OPERATOR_VERSION)
	echo OPERATOR_IMAGE_URI=$(OPERATOR_IMAGE_URI)
