CONTAINER_RUNTIME    ?= podman
CONTAINER_IMAGE_ORG  ?= quay.io/djzager
CONTAINER_IMAGE_NAME ?= crane-runner
CONTAINER_IMAGE_TAG  ?= hello-crane
CONTAINER_IMAGE      ?= $(CONTAINER_IMAGE_ORG)/$(CONTAINER_IMAGE_NAME):$(CONTAINER_IMAGE_TAG)
KIND_CONFIG          ?= kind.config
KUBECTL              ?= $(shell which kubectl)

build-image:
	$(CONTAINER_RUNTIME) build -t $(CONTAINER_IMAGE) -f Dockerfile .

kind-up: create-src-kind

kind-up-src:
	kind get clusters | grep -q src || kind create cluster --name src --config=$(KIND_CONFIG) --wait 2m
	#  https://kind.sigs.k8s.io/docs/user/ingress/#ingress-nginx
	$(KUBECTL) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	sleep 5
	$(KUBECTL) wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

kind-up-dest:
	kind create cluster --name dest --wait 2m

kind-down:
	kind delete cluster --name src
	kind delete cluster --name dest

nginx-kind:
	$(KUBECTL) config use-context kind-src
	$(KUBECTL) apply -f nginx.yaml
	$(KUBECTL) wait --namespace nginx-example --for=condition=ready pod --selector=app=nginx --timeout=90s

install-tekton:
	$(KUBECTL) config use-context kind-src
	$(KUBECTL) apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.notags.yaml
	$(KUBECTL) wait --namespace tekton-pipelines --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
