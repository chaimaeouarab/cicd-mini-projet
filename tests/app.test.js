const request = require('supertest');
const { app, add } = require('../src/app');

describe('Fonction add', () => {
  test('additionne deux nombres', () => {
    expect(add(2, 3)).toBe(5);
  });
});

describe('API', () => {
  test('GET /api/health renvoie 200 et une version', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.version).toBeDefined();
  });

  test('GET /api/add?a=2&b=3 renvoie 5', async () => {
    const res = await request(app).get('/api/add?a=2&b=3');
    expect(res.status).toBe(200);
    expect(res.body.result).toBe(5);
  });

  test('GET /api/add avec une valeur invalide renvoie 400', async () => {
    const res = await request(app).get('/api/add?a=x&b=3');
    expect(res.status).toBe(400);
  });
});
