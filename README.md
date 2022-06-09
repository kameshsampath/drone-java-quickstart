# Drone Greeter

The application has one simple REST api at URI `/` that says "Hello from Captain Canary!! 🚀".

## Pre-requisites

- Kubernetes Cluster e.g. [Rancher Desktop](https://rancherdesktop.io)
- [Drone CLI](https://docs.drone.io/cli/install/)

## Setup Environment

Before we get started with the demo let us setup the environment for running the demo,

```shell
export NODE_IP=$(kubectl get nodes -ojsonpath='{.items[0].status.addresses[?(@.type == "InternalIP")].address}')
```

The [pipeline][./.drone.yml] can be configured with following parameters,

- `MAVEN_MODULE`:  The maven module to build either `quarkus or springboot`. Default **springboot**
- `DESTINATION_IMAGE`: The container image name. Default **ttl.sh/drone-java-quickstart:1h**
- `APP_NAMESPACE`: The Kubernetes namespace to deploy the application. This namespace will be created if not exists. Default **demos**
- `KUBERNETES_CONTEXT`: The Kubernetes context top use. Default **rancher-desktop**
- `DOCKER_FILE`: The dockerfile within sources that will be used to build the container image. This path is relative to MAVEN_MODULE.  Default **Dockerfile**
- `APP_SERVICE_TYPE`: The Kubernetes service type. Default **LoadBalancer**

[ttl.sh](https://ttl.sh) is an Anonymous & ephemeral Docker image registry, which is very handy for CI, Demos and Testing.

__IMPORTANT__: If you are using Kubernetes then make sure the Cluster server address matches to `$NODE_IP` in your `$KUBECONFIG`

Edit the environment variables in the `.drone.yml` to suit your build needs

## Quarkus

[Quarkus](./quarkus)

## Build using Drone Pipeline

Update the `MAVEN_MODULE` in [pipeline][./.drone.yml] to `quarkus` before running the following command to build and deploy the application

```shell
drone exec --trusted
```

### Building locally

```shell
./mvnw clean package -pl quarkus
```
### Running locally

```shell
java -jar quarkus/target/quarkus-app/quarkus-run.jar
```

## SpringBoot

[SpringBoot](./springboot)

## Build using Drone Pipeline

Update the `MAVEN_MODULE` in [pipeline][./.drone.yml] to `springboot` before running the following command to build and deploy the application

```shell
drone exec --trusted
```

### Building locally

```shell
./mvnw clean package -pl springboot
```

### Running locally

```shell
java -jar springboot/target/drone-springboot-greeter.jar
```