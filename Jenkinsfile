pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"                  // Docker Hub registry
        IMAGE_NAME = "demo-app"
        K8S_NAMESPACE = "demo"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Get Git Short SHA') {
            steps {
                script {
                    env.SHORT_SHA = sh(
                        returnStdout: true,
                        script: '#!/bin/bash\ngit rev-parse --short HEAD'
                    ).trim()
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
#!/bin/bash
set -euxo pipefail

docker build -t $REGISTRY/$DOCKER_USER/$IMAGE_NAME:$SHORT_SHA .
docker tag $REGISTRY/$DOCKER_USER/$IMAGE_NAME:$SHORT_SHA $REGISTRY/$DOCKER_USER/$IMAGE_NAME:latest
'''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                // Use Jenkins credentials for Docker Hub
                withCredentials([usernamePassword(credentialsId: 'agent_dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
#!/bin/bash
set -euxo pipefail

echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $REGISTRY
docker push $REGISTRY/$DOCKER_USER/$IMAGE_NAME:$SHORT_SHA
docker push $REGISTRY/$DOCKER_USER/$IMAGE_NAME:latest
'''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // Optional: Use Jenkins secret file for kubeconfig
                withCredentials([file(credentialsId: 'kubeconfig-demo', variable: 'KUBECONFIG')]) {
                    sh '''
#!/bin/bash
set -euxo pipefail

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl -n $K8S_NAMESPACE set image deployment/demo-app demo-app=$REGISTRY/$DOCKER_USER/$IMAGE_NAME:$SHORT_SHA --record
kubectl -n $K8S_NAMESPACE rollout status deployment/demo-app --timeout=120s
'''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-demo', variable: 'KUBECONFIG')]) {
                    sh '''
#!/bin/bash
set -euxo pipefail

kubectl get all -n $K8S_NAMESPACE
'''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check console output."
        }
    }
}

