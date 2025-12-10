#!/bin/bash
# Script de déploiement de l'API sur Azure Functions (standalone)
# Usage: ./deploy-function.sh [resource-group] [location]

set -e

RESOURCE_GROUP="${1:-rg-latency-dashboard-001}"
LOCATION="${2:-westeurope}"
FUNCTION_APP_NAME="func-latency-api-001"
STORAGE_ACCOUNT="sanetprdfrc002"
STORAGE_RG="rg-net-prd-frc-001"
TABLE_NAME="region"

echo "=== Déploiement de l'API Azure Functions ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Function App: $FUNCTION_APP_NAME"
echo ""

# Créer un storage account pour la Function App
FUNC_STORAGE="stlatencyapi001"
echo "1. Création du Storage Account pour la Function App..."
az storage account create \
    --name "$FUNC_STORAGE" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --output none 2>/dev/null || echo "   (Storage existe déjà)"
echo "   ✓ Storage Account créé"

# Créer la Function App
echo ""
echo "2. Création de la Function App..."
az functionapp create \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --storage-account "$FUNC_STORAGE" \
    --consumption-plan-location "$LOCATION" \
    --runtime node \
    --runtime-version 20 \
    --functions-version 4 \
    --output none 2>/dev/null || echo "   (Function App existe déjà)"
echo "   ✓ Function App créée"

# Activer l'identité managée
echo ""
echo "3. Configuration de l'identité managée..."
PRINCIPAL_ID=$(az functionapp identity assign \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "principalId" -o tsv)
echo "   ✓ Identité managée: $PRINCIPAL_ID"

# Assigner les permissions sur le Storage Account source
echo ""
echo "4. Configuration des permissions Storage..."
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
fi

# Configurer les app settings
echo ""
echo "5. Configuration des paramètres..."
az functionapp config appsettings set \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings \
        STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT" \
        TABLE_NAME="$TABLE_NAME" \
    --output none
echo "   ✓ Paramètres configurés"

# Configurer CORS
echo ""
echo "6. Configuration CORS..."
az functionapp cors add \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --allowed-origins "https://witty-pebble-0725fa703.3.azurestaticapps.net" "*" \
    --output none 2>/dev/null || true
echo "   ✓ CORS configuré"

# Déployer le code
echo ""
echo "7. Déploiement du code..."
cd "$(dirname "$0")/api"
func azure functionapp publish "$FUNCTION_APP_NAME" --javascript
echo "   ✓ Code déployé"

# Récupérer l'URL
FUNC_URL=$(az functionapp show \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "defaultHostName" -o tsv)

echo ""
echo "=== Déploiement terminé ==="
echo "URL de l'API: https://$FUNC_URL/api/"
echo ""
echo "Mettez à jour le frontend pour utiliser cette URL:"
echo "  apiBaseUrl = 'https://$FUNC_URL/api'"
