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
building blocks for migrations using Tekton Pipelines.

# The Demo

## Pre-Requisites

* Install [yq](https://github.com/mikefarah/yq/#install). This is needed for
    grabbing/modifying important values in yaml.
* Install [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).
* A container runtime (`podman` or `docker`). `export CONTAINER_RUNTIME=${MY_CONTAINER_RUNTIME}`.
* Set your container image org. `export CONTAINER_IMAGE_ORG=quay.io/${username}`.

## Setup

1. Bring up two clusters using kind with `make kind-up`. This will give you two
   clusters `src` and `dest` accessible via the `kind-src` and `kind-dest` kube
   contexts.
1. Install the guestbook application using `make guestbook`. If you've ever done
   the
   [k8s example applications](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
   this will look familiar.
1. Create the namespace where the guestbook will be migrated to. You can:
   run `make demo-namespace` that will create a `hello-crane` namespace in the
   `kind-dest` cluster, customize the namespace with `NAMESPACE=my-namespace
   make demo-namespace` (just remember to pass this to future steps), or create
   namespace by hand (just remember to use the `kind-dest` context).
1. Now that we have our demo-namespace, we'll load our kubernetes config as a
   secret using `make kubeconfig`. Take a look at
   [hack/kubeconfig-secret.sh](hack/kubeconfig-secret.sh) to see what we are
   doing to prepare for running in cluster. If you are attempting this without
   kind, it is important that pods in the destination cluster have network
   connectivity to the source cluster and you will likely need to update the
   kubeconfig for the destination cluster's context to use
   `https://kubernetes.default.svc`. More info in the k8s docs for
   [accessing API from pod](https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/).
1. Upload our crane configuration file using `make craneconfig`.
1. Install Tekton with `make tekton`.


## The Fun Stuff

For this demonstration we are leveraging
[Tekton's ClusterTasks](https://tekton.dev/docs/pipelines/tasks/#task-vs-clustertask)
primarily because these tasks are at the cluster scope and can be accessed from
Pipelines we run in individual namespaces to carry out the migration.

All of the ClusterTasks in can be found in [clustertasks](./clustertasks) and
are ordered similarly to how they are included in the PipelineRun (more on that
later. I did my best to add inline comments so you should definitely check them
out to get more understanding on what they actually do.

Install the ClusterTasks with `make clustertasks`.

## Do It

Now that we are all setup, we have:

1. An application we want to migrate, the guestbook, in the source cluster.
1. A place to migrate the application to, the destination cluster + namespace.
1. We have Tekton installed and all of our ClusterTasks are ready for use in
   [TaskRuns](https://tekton.dev/docs/pipelines/taskruns/),
   [Pipelines](https://tekton.dev/docs/pipelines/pipelines/),
   and [PipelineRuns](https://tekton.dev/docs/pipelines/pipelinesruns/).
1. Our crane configuration and kubeconfig files are uploaded.

Time to instantiate our basic [PipelineRun](pipelineruns/001_basic.yaml) and see what happens.

If all is successfull your `hello-crane` namespace should look something like:

```
NAME                                              READY   STATUS      RESTARTS   AGE
pod/frontend-5fd859dcf6-54v6t                     1/1     Running     0          6m6s
pod/frontend-5fd859dcf6-c6mf6                     1/1     Running     0          6m6s
pod/frontend-5fd859dcf6-nqjx4                     1/1     Running     0          6m6s
pod/hello-crane-tekton-demo-k25kl-apply-pod       0/1     Completed   0          6m18s
pod/hello-crane-tekton-demo-k25kl-export-pod      0/1     Completed   0          6m35s
pod/hello-crane-tekton-demo-k25kl-import-pod      0/1     Completed   0          6m12s
pod/hello-crane-tekton-demo-k25kl-transform-pod   0/1     Completed   0          6m23s
pod/redis-master-f46ff57fd-47np2                  1/1     Running     0          6m6s
pod/redis-slave-57bcf745fb-2mlbz                  1/1     Running     0          6m6s
pod/redis-slave-57bcf745fb-blz27                  1/1     Running     0          6m6s

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/frontend       ClusterIP   10.96.232.215   <none>        80/TCP     6m6s
service/redis-master   ClusterIP   10.96.49.200    <none>        6379/TCP   6m6s
service/redis-slave    ClusterIP   10.96.10.63     <none>        6379/TCP   6m6s

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/frontend       3/3     3            3           6m6s
deployment.apps/redis-master   1/1     1            1           6m6s
deployment.apps/redis-slave    2/2     2            2           6m6s

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/frontend-5fd859dcf6      3         3         3       6m6s
replicaset.apps/redis-master-f46ff57fd   1         1         1       6m6s
replicaset.apps/redis-slave-57bcf745fb   2         2         2       6m6s
```

And you should be able to access the guestbook with:
1. `kubectl --context kind-dest port-forward --namespace hello-crane svc/frontend 8080:80`
1. Navigating to localhost:8080.
