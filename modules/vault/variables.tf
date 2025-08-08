variable "environment" {
  description = "Environment name"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  type        = string
}

variable "storage_class" {
  description = "Storage class for Vault PVCs"
  type        = string
  default     = "gp3"
}

variable "vault_storage_size" {
  description = "Storage size for Vault"
  type        = string
  default     = "10Gi"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
