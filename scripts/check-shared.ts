import assert from 'node:assert/strict';

import {
  isPlanningItemType,
  isTaskDone,
  isWeekViewItem,
  type MemoItem,
  type TaskItem,
} from '../packages/shared/dist/index.js';

assert.equal(isPlanningItemType('schedule'), true);
assert.equal(isPlanningItemType('memo'), true);
assert.equal(isPlanningItemType('unknown'), false);

const task: TaskItem = {
  id: 'task-1',
  type: 'task',
  title: 'Prepare sprint review',
  plannedStartAt: '2026-03-16T09:00:00.000Z',
  plannedDurationMinutes: 60,
  dueAt: '2026-03-16T12:00:00.000Z',
  reminders: [],
  status: 'done',
  createdAt: '2026-03-11T00:00:00.000Z',
  updatedAt: '2026-03-11T00:00:00.000Z',
  syncState: 'synced',
};

const memo: MemoItem = {
  id: 'memo-1',
  type: 'memo',
  title: 'Check lobby flowers',
  listId: 'default',
  reminders: [],
  status: 'active',
  createdAt: '2026-03-11T00:00:00.000Z',
  updatedAt: '2026-03-11T00:00:00.000Z',
  syncState: 'local_only',
};

assert.equal(isTaskDone(task), true);
assert.equal(isWeekViewItem(task), true);
assert.equal(isWeekViewItem(memo), false);

console.log('Shared planning model check passed');
