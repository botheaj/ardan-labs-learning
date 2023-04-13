.PHONY: import
SHELL := /bin/bash

# Testing running systems
# expvarmon -ports=":4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"

GOLANG       := golang:1.20
ALPINE       := alpine:3.17
KIND         := kindest/node:v1.25.3
POSTGRES     := postgres:15-alpine
VAULT        := hashicorp/vault:1.12
ZIPKIN       := openzipkin/zipkin:2.23
TELEPRESENCE := docker.io/datawire/tel2:2.10.4

dev-docker:
	docker pull $(GOLANG)
	docker pull $(ALPINE)
	docker pull $(KIND)
	docker pull $(POSTGRES)
	docker pull $(VAULT)
	docker pull $(ZIPKIN)
	docker pull $(TELEPRESENCE)

setup:
	brew install tilt
	brew install kind
	brew install kubectl
	brew install kubectx
	brew install kustomize
	brew install k9s
	brew install txn2/tap/kubefwd
	brew install entr
	brew install coreutils	
cluster:
	./scripts/kind-with-registry.sh

run:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go -service=SALES-API

run-help:
	go run app/services/sales-api/main.go --help
# | go run app/tooling/logfmt/main.go

build:
	cd app/services/sales-api  && go build -ldflags "-X main.build=local"

tidy:
	go mod tidy && go mod vendor 

VERSION := 1.0

all: sales-api

sales-api:
	docker build \
	-f infrastructure/docker/Dockerfile.sales-api \
	-t sales-api:$(VERSION) \
	--build-arg BUILD_REF=$(VERSION) \
	--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	.

KIND_CLUSTER := kind

dev-up:
	kind create cluster \
		--image kindest/node:v1.25.3@sha256:f52781bc0d7a19fb6c405c2af83abfeb311f130707a0e219175677e366cc45d1 \
		--name $(KIND_CLUSTER) \
		--config infrastructure/k8s/dev/kind-config.yaml
	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

# kind-up:
# 	./scripts/kind-with-registry.sh $(KIND_CLUSTER)	

dev-down:
	telepresence quit -s
	kind delete cluster --name $(KIND_CLUSTER)

dev-load:
	kind load docker-image sales-api:$(VERSION) --name $(KIND_CLUSTER)

dev-status:
	kubectx kind-kind
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

dev-apply:
	kustomize build infrastructure/k8s/base/sales | kubectl apply -f -
	kustomize build infrastructure/k8s/dev/sales | kubectl apply -f -
	kubectl wait --timeout=120s --namespace=sales-system --for=condition=Available deployment/sales

dev-restart:
	kubectl rollout restart deployment sales --namespace sales-system

dev-logs:
	kubectl logs -l app=sales --all-containers=true -f --tail=100 --namespace sales-system --max-log-requests=6 | go run app/tooling/logfmt/main.go -service=SALES-API

dev-describe:
	kubectl describe nodes
	kubectl describe svc

dev-describe-deployment:
	kubectl describe deployment --namespace=sales-system sales

dev-describe-sales:
	kubectl describe pod --namespace=sales-system -l app=sales

kind-update: all kind-load kind-restart

kind-update-apply: all kind-load kind-apply

kind-argo-install:
	kubectl create ns argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kind-argo-port-forward:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | pbcopy	
	kubectl port-forward -n argocd service/argocd-server 8443:443	

tf-apply:
	cd infrastructure/terraform && terraform apply

dev-update: all dev-load dev-restart

dev-update-apply: all dev-load dev-apply

metrics-view-local-sc:
	expvarmon -ports="localhost:4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"

dev-tel:
	kind load docker-image $(TELEPRESENCE) --name $(KIND_CLUSTER)
	telepresence --context=kind-$(KIND_CLUSTER) helm install
	telepresence --context=kind-$(KIND_CLUSTER) connect