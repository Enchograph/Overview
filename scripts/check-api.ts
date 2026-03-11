import assert from 'node:assert/strict';

import { createHealthResponse } from '@overview/shared';

const payload = createHealthResponse(new Date('2026-03-11T00:00:00.000Z'));

assert.equal(payload.status, 'ok');
assert.equal(payload.service, 'api');
assert.equal(payload.timestamp, '2026-03-11T00:00:00.000Z');

console.log('API contract check passed');
