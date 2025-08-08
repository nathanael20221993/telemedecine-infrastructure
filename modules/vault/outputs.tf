output "vault_endpoint" {
  description = "Vault endpoint URL"
  value       = "https://vault.${var.environment}.local"
}

output "vault_namespace" {
  description = "Vault namespace"
  value       = kubernetes_namespace.vault.metadata[0].name
}

output "kms_key_arn" {
  description = "KMS key ARN for Vault"
  value       = aws_kms_key.vault.arn
}
