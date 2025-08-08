# 🏥 Infrastructure Télémédecine - Terraform

## 📋 Vue d'ensemble

Infrastructure AWS complète pour application de télémédecine avec:
- ✅ **4 environnements** (dev, stage, preprod, prod)
- ✅ **Modules Terraform réutilisables** (VPC, ALB, EKS, RDS, Vault)
- ✅ **Haute disponibilité** (99.9% uptime)
- âmité RGPD et NIS2**
- ✅ **Monitoring complet** (Prometheus/Grafana)
- ✅ **Sécurité renforcée** (Vault, WAF, chiffrement)

## 🏗️ Architecture

```
Internet → ALB (WAF) → EKS Cluster → Application
                  ↓         ↓
              CloudWatch   RDS PostgreSQL (Multi-AZ)
                  ↓         ↓
            Prometheus ← → Grafana
                  ↓
              HashiCorp Vault
```

## 🚀 Déploiement Rapide

### Prérequis
```bash
# Installation des outils ris
aws configure
terraform --version  # >= 1.5
kubectl version
helm version
```

### Configuration SSL (OBLIGATOIRE)
```bash
# 1. Créez un certificat dans AWS Certificate Manager
# 2. Copiez l'ARN du certificat
# 3. Modifiez les fichiers terraform.tfvars:

nano environments/dev/terraform.tfvars
# Remplacez: certificate_arn = "arn:aws:acm:eu-west-3:YOUR_ACCOUNT:certificate/YOUR_CERT"
```

### Déploiement DEV
```bash
# Configuration des secrets
export TF_VAR_db_password="SecurePassword123!"

# Déploiememake dev        # Plan
make dev-apply  # Déploie
```

### Configuration Post-Déploiement
```bash
# Configuration kubectl
make kubectl ENV=dev

# Accès à Grafana
make grafana ENV=dev
# Login: admin / [mot de passe affiché]

# Accès à Prometheus  
make prometheus ENV=dev
```

## 📁 Structure Modulaire

```
modules/                    # 🎯 Modules réutilisables
├── vpc/                   # Réseau multi-AZ avec NAT gateways
├── alb/                   # Load Balancer + WAF + SSL
├─â         # Kubernetes cluster + nodes
├── rds/                   # PostgreSQL haute disponibilité
├── vault/                 # HashiCorp Vault pour secrets
├── monitoring/            # Prometheus + Grafana stack
└── telemedecine-app/      # Déploiement application

environments/              # 🌍 Configuration par environnement
├── dev/     (10.0.0.0/16)    # Développement - 1-3 nodes
├── stage/   (10.1.0.0/16)    # Tests intégration - 2-5 nodes
├── preprod/ (10.2.0.0/16)    # Pré-production - 2-8 nodes
└── prod/    (10.10.0.0/16)   # Production - 3-12 nodes
```

## 🎯 Commandes Essentielles

### Déploiement
```bash
# Plans rapides
make dev stage preprod prod

# Déploiements
make dev-apply      # DEV
make stage-apply    # STAGE
make preprod-apply  # PREPROD
make prod-apply     # PROD (avec confirmation)

# Scripts avancés
./scripts/deploy.sh prod plan
./scripts/deploy.sh dev apply
```

### Monitoring & Debug
```bash
# Status de tous les environnemenatus

# Configuration kubectl
make kubectl ENV=prod

# Accès aux dashboards
make grafana ENV=prod      # Port 3000
make prometheus ENV=prod   # Port 9090

# Nettoyage
make clean
```

## 🔐 Sécurité et Conformité

### 🛡️ Sécurité Implémentée
- **Chiffrement**: TLS 1.3, KMS encryption, RDS chiffré
- **WAF**: Protection SQL injection, XSS, DDoS
- **Network Security**: VPC isolés, Security Groups stricts
- **Secrets Management**: HashiCorp Vault, AWS SSM
- **RBAC**: Kubernetes Role-Based Access Control

### 📜 Conformité RGPD/NIS2
- **Audit Logs**: CloudWatch, CloudTrail activés
- **Data Retention**: Automatique selon l'environnement
- **Right to be Forgotten**: Processus automatisé
- **Incident Response**: Alertes temps réel
- **Géolocalisation**: Données en France (eu-west-3)

## 📊 Monitoring & Alertes

### Métriques Collectées
- **Application**: Latence, erreurs, throughput
- **Infrastructure**: CPU, mémoire, stockage
- **Base de données**: Connexions, performance
- **Sécurives d'intrusion, accès

### Dashboards Grafana
- **Vue d'ensemble**: Santé globale du système
- **Application**: Métriques business et techniques
- **Infrastructure**: Ressources Kubernetes et AWS
- **Sécurité**: Logs d'audit et alertes

## 🎛️ Configuration par Environnement

| Environment | VPC CIDR     | Nodes    | Instance   | Multi-AZ | WAF | Vault |
|-------------|--------------|----------|------------|----------|-----|-------|
| **DEV**     | 10.0.0.0/16  | 1-3      | t3.medium  | ❌   | ❌    |
| **STAGE**   | 10.1.0.0/16  | 2-5      | t3.medium  | ❌       | ✅   | ✅    |
| **PREPROD** | 10.2.0.0/16  | 2-8      | t3.large   | ✅       | ✅   | ✅    |
| **PROD**    | 10.10.0.0/16 | 3-12     | t3.large   | ✅       | ✅   | ✅    |

## 🆘 Troubleshooting

### Erreurs Communes
```bash
# Certificat SSL manquant
# Solution: Créer certificat dans ACM et mettre à jour terraform.tfvars

# Kubectl non configuré
make kubectl ENV=dev

# Terraform state locks
# Solution: LibÃdans DynamoDB

# Modules non trouvés
terraform init -upgrade
```

### Support
- **Documentation**: `docs/architecture.md`
- **Logs**: `kubectl logs -n telemedecine deployment/telemedecine-app`
- **Métriques**: Grafana dashboard
- **Équipe**: platform-team@healthcare.fr

## 📈 Évolutions Prévues

- [ ] **CI/CD Pipeline**: GitHub Actions pour déploiements
- [ ] **Service Mesh**: Istio pour micro-services
- [ ] **Backup Strategy**: Velero pour Kubernetes
- [ ] **Cost Optimization**: Spot instances, auown
- [ ] **Multi-Region**: Disaster recovery setup

---

🎯 **Architecture prête pour la production avec 99.9% de disponibilité garantie**
