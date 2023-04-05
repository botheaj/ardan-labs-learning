#!/bin/sh
set -o errexit

# create registry container unless it already exists
# reg_name='kind-registry'
# reg_port='5001'
# if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
#   docker run \
#     -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
#     registry:2
# fi

# create a cluster with the local registry enabled in containerd
kind create cluster --config=kubernetes/kind/kind-config.yaml
# -
# kind: Cluster
# apiVersion: kind.x-k8s.io/v1alpha4
# nodes:
# - role: control-plane
#   kubeadmConfigPatches:
#   - |
#     kind: InitConfiguration
#     nodeRegistration:
#       kubeletExtraArgs:
#         node-labels: "ingress-ready=true"
#   extraPortMappings:
#   - containerPort: 80
#     hostPort: 80
#     protocol: TCP
#   - containerPort: 443
#     hostPort: 443
#     protocol: TCP
# containerdConfigPatches:
# - |-
#   [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
#     endpoint = ["http://${reg_name}:5000"]
# EOF

# connect the registry to the cluster network if not already connected
# if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
#   docker network connect "kind" "${reg_name}"
# fi

# # Document the local registry
# # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
# cat <<EOF | kubectl apply -f -
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: local-registry-hosting
#   namespace: kube-public
# data:
#   localRegistryHosting.v1: |
#     host: "localhost:${reg_port}"
#     help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
# EOF

# # kubectl label namespace default istio-injection=enabled
# # kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
# # kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
# # istioctl install --set profile=demo -y

# ### update providers registry 
sed "3 s/kind-kind/$(/opt/homebrew/bin/kubectx | grep kind)/g" infrastructure/providers.tf | tee providers.tf && mv providers.tf infrastructure/providers.tf