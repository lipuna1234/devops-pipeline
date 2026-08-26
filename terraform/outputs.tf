output "namespace" {
  value = kubernetes_namespace.devops.metadata[0].name
}

output "service" {
  value = kubernetes_service.app.metadata[0].name
}
