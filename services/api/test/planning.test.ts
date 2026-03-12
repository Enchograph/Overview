import assert from 'node:assert/strict';

import request from 'supertest';

import { InMemoryAuthRepository } from '../src/auth/memory-repository.js';
import { createApp } from '../src/app.js';
import { InMemoryPlanningRepository } from '../src/planning/memory-repository.js';

interface PlanningListPayload {
  items: Array<{ id: string }>;
}

interface PlanningItemPayload {
  id: string;
  type: string;
  status: string;
  title?: string;
  durationMinutes?: number;
  completionAt?: string;
}

interface ErrorPayload {
  error: string;
}

interface AuthSessionPayload {
  token: string;
}

async function main() {
  const app = createApp({
    authRepository: new InMemoryAuthRepository(),
    planningRepository: new InMemoryPlanningRepository(),
  });

  const registerResponse = await request(app)
    .post('/auth/register')
    .send({
      email: 'planning-test@example.com',
      password: 'Password123',
    })
    .expect(201);
  const authToken = (registerResponse.body as AuthSessionPayload).token;
  const authHeader = { Authorization: `Bearer ${authToken}` };

  await request(app).get('/planning/schedules').expect(401);

  const scheduleCreateResponse = await request(app)
    .post('/planning/schedules')
    .set(authHeader)
    .send({
      title: 'Design review',
      startAt: '2026-03-12T09:00:00.000Z',
      endAt: '2026-03-12T10:00:00.000Z',
      reminders: [],
    })
    .expect(201);
  const scheduleCreateBody = scheduleCreateResponse.body as PlanningItemPayload;

  const scheduleId = scheduleCreateBody.id;
  assert.equal(scheduleCreateBody.type, 'schedule');
  assert.equal(scheduleCreateBody.status, 'active');

  const scheduleListResponse = await request(app)
    .get('/planning/schedules')
    .set(authHeader)
    .expect(200);
  const scheduleListBody = scheduleListResponse.body as PlanningListPayload;
  assert.equal(scheduleListBody.items.length, 1);

  const schedulePatchResponse = await request(app)
    .patch(`/planning/schedules/${scheduleId}`)
    .set(authHeader)
    .send({
      title: 'Design review updated',
      durationMinutes: 75,
    })
    .expect(200);
  const schedulePatchBody = schedulePatchResponse.body as PlanningItemPayload;
  assert.equal(schedulePatchBody.title, 'Design review updated');
  assert.equal(schedulePatchBody.durationMinutes, 75);

  await request(app)
    .get(`/planning/schedules/${scheduleId}`)
    .set(authHeader)
    .expect(200);
  await request(app)
    .delete(`/planning/schedules/${scheduleId}`)
    .set(authHeader)
    .expect(204);
  await request(app)
    .get(`/planning/schedules/${scheduleId}`)
    .set(authHeader)
    .expect(404);

  const taskCreateResponse = await request(app)
    .post('/planning/tasks')
    .set(authHeader)
    .send({
      title: 'Ship CRUD API',
      plannedStartAt: '2026-03-12T13:00:00.000Z',
      dueAt: '2026-03-13T01:00:00.000Z',
      reminders: [],
    })
    .expect(201);
  const taskCreateBody = taskCreateResponse.body as PlanningItemPayload;

  const taskId = taskCreateBody.id;
  assert.equal(taskCreateBody.status, 'todo');

  const taskPatchResponse = await request(app)
    .patch(`/planning/tasks/${taskId}`)
    .set(authHeader)
    .send({
      status: 'done',
      completionAt: '2026-03-12T15:00:00.000Z',
    })
    .expect(200);
  const taskPatchBody = taskPatchResponse.body as PlanningItemPayload;
  assert.equal(taskPatchBody.status, 'done');
  assert.equal(taskPatchBody.completionAt, '2026-03-12T15:00:00.000Z');

  await request(app)
    .delete(`/planning/tasks/${taskId}`)
    .set(authHeader)
    .expect(204);

  const memoCreateResponse = await request(app)
    .post('/planning/memos')
    .set(authHeader)
    .send({
      title: 'Buy pens',
      listId: 'inbox',
      reminders: [],
      sortOrder: 2,
    })
    .expect(201);
  const memoCreateBody = memoCreateResponse.body as PlanningItemPayload;

  const memoId = memoCreateBody.id;
  assert.equal(memoCreateBody.type, 'memo');

  const memoPatchResponse = await request(app)
    .patch(`/planning/memos/${memoId}`)
    .set(authHeader)
    .send({
      status: 'archived',
      archivedAt: '2026-03-12T18:00:00.000Z',
    })
    .expect(200);
  const memoPatchBody = memoPatchResponse.body as PlanningItemPayload;
  assert.equal(memoPatchBody.status, 'archived');

  await request(app)
    .delete(`/planning/memos/${memoId}`)
    .set(authHeader)
    .expect(204);

  const invalidResponse = await request(app)
    .post('/planning/tasks')
    .set(authHeader)
    .send({
      title: '',
      plannedStartAt: 'bad-date',
      dueAt: '2026-03-13T01:00:00.000Z',
      reminders: [],
    })
    .expect(400);
  const invalidBody = invalidResponse.body as ErrorPayload;
  assert.equal(invalidBody.error, 'Invalid request');

  console.log('Planning API tests passed');
}

await main();
