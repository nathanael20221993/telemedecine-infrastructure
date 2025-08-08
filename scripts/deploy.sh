#!/bin/bash
set -euo pipefail

ENVIRONMENT=${1:-""}
ACTION=${2:-"plan"}

show_help() {
    cat << EOF
Usage: $0 ENVIRONMENT ACTION

ENVIRONMENTS: dev, stage, preprod, prod
ACTIONS: plan, apply, destroy, output

Exemples:
  $0 dev plan
  $0 prod apply
  $0 stage destroy
EOF
}

if [[ -z "$ENVIRONMENT" ]]; then
    show_help
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|stage|preprod|prod)$ ]]; then
    echo "❌ Environnement invalide: $ENVIRONMENT"
    exit 1
fi

cd "environments/$ENVIRONMENT"

case $ACTION in
    "plan")
        echo "🔍 Plan Terraform pour $ENVIRONMENT..."
        terraform init
        terraform plan -var-file="terraform.tfvars"
        ;;
    "apply")
        echo "🚀 Déploiement de $ENVIRONMENT..."
        terraform init
        terraform plan -var-file="terraform.tfvars" -out=tfplan
        echo "Appliquer ce plan? (oui/non)"
        read -r confirmation
        if [[ "$confirmation" == "oui" ]]; then
            terraform apply tfplan
            rm -f tfplan
        else
            echo "Déploiement annulé"
            rm -f tfplan
        fi
        ;;
    "destroy")
        echo "🗑️  Destruction de $ENVIRONMENT..."
        if [[ "$ENVIRONMENT" == "prod" ]]; then
            echo "❌ Destruction de la production interdite"
            exit 1
        fi
        terraform destroy -var-file="terraform.tfvars"
        ;;
    "output")
        echo "📊 Outputs de $ENVIRONMENT..."
        terraform output
        ;;
    *)
        echo "❌ Action inconnue: $ACTION"
        show_help
        exit 1
        ;;
esac
