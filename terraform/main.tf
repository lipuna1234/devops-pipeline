resource "kubernetes_namespace" "devops" {
  metadata {
    name = "devops"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "devops-app"
    namespace = kubernetes_namespace.devops.metadata[0].name
    labels = {
      app = "devops-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "devops-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "devops-app"
        }
      }

      spec {
        container {
          name  = "devops-app"
          image = var.app_image

          port {
            container_port = 5000
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "devops-app-service"
    namespace = kubernetes_namespace.devops.metadata[0].name
  }

  spec {
    selector = {
      app = "devops-app"
    }

    port {
      port        = 80
      target_port = 5000
    }

    type = "ClusterIP"
  }
}
