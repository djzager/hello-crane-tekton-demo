#!/usr/bin/env bash

set -ex

cat <<EOF | kubectl apply --namespace ${NAMESPACE} -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: craneconfig
data:
  config: |
    debug: false
    optional-flags:
      strip-default-pull-secrets: "true"
      registry-replacement: "docker-registry.default.svc:5000": "image-registry.openshift-image-registry.svc:5000"
      extra-whiteouts:
      - ImageStream.image.openshift.io
      - ImageStreamTag.image.openshift.io
      - StatefulSet.apps
EOF
