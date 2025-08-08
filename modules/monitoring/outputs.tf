output "prometheus_url" {
  description = "Prometheus URL (port-forward required)"
  value       = "http://localhost:9090"
}

output "grafana_url" {
  description = "Grafana URL (port-forward required)"
  value       = "http://localhost:3000"
}

output "namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}
