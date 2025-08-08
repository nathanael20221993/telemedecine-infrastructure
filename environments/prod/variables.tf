variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}

variable "db_password" {
  description = "Database password (leave empty for auto-generated)"
  type        = string
  default     = ""
  sensitive   = true
}
