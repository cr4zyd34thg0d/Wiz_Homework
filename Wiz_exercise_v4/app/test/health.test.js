// Basic health check tests for Wiz Todo App

const request = require('supertest');
const app = require('../server');

describe('Health Endpoints', () => {
  test('GET /health should return health status', async () => {
    const response = await request(app).get('/health');
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('uptime');
  });

  test('GET /live should return liveness status', async () => {
    const response = await request(app).get('/live');
    
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('alive');
    expect(response.body).toHaveProperty('pid');
  });

  test('GET /ready should return readiness status', async () => {
    const response = await request(app).get('/ready');
    
    // May be 200 or 503 depending on database connection
    expect([200, 503]).toContain(response.status);
    expect(response.body).toHaveProperty('status');
  });

  test('GET /api/info should return app information', async () => {
    const response = await request(app).get('/api/info');
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('app');
    expect(response.body).toHaveProperty('version');
    expect(response.body).toHaveProperty('uptime');
    expect(response.body.app).toBe('Wiz Todo App');
  });
});