# 🚀 End-to-End DevOps / DevSecOps Pipeline

A hands-on DevOps/DevSecOps project built from the ground up on **Windows + Docker Desktop + Kind Kubernetes**. The goal is to build a practical end-to-end environment and document the setup, commands, troubleshooting and integrations so another learner can reproduce it step by step.

> 🚧 **Status:** Foundation is working. Jenkins can now authenticate to and control the Kind Kubernetes cluster. CI/CD, Terraform application deployment, Harbor, GitOps and observability are the next phases.

## 🛠️ Technology Stack

| Tool | Purpose | Status |
|---|---|---|
| Git / GitHub | Source control | ✅ |
| Docker Desktop | Container runtime | ✅ |
| Jenkins | CI/CD | ✅ |
| SonarQube | Code quality / static analysis | ✅ |
| Kind | Local Kubernetes | ✅ |
| kubectl | Kubernetes CLI | ✅ inside Jenkins |
| Terraform | Infrastructure as Code | ✅ inside Jenkins |
| Trivy | Security scanning | ✅ host + Jenkins |
| Helm | Kubernetes packaging | ✅ |
| Argo CD | GitOps CD | ✅ installed |
| NGINX Ingress | Traffic management | ✅ installed |
| Harbor | Container registry | ⏳ Planned |
| OWASP Dependency-Check | Dependency security | ⏳ Planned |
| Ansible | Configuration management | ⏳ Planned |
| Prometheus | Monitoring | ⏳ Planned |
| Grafana | Dashboards | ⏳ Planned |
| Loki | Logging | ⏳ Planned |
| Alertmanager | Alerting | ⏳ Planned |
| OpenTelemetry | Observability / tracing | ⏳ Planned |

## 🏗️ Target Architecture

```text
GitHub
  ↓
Jenkins
  ├── Unit Tests
  ├── SonarQube
  ├── Trivy
  ├── Docker Build
  └── Terraform
        ↓
      Harbor
        ↓
      GitOps
        ↓
     Argo CD
        ↓
 Kubernetes / Kind
  ├── Deployment
  ├── Service
  ├── ConfigMap
  └── NGINX Ingress
        ↓
 Prometheus / Grafana / Loki / Alertmanager / OpenTelemetry
```

---

# 1. Environment

Current local endpoints:

```text
Jenkins:   http://localhost:8080
SonarQube: http://localhost:9000
```

Current Kind cluster:

```text
Cluster: devops
Control plane: devops-control-plane
Docker network: kind
Kubernetes API from Jenkins: https://devops-control-plane:6443
```

---

# 2. Git and GitHub

Verify Git:

```powershell
git --version
```

Clone the project:

```powershell
cd D:\
git clone https://github.com/lipuna1234/devops-pipeline.git
cd D:\devops-pipeline
git status
```

Always work inside `D:\devops-pipeline`. Do not accidentally run `git init` in `D:\` itself. If Git reports `dubious ownership` for `D:/`, check that you are inside the project directory before adding a `safe.directory` exception.

---

# 3. Docker Desktop

Install/start Docker Desktop and verify:

```powershell
docker --version
docker ps
docker ps -a
docker images
docker network ls
docker volume ls
```

---

# 4. Create Kind Kubernetes

Create the cluster:

```powershell
kind create cluster --name devops
```

Verify:

```powershell
kind get clusters
kubectl cluster-info
kubectl get nodes
```

Expected:

```text
devops-control-plane   Ready   control-plane   ...   v1.36.1
```

Check the Docker network:

```powershell
docker network ls
```

The Kind network is `kind`.

---

# 5. SonarQube

SonarQube is running in Docker and is available at:

```text
http://localhost:9000
```

Verify its container:

```powershell
docker ps
```

Later Jenkins will use SonarQube analysis and a quality gate.

---

# 6. Jenkins Persistent Volume

Jenkins runs in Docker and uses the persistent volume:

```text
jenkins_home
```

Check:

```powershell
docker volume ls
docker volume inspect jenkins_home
```

Jenkins web UI:

```text
http://localhost:8080
```

Ports:

```text
8080  -> Jenkins UI
50000 -> Jenkins agent communication
```

---

# 7. Custom Jenkins Image

The repository contains:

```text
jenkins/
├── Dockerfile
└── docker-entrypoint.sh
```

The custom image installs:

```text
Docker CLI
kubectl
Terraform
Trivy
```

and defines:

```dockerfile
ENV KUBECONFIG=/var/jenkins_home/.kube/config
```

Build it:

```powershell
cd D:\devops-pipeline\jenkins
docker build --no-cache -t custom-jenkins-devops:latest .
```

Verify:

```powershell
docker images custom-jenkins-devops
```

### Why `ENV KUBECONFIG` is not enough by itself

The Dockerfile only tells kubectl **where** the kubeconfig will be. It does not contain the Kind credentials. The actual kubeconfig is mounted into Jenkins at runtime.

So we need both:

```text
Dockerfile
  └── KUBECONFIG=/var/jenkins_home/.kube/config

