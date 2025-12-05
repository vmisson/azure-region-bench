#!/bin/bash

# Script de test de performance réseau entre régions Azure
# Les serveurs sont accessibles via <region>.region.local

set -e

# Liste des régions à tester
REGIONS=(
    "australiaeast"
    "belgiumcentral"
    "brazilsouth"
    "canadacentral"
    "centralindia"
    "centralus"
    "chilecentral"
    "eastasia"
    "eastus"
    "eastus2"
    "francecentral"
    "germanywestcentral"
    "indonesiacentral"
    "israelcentral"
    "italynorth"
    "japaneast"
    "japanwest"
    "koreacentral"
    "malaysiawest"
    "mexicocentral"
    "newzealandnorth"
    "northeurope"
    "norwayeast"
    "polandcentral"
    "qatarcentral"
    "southafricanorth"
    "southcentralus"
    "southeastasia"
    "spaincentral"
    "swedencentral"
    "switzerlandnorth"
    "uaenorth"
    "uksouth"
    "westeurope"
    "westus2"
    "westus3"
)

# Récupération du token d'accès Azure
get_access_token() {
    curl -s "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F" \
        -H "Metadata:true" | jq -r ".access_token"
}

# Région source (extraite du hostname ou passée en paramètre)
SOURCE_REGION="${1:-$(hostname | cut -d'.' -f1)}"

# URL de l'API Azure Table Storage
TABLE_URL="https://sanetprdfrc001.table.core.windows.net/perf"

# Récupération du token
echo "Récupération du token d'accès Azure..."
ACCESS_TOKEN=$(get_access_token)

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    echo "Erreur: Impossible de récupérer le token d'accès"
    exit 1
fi

echo "Token récupéré avec succès"
echo "Région source: $SOURCE_REGION"
echo ""

# Fonction pour exécuter les tests qperf et envoyer les résultats
run_test() {
    local dest_region=$1
    local server="${dest_region}.region.local"
    
    # Ne pas tester vers soi-même
    if [ "$dest_region" == "$SOURCE_REGION" ]; then
        echo "=== Skip $server (même région) ==="
        return
    fi
    
    echo "=== Test vers $server ==="
    
    # Test de bande passante
    #echo "  Test de bande passante..."
    #qperf "$server" -ub -t 10 tcp_bw > "${dest_region}_bw.txt" 2>/dev/null || true
    
    # Test de latence
    echo "  Test de latence..."
    qperf "$server" tcp_lat > "${dest_region}_lat.txt" 2>/dev/null || true
    
    # Extraction des résultats
    local uuid=$(uuidgen)
    #local bw=$(grep -o '[0-9.]\+ Gb/sec' "${dest_region}_bw.txt" 2>/dev/null || echo "")
    local lat=$(grep -oE '[0-9.]+ (us|ms)' "${dest_region}_lat.txt" 2>/dev/null || echo "")

    #echo "  Bande passante: $bw"
    echo "  Latence: $lat"

    # Envoi des résultats si la latence est valide
    if [ -n "$lat" ] && [ "$lat" != "0 us" ] && [ "$lat" != "0 ms" ]; then
        echo "  Envoi des résultats vers Azure Table Storage..."
        curl -s -X POST "$TABLE_URL" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "x-ms-version: 2020-04-08" \
            -H "Accept: application/json;odata=nometadata" \
            -H "Content-Type: application/json" \
            -d "{\"PartitionKey\":\"$uuid\",\"RowKey\":\"$SOURCE_REGION\", \"Source\":\"$SOURCE_REGION\", \"Destination\":\"$dest_region\", \"Latency\":\"$lat\"}"
        echo "  Résultats envoyés"
    else
        echo "  Latence invalide, résultats non envoyés"
    fi
    echo ""
}

# Exécution des tests pour chaque région
for region in "${REGIONS[@]}"; do
    run_test "$region"
done

echo "=== Tests terminés ==="
