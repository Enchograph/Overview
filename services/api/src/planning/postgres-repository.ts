import { randomUUID } from 'node:crypto';

import type {
  CreateMemoInput,
  CreateScheduleInput,
  CreateTaskInput,
  MemoItem,
  RecurrenceRule,
  ScheduleItem,
  TaskItem,
} from '@overview/shared';
import type { PlanningStatus, Reminder, SyncState, TaskStatus } from '@overview/shared';
import type { Pool, QueryResultRow } from 'pg';

import type { AppEnv } from '../config/env.js';
import type {
  PlanningRepository,
  UpdateMemoInput,
  UpdateScheduleInput,
  UpdateTaskInput,
} from './types.js';

interface PlanningRow extends QueryResultRow {
  id: string;
  type: 'schedule' | 'task' | 'memo';
  title: string;
  description: string | null;
  location: string | null;
  timezone: string | null;
  reminders: Reminder[] | null;
  status: string;
  created_at: Date | string;
  updated_at: Date | string;
  deleted_at: Date | string | null;
  created_by: string | null;
  last_modified_by_device: string | null;
  sync_state: SyncState;
  language_meta: ScheduleItem['languageMeta'] | null;
  start_at: Date | string | null;
  end_at: Date | string | null;
  duration_minutes: number | null;
  planned_start_at: Date | string | null;
  planned_end_at: Date | string | null;
  planned_duration_minutes: number | null;
  due_at: Date | string | null;
  completion_at: Date | string | null;
  recurrence_rule: RecurrenceRule | null;
  list_id: string | null;
  estimated_duration_minutes: number | null;
  sort_order: number | null;
  archived_at: Date | string | null;
}

type UpdatePayload = UpdateScheduleInput | UpdateTaskInput | UpdateMemoInput;

interface PersistedPlanningFields {
  title?: string;
  description?: string;
  location?: string;
  timezone?: string;
  reminders?: Reminder[];
  status?: string;
  startAt?: string;
  endAt?: string;
  durationMinutes?: number;
  plannedStartAt?: string;
  plannedEndAt?: string;
  plannedDurationMinutes?: number;
  dueAt?: string;
  completionAt?: string | null;
  recurrenceRule?: RecurrenceRule;
  listId?: string;
  estimatedDurationMinutes?: number;
  sortOrder?: number;
  archivedAt?: string | null;
}

function quoteIdentifier(value: string): string {
  return `"${value.replaceAll('"', '""')}"`;
}

function toIso(value: Date | string | null | undefined): string | undefined {
  if (!value) {
    return undefined;
  }

  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}

function mapSchedule(row: PlanningRow): ScheduleItem {
  return {
    id: row.id,
    type: 'schedule',
    title: row.title,
    description: row.description ?? undefined,
    location: row.location ?? undefined,
    timezone: row.timezone ?? undefined,
    reminders: row.reminders ?? [],
    status: row.status as PlanningStatus,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
    deletedAt: toIso(row.deleted_at),
    createdBy: row.created_by ?? undefined,
    lastModifiedByDevice: row.last_modified_by_device ?? undefined,
    syncState: row.sync_state,
    languageMeta: row.language_meta ?? undefined,
    startAt: new Date(String(row.start_at)).toISOString(),
    endAt: toIso(row.end_at),
    durationMinutes: row.duration_minutes ?? undefined,
    recurrenceRule: row.recurrence_rule ?? undefined,
  };
}

function mapTask(row: PlanningRow): TaskItem {
  return {
    id: row.id,
    type: 'task',
    title: row.title,
    description: row.description ?? undefined,
    location: row.location ?? undefined,
    timezone: row.timezone ?? undefined,
    reminders: row.reminders ?? [],
    status: row.status as TaskStatus,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
    deletedAt: toIso(row.deleted_at),
    createdBy: row.created_by ?? undefined,
    lastModifiedByDevice: row.last_modified_by_device ?? undefined,
    syncState: row.sync_state,
    languageMeta: row.language_meta ?? undefined,
    plannedStartAt: new Date(String(row.planned_start_at)).toISOString(),
    plannedEndAt: toIso(row.planned_end_at),
    plannedDurationMinutes: row.planned_duration_minutes ?? undefined,
    dueAt: new Date(String(row.due_at)).toISOString(),
    recurrenceRule: row.recurrence_rule ?? undefined,
    completionAt: toIso(row.completion_at),
  };
}

