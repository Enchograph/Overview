import { randomUUID } from 'node:crypto';

import type {
  CreateMemoInput,
  CreateScheduleInput,
  CreateTaskInput,
  MemoItem,
  ScheduleItem,
  TaskItem,
} from '@overview/shared';

import type {
  PlanningRepository,
  UpdateMemoInput,
  UpdateScheduleInput,
  UpdateTaskInput,
} from './types.js';

function nowIso(): string {
  return new Date().toISOString();
}

export class InMemoryPlanningRepository implements PlanningRepository {
  private readonly schedules = new Map<string, ScheduleItem>();
  private readonly tasks = new Map<string, TaskItem>();
  private readonly memos = new Map<string, MemoItem>();

  listSchedules(): Promise<ScheduleItem[]> {
    return Promise.resolve(
      Array.from(this.schedules.values()).sort((left, right) =>
        left.startAt.localeCompare(right.startAt),
      ),
    );
  }

  getSchedule(id: string): Promise<ScheduleItem | null> {
    return Promise.resolve(this.schedules.get(id) ?? null);
  }

  createSchedule(input: CreateScheduleInput): Promise<ScheduleItem> {
    const timestamp = nowIso();
    const item: ScheduleItem = {
      id: randomUUID(),
      type: 'schedule',
      title: input.title,
      description: input.description,
      location: input.location,
      timezone: input.timezone,
      reminders: input.reminders,
      status: 'active',
      createdAt: timestamp,
      updatedAt: timestamp,
      syncState: 'synced',
      startAt: input.startAt,
      endAt: input.endAt,
      durationMinutes: input.durationMinutes,
      recurrenceRule: input.recurrenceRule,
    };

    this.schedules.set(item.id, item);
    return Promise.resolve(item);
  }

  updateSchedule(
    id: string,
    input: UpdateScheduleInput,
  ): Promise<ScheduleItem | null> {
    const current = this.schedules.get(id);

    if (!current) {
      return Promise.resolve(null);
    }

    const updated: ScheduleItem = {
      ...current,
      ...input,
      updatedAt: nowIso(),
    };

    this.schedules.set(id, updated);
    return Promise.resolve(updated);
  }

  deleteSchedule(id: string): Promise<boolean> {
    return Promise.resolve(this.schedules.delete(id));
  }

  listTasks(): Promise<TaskItem[]> {
    return Promise.resolve(
      Array.from(this.tasks.values()).sort((left, right) =>
        left.dueAt.localeCompare(right.dueAt),
      ),
    );
  }

  getTask(id: string): Promise<TaskItem | null> {
    return Promise.resolve(this.tasks.get(id) ?? null);
  }

  createTask(input: CreateTaskInput): Promise<TaskItem> {
    const timestamp = nowIso();
    const item: TaskItem = {
      id: randomUUID(),
      type: 'task',
      title: input.title,
      description: input.description,
      location: input.location,
      timezone: input.timezone,
      reminders: input.reminders,
      status: 'todo',
      createdAt: timestamp,
      updatedAt: timestamp,
      syncState: 'synced',
      plannedStartAt: input.plannedStartAt,
      plannedEndAt: input.plannedEndAt,
      plannedDurationMinutes: input.plannedDurationMinutes,
      dueAt: input.dueAt,
      recurrenceRule: input.recurrenceRule,
    };

    this.tasks.set(item.id, item);
    return Promise.resolve(item);
  }

  updateTask(id: string, input: UpdateTaskInput): Promise<TaskItem | null> {
    const current = this.tasks.get(id);

    if (!current) {
      return Promise.resolve(null);
    }

    const updated: TaskItem = {
      ...current,
      ...input,
      completionAt:
        input.completionAt === null ? undefined : input.completionAt ?? current.completionAt,
      updatedAt: nowIso(),
    };

    this.tasks.set(id, updated);
    return Promise.resolve(updated);
  }

  deleteTask(id: string): Promise<boolean> {
    return Promise.resolve(this.tasks.delete(id));
  }

  listMemos(): Promise<MemoItem[]> {
    return Promise.resolve(
      Array.from(this.memos.values()).sort(
        (left, right) => (left.sortOrder ?? 0) - (right.sortOrder ?? 0),
      ),
    );
  }

  getMemo(id: string): Promise<MemoItem | null> {
    return Promise.resolve(this.memos.get(id) ?? null);
  }

  createMemo(input: CreateMemoInput): Promise<MemoItem> {
    const timestamp = nowIso();
    const item: MemoItem = {
      id: randomUUID(),
      type: 'memo',
      title: input.title,
      description: input.description,
      timezone: input.timezone,
      reminders: input.reminders,
      status: 'active',
      createdAt: timestamp,
      updatedAt: timestamp,
      syncState: 'synced',
      listId: input.listId,
      estimatedDurationMinutes: input.estimatedDurationMinutes,
      sortOrder: input.sortOrder,
    };

    this.memos.set(item.id, item);
    return Promise.resolve(item);
  }

  updateMemo(id: string, input: UpdateMemoInput): Promise<MemoItem | null> {
    const current = this.memos.get(id);

    if (!current) {
      return Promise.resolve(null);
    }

    const updated: MemoItem = {
      ...current,
      ...input,
      archivedAt: input.archivedAt === null ? undefined : input.archivedAt ?? current.archivedAt,
      updatedAt: nowIso(),
    };

    this.memos.set(id, updated);
    return Promise.resolve(updated);
  }

  deleteMemo(id: string): Promise<boolean> {
    return Promise.resolve(this.memos.delete(id));
  }
}
