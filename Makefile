.PHONY: import
SHELL := /bin/bash

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
	cd service
	go run service/main.go

build:
	cd service && go build -ldflags "-X main.build=local"

tidy:
	go mod tidy
	go mod vendor

VERSION := 1.0

all: build-docker

build-docker:
	docker build \
	-f docker/Dockerfile \
	-t service-arm64:$(VERSION) \
	--build-arg BUILD_REF=$(VERSION) \
	--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	.

KIND_CLUSTER := kind

kind-up:
	./scripts/kind-with-registry.sh $(KIND_CLUSTER)	

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)

kind-load:
	kind load docker-image service-arm64:$(VERSION) --name $(KIND_CLUSTER)

kind-status:
	kubectx kind-kind
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

kind-apply:
	kustomize build kubernetes/kind/service-pod | kubectl apply -f -
#	kubectl apply -f kubernetes/base/service-pod/base-service.yaml --namespace service-system

kind-restart:
	kubectl rollout restart deployment service-pod --namespace service-system

kind-logs:
	kubectl logs -l app=service --all-containers=true -f --tail=100 --namespace service-system

kind-update: all kind-load kind-restart

kind-update-apply: all kind-load kind-apply

kind-argo-install:
	kubectl create ns argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kind-argo-port-forward:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | pbcopy	
	kubectl port-forward -n argocd service/argocd-server 8443:443	

