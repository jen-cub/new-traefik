SHELL := /bin/bash


CHART_VERSION ?= 1.86.1

DEV_CLUSTER ?= testrc
DEV_PROJECT ?= jendevops1
DEV_ZONE ?= australia-southeast1-c


NAMESPACE := kube-system

lint: lint-yaml lint-ci

lint-yaml:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

lint-ci:
	@circleci config validate

clean:
	rm -f credentials.yaml

init-helm:
	helm init
	helm repo update

init-dev: init-helm
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)

init-prod:
	gcloud config set project $(PROD_PROJECT)
	gcloud container clusters get-credentials $(PROD_CLUSTER) --zone $(PROD_ZONE) --project $(PROD_PROJECT)

dev prod: init-helm
ifndef CI
	$(error $@ - Please commit and push, this is intended to be run in a CI environment)
endif
	$(MAKE) -j init-$@
	@helm upgrade --install --force --wait traefik \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		-f env/$@/values.yaml \
		stable/traefik
	$(MAKE) clean

history:
	helm history traefik --max=5
