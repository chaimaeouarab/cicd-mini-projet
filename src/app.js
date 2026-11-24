const express = require('express');

const app = express();

// Version injectée au build Docker (--build-arg APP_VERSION=sha-xxxxxxx)
const VERSION = process.env.APP_VERSION || 'dev';
const STARTED_AT = new Date().toISOString();

app.get('/', (req, res) => {
  res.send(`<h1>Mini-projet CI/CD</h1><p>Version en service : <b>${VERSION}</b></p>`);
});

// Point de santé : 200 = service disponible, "version" = preuve du tag déployé
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok', version: VERSION, startedAt: STARTED_AT });
});

// Petite logique métier pour avoir de vrais tests
function add(a, b) {
  return a + b;
}

app.get('/api/add', (req, res) => {
  const a = Number(req.query.a);
  const b = Number(req.query.b);
  if (Number.isNaN(a) || Number.isNaN(b)) {
    return res.status(400).json({ error: 'a et b doivent être des nombres' });
  }
  res.json({ result: add(a, b) });
});

module.exports = { app, add };
