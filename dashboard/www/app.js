// Azure Region Latency Map Application
class LatencyMapApp {
    constructor() {
        this.map = null;
        this.markers = {};
        this.polylines = [];
        this.latencyData = null;
        this.selectedRegion = null;
        this.apiBaseUrl = 'https://func-latency-api-001.azurewebsites.net/api';
        
        this.init();
    }

    async init() {
        this.updateProgress(0, 'Initializing map...');
        this.initMap();
        
        this.updateProgress(20, 'Loading region markers...');
        this.initRegionMarkers();
        
        this.updateProgress(40, 'Setting up controls...');
        this.bindEvents();
        
        this.updateProgress(50, 'Fetching latency data...');
        await this.loadLatencyData();
        
        this.updateProgress(100, 'Complete!');
        await this.delay(300);
        this.hideLoading();
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    updateProgress(percent, text) {
        const progressBar = document.getElementById('progressBar');
        const loadingText = document.getElementById('loadingText');
        const loadingPercent = document.getElementById('loadingPercent');
        
        if (progressBar) progressBar.style.width = `${percent}%`;
        if (loadingText) loadingText.textContent = text;
        if (loadingPercent) loadingPercent.textContent = `${percent}%`;
    }

    initMap() {
        // Initialize the map centered on the world
        this.map = L.map('map', {
            center: [20, 0],
            zoom: 2,
            minZoom: 2,
            maxZoom: 8,
            worldCopyJump: true
        });

        // Add dark theme tile layer
        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
            subdomains: 'abcd',
            maxZoom: 19
        }).addTo(this.map);
    }

    initRegionMarkers() {
        // Create markers for each Azure region
        Object.entries(AZURE_REGIONS).forEach(([regionId, region]) => {
            const marker = L.circleMarker(region.coordinates, {
                radius: 8,
                fillColor: '#0078d4',
                color: '#ffffff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            });

            marker.bindTooltip(region.displayName, {
                permanent: false,
                direction: 'top',
                offset: [0, -10]
            });

            marker.on('click', () => this.selectRegion(regionId));
            marker.addTo(this.map);
            
            this.markers[regionId] = marker;
        });
    }

    bindEvents() {
        const sourceSelect = document.getElementById('sourceRegion');
        
        // Populate the region dropdown
        Object.entries(AZURE_REGIONS)
            .sort((a, b) => a[1].displayName.localeCompare(b[1].displayName))
            .forEach(([regionId, region]) => {
                const option = document.createElement('option');
                option.value = regionId;
                option.textContent = region.displayName;
                sourceSelect.appendChild(option);
            });

        sourceSelect.addEventListener('change', (e) => {
            this.selectRegion(e.target.value);
        });
    }

    async loadLatencyData() {
        try {
            this.updateProgress(55, 'Connecting to API...');
            // Fetch raw latency data (all measurements)
            const response = await fetch(`${this.apiBaseUrl}/latency`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            this.updateProgress(70, 'Downloading latency data...');
            const rawData = await response.json();
            
            this.updateProgress(85, 'Processing data...');
            // Aggregate the data: keep latest measurement and count per connection
            this.latencyData = this.aggregateLatencyData(rawData);
            
            this.updateProgress(95, 'Updating statistics...');
            this.updateStats();
        } catch (error) {
            console.error('Error loading latency data:', error);
            this.updateProgress(80, 'Using demo data...');
            // Use demo data if API is not available
            this.latencyData = this.generateDemoData();
            this.updateStats();
        }
    }

    aggregateLatencyData(rawData) {
        const latencyMap = new Map();
        const regions = new Set();

        rawData.forEach(entity => {
            const source = entity.source;
            const destination = entity.destination;
            const latencyRaw = entity.latency;
            const timestamp = entity.timestamp;

            if (source && destination && latencyRaw) {
                regions.add(source);
                regions.add(destination);

                const key = `${source}->${destination}`;
                const existing = latencyMap.get(key);
                const latency = this.parseLatency(latencyRaw);

                if (!existing) {
                    // First measurement for this connection
                    latencyMap.set(key, {
                        source,
                        destination,
                        latency,
                        latencyRaw,
                        timestamp,
                        measurementCount: 1
                    });
                } else {
                    // Increment measurement count
                    existing.measurementCount++;
                    // Keep only the latest measurement
                    if (new Date(timestamp) > new Date(existing.timestamp)) {
                        existing.latency = latency;
                        existing.latencyRaw = latencyRaw;
                        existing.timestamp = timestamp;
                    }
                }
            }
        });

        return {
            regions: Array.from(regions).sort(),
            connections: Array.from(latencyMap.values())
        };
    }

    parseLatency(latencyStr) {
        if (!latencyStr) return null;
        
        const match = latencyStr.match(/([0-9.]+)\s*(us|ms)/);
        if (!match) {
            // Try parsing as plain number
            const num = parseFloat(latencyStr);
            return isNaN(num) ? null : num;
        }
        
        const value = parseFloat(match[1]);
        const unit = match[2];
        
        if (unit === 'us') {
            return value / 1000; // Convert microseconds to milliseconds
        }
        return value; // Already in milliseconds
    }

    generateDemoData() {
        // Generate demo data for testing when API is not available
        const regions = Object.keys(AZURE_REGIONS);
        const connections = [];

        regions.forEach(source => {
            regions.forEach(destination => {
                if (source !== destination) {
                    // Calculate approximate latency based on distance
                    const sourceCoords = AZURE_REGIONS[source].coordinates;
                    const destCoords = AZURE_REGIONS[destination].coordinates;
                    const distance = this.calculateDistance(
                        sourceCoords[0], sourceCoords[1],
                        destCoords[0], destCoords[1]
                    );
                    
                    // Approximate latency: ~1ms per 100km + some randomness
                    const latency = (distance / 100) + (Math.random() * 10);
                    
                    connections.push({
                        source,
                        destination,
                        latency: Math.round(latency * 100) / 100,
                        latencyRaw: `${Math.round(latency * 100) / 100} ms`,
                        timestamp: new Date().toISOString()
                    });
                }
            });
        });

        return {
            regions,
            connections
        };
    }

    calculateDistance(lat1, lon1, lat2, lon2) {
        // Haversine formula to calculate distance in km
        const R = 6371;
        const dLat = this.toRad(lat2 - lat1);
        const dLon = this.toRad(lon2 - lon1);
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                  Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) *
                  Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    toRad(deg) {
        return deg * (Math.PI / 180);
    }

    updateStats() {
        if (!this.latencyData) return;

        const regionsCount = this.latencyData.regions ? this.latencyData.regions.length : Object.keys(AZURE_REGIONS).length;
        const connectionsCount = this.latencyData.connections ? this.latencyData.connections.length : 0;
        
        let avgLatency = 0;
        if (this.latencyData.connections && this.latencyData.connections.length > 0) {
            const totalLatency = this.latencyData.connections.reduce((sum, conn) => sum + (conn.latency || 0), 0);
            avgLatency = totalLatency / this.latencyData.connections.length;
        }

        document.getElementById('statRegions').textContent = regionsCount;
        document.getElementById('statConnections').textContent = connectionsCount;
        document.getElementById('statAvgLatency').textContent = `${avgLatency.toFixed(2)} ms`;
    }

    selectRegion(regionId) {
        if (!regionId) {
            this.clearSelection();
            return;
        }

        this.selectedRegion = regionId;
        
        // Update dropdown
        document.getElementById('sourceRegion').value = regionId;

        // Reset all markers
        Object.entries(this.markers).forEach(([id, marker]) => {
            marker.setStyle({
                radius: 8,
                fillColor: '#0078d4'
            });
        });

        // Highlight selected marker
        if (this.markers[regionId]) {
            this.markers[regionId].setStyle({
                radius: 12,
                fillColor: '#00ff88'
            });

            // Center map on selected region
            const region = AZURE_REGIONS[regionId];
            this.map.setView(region.coordinates, 3, { animate: true });
        }

        // Draw connections and update list
        this.drawConnections(regionId);
        this.updateLatencyList(regionId);
    }

    clearSelection() {
        this.selectedRegion = null;
        
        // Reset all markers
        Object.values(this.markers).forEach(marker => {
            marker.setStyle({
                radius: 8,
                fillColor: '#0078d4'
            });
        });

        // Clear polylines
        this.clearPolylines();

        // Clear latency list
        document.getElementById('latencyList').innerHTML = `
            <div class="no-data">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
                </svg>
                <p>Select a source region to view latencies</p>
            </div>
        `;
    }

    clearPolylines() {
        this.polylines.forEach(line => this.map.removeLayer(line));
        this.polylines = [];
    }

    drawConnections(sourceRegion) {
        this.clearPolylines();

        if (!this.latencyData || !this.latencyData.connections) return;

        const sourceCoords = AZURE_REGIONS[sourceRegion]?.coordinates;
        if (!sourceCoords) return;

        // Find all unique peer regions (where selected region is source OR destination)
        const peerRegions = new Set();
        this.latencyData.connections.forEach(conn => {
            if (conn.source === sourceRegion && conn.destination !== sourceRegion) {
                peerRegions.add(conn.destination);
            }
            if (conn.destination === sourceRegion && conn.source !== sourceRegion) {
                peerRegions.add(conn.source);
            }
        });

        peerRegions.forEach(peerRegionId => {
            const peerRegion = AZURE_REGIONS[peerRegionId];
            if (!peerRegion) return;

            // Find forward connection (selected -> peer)
            const forwardConn = this.latencyData.connections.find(
                c => c.source === sourceRegion && c.destination === peerRegionId
            );
            // Find reverse connection (peer -> selected)
            const reverseConn = this.latencyData.connections.find(
                c => c.source === peerRegionId && c.destination === sourceRegion
            );

            // Calculate average latency
            const forwardLatency = forwardConn?.latency;
            const reverseLatency = reverseConn?.latency;
            let avgLatency = null;
            if (forwardLatency !== null && forwardLatency !== undefined && reverseLatency !== null && reverseLatency !== undefined) {
                avgLatency = (forwardLatency + reverseLatency) / 2;
            } else if (forwardLatency !== null && forwardLatency !== undefined) {
                avgLatency = forwardLatency;
            } else if (reverseLatency !== null && reverseLatency !== undefined) {
                avgLatency = reverseLatency;
            }

            // Calculate roundtrip (sum of forward + reverse latencies)
            let roundtripLatency = null;
            if (forwardLatency !== null && forwardLatency !== undefined && reverseLatency !== null && reverseLatency !== undefined) {
                roundtripLatency = forwardLatency + reverseLatency;
            }

            const color = this.getRttColor(roundtripLatency);
            
            const polyline = L.polyline(
                [sourceCoords, peerRegion.coordinates],
                {
                    color: color,
                    weight: 3,
                    opacity: 0.7,
                    dashArray: null
                }
            );

            const forwardStr = forwardLatency !== null && forwardLatency !== undefined ? `${forwardLatency.toFixed(2)} ms` : 'N/A';
            const reverseStr = reverseLatency !== null && reverseLatency !== undefined ? `${reverseLatency.toFixed(2)} ms` : 'N/A';
            const avgStr = avgLatency !== null ? `${avgLatency.toFixed(2)} ms` : 'N/A';
            const roundtripStr = roundtripLatency !== null ? `${roundtripLatency.toFixed(2)} ms` : 'N/A';
            
            // Get measurement counts
            const forwardCount = forwardConn?.measurementCount || 0;
            const reverseCount = reverseConn?.measurementCount || 0;
            const totalCount = forwardCount + reverseCount;

            polyline.bindPopup(`
                <div class="popup-title">${AZURE_REGIONS[sourceRegion].displayName} ↔ ${peerRegion.displayName}</div>
                <div class="popup-rtt" style="color: ${color}">RTT: ${roundtripStr}</div>
                <div class="popup-latency">Average (one-way): ${avgStr}</div>
                <div class="popup-route">${AZURE_REGIONS[sourceRegion].displayName} → ${peerRegion.displayName}: ${forwardStr}</div>
                <div class="popup-route">${peerRegion.displayName} → ${AZURE_REGIONS[sourceRegion].displayName}: ${reverseStr}</div>
                <div class="popup-measurements">${totalCount} measurements (${forwardCount} + ${reverseCount})</div>
            `);

            polyline.addTo(this.map);
            this.polylines.push(polyline);
        });
    }

    getLatencyColor(latency) {
        if (latency === null || latency === undefined) return '#666666';
        if (latency < 10) return '#00ff88';   // Excellent
        if (latency < 30) return '#88ff00';   // Good
        if (latency < 80) return '#ffdd00';   // Fair
        if (latency < 150) return '#ff8800';  // Poor
        return '#ff4444';                      // Bad
    }

    getRttColor(rtt) {
        if (rtt === null || rtt === undefined) return '#666666';
        if (rtt < 20) return '#00ff88';   // Excellent
        if (rtt < 60) return '#88ff00';   // Good
        if (rtt < 160) return '#ffdd00';  // Fair
        if (rtt < 300) return '#ff8800';  // High
        return '#ff4444';                  // Very High
    }

    getRttClass(rtt) {
        if (rtt === null || rtt === undefined) return '';
        if (rtt < 20) return 'excellent';
        if (rtt < 60) return 'good';
        if (rtt < 160) return 'fair';
        if (rtt < 300) return 'poor';
        return 'bad';
    }

    getLatencyClass(latency) {
        if (latency === null || latency === undefined) return '';
        if (latency < 10) return 'excellent';
        if (latency < 30) return 'good';
        if (latency < 80) return 'fair';
        if (latency < 150) return 'poor';
        return 'bad';
    }

    updateLatencyList(sourceRegion) {
        const listContainer = document.getElementById('latencyList');
        
        if (!this.latencyData || !this.latencyData.connections) {
            listContainer.innerHTML = '<div class="no-data"><p>No data available</p></div>';
            return;
        }

        // Find all unique peer regions (where selected region is source OR destination)
        const peerRegions = new Set();
        this.latencyData.connections.forEach(conn => {
            if (conn.source === sourceRegion && conn.destination !== sourceRegion) {
                peerRegions.add(conn.destination);
            }
            if (conn.destination === sourceRegion && conn.source !== sourceRegion) {
                peerRegions.add(conn.source);
            }
        });

        // Build connections list with bidirectional data
        const connections = Array.from(peerRegions).map(peerRegionId => {
            // Find forward connection (selected -> peer)
            const forwardConn = this.latencyData.connections.find(
                c => c.source === sourceRegion && c.destination === peerRegionId
            );
            // Find reverse connection (peer -> selected)
            const reverseConn = this.latencyData.connections.find(
                c => c.source === peerRegionId && c.destination === sourceRegion
            );
            
            const forwardLatency = forwardConn?.latency;
            const reverseLatency = reverseConn?.latency;
            let avgLatency = null;
            
            if (forwardLatency !== null && forwardLatency !== undefined && reverseLatency !== null && reverseLatency !== undefined) {
                avgLatency = (forwardLatency + reverseLatency) / 2;
            } else if (forwardLatency !== null && forwardLatency !== undefined) {
                avgLatency = forwardLatency;
            } else if (reverseLatency !== null && reverseLatency !== undefined) {
                avgLatency = reverseLatency;
            }
            
            return {
                destination: peerRegionId,
                forwardLatency,
                reverseLatency,
                avgLatency,
                forwardCount: forwardConn?.measurementCount || 0,
                reverseCount: reverseConn?.measurementCount || 0
            };
        }).sort((a, b) => (a.avgLatency || 999) - (b.avgLatency || 999));

        if (connections.length === 0) {
            listContainer.innerHTML = '<div class="no-data"><p>No measurements available for this region</p></div>';
            return;
        }

        listContainer.innerHTML = connections.map(conn => {
            const destRegion = AZURE_REGIONS[conn.destination];
            const displayName = destRegion?.displayName || conn.destination;
            
            // Calculate RTT
            let rtt = null;
            if (conn.forwardLatency !== null && conn.forwardLatency !== undefined && 
                conn.reverseLatency !== null && conn.reverseLatency !== undefined) {
                rtt = conn.forwardLatency + conn.reverseLatency;
            }
            const rttClass = this.getRttClass(rtt);
            const rttStr = rtt !== null ? `${rtt.toFixed(2)}` : 'N/A';
            
            const forwardStr = conn.forwardLatency !== null && conn.forwardLatency !== undefined ? `${conn.forwardLatency.toFixed(2)}` : 'N/A';
            const reverseStr = conn.reverseLatency !== null && conn.reverseLatency !== undefined ? `${conn.reverseLatency.toFixed(2)}` : 'N/A';
            const avgStr = conn.avgLatency !== null ? `${conn.avgLatency.toFixed(2)}` : 'N/A';
            const totalCount = conn.forwardCount + conn.reverseCount;
            
            return `
                <div class="latency-item" data-destination="${conn.destination}">
                    <div class="destination">${displayName}</div>
                    <div class="latency-details">
                        <div class="value ${rttClass}">${rttStr} ms RTT</div>
                        <div class="bidirectional-info">Avg: ${avgStr} ms | ↗ ${forwardStr} ms | ↙ ${reverseStr} ms</div>
                        <div class="measurement-count">${totalCount} measurements</div>
                    </div>
                </div>
            `;
        }).join('');

        // Add click handlers to list items
        listContainer.querySelectorAll('.latency-item').forEach(item => {
            item.addEventListener('click', () => {
                const destination = item.dataset.destination;
                const destRegion = AZURE_REGIONS[destination];
                if (destRegion) {
                    this.map.setView(destRegion.coordinates, 4, { animate: true });
                    
                    // Find and open the popup for this connection
                    const connection = this.polylines.find(line => {
                        const latlngs = line.getLatLngs();
                        return latlngs[1].lat === destRegion.coordinates[0] &&
                               latlngs[1].lng === destRegion.coordinates[1];
                    });
                    
                    if (connection) {
                        connection.openPopup();
                    }
                }
            });
        });
    }

    hideLoading() {
        document.getElementById('loading').classList.add('hidden');
    }
}

// Initialize the application when the DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.app = new LatencyMapApp();
});
