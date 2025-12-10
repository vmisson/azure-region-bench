#!/bin/bash
# Script de déploiement du Dashboard de Latence Azure
# Usage: ./deploy.sh [resource-group] [location]

set -e

RESOURCE_GROUP="${1:-rg-latency-dashboard-001}"
LOCATION="${2:-westeurope}"
SWA_NAME="swa-latency-dashboard-001"
STORAGE_ACCOUNT="sanetprdfrc002"
STORAGE_RG="rg-net-prd-frc-001"
TABLE_NAME="region"

echo "=== Déploiement du Dashboard de Latence Azure ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Static Web App: $SWA_NAME"
echo ""

# Vérifier la connexion Azure
echo "1. Vérification de la connexion Azure..."
az account show > /dev/null 2>&1 || { echo "Erreur: Veuillez vous connecter avec 'az login'"; exit 1; }
echo "   ✓ Connecté à Azure"

# Créer le Resource Group
echo ""
echo "2. Création du Resource Group..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none
echo "   ✓ Resource Group créé"

# Créer la Static Web App
echo ""
echo "3. Création de la Static Web App..."
az staticwebapp create \
    --name "$SWA_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard \
    --output none 2>/dev/null || echo "   (Static Web App existe déjà)"
echo "   ✓ Static Web App créée"

# Activer l'identité managée
echo ""
echo "4. Configuration de l'identité managée..."
PRINCIPAL_ID=$(az staticwebapp show \
    --name "$SWA_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "identity.principalId" -o tsv 2>/dev/null || echo "")

if [ -z "$PRINCIPAL_ID" ] || [ "$PRINCIPAL_ID" == "null" ]; then
    echo "   Activation de l'identité système..."
    az staticwebapp identity assign \
        --name "$SWA_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --identities [system] \
        --output none
    
    PRINCIPAL_ID=$(az staticwebapp show \
        --name "$SWA_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "identity.principalId" -o tsv)
fi
echo "   ✓ Identité managée configurée (Principal ID: $PRINCIPAL_ID)"

# Assigner les permissions sur le Storage Account
echo ""
echo "5. Configuration des permissions Storage..."
STORAGE_ID=$(az storage account show \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$STORAGE_RG" \
    --query "id" -o tsv 2>/dev/null || echo "")

if [ -n "$STORAGE_ID" ]; then
    az role assignment create \
        --assignee "$PRINCIPAL_ID" \
        --role "Storage Table Data Reader" \
        --scope "$STORAGE_ID" \
        --output none 2>/dev/null || echo "   (Permission existe déjà)"
    echo "   ✓ Permissions Storage configurées"
else
    echo "   ⚠ Storage Account '$STORAGE_ACCOUNT' non trouvé, permissions à configurer manuellement"
fi

# Configurer les app settings
echo ""
echo "6. Configuration des paramètres d'application..."
az staticwebapp appsettings set \
    --name "$SWA_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --setting-names \
        STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT" \
        TABLE_NAME="$TABLE_NAME" \
    --output none
echo "   ✓ Paramètres configurés"

# Récupérer le token de déploiement
echo ""
echo "7. Récupération du token de déploiement..."
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
    --name "$SWA_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.apiKey" -o tsv)

# Récupérer l'URL
HOSTNAME=$(az staticwebapp show \
    --name "$SWA_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "defaultHostname" -o tsv)

echo ""
echo "=== Déploiement terminé ==="
echo ""
echo "URL du Dashboard: https://$HOSTNAME"
echo ""
echo "Pour déployer le code avec GitHub Actions:"
echo "1. Ajoutez ce secret dans votre repo GitHub:"
echo "   Nom: AZURE_STATIC_WEB_APPS_API_TOKEN"
echo "   Valeur: $DEPLOYMENT_TOKEN"
echo ""
echo "2. Poussez vos changements sur la branche 'master'"
echo ""
echo "Pour déployer manuellement avec SWA CLI:"
echo "   cd dashboard"
echo "   npx @azure/static-web-apps-cli deploy --deployment-token $DEPLOYMENT_TOKEN"
