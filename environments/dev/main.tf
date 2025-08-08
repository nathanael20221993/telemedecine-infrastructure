terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

# Configuration des providers K8s après la création du cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "telemedecine"
    ManagedBy   = "terraform"
    Team        = "platform-engineering"
    Compliance  = "rgpd-nis2"
  }

  config = {
    dev = {
      vpc_cidr = "10.0.0.0/16"
      availability_zones = ["eu-west-3a", "eu-west-3b"]
      enable_deletion_protection = false
      node_instance_type = "t3.medium"
      min_nodes = 1
      max_nodes = 3
      desired_nodes = 1
      db_instance_class = "db.t3.micro"
      multi_az = false
      backup_retention = 7
    }
    stage = {
      vpc_cidr = "10.1.0.0/16" 
      availability_zones = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
      enable_deletion_protection = false
      node_instance_type = "t3.medium"
      min_nodes = 2
      max_nodes = 5
      desired_nodes = 2
      db_instance_class = "db.t3.small"
      multi_az = false
      backup_retention = 14
    }
    preprod = {
      vpc_cidr = "10.2.0.0/16"
      availability_zones = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
      enable_deletion_protection = true
      node_instance_type = "t3.large"
      min_nodes = 2
      max_nodes = 8
      desired_nodes = 3
      db_instance_class = "db.t3.medium"
      multi_az = true
      backup_retention = 30
    }
    prod = {
      vpc_cidr = "10.10.0.0/16"
      availability_zones = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
      enable_deletion_protection = true
      node_instance_type = "t3.large"
      min_nodes = 3
      max_nodes = 12
      desired_nodes = 3
      db_instance_class = "db.t3.large"
      multi_az = true
      backup_retention = 30
    }
  }

  env_config = local.config[var.environment]

  public_subnet_cidrs = [
    for i, az in local.env_config.availability_zones :
    cidrsubnet(local.env_config.vpc_cidr, 8, i + 1)
  ]

  private_subnet_cidrs = [
    for i, az in local.env_config.availability_zones :
    cidrsubnet(local.env_config.vpc_cidr, 8, i + 10)
  ]

  database_subnet_cidrs = [
    for i, az in local.env_config.availability_zones :
    cidrsubnet(local.env_config.vpc_cidr, 8, i + 100)
  ]
}

module "vpc" {
  source = "../../modules/vpc"

  environment        = var.environment
  vpc_cidr          = local.env_config.vpc_cidr
  availability_zones = local.env_config.availability_zones
  
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
  database_subnet_cidrs = local.database_subnet_cidrs
  
  cluster_name = "${var.environment}-telemedecine-eks"
  common_tags  = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  environment   = var.environment
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  
  app_port            = 8080
  health_check_path   = "/health"
  certificate_arn     = var.certificate_arn
  enable_deletion_protection = local.env_config.enable_deletion_protection
  
  common_tags = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  
  cluster_name       = "${var.environment}-telemedecine-eks"
  kubernetes_version = "1.28"
  
  node_instance_type = local.env_config.node_instance_type
  min_nodes         = local.env_config.min_nodes
  max_nodes         = local.env_config.max_nodes
  desired_nodes     = local.env_config.desired_nodes
  
  enable_logging = var.environment != "dev"
  
  common_tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
  subnet_ids  = module.vpc.database_subnet_ids
  
  db_name           = "telemedecine"
  db_username       = "telemedecine_admin"
  db_password       = var.db_password
  db_instance_class = local.env_config.db_instance_class
  
  allocated_storage       = var.environment == "prod" ? 100 : 20
  max_allocated_storage   = var.environment == "prod" ? 1000 : 100
  backup_retention_period = local.env_config.backup_retention
  multi_az               = local.env_config.multi_az
  deletion_protection    = local.env_config.enable_deletion_protection
  
  common_tags = local.common_tags
}

# Data sources
data "aws_caller_identity" "current" {}

# Module Vault (optionnel pour dev)
module "vault" {
  count  = var.environment != "dev" ? 1 : 0
  source = "../../modules/vault"

  environment       = var.environment
  eks_cluster_name  = module.eks.cluster_name
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.oidc_issuer_url, "https://", "")}"
  oidc_issuer_url   = module.eks.oidc_issuer_url
  
  common_tags = local.common_tags

  depends_on = [module.eks]
}
