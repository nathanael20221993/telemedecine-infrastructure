#!/bin/bash
set -euo pipefail

KEEPASS_DB="$HOME/Documents/KeePass/Telemedecine-Credentials.kdbx"
BRANCH=${1:-"main"}

echo "🔐 Git push sécurisé avec KeePass"

# Vérification KeePassXC CLI
if ! command -v keepassxc-cli &> /dev/null; then
    echo "Installation KeePassXC CLI..."
    sudo apt install keepassxc-cli
fi

# Vérification base de données
if [[ ! -f "$KEEPASS_DB" ]]; then
    echo "❌ Base KeePass introuvable: $KEEPASS_DB"
    echo "💡 Créez-la d'abord avec KeePassXC GUI"
    exit 1
fi

echo "📋 Mot de passe maître KeePass:"
read -s MASTER_PASSWORD

# Extraction du token GitHub
echo "🔄 Extraction du token GitHub..."
GITHUB_TOKEN=$(echo "$MASTER_PASSWORD" | keepassxc-cli show -q "$KEEPASS_DB" "GitHub - Repositories/GitHub Personal Access Token" -a password 2>/dev/null || echo "")

if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "❌ Token GitHub non trouvé dans KeePass"
    echo "💡 Vérifiez le chemin: 'GitHub - Repositories/GitHub Personal Access Token'"
    exit 1
fi

# Configuration temporaire Git avec le token
git remote set-url origin "https://nathanael20221993:$GITHUB_TOKEN@github.com/nathanael20221993/telemedecine-infrastructure.git"

echo "🚀 Push vers la branche $BRANCH..."
git push origin "$BRANCH"

# Nettoyage: remet l'URL originale pour la sécurité
git remote set-url origin "https://github.com/nathanael20221993/telemedecine-infrastructure.git"

echo "✅ Push réussi !"
echo "🔒 URL repository nettoyée"

# Nettoyage variables
unset MASTER_PASSWORD
unset GITHUB_TOKEN
