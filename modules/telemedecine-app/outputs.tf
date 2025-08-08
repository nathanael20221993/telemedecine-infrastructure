output "namespace" {
  description = "Application namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "service_name" {
  description = "Service name"
  value       = kubernetes_service.app.metadata[0].name
}

output "app_url" {
  description = "Application URL (internal)"
  value       = "http://${kubernetes_service.app.metadata[0].name}.${kubernetes_namespace.app.metadata[0].name}.svc.cluster.local"
}
