import assert from 'node:assert/strict';

import request from 'supertest';

import { createApp } from '../src/app.js';

interface HealthPayload {
  status: string;
  service: string;
  timestamp: string;
}

interface ErrorPayload {
  error: string;
}

async function main() {
  const response = await request(createApp()).get('/health').expect(200);
  const body = response.body as HealthPayload;

  assert.match(String(response.headers['content-type']), /^application\/json/);
  assert.equal(body.status, 'ok');
  assert.equal(body.service, 'api');
  assert.doesNotThrow(() => new Date(body.timestamp));

  const missingResponse = await request(createApp())
    .get('/missing')
    .expect(404);
  const missingBody = missingResponse.body as ErrorPayload;

  assert.equal(missingBody.error, 'Not Found');

  console.log('API tests passed');
}

await main();
