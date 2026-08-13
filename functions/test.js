'use strict';

// Unit tests for the pure feedback-proxy helpers. Self-running (no
// emulator or Firebase credentials required).

const { test } = require('node:test');
const assert = require('node:assert');

const { validatePayload, rateWindowDecision, startOfUtcDay } = require('./lib/feedback');

const MINUTE_MS = 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
const DAY_START = Date.UTC(2026, 0, 1); // 2026-01-01T00:00:00Z

test('validatePayload accepts a valid payload', () => {
  assert.strictEqual(
    validatePayload({ title: 'Bug', body: 'Details' }),
    null,
  );
});

test('validatePayload rejects a missing title', () => {
  assert.ok(validatePayload({ body: 'Details' }));
});

test('validatePayload rejects an oversized title', () => {
  assert.ok(validatePayload({ title: 'x'.repeat(257), body: 'Details' }));
});

test('validatePayload rejects a missing body', () => {
  assert.ok(validatePayload({ title: 'Bug' }));
});

test('validatePayload rejects an oversized label', () => {
  assert.ok(
    validatePayload({ title: 'Bug', body: 'Details', label: 'y'.repeat(65) }),
  );
});

test('rateWindowDecision allows the first submission', () => {
  const d = rateWindowDecision(DAY_START, 0, 0, 0);
  assert.strictEqual(d.allowed, true);
});

test('rateWindowDecision blocks a second submission within 60s', () => {
  const now = DAY_START + 30 * 1000;
  const d = rateWindowDecision(now, DAY_START, DAY_START, 1);
  assert.strictEqual(d.allowed, false);
  assert.ok(d.retryAfterSeconds > 0 && d.retryAfterSeconds <= 60);
});

test('rateWindowDecision allows a submission after 60s', () => {
  const now = DAY_START + 61 * 1000;
  const d = rateWindowDecision(now, DAY_START, DAY_START, 1);
  assert.strictEqual(d.allowed, true);
});

test('rateWindowDecision blocks the 6th submission in a UTC day', () => {
  const now = DAY_START + 5 * 60 * 1000;
  const d = rateWindowDecision(now, now - 61 * 1000, DAY_START, 5);
  assert.strictEqual(d.allowed, false);
});

test('rateWindowDecision allows a submission on the next UTC day', () => {
  const nextDay = DAY_START + DAY_MS;
  const d = rateWindowDecision(nextDay, nextDay - MINUTE_MS - 1, DAY_START, 5);
  assert.strictEqual(d.allowed, true);
});

test('startOfUtcDay returns the UTC day boundary', () => {
  const ms = Date.UTC(2026, 5, 15, 23, 59, 59);
  assert.strictEqual(startOfUtcDay(ms), Date.UTC(2026, 5, 15));
});
