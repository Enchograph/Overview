export const planningItemTypes = ['schedule', 'task', 'memo'] as const;

export type PlanningItemType = (typeof planningItemTypes)[number];

export const planningStatuses = [
  'active',
  'done',
  'cancelled',
  'archived',
] as const;

export type PlanningStatus = (typeof planningStatuses)[number];

export const taskStatuses = [
  'todo',
  'in_progress',
  'done',
  'cancelled',
] as const;

export type TaskStatus = (typeof taskStatuses)[number];

export const syncStates = [
  'local_only',
  'pending_push',
  'synced',
  'pending_delete',
  'conflict',
] as const;

export type SyncState = (typeof syncStates)[number];

export const recurrenceFrequencies = [
  'daily',
  'weekly',
  'monthly',
  'interval',
] as const;

export type RecurrenceFrequency = (typeof recurrenceFrequencies)[number];

export const reminderKinds = [
  'relative_before',
  'due_before',
  'absolute',
  'daily_summary',
] as const;

export type ReminderKind = (typeof reminderKinds)[number];

export type IsoDateTimeString = string;
export type EntityId = string;
export type UserId = string;
export type DeviceId = string;
export type ListId = string;

export interface LanguageMeta {
  sourceLanguage?: string;
  inputMethod?: 'manual' | 'ai_text' | 'ai_voice';
}

export interface Reminder {
  id: EntityId;
  kind: ReminderKind;
  minutesBefore?: number;
  at?: IsoDateTimeString;
}

export interface RecurrenceRule {
  frequency: RecurrenceFrequency;
  interval?: number;
  until?: IsoDateTimeString;
  count?: number;
  skippedDates?: IsoDateTimeString[];
}

export interface PlanningEntityBase {
  id: EntityId;
  type: PlanningItemType;
  title: string;
  description?: string;
  location?: string;
  timezone?: string;
  reminders: Reminder[];
  status: PlanningStatus;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
  deletedAt?: IsoDateTimeString;
  createdBy?: UserId;
  lastModifiedByDevice?: DeviceId;
  syncState: SyncState;
  languageMeta?: LanguageMeta;
}

export interface ScheduleItem extends PlanningEntityBase {
  type: 'schedule';
  startAt: IsoDateTimeString;
  endAt?: IsoDateTimeString;
  durationMinutes?: number;
  recurrenceRule?: RecurrenceRule;
}

export interface TaskItem extends Omit<PlanningEntityBase, 'status'> {
  type: 'task';
  plannedStartAt: IsoDateTimeString;
  plannedEndAt?: IsoDateTimeString;
  plannedDurationMinutes?: number;
  dueAt: IsoDateTimeString;
  recurrenceRule?: RecurrenceRule;
  status: TaskStatus;
  completionAt?: IsoDateTimeString;
}

export interface MemoItem extends PlanningEntityBase {
  type: 'memo';
  listId: ListId;
  estimatedDurationMinutes?: number;
  sortOrder?: number;
  archivedAt?: IsoDateTimeString;
}

export type PlanningItem = ScheduleItem | TaskItem | MemoItem;

export type CreateScheduleInput = Pick<
  ScheduleItem,
  | 'title'
  | 'startAt'
  | 'description'
  | 'location'
  | 'timezone'
  | 'reminders'
  | 'durationMinutes'
  | 'endAt'
  | 'recurrenceRule'
>;

export type CreateTaskInput = Pick<
  TaskItem,
  | 'title'
  | 'plannedStartAt'
  | 'dueAt'
  | 'description'
  | 'location'
  | 'timezone'
  | 'reminders'
  | 'plannedEndAt'
  | 'plannedDurationMinutes'
  | 'recurrenceRule'
>;

export type CreateMemoInput = Pick<
  MemoItem,
  | 'title'
  | 'listId'
  | 'description'
  | 'timezone'
  | 'reminders'
  | 'estimatedDurationMinutes'
  | 'sortOrder'
>;

export function isPlanningItemType(value: string): value is PlanningItemType {
  return planningItemTypes.includes(value as PlanningItemType);
}

export function isWeekViewItem(item: PlanningItem): item is ScheduleItem | TaskItem {
  return item.type === 'schedule' || item.type === 'task';
}

export function isTaskDone(task: TaskItem): boolean {
  return task.status === 'done';
}
