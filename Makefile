# SHELL := /usr/bin/env bash
#
# Include shared Makefiles
include project.mk
include standard.mk

DOCKERFILE = ./build/Dockerfile


# Project specific values
IMAGE_REGISTRY?=quay.io
IMAGE_REPOSITORY?=jharrington22
IMAGE_NAME?=iperf-operator

COMMIT_NUMBER=$(shell git rev-list `git rev-list --parents HEAD | egrep "^[a-f0-9]{40}$$"`..HEAD --count)
CURRENT_COMMIT=$(shell git rev-parse --short=8 HEAD)

CONTAINER_VERSION=0.1.$(COMMIT_NUMBER)-$(CURRENT_COMMIT)

IMG?=$(IMAGE_REGISTRY)/$(IMAGE_REPOSITORY)/$(IMAGE_NAME):v$(CONTAINER_VERSION)
IMAGE_URI=${IMG}
IMAGE_URI_LATEST=$(IMAGE_REGISTRY)/$(IMAGE_REPOSITORY)/$(IMAGE_NAME):latest

.PHONY: docker-build
docker-build: build

.PHONY: login
login:
	docker login -u "$$QUAY_BOT_USERNAME" --password "$$QUAY_BOT_PASSWORD" quay.io

.PHONY: deploy
deploy:
	oc adm groups add-users osd-sre-cluster-admins $$(oc whoami)
	oc create namespace iperf-operator
	oc apply -f deploy/cluster_role.yaml
	oc apply -f deploy/cluster_role_binding.yaml
	oc apply -f deploy/service_account.yaml
	oc adm policy add-scc-to-user anyuid -z iperf-operator
	oc apply -f deploy/crds/iperf.managed.openshift.io_iperves_crd.yaml
	oc apply -f deploy/operator.yaml

.PHONY: deprovision
deprovision:
	oc delete -f deploy/cluster_role.yaml
	oc delete -f deploy/cluster_role_binding.yaml
	oc delete -f deploy/service_account.yaml
	oc delete -f deploy/crds/iperf.managed.openshift.io_iperves_crd.yaml
	oc delete -f deploy/operator.yaml
	oc delete namespace iperf-operator
	oc adm policy remove-scc-from-user anyuid -z iperf-operator