function mapMemo(row: PlanningRow): MemoItem {
  return {
    id: row.id,
    type: 'memo',
    title: row.title,
    description: row.description ?? undefined,
    timezone: row.timezone ?? undefined,
    reminders: row.reminders ?? [],
    status: row.status as PlanningStatus,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
    deletedAt: toIso(row.deleted_at),
    createdBy: row.created_by ?? undefined,
    lastModifiedByDevice: row.last_modified_by_device ?? undefined,
    syncState: row.sync_state,
    languageMeta: row.language_meta ?? undefined,
    listId: String(row.list_id),
    estimatedDurationMinutes: row.estimated_duration_minutes ?? undefined,
    sortOrder: row.sort_order ?? undefined,
    archivedAt: toIso(row.archived_at),
  };
}

function cleanUndefined<T extends Record<string, unknown>>(input: T): T {
  return Object.fromEntries(
    Object.entries(input).filter(([, value]) => value !== undefined),
  ) as T;
}

function buildTableName(env: AppEnv): string {
  return `${quoteIdentifier(env.DATABASE_SCHEMA)}.${quoteIdentifier('planning_items')}`;
}

export class PostgresPlanningRepository implements PlanningRepository {
  private readonly tableName: string;

  constructor(
    private readonly pool: Pool,
    env: AppEnv,
  ) {
    this.tableName = buildTableName(env);
  }

  async listSchedules(): Promise<ScheduleItem[]> {
    const result = await this.pool.query<PlanningRow>(
      `SELECT * FROM ${this.tableName} WHERE type = 'schedule' AND deleted_at IS NULL ORDER BY start_at ASC, created_at ASC`,
    );
    return result.rows.map(mapSchedule);
  }

  async getSchedule(id: string): Promise<ScheduleItem | null> {
    const row = await this.getById(id, 'schedule');
    return row ? mapSchedule(row) : null;
  }

  async createSchedule(input: CreateScheduleInput): Promise<ScheduleItem> {
    const row = await this.insertRow('schedule', cleanUndefined({
      title: input.title,
      description: input.description,
      location: input.location,
      timezone: input.timezone,
      reminders: input.reminders,
      status: 'active',
      syncState: 'synced',
      startAt: input.startAt,
      endAt: input.endAt,
      durationMinutes: input.durationMinutes,
      recurrenceRule: input.recurrenceRule,
    }));
    return mapSchedule(row);
  }

  async updateSchedule(id: string, input: UpdateScheduleInput): Promise<ScheduleItem | null> {
    const row = await this.updateRow(id, 'schedule', input);
    return row ? mapSchedule(row) : null;
  }

  async deleteSchedule(id: string): Promise<boolean> {
    return this.softDelete(id, 'schedule');
  }

  async listTasks(): Promise<TaskItem[]> {
    const result = await this.pool.query<PlanningRow>(
      `SELECT * FROM ${this.tableName} WHERE type = 'task' AND deleted_at IS NULL ORDER BY due_at ASC, created_at ASC`,
    );
    return result.rows.map(mapTask);
  }

  async getTask(id: string): Promise<TaskItem | null> {
    const row = await this.getById(id, 'task');
    return row ? mapTask(row) : null;
  }

