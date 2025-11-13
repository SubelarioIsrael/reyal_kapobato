/**
 * Simple server to send FCM messages using firebase-admin.
 * Install: npm i express firebase-admin body-parser cors
 * Usage:
 *  - Place your Firebase service account JSON at ./serviceAccountKey.json
 *  - Set env var AUTH_TOKEN to a secret token (e.g. export AUTH_TOKEN=supersecret)
 *  - node send_fcm_server.js
 *
 * Health: GET /health
 *
 * Examples:
 *  Send to single token:
 *    curl -X POST http://localhost:8080/send \
 *      -H "Content-Type: application/json" \
 *      -H "x-auth-token: supersecret" \
 *      -d '{"token":"<FCM_TOKEN>","notification":{"title":"Hi","body":"Hello"}}'
 *
 *  Send to userId (server looks up tokens in Firestore collection device_tokens):
 *    curl -X POST http://localhost:8080/send \
 *      -H "Content-Type: application/json" \
 *      -H "x-auth-token: supersecret" \
 *      -d '{"userId":"uid123","notification":{"title":"Hi","body":"Hello"}}'
 */
const express = require('express');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const cors = require('cors'); // added

const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json'); // add your service account here
const AUTH_TOKEN = process.env.AUTH_TOKEN || ''; // set this in env for simple auth
const PORT = process.env.PORT || 8080;

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error('Missing serviceAccountKey.json at', SERVICE_ACCOUNT_PATH);
  process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const app = express();
app.use(cors()); // allow simple cross-origin usage from local/dev
app.use(bodyParser.json());

function requireAuth(req, res, next) {
  const token = req.header('x-auth-token') || '';
  if (!AUTH_TOKEN || token !== AUTH_TOKEN) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }
  next();
}

app.post('/send', requireAuth, async (req, res) => {
  try {
    const { userId, token, tokens, notification, data } = req.body;

    let targetTokens = [];
    if (token) targetTokens = [token];
    else if (Array.isArray(tokens)) targetTokens = tokens;
    else if (userId) {
      // Query Firestore collection 'device_tokens' for userId
      const snaps = await db.collection('device_tokens').where('userId', '==', userId).get();
      snaps.forEach(doc => {
        const d = doc.data();
        if (d && d.token) targetTokens.push(d.token);
      });
    }

    if (targetTokens.length === 0) {
      return res.status(400).json({ ok: false, error: 'no tokens found' });
    }

    // Build message payload
    const messagePayload = {
      notification: notification || undefined,
      data: data || undefined,
    };

    // If multiple tokens, use sendMulticast
    if (targetTokens.length === 1) {
      const result = await admin.messaging().send({
        token: targetTokens[0],
        notification: messagePayload.notification,
        data: messagePayload.data,
      });
      return res.json({ ok: true, result });
    } else {
      const multicast = {
        tokens: targetTokens,
        notification: messagePayload.notification,
        data: messagePayload.data,
      };
      const response = await admin.messaging().sendMulticast(multicast);
      return res.json({ ok: true, successCount: response.successCount, failureCount: response.failureCount, responses: response.responses });
    }
  } catch (err) {
    console.error('send error', err);
    return res.status(500).json({ ok: false, error: err.message || String(err) });
  }
});

// health endpoint for quick checks
app.get('/health', (req, res) => {
  res.json({ ok: true, uptime: process.uptime() });
});

app.listen(PORT, () => {
  console.log(`FCM send server running on http://localhost:${PORT}`);
});
