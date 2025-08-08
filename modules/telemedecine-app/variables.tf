variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_image" {
  description = "Docker image for the telemedecine application"
  type        = string
  default     = "nginx:latest"  # Placeholder
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 2
}

variable "min_replicas" {
  description = "Minimum replicas for HPA"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum replicas for HPA"
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for HPA"
  type        = number
  default     = 70
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "250m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

# Database connection
variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