  async createTask(input: CreateTaskInput): Promise<TaskItem> {
    const row = await this.insertRow('task', cleanUndefined({
      title: input.title,
      description: input.description,
      location: input.location,
      timezone: input.timezone,
      reminders: input.reminders,
      status: 'todo',
      syncState: 'synced',
      plannedStartAt: input.plannedStartAt,
      plannedEndAt: input.plannedEndAt,
      plannedDurationMinutes: input.plannedDurationMinutes,
      dueAt: input.dueAt,
      recurrenceRule: input.recurrenceRule,
    }));
    return mapTask(row);
  }

  async updateTask(id: string, input: UpdateTaskInput): Promise<TaskItem | null> {
    const row = await this.updateRow(id, 'task', input);
    return row ? mapTask(row) : null;
  }

  async deleteTask(id: string): Promise<boolean> {
    return this.softDelete(id, 'task');
  }

  async listMemos(): Promise<MemoItem[]> {
    const result = await this.pool.query<PlanningRow>(
      `SELECT * FROM ${this.tableName} WHERE type = 'memo' AND deleted_at IS NULL ORDER BY list_id ASC, sort_order ASC NULLS LAST, created_at ASC`,
    );
    return result.rows.map(mapMemo);
  }

  async getMemo(id: string): Promise<MemoItem | null> {
    const row = await this.getById(id, 'memo');
    return row ? mapMemo(row) : null;
  }

  async createMemo(input: CreateMemoInput): Promise<MemoItem> {
    const row = await this.insertRow('memo', cleanUndefined({
      title: input.title,
      description: input.description,
      timezone: input.timezone,
      reminders: input.reminders,
      status: 'active',
      syncState: 'synced',
      listId: input.listId,
      estimatedDurationMinutes: input.estimatedDurationMinutes,
      sortOrder: input.sortOrder,
    }));
    return mapMemo(row);
  }

  async updateMemo(id: string, input: UpdateMemoInput): Promise<MemoItem | null> {
    const row = await this.updateRow(id, 'memo', input);
    return row ? mapMemo(row) : null;
  }

  async deleteMemo(id: string): Promise<boolean> {
    return this.softDelete(id, 'memo');
  }

  private async getById(
    id: string,
    type: 'schedule' | 'task' | 'memo',
  ): Promise<PlanningRow | null> {
    const result = await this.pool.query<PlanningRow>(
      `SELECT * FROM ${this.tableName} WHERE id = $1 AND type = $2 AND deleted_at IS NULL LIMIT 1`,
      [id, type],
    );
    return result.rows[0] ?? null;
  }

  private async insertRow(
    type: 'schedule' | 'task' | 'memo',
    fields: Record<string, unknown>,
  ): Promise<PlanningRow> {
    const result = await this.pool.query<PlanningRow>(
      `
        INSERT INTO ${this.tableName} (
          id, type, title, description, location, timezone, reminders, status,
          created_at, updated_at, created_by, last_modified_by_device,
          sync_state, language_meta, start_at, end_at, duration_minutes,
          planned_start_at, planned_end_at, planned_duration_minutes, due_at,
          completion_at, recurrence_rule, list_id, estimated_duration_minutes,
          sort_order, archived_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7::jsonb, $8,
          NOW(), NOW(), $9, $10,
          $11, $12::jsonb, $13, $14, $15,
          $16, $17, $18, $19,
          $20, $21::jsonb, $22, $23,
          $24, $25
        )
        RETURNING *
      `,
      [
        randomUUID(),
        type,
        fields.title,
        fields.description ?? null,
        fields.location ?? null,
        fields.timezone ?? null,
        JSON.stringify(fields.reminders ?? []),
        fields.status,
        fields.createdBy ?? null,
        fields.lastModifiedByDevice ?? null,
        fields.syncState,
        fields.languageMeta ? JSON.stringify(fields.languageMeta) : null,
        fields.startAt ?? null,
        fields.endAt ?? null,
        fields.durationMinutes ?? null,
        fields.plannedStartAt ?? null,
        fields.plannedEndAt ?? null,
        fields.plannedDurationMinutes ?? null,
        fields.dueAt ?? null,
        fields.completionAt ?? null,
        fields.recurrenceRule ? JSON.stringify(fields.recurrenceRule) : null,
        fields.listId ?? null,
        fields.estimatedDurationMinutes ?? null,
        fields.sortOrder ?? null,
        fields.archivedAt ?? null,
      ],
    );

    return result.rows[0] as PlanningRow;
  }

