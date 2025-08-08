output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = module.vpc.vpc_cidr
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "vault_endpoint" {
  description = "Vault endpoint"
  value       = var.environment != "dev" ? module.vault[0].vault_endpoint : null
}

output "environment_summary" {
  description = "Environment configuration summary"
  value = {
    environment    = var.environment
    vpc_cidr      = module.vpc.vpc_cidr
    alb_dns       = module.alb.alb_dns_name
    eks_cluster   = module.eks.cluster_name
    db_endpoint   = module.rds.db_endpoint
    nodes_config  = "${local.env_config.min_nodes}-${local.env_config.max_nodes} ${local.env_config.node_instance_type}"
    db_config     = "${local.env_config.db_instance_class} (Multi-AZ: ${local.env_config.multi_az})"
    vault_enabled = var.environment != "dev"
  }
}
