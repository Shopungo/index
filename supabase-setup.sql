-- ChronoBlock private cloud sync setup
-- Run this once in Supabase Dashboard > SQL Editor.

create table if not exists public.user_app_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_app_state enable row level security;

revoke all on table public.user_app_state from anon, public;
grant select, insert, update on table public.user_app_state to authenticated;

drop policy if exists "Users can read their own ChronoBlock state" on public.user_app_state;
create policy "Users can read their own ChronoBlock state"
  on public.user_app_state for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own ChronoBlock state" on public.user_app_state;
create policy "Users can create their own ChronoBlock state"
  on public.user_app_state for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own ChronoBlock state" on public.user_app_state;
create policy "Users can update their own ChronoBlock state"
  on public.user_app_state for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function public.set_user_app_state_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_app_state_updated_at on public.user_app_state;
create trigger set_user_app_state_updated_at
  before update on public.user_app_state
  for each row execute function public.set_user_app_state_updated_at();