  private async updateRow(
    id: string,
    type: 'schedule' | 'task' | 'memo',
    input: UpdatePayload,
  ): Promise<PlanningRow | null> {
    const current = await this.getById(id, type);

    if (!current) {
      return null;
    }

    const updateInput = input as PersistedPlanningFields;

    const next = {
      title: updateInput.title ?? current.title,
      description: updateInput.description ?? current.description,
      location: updateInput.location ?? current.location,
      timezone: updateInput.timezone ?? current.timezone,
      reminders: updateInput.reminders ?? current.reminders ?? [],
      status: updateInput.status ?? current.status,
      startAt: updateInput.startAt ?? current.start_at,
      endAt: updateInput.endAt ?? current.end_at,
      durationMinutes: updateInput.durationMinutes ?? current.duration_minutes,
      plannedStartAt: updateInput.plannedStartAt ?? current.planned_start_at,
      plannedEndAt: updateInput.plannedEndAt ?? current.planned_end_at,
      plannedDurationMinutes:
        updateInput.plannedDurationMinutes ?? current.planned_duration_minutes,
      dueAt: updateInput.dueAt ?? current.due_at,
      completionAt:
        Object.prototype.hasOwnProperty.call(updateInput, 'completionAt')
          ? updateInput.completionAt ?? null
          : current.completion_at,
      recurrenceRule: updateInput.recurrenceRule ?? current.recurrence_rule,
      listId: updateInput.listId ?? current.list_id,
      estimatedDurationMinutes:
        updateInput.estimatedDurationMinutes ?? current.estimated_duration_minutes,
      sortOrder: updateInput.sortOrder ?? current.sort_order,
      archivedAt:
        Object.prototype.hasOwnProperty.call(updateInput, 'archivedAt')
          ? updateInput.archivedAt ?? null
          : current.archived_at,
    };

    const result = await this.pool.query<PlanningRow>(
      `
        UPDATE ${this.tableName}
        SET
          title = $3,
          description = $4,
          location = $5,
          timezone = $6,
          reminders = $7::jsonb,
          status = $8,
          updated_at = NOW(),
          start_at = $9,
          end_at = $10,
          duration_minutes = $11,
          planned_start_at = $12,
          planned_end_at = $13,
          planned_duration_minutes = $14,
          due_at = $15,
          completion_at = $16,
          recurrence_rule = $17::jsonb,
          list_id = $18,
          estimated_duration_minutes = $19,
          sort_order = $20,
          archived_at = $21
        WHERE id = $1 AND type = $2 AND deleted_at IS NULL
        RETURNING *
      `,
      [
        id,
        type,
        next.title,
        next.description,
        next.location,
        next.timezone,
        JSON.stringify(next.reminders ?? []),
        next.status,
        next.startAt,
        next.endAt,
        next.durationMinutes,
        next.plannedStartAt,
        next.plannedEndAt,
        next.plannedDurationMinutes,
        next.dueAt,
        next.completionAt,
        next.recurrenceRule ? JSON.stringify(next.recurrenceRule) : null,
        next.listId,
        next.estimatedDurationMinutes,
        next.sortOrder,
        next.archivedAt,
      ],
    );

    return result.rows[0] ?? null;
  }

  private async softDelete(
    id: string,
    type: 'schedule' | 'task' | 'memo',
  ): Promise<boolean> {
    const result = await this.pool.query(
      `
        UPDATE ${this.tableName}
        SET deleted_at = NOW(), updated_at = NOW()
        WHERE id = $1 AND type = $2 AND deleted_at IS NULL
      `,
      [id, type],
    );

    return result.rowCount === 1;
  }
}
