# 🚀 DevOps End-to-End CI/CD & DevSecOps Pipeline

A hands-on DevOps/DevSecOps project built from the ground up with open-source technologies.

The goal is to build and document a practical end-to-end environment covering CI/CD, code quality, security scanning, containerization, Kubernetes, GitOps, monitoring, logging, alerting, and observability.

> 🚧 This project is under active development. The README is updated as each phase is completed.

---

## 🛠️ Technologies

### Currently Set Up

- 🐳 Docker Desktop
- 🐙 Git & GitHub
- 🔧 Jenkins
- 🔍 SonarQube
- ☸️ Kind Kubernetes
- 🚀 Argo CD
- 🌐 NGINX Ingress Controller
- ⛵ Helm
- 🔐 Trivy

### Jenkins DevOps Tooling

A custom Jenkins image is being prepared under `jenkins/Dockerfile` with:

- Docker CLI
- kubectl
- Terraform
- Trivy

Jenkins is connected to the Docker `kind` network so that the Jenkins container can reach the Kind Kubernetes API directly at `devops-control-plane:6443`.

### Planned

- 🛡️ OWASP Dependency-Check
- 📦 Harbor
- ⚙️ Ansible
- 📊 Prometheus
- 📈 Grafana
- 📝 Loki
- 🔔 Alertmanager
- 🔭 OpenTelemetry

---

# 📌 Project Progress

## Phase 1 — Local DevOps Environment

The local DevOps environment is running on Windows using Docker Desktop, Docker containers, and Kind Kubernetes.

### 1. Git & GitHub

Git is installed on Windows.

```powershell
git --version
git clone https://github.com/lipuna1234/devops-pipeline.git
```

Repository:

`https://github.com/lipuna1234/devops-pipeline`

---

## 2. Docker Desktop

Docker Desktop is installed and running on Windows.

```powershell
docker --version
docker ps
docker network ls
```

Docker provides the runtime for Jenkins, SonarQube, and Kind.

---

## 3. Jenkins

Jenkins is running in Docker and is used for CI/CD automation.

Current local Jenkins endpoint:

```text
http://localhost:8080
```

The repository also contains a custom Jenkins image definition:

```text
jenkins/
└── Dockerfile
```

The image is designed to provide Jenkins with the command-line tools required by the pipeline: Docker CLI, kubectl, Terraform, and Trivy.

Build the image locally:

```powershell
cd D:\devops-pipeline\jenkins
docker build -t custom-jenkins-devops:latest .
```

> Do not delete the currently working Jenkins container until its persistent Jenkins home, Docker access, Kubernetes credentials, and `kind` network connection have been migrated to the custom image.

### Jenkins → Kind Network

Jenkins is connected to the Docker `kind` network:

```powershell
docker network connect kind jenkins
```

Verify:

```powershell
docker inspect jenkins --format "{{json .NetworkSettings.Networks}}"
```

The current setup has Jenkins on the `kind` network and the Kind control plane at:

```text
devops-control-plane:6443
```

Kubernetes API connectivity has been verified from Jenkins with:

```powershell
docker exec jenkins bash -c "curl -k https://devops-control-plane:6443/version"
```

This returned Kubernetes `v1.36.1`.

### Jenkins Kubernetes Access

The current Jenkins image does not yet contain kubectl. The target state is:

```text
Jenkins Container
├── kubectl
├── Terraform
├── Trivy
└── Docker CLI
        |
        v
Kind Docker Network
        |
        v
devops-control-plane:6443
        |
        v
Kubernetes API
```

After the custom image and kubeconfig are configured, verify:

```powershell
docker exec jenkins kubectl get nodes
docker exec jenkins kubectl get namespaces
```

Expected node state:

```text
devops-control-plane   Ready   control-plane
```

---

## 4. SonarQube

SonarQube is running as a Docker container and will be used for static code analysis and quality gates.

Current endpoint:

```text
http://localhost:9000
```

Verify:

```powershell
docker ps
```

---

# ☸️ Kubernetes Environment

## 5. Kind

Kind (Kubernetes in Docker) is used to create the local Kubernetes cluster.

```powershell
kind create cluster --name devops
kind get clusters
kubectl get nodes
kubectl cluster-info
```

Current control-plane container:

```text
devops-control-plane
```

The Kind Docker network is:

```text
kind
```

---

# 🚀 Argo CD

## 6. Install Argo CD

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl get svc -n argocd
```

Argo CD is used for GitOps-based continuous delivery.

---

# 🌐 NGINX Ingress Controller

## 7. Install NGINX Ingress Controller

```powershell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
kubectl get ingress -A
```

NGINX Ingress is used to expose applications running in Kind.

---

# ⛵ Helm

## 8. Helm

Helm is installed on Windows and will be used as the Kubernetes package manager.

```powershell
helm version
```

---

# 🔐 Trivy

## 9. Trivy

Trivy is installed on the Windows environment and is planned for Jenkins filesystem, image, and Kubernetes configuration scanning.

```powershell
trivy --version
```

The custom Jenkins image also installs Trivy so the same scanner can be used inside CI.

---

# 🐍 Sample Application

A sample Python application is included in the repository with tests and a Dockerfile.

```text
app/
├── app.py
├── requirements.txt
└── test_app.py

