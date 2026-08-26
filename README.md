# 🚀 DevOps End-to-End CI/CD & DevSecOps Pipeline

A hands-on DevOps/DevSecOps project being built from the ground up with open-source technologies.

The goal is to build and document a practical end-to-end environment covering CI/CD, code quality, security scanning, containerization, Kubernetes, GitOps, monitoring, logging, alerting, and observability.

> 🚧 This project is under active development. The README will be updated as each phase is completed.

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

### Planned

- 🛡️ OWASP Dependency-Check
- 📦 Harbor
- 🏗️ Terraform
- ⚙️ Ansible
- 📊 Prometheus
- 📈 Grafana
- 📝 Loki
- 🔔 Alertmanager
- 🔭 OpenTelemetry

---

# 📌 Project Progress

## Phase 1 — Local DevOps Environment

The initial local DevOps environment has been set up on Windows using Docker Desktop, Docker containers, and Kind Kubernetes.

### 1. Git & GitHub

Git is installed on Windows.

Verify Git:

```powershell
git --version
```

Clone the project repository:

```powershell
git clone https://github.com/lipuna1234/devops-pipeline.git
```

Repository:

```text
https://github.com/lipuna1234/devops-pipeline
```

---

## 2. Docker Desktop

Docker Desktop is installed and running on Windows.

Docker is used as the container runtime for Jenkins and SonarQube and also provides the environment used by Kind.

Verify Docker:

```powershell
docker --version
docker ps
```

---

## 3. Jenkins

Jenkins is running as a Docker container and will be used for CI/CD automation.

Pull the Jenkins image:

```powershell
docker pull jenkins/jenkins:lts
```

Create a persistent volume:

```powershell
docker volume create jenkins_home
```

Run Jenkins:

```powershell
docker run -d `
--name jenkins `
-p 8081:8080 `
-p 50000:50000 `
-v jenkins_home:/var/jenkins_home `
jenkins/jenkins:lts
```

Check the container:

```powershell
docker ps
```

Jenkins is accessible locally at:

```text
http://localhost:8081
```

---

## 4. SonarQube

SonarQube is running as a Docker container and will be used for static code analysis and code quality checks.

Pull the SonarQube image:

```powershell
docker pull sonarqube:lts-community
```

Run SonarQube:

```powershell
docker run -d `
--name sonarqube `
-p 9000:9000 `
sonarqube:lts-community
```

SonarQube is accessible locally at:

```text
http://localhost:9000
```

---

# ☸️ Kubernetes Environment

## 5. Kind

Kind (Kubernetes in Docker) is being used to create a local Kubernetes cluster.

```powershell
kind create cluster --name devops
kind get clusters
kubectl get nodes
kubectl cluster-info
```

The Kind cluster provides the local Kubernetes environment for application deployment and GitOps testing.

---

# 🚀 Argo CD

## 6. Install Argo CD

Argo CD is installed inside the Kind Kubernetes cluster and will be used for GitOps-based continuous delivery.

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### Access Argo CD Locally

```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

```text
https://localhost:8080
```

Username:

```text
admin
```

---

# 🌐 NGINX Ingress Controller

## 7. Install NGINX Ingress Controller

NGINX Ingress Controller is being used to expose applications running inside the Kind Kubernetes cluster.

```powershell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
kubectl get ingress -A
```

---

# ⛵ Helm

## 8. Helm

Helm is installed on Windows and will be used as the Kubernetes package manager.

Verify Helm:

```powershell
helm version
```

Helm will be used to install and manage components such as Harbor and the monitoring stack, and later to package the sample application.

---

# 🔐 Trivy

## 9. Trivy

Trivy is installed and will be used for DevSecOps security scanning.

Verify Trivy:

```powershell
trivy --version
```

Planned Trivy usage includes:

- Filesystem vulnerability scanning
- Docker image vulnerability scanning
- Kubernetes/configuration scanning
- Jenkins security pipeline stages

---

# 🏗️ Current Architecture

The current environment is running locally on Windows:

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
                                   +-- Argo CD
                                   |
                                   +-- NGINX Ingress
                                   |
                                   +-- Helm
                                   |
                                   +-- Trivy
```

---

# 📊 Current Status

| Component | Status |
|---|---|
| Docker Desktop | ✅ Completed |
| Git | ✅ Installed |
| GitHub Repository | ✅ Created |
| Jenkins | ✅ Completed |
| SonarQube | ✅ Completed |
| Kind | ✅ Completed |
| Kubernetes | ✅ Running through Kind |
| Argo CD | ✅ Installed |
| Argo CD Local Access | ✅ Configured |
| NGINX Ingress Controller | ✅ Installed |
| Helm | ✅ Installed |
| Trivy | ✅ Installed |
| OWASP Dependency-Check | ⏳ Planned |
| Harbor | ⏳ Planned |
| Terraform | ⏳ Planned |
| Ansible | ⏳ Planned |
| Prometheus | ⏳ Planned |
| Grafana | ⏳ Planned |
| Loki | ⏳ Planned |
| Alertmanager | ⏳ Planned |
| OpenTelemetry | ⏳ Planned |

---

# 🧭 Planned Project Roadmap

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

### Phase 2 — Application

- [ ] Create sample application
- [ ] Add unit tests
- [ ] Create Dockerfile
- [ ] Build and run application locally

### Phase 3 — CI

- [ ] Connect GitHub to Jenkins
- [ ] Create Jenkinsfile
- [ ] Automated checkout
- [ ] Automated build
- [ ] Automated tests
- [ ] SonarQube integration
- [ ] Quality gate

### Phase 4 — DevSecOps

- [x] Install Trivy
- [ ] Trivy filesystem scanning in Jenkins
- [ ] Trivy container image scanning in Jenkins
- [ ] Trivy Kubernetes/configuration scanning
- [ ] OWASP Dependency-Check
- [ ] Security gates in Jenkins

### Phase 5 — Container Registry

- [ ] Install Harbor
- [ ] Configure Harbor project
- [ ] Push Docker images from Jenkins
- [ ] Image versioning
- [ ] Integrate Harbor with Kubernetes

### Phase 6 — Kubernetes

- [ ] Create namespace through Terraform
- [ ] Create Deployment
- [ ] Create Service
- [ ] Create Ingress
- [ ] Deploy application to Kind

### Phase 7 — Helm

- [x] Install Helm
- [ ] Create Helm chart
- [ ] Create values.yaml
- [ ] Template Kubernetes resources
- [ ] Deploy application using Helm
- [ ] Use Helm for platform components

### Phase 8 — Infrastructure as Code

- [ ] Install Terraform
- [ ] Configure Kubernetes provider
- [ ] Manage Kubernetes namespaces with Terraform
- [ ] Manage Services and application infrastructure with Terraform
- [ ] Integrate Terraform plan/apply with Jenkins
- [ ] Handle/import existing Kubernetes resources where required
- [ ] Introduce Terraform state management

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

Terraform will manage selected infrastructure/Kubernetes resources, with Jenkins executing the Terraform workflow where appropriate.

---

# 📚 Project Objectives

This project is intended to demonstrate practical knowledge of:

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

The focus is on building the environment practically, understanding how the tools integrate with each other, and documenting problems and solutions encountered along the way.

---

## 🚧 Project Status

**Currently in development.**

The local DevOps foundation is ready with Docker Desktop, Kind/Kubernetes, Jenkins, SonarQube, Argo CD, NGINX Ingress, Helm, and Trivy installed. The next milestone is to complete the remaining platform stack and then build the application and integrate the complete CI/CD and DevSecOps workflow.
