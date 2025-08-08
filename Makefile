.PHONY: help dev stage preprod prod validate clean init

help:
	@echo "🚀 Infrastructure Télémédecine - Terraform"
	@echo ""
	@echo "📋 COMMANDES PRINCIPALES:"
	@echo "  make dev         - Plan pour DEV"
	@echo "  make dev-apply   - Déploie DEV"
	@echo "  make stage       - Plan pour STAGE"  
	@echo "  make stage-apply - Déploie STAGEake preprod     - Plan pour PREPROD"
	@echo "  make preprod-apply - Déploie PREPROD"
	@echo "  make prod        - Plan pour PROD"
	@echo "  make prod-apply  - Déploie PROD"
	@echo ""
	@echo "🔧 COMMANDES UTILITAIRES:"
	@echo "  make validate ENV=dev    - Valide la configuration"
	@echo "  make init ENV=dev        - Initialise Terraform"
	@echo "  make clean              - Nettoie les fichiers temporaires"
	@echo "  make status             - Affiche le statut de tous les environnements"
	@echo ""
	@echo 📊 POST-DÉPLOIEMENT:"
	@echo "  make kubectl ENV=dev    - Configure kubectl"
	@echo "  make grafana ENV=dev    - Port-forward Grafana"
	@echo "  make prometheus ENV=dev - Port-forward Prometheus"

# Plans
dev:
	@./scripts/deploy.sh dev plan

stage:
	@./scripts/deploy.sh stage plan

preprod:
	@./scripts/deploy.sh preprod plan

prod:
	@./scripts/deploy.sh prod plan

# Déploiements
dev-apply:
	@./scripts/deploy.sh dev apply

stage-apply:
	@./scripts/deploy.sh stage apply

preprod-apply:
	@./scripts/deploy.reprod apply

prod-apply:
	@echo "⚠️  DÉPLOIEMENT PRODUCTION ⚠️"
	@echo "Êtes-vous sûr de vouloir déployer en production? (oui/non)"
	@read confirmation && [ "$confirmation" = "oui" ] && ./scripts/deploy.sh prod apply || echo "Déploiement annulé"

# Utilitaires
validate:
	@./scripts/deploy.sh $(ENV) validate

init:
	@cd environments/$(ENV) && terraform init

clean:
	@find . -name "*.tfplan" -delete
	@find . -name ".terraform.lock.hcl" -delete
	@find . -type d -name ".terraform" -exec rm -rf {} || true
	@echo "🧹 Fichiers temporaires supprimés"

status:
	@echo "📊 Statut des environnements:"
	@for env in dev stage preprod prod; do \
		echo ""; \
		echo "🎯 $env:"; \
		if [ -f "environments/$env/terraform.tfstate" ]; then \
			echo "  ✅ Déployé"; \
		else \
			echo "  ❌ Non déployé"; \
		fi; \
	done

# Post-déploiement
kubectl:
	@aws eks update-kubeconfig --region eu-west-3 --name $(ENV)-telemedecine-eks
	@echo "✅ kubectl configuré pour $(ENV)"

grafana:
	@echo "🔓 Mot de passfana:"
	@kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode && echo
	@echo "🌐 Ouverture de Grafana sur http://localhost:3000"
	@kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

prometheus:
	@echo "🌐 Ouverture de Prometheus sur http://localhost:9090"
	@kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