Dockerfile
```

The application is used to validate the complete CI/CD and DevSecOps workflow.

---

# 🏗️ Terraform + Jenkins + Kubernetes

Terraform is being used to manage **application-owned Kubernetes resources**, while existing platform namespaces such as `argocd`, `ingress-nginx`, and `kube-system` are not blindly recreated.

The Terraform configuration accepts runtime values for:

- Namespace
- Application name
- Container image
- Replica count
- Container port
- Service port
- Environment-specific ConfigMap values

Example:

```text
NAMESPACE=devops
APP_NAME=devops-app
APP_IMAGE=devops-app:25
REPLICAS=3
CONTAINER_PORT=5000
SERVICE_PORT=80
```

Existing application Deployment, Service, and ConfigMap resources can be imported into Terraform state before applying changes.

This prevents the pipeline from blindly attempting to recreate resources that already exist.

---

# 🔄 Jenkins Pipeline

The repository contains a Declarative Jenkins pipeline in `Jenkinsfile`.

The intended flow is:

```text
GitHub
  |
  v
Jenkins
  |
  +--> Python Tests
  |
  +--> Docker Build
  |
  +--> Trivy Scan
  |
  +--> kubectl - discover live Kubernetes state
  |
  +--> Terraform Init
  |
  +--> Import existing application resources when required
  |
  +--> Terraform Plan
  |
  +--> Manual Approval
  |
  +--> Terraform Apply
  |
  +--> Verify Deployment
  |
  v
Kubernetes / Kind
```

### Runtime Parameters

The pipeline accepts:

```text
NAMESPACE
APP_NAME
APP_IMAGE
REPLICAS
CONTAINER_PORT
SERVICE_PORT
CONFIG_VALUES
```

The pipeline uses `kubectl` to inspect the live cluster before Terraform runs:

```bash
kubectl get namespaces
kubectl get deployments -n <namespace>
kubectl get services -n <namespace>
kubectl get configmaps -n <namespace>
```

This means the pipeline is designed around the **current Kubernetes state**, rather than maintaining a hardcoded list of namespaces and applications.

> Note: Jenkins must have kubectl installed and authenticated against the Kind cluster before this pipeline can run successfully.

---

# 🧩 Resource Ownership Model

The project follows a simple ownership model:

```text
Platform Resources
├── argocd             → Argo CD / platform setup
├── ingress-nginx      → Ingress controller
└── kube-system        → Kubernetes

Application Resources
└── selected namespace
    ├── Deployment      → Terraform
    ├── Service         → Terraform
    └── ConfigMap       → Terraform
```

Terraform should manage resources that belong to the application. Existing resources that Terraform needs to own should be imported into Terraform state rather than recreated blindly.

---

# 🏗️ Current Architecture

```text
                         Windows
                            |
                    Docker Desktop
                       /        \
                      /          \
                     v            v
               Docker Containers  Kind
                  /       \        |
                 /         \       v
                v           v  Kubernetes
             Jenkins     SonarQube   |
                |                   +-- Argo CD
                |                   +-- NGINX Ingress
                |                   +-- Helm
                |                   +-- Trivy
                |
                +-- kubectl
                +-- Terraform
                +-- Docker CLI
                +-- Trivy
