const client = require('prom-client');
const { getSystemHealth } = require('./systemInfo');

// Create a dedicated Registry
const register = new client.Registry();

// Add default recommended node.js / process metrics
client.collectDefaultMetrics({
  register,
  prefix: 'devops_monitor_'
});

// Custom System Metrics
const cpuGauge = new client.Gauge({
  name: 'system_cpu_usage_percent',
  help: 'Current system CPU usage percentage',
  registers: [register]
});

const memoryGauge = new client.Gauge({
  name: 'system_memory_usage_percent',
  help: 'Current system memory usage percentage',
  registers: [register]
});

const diskGauge = new client.Gauge({
  name: 'system_disk_usage_percent',
  help: 'Current system disk usage percentage',
  registers: [register]
});

const healthStatusGauge = new client.Gauge({
  name: 'system_health_status',
  help: 'Overall system health (1 = healthy, 0 = needs attention)',
  registers: [register]
});

// HTTP Request Metrics
const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests received',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Histogram of HTTP request durations in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5],
  registers: [register]
});

/**
 * Updates Prometheus gauges from latest system snapshot
 */
function updateGauges() {
  const health = getSystemHealth();
  cpuGauge.set(health.metrics.cpu.usagePercent);
  memoryGauge.set(health.metrics.memory.usagePercent);
  diskGauge.set(health.metrics.disk.usagePercent);
  healthStatusGauge.set(health.status === 'HEALTHY' ? 1 : 0);
}

// Update gauges periodically every 5 seconds
setInterval(updateGauges, 5000);
updateGauges();

module.exports = {
  register,
  httpRequestCounter,
  httpRequestDuration,
  updateGauges
};

