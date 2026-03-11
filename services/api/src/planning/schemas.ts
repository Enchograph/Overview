import { randomUUID } from 'node:crypto';

import { z } from 'zod';

import {
  planningStatuses,
  reminderKinds,
  recurrenceFrequencies,
  taskStatuses,
} from '@overview/shared';

const isoDateTimeSchema = z.string().datetime({ offset: true });

const reminderSchema = z.object({
  id: z.string().trim().min(1).default(() => randomUUID()),
  kind: z.enum(reminderKinds),
  minutesBefore: z.coerce.number().int().nonnegative().optional(),
  at: isoDateTimeSchema.optional(),
});

const recurrenceRuleSchema = z.object({
  frequency: z.enum(recurrenceFrequencies),
  interval: z.coerce.number().int().positive().optional(),
  until: isoDateTimeSchema.optional(),
  count: z.coerce.number().int().positive().optional(),
  skippedDates: z.array(isoDateTimeSchema).optional(),
});

const scheduleBaseSchema = z.object({
  title: z.string().trim().min(1),
  description: z.string().trim().min(1).optional(),
  location: z.string().trim().min(1).optional(),
  timezone: z.string().trim().min(1).optional(),
  reminders: z.array(reminderSchema).default([]),
  startAt: isoDateTimeSchema,
  endAt: isoDateTimeSchema.optional(),
  durationMinutes: z.coerce.number().int().positive().optional(),
  recurrenceRule: recurrenceRuleSchema.optional(),
});

const taskBaseSchema = z.object({
  title: z.string().trim().min(1),
  description: z.string().trim().min(1).optional(),
  location: z.string().trim().min(1).optional(),
  timezone: z.string().trim().min(1).optional(),
  reminders: z.array(reminderSchema).default([]),
  plannedStartAt: isoDateTimeSchema,
  plannedEndAt: isoDateTimeSchema.optional(),
  plannedDurationMinutes: z.coerce.number().int().positive().optional(),
  dueAt: isoDateTimeSchema,
  recurrenceRule: recurrenceRuleSchema.optional(),
});

const memoBaseSchema = z.object({
  title: z.string().trim().min(1),
  description: z.string().trim().min(1).optional(),
  timezone: z.string().trim().min(1).optional(),
  reminders: z.array(reminderSchema).default([]),
  listId: z.string().trim().min(1),
  estimatedDurationMinutes: z.coerce.number().int().positive().optional(),
  sortOrder: z.coerce.number().int().optional(),
});

export const createScheduleSchema = scheduleBaseSchema;
export const updateScheduleSchema = scheduleBaseSchema
  .partial()
  .extend({
    status: z.enum(planningStatuses).optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'At least one field is required',
  });

export const createTaskSchema = taskBaseSchema;
export const updateTaskSchema = taskBaseSchema
  .partial()
  .extend({
    status: z.enum(taskStatuses).optional(),
    completionAt: isoDateTimeSchema.optional().nullable(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'At least one field is required',
  });

export const createMemoSchema = memoBaseSchema;
export const updateMemoSchema = memoBaseSchema
  .partial()
  .extend({
    status: z.enum(planningStatuses).optional(),
    archivedAt: isoDateTimeSchema.optional().nullable(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'At least one field is required',
  });

export const idParamSchema = z.object({
  id: z.string().uuid(),
});
