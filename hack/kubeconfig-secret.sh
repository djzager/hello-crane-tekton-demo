#!/usr/bin/env bash

SRC_CONTEXT="${SOURCE_CONTEXT:-kind-src}"
DEST_CONTEXT="${DEST_CONTEXT:-kind-dest}"

set -x

# Save off kubeconfig
kubectl config view --flatten > kubeconfig

# Use ip from docker for accessing the cluster
ctx="${SRC_CONTEXT}" ip=$(kind get kubeconfig --name src --internal | yq eval '.clusters[0].cluster.server' -) \
	yq eval --inplace -e '(.clusters[] | select(.name == strenv(ctx))).cluster.server |= strenv(ip)' kubeconfig

# Update destination cluster with internal cluster ip
ctx="${DEST_CONTEXT}" \
	yq eval --inplace -e '(.clusters[] | select(.name == strenv(ctx))).cluster.server |= "https://kubernetes.default.svc"' kubeconfig
