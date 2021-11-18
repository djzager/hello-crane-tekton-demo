CONTAINER_RUNTIME    ?= docker
CONTAINER_IMAGE_ORG  ?= quay.io/djzager
CONTAINER_IMAGE_NAME ?= crane-runner
CONTAINER_IMAGE_TAG  ?= hello-crane
CONTAINER_IMAGE      ?= $(CONTAINER_IMAGE_ORG)/$(CONTAINER_IMAGE_NAME):$(CONTAINER_IMAGE_TAG)
KUBECTL              ?= $(shell which kubectl)
NAMESPACE            ?= hello-crane
SRC_CONTEXT          ?= kind-src
DEST_CONTEXT         ?= kind-dest
KUBECONFIG           ?= $(HOME)/.kube/config

build-image: ## Build the crane-runner container image
	$(CONTAINER_RUNTIME) build -t $(CONTAINER_IMAGE) -f Dockerfile .

push-image: ## Push the crane-runner container image
	$(CONTAINER_RUNTIME) push $(CONTAINER_IMAGE)

build-push-image: build-image push-image ## Build and push crane-runner container image

# If we need special configuration of kind cluster
# ./hack/kind-up.sh
kind-up: ## Bring up kind src and dest clusters
	kind get clusters | grep -q src  || kind create cluster --name src --wait 2m
	kind get clusters | grep -q dest || kind create cluster --name dest --wait 2m

kind-down: ## Take kind clusters down
	kind delete cluster --name src
	kind delete cluster --name dest

kind-load: ## Update the crane-runner image in kind cluster
	kind load docker-image --name dest $(CONTAINER_IMAGE)

guestbook: ## Install sample workload (guestbook) in source cluster
	$(KUBECTL) --context $(SRC_CONTEXT) create namespace guestbook || true
	$(KUBECTL) --context $(SRC_CONTEXT) --namespace guestbook apply -f guestbook-all-in-one.yaml
	$(KUBECTL) --context $(SRC_CONTEXT) --namespace guestbook wait --for=condition=ready pod --selector=app=guestbook --timeout=180s

demo-namespace: ## Create the demo namespace in the destination cluster
	$(KUBECTL) --context $(DEST_CONTEXT) create namespace $(NAMESPACE) || true

kubeconfig: demo-namespace ## Upload kubeconfig as secret, this is only useful for kind
	$(KUBECTL) --context $(DEST_CONTEXT) --namespace $(NAMESPACE) delete secret kubeconfig || true
	SRC_CONTEXT=$(SRC_CONTEXT) DEST_CONTEXT=$(DEST_CONTEXT) \
		./hack/kubeconfig-secret.sh
	$(KUBECTL) --context $(DEST_CONTEXT) --namespace $(NAMESPACE) create secret generic kubeconfig --from-file=config=kubeconfig

craneconfig: demo-namespace ## Uploade configmap holding the crane configuration
	NAMESPACE=$(NAMESPACE) ./hack/craneconfig.sh

tekton: ## Install tekton in destination cluster
	$(KUBECTL) --context $(DEST_CONTEXT) apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.notags.yaml
	$(KUBECTL) --context $(DEST_CONTEXT) --namespace tekton-pipelines wait --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

clustertasks: ## Install tekton ClusterTasks in the destination cluster
	$(KUBECTL) --context $(DEST_CONTEXT) apply -f clustertasks/

pipelinerun-basic: demo-namespace clustertasks ## Run basic tekton PipelineRun that does export, transform, apply, and oc apply to import into destination cluster
	$(KUBECTL) --context $(DEST_CONTEXT) --namespace $(NAMESPACE) create -f pipelineruns/001_basic.yaml

help: ## Show this help screen
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ''

.PHONY: build-image push-image build-push-image kind-up kind-down nginx demo-namespace upload-kubeconfig tekton clustertasks pipelinerun-basic help
