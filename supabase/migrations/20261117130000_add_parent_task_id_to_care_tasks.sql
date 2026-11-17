-- Add parent_task_id to public.care_tasks to establish strong relational lineage for recurring tasks
-- This prevents false-positive conflicts where tasks with identical titles on the same plant block next due date creation.

alter table public.care_tasks
  add column if not exists parent_task_id uuid references public.care_tasks(id) on delete set null;

create index if not exists care_tasks_parent_task_id_idx on public.care_tasks (parent_task_id);
