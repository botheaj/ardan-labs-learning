.PHONY: import
SHELL := /bin/bash

# Testing running systems
# expvarmon -ports=":4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"

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
	go run app/services/sales-api/main.go 
# | go run app/tooling/logfmt/main.go

build:
	cd app/services/sales-api  && go build -ldflags "-X main.build=local"

tidy:
	go mod tidy && go mod vendor

VERSION := 1.1

all: sales-api

sales-api:
	docker build \
	-f docker/Dockerfile.sales-api \
	-t sales-api-arm64:$(VERSION) \
	--build-arg BUILD_REF=$(VERSION) \
	--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	.

KIND_CLUSTER := kind

kind-up:
	./scripts/kind-with-registry.sh $(KIND_CLUSTER)	

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)

kind-load:
	cd kubernetes/kind/sales-pod; kustomize edit set image sales-api-image=sales-api-arm64:$(VERSION)
	kind load docker-image sales-api-arm64:$(VERSION) --name $(KIND_CLUSTER)

kind-status:
	kubectx kind-kind
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

kind-apply:
	kustomize build kubernetes/kind/sales-pod | kubectl apply -f -
#	kubectl apply -f kubernetes/base/sales-pod/base-sales.yaml --namespace sales-system

kind-restart:
	kubectl rollout restart deployment sales-pod --namespace sales-system

kind-logs:
	kubectl logs -l app=sales --all-containers=true -f --tail=100 --namespace sales-system | go run app/tooling/logfmt/main.go

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