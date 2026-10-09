const express = require('express');
const path = require('path');
const { getSystemHealth } = require('./systemInfo');
const { register, httpRequestCounter, httpRequestDuration, updateGauges } = require('./metrics');

const app = express();
const PORT = process.env.PORT || 3000;

// HTTP Request logging & Prometheus latency metrics middleware
app.use((req, res, next) => {
  const start = process.hrtime();
  res.on('finish', () => {
    const diff = process.hrtime(start);
    const durationInSeconds = diff[0] + diff[1] / 1e9;
    const route = req.route ? req.route.path : req.path;
    
    // Skip Prometheus scrape endpoint from bloating metrics
    if (req.path !== '/metrics') {
      httpRequestCounter.inc({
        method: req.method,
        route,
        status_code: res.statusCode
      });
      httpRequestDuration.observe(
        {
          method: req.method,
          route,
          status_code: res.statusCode
        },
        durationInSeconds
      );
    }
  });
  next();
});

// Serve static frontend assets
app.use(express.static(path.join(__dirname, 'public')));

/**
 * Kubernetes Liveness Probe
 */
app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'alive', uptime: process.uptime() });
});

/**
 * Kubernetes Readiness Probe
 */
app.get('/readyz', (req, res) => {
  res.status(200).json({ status: 'ready', timestamp: new Date().toISOString() });
});

/**
 * Detailed System Health API
 */
app.get('/api/v1/health', (req, res) => {
  const healthData = getSystemHealth();
  const statusCode = healthData.status === 'HEALTHY' ? 200 : 200; // Returns 200 with details for observability
  res.status(statusCode).json(healthData);
});

/**
 * Prometheus Metrics Scraping Endpoint
 */
app.get('/metrics', async (req, res) => {
  try {
    updateGauges();
    res.setHeader('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (err) {
    res.status(500).end(err.message);
  }
});

// Graceful shutdown handling
let server;
if (require.main === module) {
  server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`====================================================`);
    console.log(`🚀 DevOps Server Health Monitor running on port ${PORT}`);
    console.log(`📊 Dashboard:   http://localhost:${PORT}/`);
    console.log(`📈 Metrics:     http://localhost:${PORT}/metrics`);
    console.log(`🩺 Health API:  http://localhost:${PORT}/api/v1/health`);
    console.log(`🩺 Liveness:    http://localhost:${PORT}/healthz`);
    console.log(`🩺 Readiness:   http://localhost:${PORT}/readyz`);
    console.log(`====================================================`);
  });

  const handleShutdown = (signal) => {
    console.log(`Received ${signal}. Shutting down gracefully...`);
    server.close(() => {
      console.log('HTTP server closed.');
      process.exit(0);
    });
  };

  process.on('SIGTERM', () => handleShutdown('SIGTERM'));
  process.on('SIGINT', () => handleShutdown('SIGINT'));
}

module.exports = app;
