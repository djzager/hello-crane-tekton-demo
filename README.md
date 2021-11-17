hello-crane-tekton-demo
=======================

This is a demonstration of a basic use-case with Crane 2, previously
demonstrated in
[hello-crane-demon](https://github.com/eriknelson/hello-crane-demo),
using [Pipelines](https://tekton.dev/docs/getting-started/pipelines/).


# Useful Links

* [Crane 2 Preview: Introduction (video)](https://www.youtube.com/watch?v=esIZS7PVrvs)
* [Tekton - Kubernetes Cloud-Native CI/CD Pipelines and Workflows (video)](https://www.youtube.com/watch?v=7mvrpxz_BfE)
* [Kind Networking](https://gist.github.com/aojea/00bca6390f5f67c0a30db6acacf3ea91#file-kind_networking-md)
    It's not actually needed for this particular demonstration, but I found it
    when trying to make pods in destination cluster talk to the source cluster's
    API server and it was helpful regardless. Interestingly, there is a `kind get
    kubeconfig --name src --internal` that will return the internal kubeconfig.
    We leverage that in [kubeconfig-secret.sh](./hack/kubeconfig-secret.sh) to
    prepare the kubeconfig for our pipeline runs.

# Getting Started w/ Tekton

* https://tekton.dev/docs/getting-started/ will walk you through getting Tekton
    running in the cluster and executing your first
    [workflow with Tekton](https://tekton.dev/docs/getting-started/#your-first-ci-cd-workflow-with-tekton).
* https://tekton.dev/docs/getting-started/pipelines/ expands on Tasks and shows
    you how to start building and running pipelines.

# Getting started with this demonstration

You should really check out [@eriknelson's
hello-crane-demo](https://github.com/eriknelson/hello-crane-demo) that I'll be
stealing a lot of content from for this demo.

Crane exists as two primary repos at the moment:

https://github.com/konveyor/crane - The cli tool, effectively a wrapper exposing the reusable logic found in crane-lib
https://github.com/konveyor/crane-lib - Resuable library housing the core crane logic

What we are demonstrating in this repository, is the ability to create a
collection of Tekton ClusterTasks that can be used as
building blocks for migrations using Tekton Pipelines. While some ClusterTasks
would be required in a Pipeline (ie.
[crane-export](002_crane-export.clustertask.yaml)), others may be optional (for
example, [oc-import](002_oc-import.clustertask.yaml) could potentially be
replaced in a Pipeline with ClusterTask(s) that leverage kustomize, git, or
Argo.

# The Demo

## Pre-Requisites

* Install [yq](https://github.com/mikefarah/yq/#install). This is needed for
    grabbing/modifying important values in yaml.
* Install [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).
* A container runtime (`podman` or `docker`). `export CONTAINER_RUNTIME=${MY_CONTAINER_RUNTIME}`.
* Set your container image org. `export CONTAINER_IMAGE_ORG=quay.io/${username}`.

## Setup

While I'm mucking about, the best documentation will be the
[Makefile](Makefile).
