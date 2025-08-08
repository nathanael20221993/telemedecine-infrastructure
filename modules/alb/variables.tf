variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
