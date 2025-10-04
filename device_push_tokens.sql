-- Creates a table to store OneSignal player IDs per user (Android-only for now)
create table if not exists public.device_push_tokens (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  onesignal_player_id text not null,
  platform text check (platform in ('android','ios','web')) default 'android',
  last_seen timestamptz not null default now(),
  unique (user_id, onesignal_player_id)
);

alter table public.device_push_tokens enable row level security;

create policy if not exists "Users manage own device tokens"
on public.device_push_tokens
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);



