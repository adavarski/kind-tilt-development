#  kind - Tilt (Example FastAPI app + Helm) 

Simple example showcasing an option for a local development setup for python apps in kubernetes.

You need these tools to set this up and try it for yourself:
- [docker](https://www.docker.com): this is where the local cluster will be hosted
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/): installs a kind cluster in you docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/): the means of interacting with the kubernetes cluster
- [helm](https://k3d.io): package manager for kubernetes
- [tilt](https://tilt.dev): smart rebuilds and live updates making your live easier. Tilt define your dev environment as code. Very usable for microservice apps on Kubernetes, and better than Skaffold ).

## Installing the cluster
Create a local k3d cluster with docker registry using:

```
make up
```

## Running tilt
```
tilt up
```

## Clean dev environment
```
tilt down
make clean
```
