-- Migration: Messaging Polish Features
-- Adds read receipts, pins, threading, and search capabilities

-- Enable pg_trgm for search if not already
create extension if not exists pg_trgm;

-- Threading: Add parent_message_id for proper threading (if not exists)
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='messages' and column_name='parent_message_id'
  ) then
    alter table public.messages
      add column parent_message_id uuid references public.messages(id) on delete cascade;
    create index if not exists messages_parent_idx on public.messages(parent_message_id);
  end if;
end $$;

-- Read receipts table
create table if not exists public.message_reads (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  reader_id uuid not null references auth.users(id),
  read_at timestamptz not null default now(),
  unique (message_id, reader_id)
);
create index if not exists message_reads_msg_idx on public.message_reads(message_id);
create index if not exists message_reads_reader_idx on public.message_reads(reader_id);
alter table public.message_reads enable row level security;

-- Pins table
create table if not exists public.message_pins (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  pinned_at timestamptz not null default now(),
  unique (message_id, user_id)
);
create index if not exists message_pins_msg_idx on public.message_pins(message_id);
create index if not exists message_pins_user_idx on public.message_pins(user_id);
alter table public.message_pins enable row level security;

-- Search index for messages content
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='messages' and column_name='text'
  ) then
    create index if not exists messages_text_trgm
    on public.messages using gin (text gin_trgm_ops);
  end if;
end $$;

-- RLS policies for read receipts
do $$
begin
  -- READ RECEIPTS: reader can select their own; senders can see receipts on their sent messages
  if not exists (select 1 from pg_policies where policyname = 'msg_reads_select_own_or_sender') then
    create policy msg_reads_select_own_or_sender on public.message_reads
    for select to authenticated
    using (
      reader_id = auth.uid()
      or exists (
        select 1 from public.messages m
        where m.id = message_reads.message_id and m.sender_id = auth.uid()
      )
    );
  end if;

  if not exists (select 1 from pg_policies where policyname = 'msg_reads_insert_self') then
    create policy msg_reads_insert_self on public.message_reads
    for insert to authenticated
    with check (reader_id = auth.uid());
  end if;

  -- PINS: users can see/insert/delete only their own pins
  if not exists (select 1 from pg_policies where policyname = 'msg_pins_select_own') then
    create policy msg_pins_select_own on public.message_pins
    for select to authenticated
    using (user_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'msg_pins_insert_own') then
    create policy msg_pins_insert_own on public.message_pins
    for insert to authenticated
    with check (user_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'msg_pins_delete_own') then
    create policy msg_pins_delete_own on public.message_pins
    for delete to authenticated
    using (user_id = auth.uid());
  end if;
end $$;

select 'messaging polish ready' as status;
