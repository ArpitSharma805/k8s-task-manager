const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';

app.use(express.json());

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Sample Application',
    version: VERSION,
    status: 'healthy'
  });
});

// Health endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    version: VERSION,
    uptime: process.uptime()
  });
});

// Version endpoint
app.get('/version', (req, res) => {
  res.json({
    version: VERSION
  });
});

// Metrics endpoint (for Prometheus)
app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send(`# Sample Application Metrics
# HELP sample_app_up Application is up
# TYPE sample_app_up gauge
sample_app_up 1
# HELP sample_app_version Application version
# TYPE sample_app_version gauge
sample_app_version{version="${VERSION}"} 1
`);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Sample application listening on port ${PORT}`);
  console.log(`Version: ${VERSION}`);
});
