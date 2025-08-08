variable "environment" {
  description = "Environment name"
  type        = string
}

variable "storage_class" {
  description = "Storage class for monitoring components"
  type        = string
  default     = "gp3"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

variable "prometheus_retention" {
  description = "Prometheus retention period"
  type        = string
  default     = "15d"
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
