import assert from 'node:assert/strict';

import request from 'supertest';

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

async function main() {
  const app = createApp({
    planningRepository: new InMemoryPlanningRepository(),
  });

  const scheduleCreateResponse = await request(app)
    .post('/planning/schedules')
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
    .expect(200);
  const scheduleListBody = scheduleListResponse.body as PlanningListPayload;
  assert.equal(scheduleListBody.items.length, 1);

  const schedulePatchResponse = await request(app)
    .patch(`/planning/schedules/${scheduleId}`)
    .send({
      title: 'Design review updated',
      durationMinutes: 75,
    })
    .expect(200);
  const schedulePatchBody = schedulePatchResponse.body as PlanningItemPayload;
  assert.equal(schedulePatchBody.title, 'Design review updated');
  assert.equal(schedulePatchBody.durationMinutes, 75);

  await request(app).get(`/planning/schedules/${scheduleId}`).expect(200);
  await request(app).delete(`/planning/schedules/${scheduleId}`).expect(204);
  await request(app).get(`/planning/schedules/${scheduleId}`).expect(404);

  const taskCreateResponse = await request(app)
    .post('/planning/tasks')
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
    .send({
      status: 'done',
      completionAt: '2026-03-12T15:00:00.000Z',
    })
    .expect(200);
  const taskPatchBody = taskPatchResponse.body as PlanningItemPayload;
  assert.equal(taskPatchBody.status, 'done');
  assert.equal(taskPatchBody.completionAt, '2026-03-12T15:00:00.000Z');

  await request(app).delete(`/planning/tasks/${taskId}`).expect(204);

  const memoCreateResponse = await request(app)
    .post('/planning/memos')
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
    .send({
      status: 'archived',
      archivedAt: '2026-03-12T18:00:00.000Z',
    })
    .expect(200);
  const memoPatchBody = memoPatchResponse.body as PlanningItemPayload;
  assert.equal(memoPatchBody.status, 'archived');

  await request(app).delete(`/planning/memos/${memoId}`).expect(204);

  const invalidResponse = await request(app)
    .post('/planning/tasks')
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
