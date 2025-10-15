const express = require('express');
const { MongoClient } = require('mongodb');

const app = express();
const port = process.env.PORT || 3000;

// MongoDB connection with authentication
const mongoHost = process.env.MONGODB_HOST || 'localhost';
const mongoPort = process.env.MONGODB_PORT || '27017';
const mongoUser = process.env.MONGODB_USER || 'todoapp';
const mongoPass = process.env.MONGODB_PASS || 'todopass';
const dbName = process.env.MONGODB_DATABASE || 'todoapp';

const mongoUri = `mongodb://${mongoUser}:${mongoPass}@${mongoHost}:${mongoPort}/${dbName}`;

let db;

// Connect to MongoDB (skip if host is disabled)
if (mongoHost && mongoHost !== 'disabled' && mongoHost !== '') {
  console.log(`Attempting MongoDB connection to: ${mongoUri}`);
  MongoClient.connect(mongoUri)
    .then(client => {
      console.log('Connected to MongoDB with authentication');
      db = client.db(dbName);
    })
    .catch(error => {
      console.error('MongoDB connection failed:', error.message);
      // Continue without MongoDB for demo purposes
    });
} else {
  console.log('MongoDB connection disabled - running without database');
}

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Wiz Demo App - Intentionally Vulnerable',
    mongodb: db ? 'connected' : 'disconnected'
  });
});

// Liveness probe
app.get('/live', (req, res) => {
  res.json({ status: 'alive' });
});

// Readiness probe
app.get('/ready', (req, res) => {
  res.json({ status: 'ready', mongodb: db ? 'ready' : 'not ready' });
});

// Get todos
app.get('/api/todos', async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({ error: 'Database not available' });
    }
    const todos = await db.collection('todos').find({}).toArray();
    res.json(todos);
  } catch (error) {
    console.error('Error fetching todos:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add todo
app.post('/api/todos', async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({ error: 'Database not available' });
    }
    const { task, user } = req.body;
    const todo = {
      task,
      user: user || 'anonymous',
      completed: false,
      createdAt: new Date()
    };
    const result = await db.collection('todos').insertOne(todo);
    res.status(201).json({ ...todo, _id: result.insertedId });
  } catch (error) {
    console.error('Error creating todo:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get app info
app.get('/api/info', (req, res) => {
  res.json({
    app: 'Wiz Security Demo',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    mongodb: {
      host: mongoHost,
      port: mongoPort,
      database: dbName,
      connected: !!db
    },
    vulnerabilities: [
      'Outdated Node.js version (16.14.0)',
      'Outdated Alpine Linux (3.15)',
      'Cluster-admin Kubernetes privileges',
      'MongoDB credentials in environment variables',
      'Public S3 bucket with database backups'
    ]
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.send(`
    <h1>Wiz Security Demo Application</h1>
    <p>This application demonstrates common security vulnerabilities that Wiz can detect.</p>
    <h2>API Endpoints:</h2>
    <ul>
      <li><a href="/health">GET /health</a> - Health check</li>
      <li><a href="/api/info">GET /api/info</a> - Application information</li>
      <li><a href="/api/todos">GET /api/todos</a> - Get todos from MongoDB</li>
      <li>POST /api/todos - Create new todo</li>
    </ul>
    <h2>Security Issues (Intentional):</h2>
    <ul>
      <li>Outdated Node.js and Alpine Linux versions</li>
      <li>Kubernetes service account with cluster-admin privileges</li>
      <li>MongoDB credentials in environment variables</li>
      <li>Public S3 bucket with database backups</li>
      <li>SSH access from anywhere (0.0.0.0/0)</li>
    </ul>
  `);
});

app.listen(port, () => {
  console.log(`Wiz Demo App running on port ${port}`);
  console.log('Intentionally vulnerable for security demonstration');
});