const { app } = require('@azure/functions');
const { TableClient } = require('@azure/data-tables');
const { ManagedIdentityCredential } = require('@azure/identity');

// Helper function to create table client
function createTableClient(tableName) {
    const storageAccountName = process.env.STORAGE_ACCOUNT_NAME || 'sanetprdfrc002';
    const tableUrl = `https://${storageAccountName}.table.core.windows.net`;
    
    // Use Managed Identity credential
    const credential = new ManagedIdentityCredential();
    return new TableClient(tableUrl, tableName, credential);
}

app.http('getLatencyData', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'latency',
    handler: async (request, context) => {
        try {
            const tableName = process.env.TABLE_NAME || 'region';
            const tableClient = createTableClient(tableName);

            const latencyData = [];
            
            // Query all entities from the table
            const entities = tableClient.listEntities();
            
            for await (const entity of entities) {
                latencyData.push({
                    partitionKey: entity.partitionKey,
                    rowKey: entity.rowKey,
                    source: entity.Source,
                    destination: entity.Destination,
                    latency: entity.Latency,
                    timestamp: entity.timestamp
                });
            }

            return {
                status: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify(latencyData)
            };
        } catch (error) {
            context.log('Error fetching latency data:', error);
            return {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({ error: error.message })
            };
        }
    }
});

app.http('getLatencyMatrix', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'latency/matrix',
    handler: async (request, context) => {
        try {
            const tableName = process.env.TABLE_NAME || 'region';
            const tableClient = createTableClient(tableName);

            const latencyMap = new Map();
            const regions = new Set();
            
            // Query all entities and build the latest latency matrix
            const entities = tableClient.listEntities();
            
            for await (const entity of entities) {
                const source = entity.Source;
                const destination = entity.Destination;
                const latency = entity.Latency;
                const timestamp = entity.timestamp;
                
                if (source && destination && latency) {
                    regions.add(source);
                    regions.add(destination);
                    
                    const key = `${source}->${destination}`;
                    const existing = latencyMap.get(key);
                    
                    if (!existing) {
                        // First measurement for this connection
                        latencyMap.set(key, {
                            source,
                            destination,
                            latency: parseLatency(latency),
                            latencyRaw: latency,
                            timestamp,
                            measurementCount: 1
                        });
                    } else {
                        // Increment measurement count
                        existing.measurementCount++;
                        // Keep only the latest measurement
                        if (new Date(timestamp) > new Date(existing.timestamp)) {
                            existing.latency = parseLatency(latency);
                            existing.latencyRaw = latency;
                            existing.timestamp = timestamp;
                        }
                    }
                }
            }

            return {
                status: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    regions: Array.from(regions).sort(),
                    connections: Array.from(latencyMap.values())
                })
            };
        } catch (error) {
            context.log('Error fetching latency matrix:', error);
            return {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({ error: error.message })
            };
        }
    }
});

// Helper function to parse latency value to milliseconds
function parseLatency(latencyStr) {
    if (!latencyStr) return null;
    
    const match = latencyStr.match(/([0-9.]+)\s*(us|ms)/);
    if (!match) return null;
    
    const value = parseFloat(match[1]);
    const unit = match[2];
    
    if (unit === 'us') {
        return value / 1000; // Convert microseconds to milliseconds
    }
    return value; // Already in milliseconds
}
