variable "kubeconfig_path" {
  description = "Path to kubeconfig used by Terraform"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context used by Terraform"
  type        = string
  default     = "kind-devops"
}

variable "namespace" {
  description = "Existing Kubernetes namespace in which the application is deployed"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "app_image" {
  description = "Container image to deploy"
  type        = string
}

variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 5000
}

variable "service_port" {
  description = "Kubernetes Service port"
  type        = number
  default     = 80
}

variable "config" {
  description = "Environment-specific ConfigMap values"
  type        = map(string)
  default     = {}
}
