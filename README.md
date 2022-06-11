# Drone Greeter

A Java quickstart to show how to use [Drone](https://drone.io) for the local development workflow. As part of this demo
we will use a Drone pipeline to build a Java REST API application and deploy the application to the
local [Rancher Desktop](https://rancherdesktop.io) Kubernetes cluster.

## Pre-requisites

The following tools are required to run this quickstart,

- Kubernetes Cluster e.g. [Rancher Desktop](https://rancherdesktop.io)
- [Drone CLI](https://docs.drone.io/cli/install/)
- [JDK 11](https://openjdk.java.net/projects/jdk/11/)
- [Maven 3.x](https://maven.apache.org/install.html)
- [yq](https://github.com/mikefarah/yq)

## Clone the sources

```shell
git clone https://github.com/kameshsampath/drone-java-quickstart
cd drone-java-quickstart
export PROJECT_HOME="$(pwd)"
```

Going forward we will call this folder as `$PROJECT_HOME` in the **README**.

## Setup Environment

Before we get started with the demo let us set up the environment for running the demo,

### Update Kube config

Get the Kubernetes NODE_IP of the Rancher Desktop cluster,

```shell
export NODE_IP=$(kubectl get nodes -ojson≥path='{.items[0].status.addresses[?(@.type == "InternalIP")].address}')
```

The Rancher Desktop sets the value of Kubernetes Server to be `127.0.0.1` in the `$KUBECONFIG` **~/.kube/config**. If we
use the default value then the `deploy-app` step will fail as it can't reach the Kubernetes server from the container,
hence we need to update the Kubernetes context `rancher-desktop`'s server IP to be `$NODE_IP`. Run the following command
to update the `~/.kube/config`,

```shell
kubectl config set-cluster rancher-desktop --server="https://$NODE_IP:6443"
```

Now run the command `kubectl cluster-info` to ensure that cluster is pointing to `$NODE_IP`,

```shell
kubectl cluster-info --context rancher-desktop
```

The command should return an output like the following, in this case the `$NODE_IP` is **192.168.68.122**

```shell
Kubernetes control plane is running at https://192.168.68.122:6443
CoreDNS is running at https://192.168.68.122:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://192.168.68.122:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy
```

### Pipeline Environment variables

The [pipeline][./.drone.yml] can be configured with following parameters,

- `MAVEN_MODULE`:  The maven module to build either `quarkus or springboot`. Default **springboot**
- `DESTINATION_IMAGE`: The container image name. Default **ttl.sh/drone-java-quickstart:1h**
- `APP_NAMESPACE`: The Kubernetes namespace to deploy the application. This namespace will be created if not exists.
  Default **demos**
- `KUBERNETES_CONTEXT`: The Kubernetes context top use. Default **rancher-desktop**
- `DOCKER_FILE`: The dockerfile within sources that will be used to build the container image. This path is relative to
  MAVEN_MODULE. Default **Dockerfile**
- `APP_SERVICE_TYPE`: The Kubernetes service type. Default **LoadBalancer**

[ttl.sh](https://ttl.sh) is an anonymous & ephemeral container image registry, which is very handy for CI, Demos and
Testing.

### Update Drone Pipeline Resource

As this demo is best suited for the local development workflow, we need to generate the `.drone.yml.local` to suit your
local environment.

Find the architecture of the underlying operating systems e.g. amd64 or arm64 etc.,

```shell
export ARCH=$(uname -m)
```

Find the local maven repository path by default its `$HOME/.m2`,

```shell
export MAVEN_REPO=$(mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout | xargs dirname)
```

Let us now generate the drone pipeline resource file `.drone.yml.local`,

```shell
yq .drone.yml.tpl | envsubst '${ARCH},${MAVEN_REPO},${USER}' | yq -P > .drone.yml.tpl.local
```

__NOTE__: We use the `.drone.yml.local` file, it is ignored by git so that you can have any local settings that you
don't wish to commit in to the Git repo.

## Quarkus

[Quarkus](./quarkus)

## Build using Drone Pipeline

Update the `MAVEN_MODULE` in `.drone.yml.local` to `quarkus` before running the following command to build and deploy
the application

Copy the file `post-commit.tpl` to `$PROJECT_HOME/.git/hooks/post-commmit`.

```shell
cp $PROJECT_HOME/post-commit.tpl $PROJECT_HOME/.git/hooks/post-commmit
```

Now any change you make to source and commit will trigger a Drone pipeline run.

If you still need to trigger a manual run you can do,

```shell
drone exec --trusted .drone.yml.local
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

Update the `MAVEN_MODULE` in `.drone.yml.local` to `springboot` and just commit the file to trigger a pipeline run.

```shell
drone exec --trusted .drone.yml.local
```

### Building locally

```shell
./mvnw clean package -pl springboot
```

### Running locally

```shell
java -jar springboot/target/drone-springboot-greeter.jar
```

## Access Application

If the pipeline ran successfully you will see a pod and service in the `demos` namespace,

```shell
kubectl --context rancher-desktop get po,svc -n demos
```

The command should show an output like,

```shell
NAME                           READY   STATUS    RESTARTS   AGE
pod/svclb-greeter-666sq        1/1     Running   0          40h
pod/greeter-67595659c7-96ldq   1/1     Running   0          18m

NAME              TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)          AGE
service/greeter   LoadBalancer   10.43.236.7   192.168.68.122   8080:31131/TCP   40h
```

__NOTE__: The `EXTERNAL-IP` may vary in your local environment

Now call the service using curl as shown below to see a response like **"Hello from Captain Canary!!🐥🚀"**

```shell
curl 192.168.68.122:8080/
````

## Cleanup

```shell
kubectl --context rancher-desktop delete ns demos
```