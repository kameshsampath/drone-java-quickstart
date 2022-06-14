---
kind: pipeline
type: docker
name: cloud-run-demo

# remove this section if your CPU is amd64
platform:
  os: linux
  arch: arm64

environment: &buildEnv
  MAVEN_MODULE: springboot
  DESTINATION_IMAGE:
    from_secret: destination_image
  APP_NAMESPACE: demos
  KUBERNETES_CONTEXT: rancher-desktop
  DOCKER_FILE: Dockerfile
  APP_SERVICE_TYPE: LoadBalancer
  SERVICE_ACCOUNT_JSON:
    from_secret: service_account_json
  GOOGLE_APPLICATION_CREDENTIALS: /kaniko/sa.json
  GCP_REGION:
    from_secret: gcp_region
  
steps:
  - name: configure gcloud
    image: quay.io/kameshsampath/drone-gcloud-auth
    pull: always
    settings:
      google_application_credentials:
        from_secret: service_account_json
      google_cloud_project:
        from_secret: google_cloud_project
      registries:
        - asia.gcr.io
    volumes:
      - name: gcloud-config
        path: /home/dev/.config/gcloud

  - name: log the config
    image: quay.io/kameshsampath/drone-gcloud-auth
    pull: always
    commands:
      - gcloud config list
    volumes:
      - name: gcloud-config
        path: /home/dev/.config/gcloud
      
  - name: java-test
    image: quay.io/kameshsampath/drone-java-maven-plugin
    settings:
      goals:
        - clean
        - test
      maven_modules:
        - $MAVEN_MODULE
    environment: *buildEnv
   
  - name: java-build
    image: quay.io/kameshsampath/drone-java-maven-plugin
    settings:
      goals:
        - clean
        - install
      maven_modules:
        - $MAVEN_MODULE
    environment: *buildEnv
      
  - name: build-image
    image: gcr.io/kaniko-project/executor:debug
    commands:
      - echo "$SERVICE_ACCOUNT_JSON" > "$GOOGLE_APPLICATION_CREDENTIALS"
      - >
        /kaniko/executor
        --context /drone/src/$MAVEN_MODULE
        --dockerfile $DOCKER_FILE 
        --customPlatform=linux/amd64
        --destination $DESTINATION_IMAGE
        --digest-file /tmp/images/image-digest
    environment: *buildEnv
    volumes:
      - name: digest-folder
        path: /tmp/images

  - name: log the digest
    image: quay.io/kameshsampath/drone-gcloud-auth
    pull: always
    commands:
      - cat /tmp/images/image-digest
    volumes:
      - name: digest-folder
        path: /tmp/images

  - name: Deploy to Google Cloud Run
    image: quay.io/kameshsampath/drone-gcloud-auth
    pull: always
    commands:
      - IMAGE_DIGEST=$(cat /tmp/images/image-digest)
      - |
        gcloud run deploy greeter-demo \
          --image=$DESTINATION_IMAGE@$IMAGE_DIGEST \
          --region=$GCP_REGION \
          --allow-unauthenticated
    environment: *buildEnv
    volumes:
      - name: gcloud-config
        path: /home/dev/.config/gcloud 
      - name: digest-folder
        path: /tmp/images
trigger:
  branch:
  - main

volumes:
  - name: gcloud-config
    temp: {}
  - name: digest-folder
    temp: {}
