-- Migration: Messaging Polish Features
-- Adds read receipts, pins, threading, and search capabilities

-- Enable pg_trgm for search if not already
create extension if not exists pg_trgm;

-- Messages table (create if it doesn't exist)
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid references auth.users(id) on delete cascade,
  content text not null,
  message_type text default 'text' check (message_type in ('text', 'image', 'file', 'system')),
  created_at timestamptz not null default now(),
  updated_at timestamptz default now(),
  is_read boolean default false,
  is_pinned boolean default false,
  parent_message_id uuid references public.messages(id) on delete cascade
);

-- Indexes for messages
create index if not exists idx_messages_sender_id on public.messages(sender_id);
create index if not exists idx_messages_recipient_id on public.messages(recipient_id);
create index if not exists idx_messages_created_at on public.messages(created_at desc);
create index if not exists messages_parent_idx on public.messages(parent_message_id);

-- Enable RLS on messages
alter table public.messages enable row level security;

-- RLS policies for messages
do $$
begin
  -- Users can read messages they sent or received
  if not exists (select 1 from pg_policies where policyname = 'messages_select_own') then
    create policy messages_select_own on public.messages
      for select to authenticated
      using (sender_id = auth.uid() or recipient_id = auth.uid());
  end if;

  -- Users can insert messages
  if not exists (select 1 from pg_policies where policyname = 'messages_insert_own') then
    create policy messages_insert_own on public.messages
      for insert to authenticated
      with check (sender_id = auth.uid());
  end if;

  -- Users can update their own messages
  if not exists (select 1 from pg_policies where policyname = 'messages_update_own') then
    create policy messages_update_own on public.messages
      for update to authenticated
      using (sender_id = auth.uid())
      with check (sender_id = auth.uid());
  end if;

  -- Users can delete their own messages
  if not exists (select 1 from pg_policies where policyname = 'messages_delete_own') then
    create policy messages_delete_own on public.messages
      for delete to authenticated
      using (sender_id = auth.uid());
  end if;
end $$;

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
