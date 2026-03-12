import assert from 'node:assert/strict';

import request from 'supertest';

import { HeuristicAiService } from '../src/ai/heuristic-service.js';
import { InMemoryAuthRepository } from '../src/auth/memory-repository.js';
import { createApp } from '../src/app.js';
import { InMemoryPlanningRepository } from '../src/planning/memory-repository.js';

interface AuthSessionPayload {
  token: string;
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
      email: 'ai-test@example.com',
      password: 'Password123',
    })
    .expect(201);
  const authToken = (registerResponse.body as AuthSessionPayload).token;
  const authHeader = { Authorization: `Bearer ${authToken}` };

  await request(app)
    .post('/ai/ingest/text')
    .send({ text: '记得买猫粮' })
    .expect(401);

  const ingestResponse = await request(app)
    .post('/ai/ingest/text')
    .set(authHeader)
    .send({ text: '明晚 8 点做英语作业，周六晚上前必须交' })
    .expect(200);
  assert.equal(
    (ingestResponse.body as { suggestedType: string }).suggestedType,
    'task',
  );

  await request(app)
    .post('/planning/schedules')
    .set(authHeader)
    .send({
      title: 'AI review',
      startAt: '2026-03-12T09:00:00.000Z',
      endAt: '2026-03-12T10:00:00.000Z',
      reminders: [],
    })
    .expect(201);

  await request(app)
    .post('/planning/tasks')
    .set(authHeader)
    .send({
      title: 'Ship AI route',
      plannedStartAt: '2026-03-12T13:00:00.000Z',
      dueAt: '2026-03-13T01:00:00.000Z',
      reminders: [],
    })
    .expect(201);

  await request(app)
    .post('/planning/memos')
    .set(authHeader)
    .send({
      title: 'Collect AI notes',
      listId: 'inbox',
      reminders: [],
    })
    .expect(201);

  const askResponse = await request(app)
    .post('/ai/ask')
    .set(authHeader)
    .send({ question: 'What do I have this week?' })
    .expect(200);
  assert.match(
    (askResponse.body as { answer: string }).answer,
    /1 schedules.*1 tasks.*1 memos/,
  );

  await request(app)
    .post('/ai/transcribe')
    .set(authHeader)
    .send({
      audioBase64: Buffer.from([1, 2, 3]).toString('base64'),
      mimeType: 'audio/wav',
      locale: 'zh-CN',
    })
    .expect(503);

  console.log('AI API tests passed');
}

await main();
