pipeline {
    agent any
    environment {
	SHELL = "/bin/bash"
        REGISTRY = 'docker.io'
        DOCKER_USER = 'harshithmadhuri'
        IMAGE_NAME = 'demo-app'
        K8S_NAMESPACE = 'demo'
    }
    options { timestamps() }
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Build Docker image') {
            steps {
                script { env.SHORT_SHA = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim() }
                sh '''
                  set -euxo pipefail
                  docker build -t $REGISTRY/$DOCKER_USER/$IMAGE_NAME:$SHORT_SHA .
                  docker tag $REGISTRY/$DOCKER_USER/$IMAGE_NAME:$SHORT_SHA $REGISTRY/$DOCKER_USER/$IMAGE_NAME:latest
                '''
            }
        }
        stage('Push to registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'agent_dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh '''
                      set -euxo pipefail
                      echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin $REGISTRY
                      docker push $REGISTRY/$DOCKER_USER/$IMAGE_NAME:$SHORT_SHA
                      docker push $REGISTRY/$DOCKER_USER/$IMAGE_NAME:latest
                    '''
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                  set -euxo pipefail
                  kubectl apply -f k8s/namespace.yaml
                  kubectl apply -f k8s/deployment.yaml
                  kubectl apply -f k8s/service.yaml
                  kubectl -n $K8S_NAMESPACE set image deployment/demo-app demo-app=$REGISTRY/$DOCKER_USER/$IMAGE_NAME:$SHORT_SHA --record
                  kubectl -n $K8S_NAMESPACE rollout status deployment/demo-app --timeout=120s
                '''
            }
        }
        stage('Verify & Print objects') {
            steps {
                sh '''
                  set -euxo pipefail
                  kubectl get all -n $K8S_NAMESPACE -o wide | tee kubectl_get_all.txt
                '''
                archiveArtifacts artifacts: 'kubectl_get_all.txt', onlyIfSuccessful: true
            }
        }
    }
    post { always { cleanWs() } }
}
