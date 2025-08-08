#!/bin/bash
set -euo pipefail

ENVIRONMENT=${1:-"dev"}
ACTION=${2:-"plan"}
KEEPASS_DB="$HOME/Documents/KeePass/Telemedecine-Credentials.kdbx"

echo "🏥 Terraform avec KeePass - $ENVIRONMENT"

if [[ ! -f "$KEEPASS_DB" ]]; then
    echo "❌ Base KeePass introuvable"
    exit 1
fi

echo "🔐 Mot de passe maître KeePass:"
read -s MASTER_PASSWORD

# Chargement des credentials AWS
echo "🔄 Chargement des credentials..."
AWS_ACCESS_KEY=$(echo "$MASTER_PASSWORD" | keepassxc-cli show -q "$KEEPASS_DB" "AWS - Télémédecine/AWS Terraform User" -a username 2>/dev/null || echo "")
AWS_SECRET_KEY=$(echo "$MASTER_PASSWORD" | keepassxc-cli show -q "$KEEPASS_DB" "AWS - Télémédecine/AWS Terraform User" -a password 2>/dev/null || echo "")

if [[ -z "$AWS_ACCESS_KEY" || -z "$AWS_SECRET_KEY" ]]; then
    echo "❌ Credentials AWS manquants dans KeePass"
    exit 1
fi

# Export des variables
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
export AWS_DEFAULT_REGION="eu-west-3"
export TF_VAR_db_password="DefaultPassword123!"

echo "✅ Credentials chargés"

# Exécution Terraform
cd "environments/$ENVIRONMENT"
terraform init
terraform $ACTION -var-file="terraform.tfvars"

# Nettoyage
unset MASTER_PASSWORD AWS_ACCESS_KEY AWS_SECRET_KEY AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
