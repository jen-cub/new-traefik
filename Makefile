RELEASE := traefik
NAMESPACE := kube-system

CHART_NAME := stable/traefik
CHART_VERSION ?= 1.86.1

DEV_CLUSTER ?= testrc
DEV_PROJECT ?= jendevops1
DEV_ZONE ?= australia-southeast1-c

.DEFAULT_TARGET: status

lint:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

init:
	helm3 repo add center https://repo.chartcenter.io
	helm3 repo update

dev: lint init
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	helm3 upgrade --install --wait $(RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
    -f dev/values.yaml \
		$(CHART_NAME)
	$(MAKE) history

destroy:
	helm3 uninstall $(RELEASE) -n $(NAMESPACE)

history:
	helm3 history $(RELEASE) -n $(NAMESPACE) --max=5