Runtime volume
  └── /var/jenkins_home/.kube/config
```

---

# 8. Jenkins Docker Socket

Jenkins needs the Docker CLI to build container images. The host Docker socket is mounted:

```text
/var/run/docker.sock
```

Check the socket:

```powershell
docker exec jenkins ls -ln /var/run/docker.sock
```

Check Docker CLI:

```powershell
docker exec jenkins docker --version
```

The important final test is:

```powershell
docker exec jenkins docker ps
```

If this gives `permission denied`, inspect:

```powershell
docker exec jenkins id
docker exec jenkins ls -ln /var/run/docker.sock
```

The custom `docker-entrypoint.sh` is intended to handle the Docker socket's host-specific group ID.

---

# 9. Connect Jenkins to Kind Network

Jenkins must be on the same Docker network as the Kind control plane.

If the Jenkins container already exists:

```powershell
docker network connect kind jenkins
```

Verify:

```powershell
docker inspect jenkins --format "{{json .NetworkSettings.Networks}}"
```

Check the Kind control plane address:

```powershell
docker inspect -f "{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}" devops-control-plane
```

The important DNS name from Jenkins is:

```text
devops-control-plane
```

and Kubernetes listens on:

```text
6443
```

---

# 10. Test Jenkins → Kubernetes Network Connectivity

Before configuring kubectl, test the Kubernetes API directly:

```powershell
docker exec jenkins bash -c "curl -k https://devops-control-plane:6443/version"
```

A successful response contains Kubernetes version information such as:

```json
{
  "major": "1",
  "minor": "36",
  "gitVersion": "v1.36.1"
}
```

This proves Docker networking is working:

```text
Jenkins container
      ↓
Docker network: kind
      ↓
devops-control-plane:6443
      ↓
Kubernetes API
```

---

# 11. Jenkins Kubernetes Kubeconfig

The Kind kubeconfig originally uses a host-only endpoint such as:

```text
https://127.0.0.1:49879
```

That is not suitable inside Jenkins because `127.0.0.1` inside Jenkins means the Jenkins container itself.

For Jenkins, the Kubernetes server must be:

```text
https://devops-control-plane:6443
```

The kubeconfig used by Jenkins contains:

```yaml
server: https://devops-control-plane:6443
current-context: kind-devops
```

It is mounted to:

```text
/var/jenkins_home/.kube/config
```

Verify it:

```powershell
docker exec jenkins sh -c "ls -la /var/jenkins_home/.kube/"
docker exec jenkins sh -c "grep -E 'server:|current-context:' /var/jenkins_home/.kube/config"
```

Expected:

```text
server: https://devops-control-plane:6443
current-context: kind-devops
```

Check the context explicitly:

```powershell
docker exec jenkins sh -c "KUBECONFIG=/var/jenkins_home/.kube/config kubectl config get-contexts"
```

Expected:

```text
CURRENT   NAME          CLUSTER       AUTHINFO      NAMESPACE
*         kind-devops   kind-devops   kind-devops
```

---

# 12. Final Jenkins → Kubernetes Test

This is the most important verification:

```powershell
docker exec jenkins kubectl get nodes
```

Current successful result:

```text
NAME                   STATUS   ROLES           AGE   VERSION
devops-control-plane   Ready    control-plane   ...   v1.36.1
```

Also test:

```powershell
docker exec jenkins kubectl get namespaces
docker exec jenkins kubectl get pods -A
docker exec jenkins kubectl get deployments -A
docker exec jenkins kubectl get services -A
```

Jenkins can now run Kubernetes commands against the Kind cluster.

---

# 13. Working Jenkins Container Command

The current working setup uses the persistent Jenkins volume, Docker socket, Kind network and the Kubernetes kubeconfig.

First remove only the container — **do not delete `jenkins_home`**:

```powershell
docker rm -f jenkins
```

Then:

```powershell
docker run -d `
  --name jenkins `
  --network kind `
  -p 8080:8080 `
  -p 50000:50000 `
  -e KUBECONFIG=/var/jenkins_home/.kube/config `
  -v jenkins_home:/var/jenkins_home `
  -v //var/run/docker.sock:/var/run/docker.sock `
  -v D:\devops-pipeline\jenkins\kind-config.yaml:/var/jenkins_home/.kube/config:ro `
  custom-jenkins-devops:latest
```

