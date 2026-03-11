import type {
  CreateMemoInput,
  CreateScheduleInput,
  CreateTaskInput,
  MemoItem,
  ScheduleItem,
  TaskItem,
} from '@overview/shared';

export interface UpdateScheduleInput extends Partial<CreateScheduleInput> {
  title?: string;
  status?: ScheduleItem['status'];
}

export interface UpdateTaskInput extends Partial<CreateTaskInput> {
  title?: string;
  status?: TaskItem['status'];
  completionAt?: TaskItem['completionAt'] | null;
}

export interface UpdateMemoInput extends Partial<CreateMemoInput> {
  title?: string;
  status?: MemoItem['status'];
  archivedAt?: MemoItem['archivedAt'] | null;
}

export interface PlanningRepository {
  listSchedules(): Promise<ScheduleItem[]>;
  getSchedule(id: string): Promise<ScheduleItem | null>;
  createSchedule(input: CreateScheduleInput): Promise<ScheduleItem>;
  updateSchedule(id: string, input: UpdateScheduleInput): Promise<ScheduleItem | null>;
  deleteSchedule(id: string): Promise<boolean>;
  listTasks(): Promise<TaskItem[]>;
  getTask(id: string): Promise<TaskItem | null>;
  createTask(input: CreateTaskInput): Promise<TaskItem>;
  updateTask(id: string, input: UpdateTaskInput): Promise<TaskItem | null>;
  deleteTask(id: string): Promise<boolean>;
  listMemos(): Promise<MemoItem[]>;
  getMemo(id: string): Promise<MemoItem | null>;
  createMemo(input: CreateMemoInput): Promise<MemoItem>;
  updateMemo(id: string, input: UpdateMemoInput): Promise<MemoItem | null>;
  deleteMemo(id: string): Promise<boolean>;
}
