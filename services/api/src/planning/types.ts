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
  listSchedules(userId: string): Promise<ScheduleItem[]>;
  getSchedule(id: string, userId: string): Promise<ScheduleItem | null>;
  createSchedule(input: CreateScheduleInput, userId: string): Promise<ScheduleItem>;
  updateSchedule(
    id: string,
    input: UpdateScheduleInput,
    userId: string,
  ): Promise<ScheduleItem | null>;
  deleteSchedule(id: string, userId: string): Promise<boolean>;
  listTasks(userId: string): Promise<TaskItem[]>;
  getTask(id: string, userId: string): Promise<TaskItem | null>;
  createTask(input: CreateTaskInput, userId: string): Promise<TaskItem>;
  updateTask(id: string, input: UpdateTaskInput, userId: string): Promise<TaskItem | null>;
  deleteTask(id: string, userId: string): Promise<boolean>;
  listMemos(userId: string): Promise<MemoItem[]>;
  getMemo(id: string, userId: string): Promise<MemoItem | null>;
  createMemo(input: CreateMemoInput, userId: string): Promise<MemoItem>;
  updateMemo(id: string, input: UpdateMemoInput, userId: string): Promise<MemoItem | null>;
  deleteMemo(id: string, userId: string): Promise<boolean>;
}
