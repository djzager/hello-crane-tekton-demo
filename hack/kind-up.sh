#!/usr/bin/env bash

set -ex

kind get clusters | grep -q src || cat <<EOF | kind create cluster --name src --wait 2m --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: 10.110.0.0/16
  serviceSubnet: 10.115.0.0/16
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
echo "src cluster up"

kind get clusters | grep -q dest || cat <<EOF | kind create cluster --name dest --wait 2m --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: 10.220.0.0/16
  serviceSubnet: 10.225.0.0/16
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
echo "dest cluster up"

# Make sure that every node in the destination cluster
# can talk to the src cluster's service subnet
# for node in $(kind get nodes --name dest); do
#   node_ip=$(kubectl --context kind-dest get nodes ${node} -o yaml | yq eval '.status.addresses[] | select(.type == "InternalIP").address' -)
#   docker exec ${node} ip route add 10.115.0.0/16 via ${node_ip}
# done
