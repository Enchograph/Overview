import assert from 'node:assert/strict';

import request from 'supertest';

import { HeuristicAiService } from '../src/ai/heuristic-service.js';
import { InMemoryAuthRepository } from '../src/auth/memory-repository.js';
import { createApp } from '../src/app.js';
import { InMemoryPlanningRepository } from '../src/planning/memory-repository.js';

interface AuthPayload {
  token: string;
  expiresAt: string;
  user: {
    id: string;
    email: string;
  };
}

interface ErrorPayload {
  error: string;
}

async function main() {
  const planningRepository = new InMemoryPlanningRepository();
  const app = createApp({
    aiService: new HeuristicAiService(planningRepository),
    authRepository: new InMemoryAuthRepository(),
    planningRepository,
  });

  const registerResponse = await request(app)
    .post('/auth/register')
    .send({
      email: 'test@example.com',
      password: 'Password123',
    })
    .expect(201);
  const registerBody = registerResponse.body as AuthPayload;

  assert.equal(registerBody.user.email, 'test@example.com');
  assert.equal(typeof registerBody.token, 'string');
  assert.ok(registerBody.token.length > 10);
  assert.doesNotThrow(() => new Date(registerBody.expiresAt));

  const duplicateResponse = await request(app)
    .post('/auth/register')
    .send({
      email: 'test@example.com',
      password: 'Password123',
    })
    .expect(409);
  assert.equal(
    (duplicateResponse.body as ErrorPayload).error,
    'Email already registered',
  );

  const loginResponse = await request(app)
    .post('/auth/login')
    .send({
      email: 'test@example.com',
      password: 'Password123',
    })
    .expect(200);
  const loginBody = loginResponse.body as AuthPayload;

  assert.equal(loginBody.user.email, 'test@example.com');
  assert.notEqual(loginBody.token, registerBody.token);

  const invalidLoginResponse = await request(app)
    .post('/auth/login')
    .send({
      email: 'test@example.com',
      password: 'wrongpass',
    })
    .expect(401);
  assert.equal(
    (invalidLoginResponse.body as ErrorPayload).error,
    'Invalid email or password',
  );

  const invalidRequestResponse = await request(app)
    .post('/auth/register')
    .send({
      email: 'bad-email',
      password: 'short',
    })
    .expect(400);
  assert.equal(
    (invalidRequestResponse.body as ErrorPayload).error,
    'Invalid request',
  );

  console.log('Auth API tests passed');
}

await main();
