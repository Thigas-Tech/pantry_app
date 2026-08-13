'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');

const {
  validatePayload,
  rateWindowDecision,
  startOfUtcDay,
} = require('./lib/feedback');

admin.initializeApp();
const db = admin.firestore();

const GITHUB_OWNER = process.env.GITHUB_OWNER || 'Thigas-Tech';
const GITHUB_REPO = process.env.GITHUB_REPO || 'pantry_app';

/**
 * Serverless feedback proxy.
 *
 * Holds the GitHub PAT (set as the FEEDBACK_TOKEN env var at deploy time —
 * never shipped in the app), validates the payload, enforces per-device
 * server-side rate limits (1/min, 5/day keyed by X-Device-Id with an IP
 * fallback), and posts the issue to GitHub on the caller's behalf.
 */
exports.submitFeedback = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method not allowed' });
    return;
  }

  const token = process.env.FEEDBACK_TOKEN;
  if (!token) {
    console.error('FEEDBACK_TOKEN is not configured');
    res.status(500).json({ error: 'server misconfigured' });
    return;
  }

  const validation = validatePayload(req.body || {});
  if (validation) {
    res.status(400).json({ error: validation });
    return;
  }

  const deviceId = (req.get('x-device-id') || '').trim();
  const rateKey = deviceId || `ip:${req.ip || 'unknown'}`;

  const decision = await checkRateLimit(db, rateKey);
  if (!decision.allowed) {
    res.status(429).json({
      error: 'rate_limited',
      retryAfter: decision.retryAfterSeconds,
    });
    return;
  }

  const { title, body, label } = req.body;

  try {
    const gh = await fetch(
      `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/issues`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/vnd.github+json',
          'Content-Type': 'application/json',
          'User-Agent': 'PantryApp/1.0',
        },
        body: JSON.stringify({
          title,
          body,
          labels: label ? [label, 'from-app'] : ['from-app'],
        }),
      },
    );
    const text = await gh.text();
    if (gh.status === 201) {
      await recordSubmission(db, rateKey);
      res.status(201).json({ url: JSON.parse(text).html_url });
      return;
    }
    console.error(
      'GitHub responded',
      gh.status,
      text.slice(0, 200),
    );
    res.status(502).json({ error: 'upstream failed' });
  } catch (e) {
    console.error('GitHub request failed', e);
    res.status(502).json({ error: 'upstream failed' });
  }
});

/**
 * Reads the stored counters for [key] and decides whether a new
 * submission is allowed.
 */
async function checkRateLimit(dbInstance, key) {
  const ref = dbInstance.collection('feedback_limits').doc(key);
  const snap = await ref.get();
  const data = snap.exists ? snap.data() : {};
  const now = Date.now();
  return rateWindowDecision(
    now,
    data.lastSubmittedAt || 0,
    data.dayStart || 0,
    data.count || 0,
  );
}

/**
 * Records a successful submission for [key], rolling the daily window over
 * at the UTC day boundary.
 */
async function recordSubmission(dbInstance, key) {
  const ref = dbInstance.collection('feedback_limits').doc(key);
  const snap = await ref.get();
  const data = snap.exists ? snap.data() : {};
  const now = Date.now();
  const day = startOfUtcDay(now);
  const sameDay = data.dayStart === day;
  await ref.set({
    lastSubmittedAt: now,
    dayStart: sameDay ? data.dayStart : day,
    count: sameDay ? (data.count || 0) + 1 : 1,
  });
}