Verify:

```powershell
docker ps
docker logs jenkins
docker exec jenkins printenv KUBECONFIG
docker exec jenkins kubectl get nodes
```

Expected:

```text
/var/jenkins_home/.kube/config
```

and the Kind node should be `Ready`.

> `-e KUBECONFIG=...` is technically redundant if the current Dockerfile image is used because the Dockerfile already contains the same `ENV`. Keeping it in the run command makes the runtime configuration explicit and easier to troubleshoot.

### PowerShell warning

PowerShell uses the backtick `` ` `` for multiline commands. Linux/bash uses `\`. Do not paste Linux multiline syntax directly into PowerShell.

---

# 14. Jenkins Tool Verification

Verify every tool from inside Jenkins:

```powershell
docker exec jenkins docker --version
docker exec jenkins kubectl version --client
docker exec jenkins terraform version
docker exec jenkins trivy --version
```

Versions verified during this build:

```text
Docker CLI  29.7.2
kubectl     v1.36.4
Terraform   v1.16.0
Trivy       0.74.0
```

Versions can change when the Dockerfile is rebuilt because current upstream packages are installed.

---

# 15. Security — NEVER Commit kubeconfig

The Kind kubeconfig contains Kubernetes client credentials, including a private key. **Do not commit it to GitHub.**

Add to `.gitignore`:

```gitignore
# Kubernetes credentials
kind-config.yaml
*.kubeconfig

# Terraform state
.terraform/
*.tfstate
*.tfstate.*

# Secrets
.env
*.secret
*.key
```

If a kubeconfig/private key is accidentally pushed to a public repository, treat the credentials as exposed and recreate/rotate the affected credentials.

---

# 16. Helm

Verify:

```powershell
helm version
```

Helm will be used later to package the application:

```text
helm/devops-app/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── configmap.yaml
    └── ingress.yaml
```

---

# 17. Trivy

Verify on Windows:

```powershell
trivy --version
```

Verify inside Jenkins:

```powershell
docker exec jenkins trivy --version
```

Planned security stages:

```text
Trivy filesystem scan
        ↓
Trivy Docker image scan
        ↓
Trivy Kubernetes/config scan
        ↓
Jenkins security gate
```

Examples:

```bash
trivy fs .
trivy image <image>:<tag>
trivy config .
```

---

# 18. Argo CD

Install:

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Verify:

```powershell
kubectl get pods -n argocd
kubectl get svc -n argocd
```

Argo CD will later synchronize desired Kubernetes state from Git.

---

# 19. NGINX Ingress

Install the Kind-compatible controller:

```powershell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Verify:

```powershell
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
kubectl get ingress -A
```

---

# 20. Terraform + Jenkins + Kubernetes Design

Terraform will manage **application-owned resources**, not blindly recreate the whole Kubernetes platform.

Example:

```text
Application
├── Namespace
├── Deployment
├── Service
├── ConfigMap
└── Ingress
```

Platform resources such as `kube-system`, `argocd` and `ingress-nginx` are installed/managed separately unless we deliberately bring them under Terraform.

Jenkins runtime parameters will make the deployment dynamic:

```text
NAMESPACE
APP_NAME
APP_IMAGE
REPLICAS
CONTAINER_PORT
SERVICE_PORT
CONFIG_VALUES
```

Example:

```text
NAMESPACE=dev
APP_NAME=python-app
APP_IMAGE=python-app:25
REPLICAS=2
CONTAINER_PORT=5000
SERVICE_PORT=80
CONFIG_VALUES=APP_ENV=dev
```

---

# 21. Existing Kubernetes Resources

