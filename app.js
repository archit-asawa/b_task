// app.js
// Main Express application

const express = require('express');
const db = require('./db');
const lowStockAlerts = require('./lowStockAlerts');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Make database available to routes
app.locals.db = db;

// Routes
app.use(lowStockAlerts);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Test endpoint: http://localhost:${PORT}/api/companies/1/alerts/low-stock`);
});

module.exports = app;
