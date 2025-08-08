resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
      environment = var.environment
    }
  }
}

# Prometheus via kube-prometheus-stack
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "55.5.0"

  values = [
    templatefile("${path.module}/prometheus-values.yaml", {
      environment = var.environment
      storage_class = var.storage_class
      prometheus_storage_size = var.prometheus_storage_size
      grafana_storage_size = var.grafana_storage_size
      retention_days = var.prometheus_retention
    })
  ]

  timeout = 600

  depends_on = [kubernetes_namespace.monitoring]
}

# Service Monitor pour notre application
resource "kubernetes_manifest" "app_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "telemedecine-app"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app = "telemedecine"
        environment = var.environment
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "telemedecine"
        }
      }
      endpoints = [
        {
          port = "metrics"
          path = "/metrics"
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus_stack]
}