A key requirement is that we should **not blindly recreate resources that already exist**.

Jenkins can inspect live state before Terraform:

```bash
kubectl get namespaces
kubectl get deployments -n <namespace>
kubectl get services -n <namespace>
kubectl get configmaps -n <namespace>
```

If a Deployment/Service/ConfigMap already exists but is not in Terraform state, the preferred approach is to import it into Terraform state and then make the Terraform configuration match the existing resource.

Conceptually:

```text
Live Kubernetes resource
        ↓
terraform import
        ↓
Terraform state
        ↓
terraform plan
        ↓
terraform apply
```

This is safer than deleting a working resource just because Terraform has not managed it before.

> Terraform import changes Terraform state; it does not automatically produce a perfect `.tf` configuration. The configuration must still be written to represent the existing resource correctly.

---

# 22. Jenkins Pipeline Design

The intended Declarative Pipeline is:

```text
Checkout
   ↓
Python Tests
   ↓
SonarQube Analysis
   ↓
SonarQube Quality Gate
   ↓
Trivy Filesystem Scan
   ↓
Docker Build
   ↓
Trivy Image Scan
   ↓
Kubernetes Live Discovery
   ↓
Terraform Init
   ↓
Terraform Import / State Reconciliation
   ↓
Terraform Plan
   ↓
Manual Approval
   ↓
Terraform Apply
   ↓
Kubernetes Verification
```

Example runtime parameters:

```text
NAMESPACE
APP_NAME
APP_IMAGE
REPLICAS
CONTAINER_PORT
SERVICE_PORT
CONFIG_VALUES
```

The important design principle is that Jenkins queries the **live Kubernetes cluster** instead of relying on a hardcoded list of namespaces/resources.

---

# 23. Sample Jenkins Kubernetes Test

Before the complete application pipeline, verify Jenkins itself can execute Kubernetes commands:

```groovy
pipeline {
    agent any
    stages {
        stage('Kubernetes Connectivity') {
            steps {
                sh 'kubectl get nodes'
                sh 'kubectl get namespaces'
            }
        }
    }
}
```

For the current Linux Jenkins container, `sh` is appropriate.

---

# 24. Sample Python Application

The application is intended to contain:

```text
app/
├── app.py
├── requirements.txt
└── test_app.py
```

The Dockerfile will package the application.

First CI goal:

```text
GitHub
  ↓
Jenkins
  ↓
Checkout
  ↓
Python tests
  ↓
SonarQube
  ↓
Trivy
  ↓
Docker build
```

Then the image will be pushed to Harbor and deployed to Kubernetes.

---

# 25. Troubleshooting

## `kubectl` not found inside Jenkins

```text
exec: "kubectl": executable file not found in $PATH
```

Rebuild the custom image and recreate the container:

```powershell
cd D:\devops-pipeline\jenkins
docker build --no-cache -t custom-jenkins-devops:latest .
docker rm -f jenkins
```

Do not delete `jenkins_home`.

Verify:

```powershell
docker exec jenkins kubectl version --client
```

## `KUBECONFIG` is empty

```powershell
docker exec jenkins printenv KUBECONFIG
```

If empty, recreate from the current image and/or explicitly use:

```powershell
-e KUBECONFIG=/var/jenkins_home/.kube/config
```

## `current-context must exist`

Check:

```powershell
docker exec jenkins sh -c "ls -la /var/jenkins_home/.kube/"
docker exec jenkins sh -c "KUBECONFIG=/var/jenkins_home/.kube/config kubectl config get-contexts"
```

## Jenkins gets an HTML Jenkins login page from `kubectl`

If the output contains:

```text
Authentication required
You are authenticated as: anonymous
```

kubectl is reaching Jenkins instead of Kubernetes.

Check:

```powershell
docker exec jenkins sh -c "grep -E 'server:|current-context:' /var/jenkins_home/.kube/config"
```

The server must be:

```text
https://devops-control-plane:6443
```

not `localhost:8080`.

## Docker socket permission denied

Check:

```powershell
docker exec jenkins id
docker exec jenkins ls -ln /var/run/docker.sock
docker exec jenkins docker ps
```

If the final command fails, inspect the custom entrypoint and rebuild the image.

## `docker-entrypoint.sh: no such file or directory`

Windows may have saved the script with CRLF line endings. The Dockerfile normalizes it:

```dockerfile
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh
```

