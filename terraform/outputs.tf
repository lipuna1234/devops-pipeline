output "namespace" {
  value = data.kubernetes_namespace.target.metadata[0].name
}

output "deployment" {
  value = kubernetes_deployment.app.metadata[0].name
}

output "service" {
  value = kubernetes_service.app.metadata[0].name
}

output "configmap" {
  value = kubernetes_config_map.app.metadata[0].name
}
