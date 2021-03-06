---
kind: pipeline
type: docker
name: drone-java-quickstart

# remove this section if your CPU is amd64
platform:
  os: linux
  arch: $ARCH

environment: &buildEnv
  MAVEN_MODULE: springboot
  DESTINATION_IMAGE: "ttl.sh/$USER/drone-java-quickstart:1h"
  APP_NAMESPACE: demos
  KUBERNETES_CONTEXT: rancher-desktop
  DOCKER_FILE: Dockerfile
  APP_SERVICE_TYPE: LoadBalancer
  
steps:
  
  - name: java-test
    image: docker.io/maven:3.8.5-jdk-11-slim
    commands:
    - mvn -pl $MAVEN_MODULE clean test
    volumes:
      - name: m2
        path: /root/.m2
    environment: *buildEnv
   
  # TODO cache maven repo
  - name: java-build
    image: docker.io/maven:3.8.5-jdk-11-slim
    commands:
    - mvn -DskipTests -pl $MAVEN_MODULE clean install
    volumes:
      - name: m2
        path: /root/.m2
    environment: *buildEnv
      
  # TODO enable cache
  - name: build-image
    image: gcr.io/kaniko-project/executor:debug
    commands:
      - >
        /kaniko/executor
        --context /drone/src/$MAVEN_MODULE
        --dockerfile $DOCKER_FILE 
        --destination $DESTINATION_IMAGE
    environment: *buildEnv

  - name: deploy-app
    image: quay.io/kameshsampath/kube-dev-tools
    commands:
      - kubectx $KUBERNETES_CONTEXT
      - kubectl create ns $APP_NAMESPACE || true
      - kubens $APP_NAMESPACE
      - kustomize build /drone/src/k8s/ | envsubst | kubectl apply -f -
    environment: *buildEnv
    volumes:
      - name: kubeconfig
        path: /apps/.kube/config

trigger:
  branch:
  - main

volumes:
  - name: m2
    host:
      path: $MAVEN_REPO
  - name: kubeconfig
    host:
      path: $HOME/.kube/config
  - name: varlibc
    temp: {}