```

---

# 📊 Current Status

| Component | Status |
|---|---|
| Docker Desktop | ✅ Completed |
| Git | ✅ Installed |
| GitHub Repository | ✅ Created |
| Jenkins | ✅ Running |
| SonarQube | ✅ Running |
| Kind | ✅ Completed |
| Kubernetes | ✅ Running through Kind |
| Jenkins → Kind network | ✅ Connected |
| Jenkins → Kubernetes API network test | ✅ Verified |
| kubectl inside current Jenkins container | ⏳ Pending custom Jenkins image |
| Jenkins Docker CLI | ⏳ Pending custom Jenkins image |
| Jenkins Terraform | ⏳ Pending custom Jenkins image |
| Jenkins Trivy | ⏳ Pending custom Jenkins image |
| Argo CD | ✅ Installed |
| NGINX Ingress Controller | ✅ Installed |
| Helm | ✅ Installed |
| Trivy on Windows | ✅ Installed |
| Sample Python application | ✅ Added |
| Dockerfile | ✅ Added |
| Dynamic Terraform variables | ✅ Added |
| Dynamic Jenkins runtime parameters | ✅ Added |
| Harbor | ⏳ Planned |
| OWASP Dependency-Check | ⏳ Planned |
| Ansible | ⏳ Planned |
| Prometheus | ⏳ Planned |
| Grafana | ⏳ Planned |
| Loki | ⏳ Planned |
| Alertmanager | ⏳ Planned |
| OpenTelemetry | ⏳ Planned |

---

# 🧭 Project Roadmap

### Phase 1 — Foundation

- [x] Docker Desktop
- [x] Git & GitHub
- [x] Kind
- [x] Kubernetes
- [x] Jenkins
- [x] SonarQube
- [x] Argo CD
- [x] NGINX Ingress
- [x] Helm
- [x] Trivy
- [x] Connect Jenkins to Kind Docker network
- [x] Verify Jenkins can reach Kubernetes API

### Phase 2 — Jenkins Build Environment

- [x] Create custom Jenkins Dockerfile
- [ ] Recreate Jenkins using custom image
- [ ] Configure Docker CLI access
- [ ] Configure kubectl
- [ ] Configure Jenkins Kubernetes credentials
- [ ] Verify `kubectl get nodes` from Jenkins
- [ ] Verify Terraform from Jenkins
- [ ] Verify Trivy from Jenkins

### Phase 3 — Application

- [x] Create sample Python application
- [x] Add unit tests
- [x] Create Dockerfile
- [ ] Build and run application locally

### Phase 4 — CI

- [x] Create Jenkinsfile
- [ ] Connect GitHub to Jenkins
- [ ] Automated checkout
- [ ] Automated Python tests
- [ ] Docker build
- [ ] SonarQube integration
- [ ] Quality gate

### Phase 5 — DevSecOps

- [x] Install Trivy
- [x] Add Trivy stage to Jenkins pipeline
- [ ] Trivy filesystem scanning
- [ ] Trivy container image scanning
- [ ] Trivy Kubernetes/configuration scanning
- [ ] OWASP Dependency-Check
- [ ] Security gates in Jenkins

### Phase 6 — Kubernetes & Terraform

- [x] Dynamic Terraform variables
- [x] Existing resource import logic
- [x] Dynamic Jenkins runtime parameters
- [x] Live Kubernetes discovery with kubectl
- [ ] Terraform plan/apply from Jenkins
- [ ] Deploy sample application to Kind
- [ ] Manage Deployment
- [ ] Manage Service
- [ ] Manage ConfigMap
- [ ] Manage Ingress

### Phase 7 — Container Registry

- [ ] Install Harbor
- [ ] Configure Harbor project
- [ ] Push Docker images from Jenkins
- [ ] Image versioning
- [ ] Integrate Harbor with Kubernetes

### Phase 8 — Helm

- [x] Install Helm
- [ ] Create Helm chart
- [ ] Create values.yaml
- [ ] Template Kubernetes resources
- [ ] Deploy application using Helm

### Phase 9 — GitOps

- [ ] Create Argo CD Application
- [ ] Connect Argo CD to GitHub
- [ ] Configure desired state in Git
- [ ] Configure automated synchronization
- [ ] Implement GitOps deployment workflow

### Phase 10 — Monitoring & Observability

- [ ] Prometheus
- [ ] Grafana
- [ ] Loki
- [ ] Alertmanager
- [ ] OpenTelemetry

### Phase 11 — Configuration Management

- [ ] Ansible
- [ ] Document configuration management workflows

---

# 🔄 Target End-to-End Architecture

```text
                         Developer
                             |
                             v
                          GitHub
                             |
                             v
                          Jenkins
                             |
          +------------------+------------------+
          |                  |                  |
          v                  v                  v
       Build/Test        SonarQube       Trivy Security
                                              |
                              +---------------+
                              |
                              v
                         Docker Build
                              |
                              v
                           Harbor
                              |
                              v
                         Kubernetes
                              |
                           Argo CD
                              |
                              v
                       NGINX Ingress
                              |
                              v
                         Application
                              |
              +---------------+---------------+
              |               |               |
              v               v               v
          Prometheus         Loki      OpenTelemetry
              |               |               |
              +-------+-------+---------------+
                      |
                      v
                   Grafana
                      |
                      v
                Alertmanager
```

Terraform manages selected application infrastructure/Kubernetes resources, while Jenkins executes CI and the Terraform workflow. Argo CD will later be used for the GitOps CD portion of the final architecture.

---

# 📚 Project Objectives

This project demonstrates practical knowledge of:

- CI/CD automation
- Git and GitHub workflows
- Jenkins pipelines
- Static code analysis
- Quality gates
- DevSecOps security scanning
- Docker containerization
- Private container registries
- Kubernetes orchestration
- Helm package management
- Infrastructure as Code with Terraform
- GitOps with Argo CD
- Ingress and traffic management
- Metrics and monitoring
- Centralized logging
- Alerting
- Distributed tracing and observability
- Configuration management with Ansible

The focus is on building the environment practically, understanding how the tools integrate, and documenting problems and solutions encountered along the way.

---

## 🚧 Project Status

**Currently in development.**

The local DevOps foundation is ready. Jenkins networking to the Kind Kubernetes API has been verified, and the repository now contains the custom Jenkins tooling definition, sample application, Terraform configuration, and parameterized Jenkins pipeline. The next milestone is to migrate Jenkins safely to the custom image and verify Docker, kubectl, Terraform, and Trivy from inside Jenkins.
