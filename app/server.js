// Simple Demo App for Wiz Exercise
// Based on basic Express.js tutorial - adapted for security demonstration

const express = require('express');
const { MongoClient } = require('mongodb');
const app = express();
const PORT = process.env.PORT || 3000;

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/todoapp';
let db;

// Connect to MongoDB
async function connectDB() {
  try {
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    db = client.db('todoapp');
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
  }
}

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Routes
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Wiz Security Demo App</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
            h1 { color: #333; }
            .info { background: #e8f4f8; padding: 15px; border-radius: 4px; margin: 10px 0; }
            .status { color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎯 Wiz Security Demo Application</h1>
            <p>This is a simple Node.js application used to demonstrate security vulnerabilities in cloud environments.</p>
            
            <div class="info">
                <strong>Application Details:</strong><br>
                MongoDB URI: ${process.env.MONGODB_URI || 'Not configured'}<br>
                Node Version: ${process.version}<br>
                Environment: ${process.env.NODE_ENV || 'development'}
            </div>
            
            <div class="info">
                <strong>Security Demo Purpose:</strong><br>
                • Demonstrates container vulnerabilities<br>
                • Shows database connectivity<br>
                • Contains required wizexercise.txt file<br>
                • Runs with intentional security misconfigurations
            </div>
            
            <p class="status">Application is running and ready for security analysis.</p>
        </div>
    </body>
    </html>
  `);
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    let dbStatus = 'disconnected';
    if (db) {
      await db.admin().ping();
      dbStatus = 'connected';
    }
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: dbStatus,
      uptime: process.uptime(),
      version: '1.0.0'
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Simple API endpoint to demonstrate database connectivity
app.get('/api/info', (req, res) => {
  res.json({
    app: 'Wiz Security Demo',
    version: '1.0.0',
    mongodb_uri: MONGODB_URI.replace(/\/\/.*@/, '//***:***@'), // Hide credentials
    node_version: process.version,
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// File validation endpoint (for wizexercise.txt requirement)
app.get('/api/validate-file', (req, res) => {
  const fs = require('fs');
  try {
    const content = fs.readFileSync('/app/wizexercise.txt', 'utf8').trim();
    res.json({
      file_exists: true,
      content: content,
      valid: content === 'Devon Diffie'
    });
  } catch (error) {
    res.json({
      file_exists: false,
      error: error.message
    });
  }
});

// Start server
connectDB().then(() => {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Wiz Demo App running on port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
  });
});