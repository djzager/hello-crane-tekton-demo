#!/usr/bin/env bash

SRC_CONTEXT="${SOURCE_CONTEXT:-kind-src}"
DEST_CONTEXT="${DEST_CONTEXT:-kind-dest}"

set -x

# Save off kubeconfig
kubectl config view --flatten > kubeconfig

# Use kind to get the internal kubeconfig for accessing the source cluster's apiserver
# and use that to replace our https://127.0.0.1:... address for the source cluster.
ctx="${SRC_CONTEXT}" ip=$(kind get kubeconfig --name src --internal | yq eval '.clusters[0].cluster.server' -) \
	yq eval --inplace -e '(.clusters[] | select(.name == strenv(ctx))).cluster.server |= strenv(ip)' kubeconfig

# Update destination cluster with internal cluster hostname
# https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/
ctx="${DEST_CONTEXT}" \
	yq eval --inplace -e '(.clusters[] | select(.name == strenv(ctx))).cluster.server |= "https://kubernetes.default.svc"' kubeconfig