Rebuild:

```powershell
docker build --no-cache -t custom-jenkins-devops:latest .
```

## PowerShell `Missing expression after unary operator '--'`

This happens when Linux `\` line continuation is pasted into PowerShell.

PowerShell:

```powershell
docker run -d `
  --name jenkins `
  ...
```

Linux/bash:

```bash
docker run -d \
  --name jenkins \
  ...
```

---

# 26. Daily Verification

### Docker

```powershell
docker ps
docker ps -a
docker network ls
docker volume ls
```

### Jenkins tools

```powershell
docker exec jenkins docker --version
docker exec jenkins kubectl version --client
docker exec jenkins terraform version
docker exec jenkins trivy --version
```

### Jenkins → Kubernetes

```powershell
docker exec jenkins kubectl get nodes
docker exec jenkins kubectl get namespaces
docker exec jenkins kubectl get pods -A
docker exec jenkins kubectl get deployments -A
docker exec jenkins kubectl get services -A
```

These commands verify what the Jenkins pipeline itself can access.

---

# 27. Git Ignore / Secrets

If `.gitignore` does not exist:

```powershell
cd D:\devops-pipeline
New-Item .gitignore -ItemType File
notepad .gitignore
```

Recommended minimum:

```gitignore
kind-config.yaml
*.kubeconfig
.terraform/
*.tfstate
*.tfstate.*
.env
*.secret
*.key
```

Then:

```powershell
git add .gitignore
git commit -m "Add security gitignore"
git push
```

---

# 28. Current Verified Progress

```text
✅ Git installed
✅ GitHub repository
✅ Docker Desktop
✅ Jenkins
✅ Jenkins persistent volume: jenkins_home
✅ SonarQube
✅ Kind Kubernetes cluster
✅ Jenkins connected to kind network
✅ Jenkins can reach Kubernetes API
✅ Custom Jenkins image
✅ Docker CLI inside Jenkins
✅ kubectl inside Jenkins
✅ Terraform inside Jenkins
✅ Trivy inside Jenkins
✅ KUBECONFIG configured
✅ Kind kubeconfig mounted into Jenkins
✅ Jenkins Kubernetes authentication
✅ `docker exec jenkins kubectl get nodes`
✅ Helm
✅ Argo CD
✅ NGINX Ingress

⏳ Python application CI
⏳ SonarQube Jenkins integration / quality gate
⏳ Full Trivy security gates
⏳ Dynamic Terraform deployment
⏳ Harbor
⏳ Helm application chart
⏳ Argo CD GitOps application
⏳ Prometheus
⏳ Grafana
⏳ Loki
⏳ Alertmanager
⏳ OpenTelemetry
⏳ Ansible
```

---

# 29. Next Steps

Build in this order:

1. Verify `docker exec jenkins docker ps` works.
2. Build and test the sample Python application.
3. Create/connect the Jenkins Pipeline to this GitHub repository.
4. Run Python tests from Jenkins.
5. Integrate SonarQube and add the quality gate.
6. Add Trivy filesystem and image scans.
7. Build the Docker image.
8. Install/configure Harbor and push the image.
9. Use Jenkins runtime parameters for namespace/app/image/replicas/ports/config.
10. Use Terraform to manage the application Deployment, Service, ConfigMap and Ingress.
11. Discover existing resources and import them into Terraform state when required.
12. Add Helm packaging.
13. Connect Argo CD to the GitOps desired state.
14. Add Prometheus, Grafana, Loki, Alertmanager and OpenTelemetry.
15. Add Ansible.

---

# 🎯 Project Goal

The final project should demonstrate a realistic DevOps/DevSecOps workflow rather than isolated tool installations:

- CI/CD with Jenkins
- Code quality with SonarQube
- Security with Trivy and OWASP Dependency-Check
- Containerization with Docker
- Registry with Harbor
- Kubernetes orchestration
- Infrastructure as Code with Terraform
- Packaging with Helm
- GitOps with Argo CD
- Ingress with NGINX
- Monitoring with Prometheus
- Visualization with Grafana
- Logging with Loki
- Alerting with Alertmanager
- Observability/tracing with OpenTelemetry
- Configuration management with Ansible

> **Build it, break it, fix it, automate it, and document every step. 🚀**

## 📌 Repository

https://github.com/lipuna1234/devops-pipeline
