# Azure Region Latency Dashboard

An interactive visualization application that displays network latency between different Azure regions on a world map.

## Architecture

```
dashboard/
├── api/                      # Azure Functions API (Node.js)
│   ├── src/functions/
│   │   └── latency.js       # Endpoints for retrieving latency data
│   ├── host.json
│   ├── local.settings.json
│   └── package.json
└── www/                      # Static frontend
    ├── index.html           # Main page with Leaflet map
    ├── app.js               # Application logic
    ├── regions.js           # Azure region coordinates
    └── staticwebapp.config.json
```

## Features

- 🗺️ **Interactive map**: Visualization of Azure regions on a world map
- 📊 **Real-time data**: Retrieval of latency measurements from Azure Table Storage
- 🎨 **Color coding**: Connections are colored based on latency (green = excellent, red = high)
- 📋 **Sorted list**: Display of latencies to each region, sorted by performance
- 📈 **Statistics**: Overview of metrics (number of regions, connections, average latency)

## Prerequisites

- [Node.js](https://nodejs.org/) 18.x or higher
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local) v4
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (for deployment)
- An Azure account with access to the Storage Account containing latency data

## Local Installation

### 1. Install API dependencies

```bash
cd dashboard/api
npm install
```

### 2. Configure environment variables

Edit `dashboard/api/local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "STORAGE_ACCOUNT_NAME": "your-storage-account",
    "TABLE_NAME": "region"
  }
}
```

### 3. Authenticate with Azure

```bash
az login
```

### 4. Run the API locally

```bash
cd dashboard/api
func start
```

The API will be available at `http://localhost:7071/api/`

### 5. Serve the frontend

In another terminal, serve the static files:

```bash
cd dashboard/www
# With Python
python -m http.server 8080
# Or with Node.js
npx serve -l 8080
```

Open `http://localhost:8080` in your browser.

## API Endpoints

### GET /api/latency

Returns all raw latency measurements.

**Response:**
```json
[
  {
    "partitionKey": "...",
    "rowKey": "...",
    "source": "francecentral",
    "destination": "westeurope",
    "latency": "12.5 ms",
    "timestamp": "2024-01-15T10:30:00Z"
  }
]
```

### GET /api/latency/matrix

Returns the latency matrix with only the latest measurements.

**Response:**
```json
{
  "regions": ["eastus", "westeurope", "francecentral", ...],
  "connections": [
    {
      "source": "francecentral",
      "destination": "westeurope",
      "latency": 12.5,
      "latencyRaw": "12.5 ms",
      "timestamp": "2024-01-15T10:30:00Z"
    }
  ]
}
```

## Deployment on Azure Static Web Apps

### 1. Create a Static Web App

```bash
az staticwebapp create \
  --name "latency-dashboard" \
  --resource-group "your-rg" \
  --location "westeurope" \
  --source "." \
  --app-location "dashboard/www" \
  --api-location "dashboard/api" \
  --output-location ""
```

### 2. Configure environment variables

In the Azure portal or via CLI:

```bash
az staticwebapp appsettings set \
  --name "latency-dashboard" \
  --setting-names \
    STORAGE_ACCOUNT_NAME="your-storage-account" \
    TABLE_NAME="region"
```

### 3. Configure Storage Account access

The API uses `DefaultAzureCredential` which supports:
- Managed Identity (recommended for production)
- Azure CLI credentials (local development)

Assign the "Storage Table Data Reader" role to the Static Web App identity:

```bash
az role assignment create \
  --assignee "<static-web-app-principal-id>" \
  --role "Storage Table Data Reader" \
  --scope "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-account>"
```

## Data Structure

Latency data is stored in Azure Table Storage with the following schema:

| Column | Type | Description |
|--------|------|-------------|
| PartitionKey | String | Unique UUID of the measurement |
| RowKey | String | Source region |
| Source | String | Name of the source region |
| Destination | String | Name of the destination region |
| Latency | String | Latency value (e.g., "12.5 ms") |

## Color Legend

| Color | Latency | Description |
|-------|---------|-------------|
| 🟢 Green | < 10 ms | Excellent |
| 🟡 Yellow-green | 10-30 ms | Good |
| 🟠 Yellow | 30-80 ms | Medium |
| 🔴 Orange | 80-150 ms | High |
| ⭕ Red | > 150 ms | Very high |

## Technologies Used

- **Frontend**: HTML5, CSS3, vanilla JavaScript
- **Map**: [Leaflet.js](https://leafletjs.com/)
- **Backend**: Azure Functions v4 (Node.js)
- **Storage**: Azure Table Storage
- **Auth**: Azure Identity (DefaultAzureCredential)

