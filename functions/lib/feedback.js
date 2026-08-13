'use strict';

// Pure helpers for the submitFeedback Cloud Function. Kept free of Firebase
// dependencies so they can be unit-tested without an emulator.

const MINUTE_MS = 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Validates a feedback payload.
 * @param {{title: unknown, body: unknown, label: unknown}} payload
 * @returns {string|null} an error message, or null when valid.
 */
function validatePayload({ title, body, label } = {}) {
  if (typeof title !== 'string' || title.trim().length === 0) {
    return 'title must be a non-empty string';
  }
  if (title.trim().length > 256) {
    return 'title must be at most 256 characters';
  }
  if (typeof body !== 'string' || body.trim().length === 0) {
    return 'body must be a non-empty string';
  }
  if (body.trim().length > 50000) {
    return 'body must be at most 50000 characters';
  }
  if (label !== undefined && label !== null) {
    if (typeof label !== 'string' || label.length > 64) {
      return 'label must be a string of at most 64 characters';
    }
  }
  return null;
}

/**
 * Returns the UTC epoch ms for the start of the UTC day containing [ms].
 * @param {number} ms epoch milliseconds
 * @returns {number}
 */
function startOfUtcDay(ms) {
  const d = new Date(ms);
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
}

/**
 * Decides whether a submission is allowed under the server-side rate
 * window: at most 1 per minute and 5 per UTC day, per rate-limit key.
 * @param {number} nowMs current epoch ms
 * @param {number} lastMs last submission epoch ms (0 = never)
 * @param {number} dayStartMs stored UTC-day-start of the running daily count
 * @param {number} count running daily count
 * @returns {{allowed: boolean, retryAfterSeconds: number}}
 */
function rateWindowDecision(nowMs, lastMs, dayStartMs, count) {
  if (lastMs > 0 && nowMs - lastMs < MINUTE_MS) {
    return {
      allowed: false,
      retryAfterSeconds: Math.ceil((MINUTE_MS - (nowMs - lastMs)) / 1000),
    };
  }

  const day = startOfUtcDay(nowMs);
  const effectiveDayStart = dayStartMs > 0 ? dayStartMs : day;
  if (effectiveDayStart === day && count >= 5) {
    const nextDay = day + DAY_MS;
    return {
      allowed: false,
      retryAfterSeconds: Math.ceil((nextDay - nowMs) / 1000),
    };
  }

  return { allowed: true, retryAfterSeconds: 0 };
}

module.exports = { validatePayload, rateWindowDecision, startOfUtcDay };
