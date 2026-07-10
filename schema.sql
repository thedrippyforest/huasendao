
-- 花森島 Project Hub 多人協作版
create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  role text not null default 'member' check (role in ('pm','lead','member')),
  team text,
  created_at timestamptz not null default now()
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  team text not null,
  category text,
  subcategory text,
  title text not null,
  owner_name text,
  owner_user_id uuid references profiles(id) on delete set null,
  start_date date,
  due_date date,
  dependency_codes text[] not null default '{}',
  priority text not null default '中' check (priority in ('高','中','低')),
  status text not null default '未開始' check (status in ('未開始','進行中','待確認','已完成')),
  progress int not null default 0 check (progress between 0 and 100),
  milestone text,
  notes text,
  created_by uuid references profiles(id) on delete set null,
  updated_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists meetings (
  id uuid primary key default gen_random_uuid(),
  week_start date not null,
  type text not null default '進度追蹤',
  topic text not null,
  decision text,
  owner_name text,
  status text not null default '待討論',
  linked_task_id uuid references tasks(id) on delete set null,
  created_by uuid references profiles(id) on delete set null,
  updated_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists meeting_summaries (
  id uuid primary key default gen_random_uuid(),
  week_start date unique not null,
  goal text,
  important_decisions text,
  risks text,
  updated_by uuid references profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

create table if not exists activity_log (
  id bigint generated always as identity primary key,
  actor_id uuid references profiles(id) on delete set null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  summary text,
  created_at timestamptz not null default now()
);

create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_tasks_updated_at on tasks;
create trigger trg_tasks_updated_at before update on tasks
for each row execute function set_updated_at();

drop trigger if exists trg_meetings_updated_at on meetings;
create trigger trg_meetings_updated_at before update on meetings
for each row execute function set_updated_at();

drop trigger if exists trg_meeting_summaries_updated_at on meeting_summaries;
create trigger trg_meeting_summaries_updated_at before update on meeting_summaries
for each row execute function set_updated_at();

-- 建立新使用者時自動建立 profile
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, role, team)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    'member',
    null
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table profiles enable row level security;
alter table tasks enable row level security;
alter table meetings enable row level security;
alter table meeting_summaries enable row level security;
alter table activity_log enable row level security;

-- 已登入成員可讀取
drop policy if exists "profiles read authenticated" on profiles;
create policy "profiles read authenticated" on profiles
for select to authenticated using (true);

drop policy if exists "profiles update own" on profiles;
create policy "profiles update own" on profiles
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "tasks read authenticated" on tasks;
create policy "tasks read authenticated" on tasks
for select to authenticated using (true);

drop policy if exists "tasks insert authenticated" on tasks;
create policy "tasks insert authenticated" on tasks
for insert to authenticated with check (true);

drop policy if exists "tasks update authenticated" on tasks;
create policy "tasks update authenticated" on tasks
for update to authenticated using (true) with check (true);

drop policy if exists "tasks delete authenticated" on tasks;
create policy "tasks delete authenticated" on tasks
for delete to authenticated using (true);

drop policy if exists "meetings read authenticated" on meetings;
create policy "meetings read authenticated" on meetings
for select to authenticated using (true);

drop policy if exists "meetings write authenticated" on meetings;
create policy "meetings write authenticated" on meetings
for all to authenticated using (true) with check (true);

drop policy if exists "summaries read authenticated" on meeting_summaries;
create policy "summaries read authenticated" on meeting_summaries
for select to authenticated using (true);

drop policy if exists "summaries write authenticated" on meeting_summaries;
create policy "summaries write authenticated" on meeting_summaries
for all to authenticated using (true) with check (true);

drop policy if exists "activity log read authenticated" on activity_log;
create policy "activity log read authenticated" on activity_log
for select to authenticated using (true);

drop policy if exists "activity log insert authenticated" on activity_log;
create policy "activity log insert authenticated" on activity_log
for insert to authenticated with check (true);

-- Realtime
do $$
begin
  alter publication supabase_realtime add table tasks;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table meetings;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table meeting_summaries;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table activity_log;
exception when duplicate_object then null;
end $$;
