resource "kubernetes_namespace" "app" {
  metadata {
    name = "telemedecine"
    labels = {
      name = "telemedecine"
      environment = var.environment
    }
  }
}

# Secret pour la base de données
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentiamespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    host     = var.db_host
    port     = "5432"
    database = var.db_name
    username = var.db_username
    password = var.db_password
  }

  type = "Opaque"
}

# ConfigMap pour la configuration de l'application
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "telemedecine-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
    METRICS_ENABLED = "true"
    METRICS_PORT    = "9090"
  }
}

# Deployment de l'application
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "telemedecine-app"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "telemedecine"
      environment = var.environment
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "telemedecine"
      }
    }

    template {
      metadata {
        labels = {
          app = "telemedecine"
          environment = var.environment
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9090"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        container {
          name  = "telemedecine"
          image = var.app_image

          port {
            name           = "http"
            container_port = 8080
          }

          port {
            name           = "metrics"
            container_port = 9090
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name = "DB_HOST"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "host"
              }
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "password"
              }
            }
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            run_as_user                = 1001
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        security_context {
          fs_group = 1001
        }
      }
    }
  }
}

# Service pour exposer l'application
resource "kubernetes_service" "app" {
  metadata {
    name      = "telemedecine-service"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "telemedecine"
    }
  }

  spec {
    selector = {
      app = "telemedecine"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "metrics"
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# HPA pour l'auto-scaling
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = "telemedecine-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.target_cpu_utilization
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}
