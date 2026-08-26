pipeline {
    agent any

    parameters {
        string(name: 'NAMESPACE', defaultValue: 'devops', description: 'Existing Kubernetes namespace to deploy into')
        string(name: 'APP_NAME', defaultValue: 'devops-app', description: 'Application/deployment name')
        string(name: 'APP_IMAGE', defaultValue: 'devops-app:local', description: 'Container image to deploy')
        string(name: 'REPLICAS', defaultValue: '2', description: 'Number of replicas')
        string(name: 'CONTAINER_PORT', defaultValue: '5000', description: 'Application container port')
        string(name: 'SERVICE_PORT', defaultValue: '80', description: 'Kubernetes Service port')
        text(name: 'CONFIG_VALUES', defaultValue: 'ENVIRONMENT=dev\nLOG_LEVEL=INFO', description: 'ConfigMap values, one KEY=VALUE per line')
    }

    environment {
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Discover Kubernetes Live') {
            steps {
                sh '''
                    set -e
                    echo "=== Live Kubernetes Namespaces ==="
                    kubectl get namespaces

                    echo "=== Selected Namespace ==="
                    kubectl get namespace "${NAMESPACE}"

                    echo "=== Existing Deployments ==="
                    kubectl get deployments -n "${NAMESPACE}" || true

                    echo "=== Existing Services ==="
                    kubectl get services -n "${NAMESPACE}" || true

                    echo "=== Existing ConfigMaps ==="
                    kubectl get configmaps -n "${NAMESPACE}" || true

                    echo "=== Current ConfigMap for selected application ==="
                    kubectl get configmap "${APP_NAME}-config" -n "${NAMESPACE}" -o yaml || true
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    python3 -m pip install -r app/requirements.txt
                    python3 -m pytest app
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t "${APP_IMAGE}" .'
            }
        }

        stage('Trivy Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL "${APP_IMAGE}"'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Import Existing Application Resources') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        import_if_needed() {
                            RESOURCE="$1"
                            ID="$2"
                            KIND="$3"
                            NAME="$4"

                            if ! terraform state list | grep -Fxq "$RESOURCE"; then
                                if kubectl get "$KIND" "$NAME" -n "${NAMESPACE}" >/dev/null 2>&1; then
                                    echo "Importing existing resource: $RESOURCE"
                                    terraform import "$RESOURCE" "$ID"
                                else
                                    echo "Resource does not exist yet: $RESOURCE"
                                fi
                            else
                                echo "Already managed by Terraform: $RESOURCE"
                            fi
                        }

                        import_if_needed \
                          'kubernetes_deployment.app' \
                          "${NAMESPACE}/${APP_NAME}" \
                          deployment "${APP_NAME}"

                        import_if_needed \
                          'kubernetes_service.app' \
                          "${NAMESPACE}/${APP_NAME}-service" \
                          service "${APP_NAME}-service"

                        import_if_needed \
                          'kubernetes_config_map.app' \
                          "${NAMESPACE}/${APP_NAME}-config" \
                          configmap "${APP_NAME}-config"
                    '''
                }
            }
        }

        stage('Prepare ConfigMap Variables') {
            steps {
                sh '''
                    python3 - <<'PY'
import json
import os

values = {}
for line in os.environ.get("CONFIG_VALUES", "").splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    if "=" not in line:
        raise SystemExit(f"Invalid ConfigMap entry: {line}")
    key, value = line.split("=", 1)
    values[key.strip()] = value.strip()

with open("config.auto.tfvars.json", "w", encoding="utf-8") as f:
    json.dump({"config": values}, f)
PY
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform plan \
                          -var="namespace=${NAMESPACE}" \
                          -var="app_name=${APP_NAME}" \
                          -var="app_image=${APP_IMAGE}" \
                          -var="replicas=${REPLICAS}" \
                          -var="container_port=${CONTAINER_PORT}" \
                          -var="service_port=${SERVICE_PORT}" \
                          -var-file="../config.auto.tfvars.json" \
                          -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                input message: 'Review Terraform plan. Apply these Kubernetes changes?', ok: 'Apply'
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE} --timeout=120s
                    kubectl get deployment,service,configmap -n ${NAMESPACE} | grep "${APP_NAME}" || true
                '''
            }
        }
    }

    post {
        always {
            sh 'rm -f config.auto.tfvars.json terraform/config.auto.tfvars.json terraform/tfplan 2>/dev/null || true'
        }
        success {
            echo 'DevOps pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check the console output.'
        }
    }
}
