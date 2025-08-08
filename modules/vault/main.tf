# Ce module sera déployé sur EKS via Helm
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      name = "vault"
      environment = var.environment
    }
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  version    = "0.27.0"

  values = [
    templatefile("${path.module}/vault-values.yaml", {
      environment = var.environment
      storage_class = var.storage_class
      vault_storage_size = var.vault_storage_size
    })
  ]

  depends_on = [kubernetes_namespace.vault]
}

# Service Account pour Vault avec IRSA
resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace.vault.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.vault_irsa.arn
    }
  }
}

# IAM Role pour Vault IRSA
resource "aws_iam_role" "vault_irsa" {
  name = "${var.environment}-vault-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:vault:vault"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# Policy pour Vault (accès KMS et S3)
resource "aws_iam_role_policy" "vault_policy" {
  name = "${var.environment}-vault-policy"
  role = aws_iam_role.vault_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.vault.arn
      }
    ]
  })
}

# KMS Key pour Vault auto-unseal
resource "aws_kms_key" "vault" {
  description             = "Vault unseal key for ${var.environment}"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.environment}-vault-unseal"
  })
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.environment}-vault-unseal"
  target_key_id = aws_kms_key.vault.key_id
}
