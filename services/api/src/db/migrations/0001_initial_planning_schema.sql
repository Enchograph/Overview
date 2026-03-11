CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS planning_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('schedule', 'task', 'memo')),
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  timezone TEXT,
  reminders JSONB NOT NULL DEFAULT '[]'::jsonb,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  created_by UUID,
  last_modified_by_device TEXT,
  sync_state TEXT NOT NULL CHECK (
    sync_state IN ('local_only', 'pending_push', 'synced', 'pending_delete', 'conflict')
  ),
  language_meta JSONB,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,
  duration_minutes INTEGER,
  planned_start_at TIMESTAMPTZ,
  planned_end_at TIMESTAMPTZ,
  planned_duration_minutes INTEGER,
  due_at TIMESTAMPTZ,
  completion_at TIMESTAMPTZ,
  recurrence_rule JSONB,
  list_id TEXT,
  estimated_duration_minutes INTEGER,
  sort_order INTEGER,
  archived_at TIMESTAMPTZ,
  CHECK (
    (type = 'schedule' AND start_at IS NOT NULL)
    OR (type = 'task' AND planned_start_at IS NOT NULL AND due_at IS NOT NULL)
    OR (type = 'memo' AND list_id IS NOT NULL)
  ),
  CHECK (
    (type = 'schedule' AND status IN ('active', 'done', 'cancelled', 'archived'))
    OR (type = 'task' AND status IN ('todo', 'in_progress', 'done', 'cancelled'))
    OR (type = 'memo' AND status IN ('active', 'done', 'cancelled', 'archived'))
  )
);

CREATE INDEX IF NOT EXISTS planning_items_type_idx ON planning_items (type);
CREATE INDEX IF NOT EXISTS planning_items_sync_state_idx ON planning_items (sync_state);
CREATE INDEX IF NOT EXISTS planning_items_created_by_idx ON planning_items (created_by);
CREATE INDEX IF NOT EXISTS planning_items_schedule_window_idx
  ON planning_items (start_at, end_at)
  WHERE type = 'schedule';
CREATE INDEX IF NOT EXISTS planning_items_task_due_idx
  ON planning_items (due_at, planned_start_at)
  WHERE type = 'task';
CREATE INDEX IF NOT EXISTS planning_items_memo_list_idx
  ON planning_items (list_id, sort_order)
  WHERE type = 'memo';
