-- 0022_support_inbox_v1.sql
-- Real support inbox tables + policies. Idempotent, safe to re-run.

-- Helper: detect table
create or replace function public._table_exists(tbl text)
returns boolean language sql stable as $$
  select exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name = tbl
  );
$$;

-- Helper: simple admin check (assumes public.profiles.role = 'admin')
create or replace function public.is_admin()
returns boolean language sql stable as $$
  select exists(
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  );
$$;

-- support_requests
do $$
begin
  if not public._table_exists('support_requests') then
    create table public.support_requests (
      id            uuid primary key default gen_random_uuid(),
      requester_id  uuid not null,
      requester_email text not null default '',
      title         text not null default '',
      body          text not null default '',
      priority      text not null default 'normal' check (priority in ('low','normal','high','urgent')),
      status        text not null default 'open'   check (status in ('open','assigned','waiting','closed')),
      tags          text[] not null default '{}',
      assignee_id   uuid,
      created_at    timestamptz not null default now(),
      updated_at    timestamptz not null default now()
    );
    create index on public.support_requests (status);
    create index on public.support_requests (priority);
    create index on public.support_requests (assignee_id);
    create index on public.support_requests (requester_id);
    create index on public.support_requests (created_at desc);
    create index on public.support_requests using gin (tags);
    alter table public.support_requests enable row level security;
  end if;
end $$;

-- Create the set_updated_at function outside the do block
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- Create the trigger for support_requests
do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_support_requests_updated') then
    create trigger trg_support_requests_updated
      before update on public.support_requests
      for each row execute function public.set_updated_at();
  end if;
end $$;

-- support_replies
do $$
begin
  if not public._table_exists('support_replies') then
    create table public.support_replies (
      id         uuid primary key default gen_random_uuid(),
      ticket_id  uuid not null references public.support_requests(id) on delete cascade,
      author_id  uuid not null,
      body       text not null,
      created_at timestamptz not null default now()
    );
    create index on public.support_replies (ticket_id, created_at);
    alter table public.support_replies enable row level security;
  end if;
end $$;

-- RLS policies
-- Requests: requester, assignee, and admins can read; requester can insert; updates by requester, assignee, admins.
do $$
begin
  -- SELECT
  if not exists (select 1 from pg_policies where tablename='support_requests' and policyname='sr_select') then
    create policy sr_select on public.support_requests
      for select using (
        requester_id = auth.uid()
        or assignee_id = auth.uid()
        or public.is_admin()
      );
  end if;

  -- INSERT
  if not exists (select 1 from pg_policies where tablename='support_requests' and policyname='sr_insert') then
    create policy sr_insert on public.support_requests
      for insert with check (requester_id = auth.uid() or public.is_admin());
  end if;

  -- UPDATE
  if not exists (select 1 from pg_policies where tablename='support_requests' and policyname='sr_update') then
    create policy sr_update on public.support_requests
      for update using (
        requester_id = auth.uid() or assignee_id = auth.uid() or public.is_admin()
      );
  end if;

  -- Replies policies
  if not exists (select 1 from pg_policies where tablename='support_replies' and policyname='srep_select') then
    create policy srep_select on public.support_replies
      for select using (
        exists (select 1 from public.support_requests r
                where r.id = ticket_id
                  and (r.requester_id = auth.uid() or r.assignee_id = auth.uid() or public.is_admin()))
      );
  end if;

  if not exists (select 1 from pg_policies where tablename='support_replies' and policyname='srep_insert') then
    create policy srep_insert on public.support_replies
      for insert with check (
        exists (select 1 from public.support_requests r
                where r.id = ticket_id
                  and (r.requester_id = auth.uid() or r.assignee_id = auth.uid() or public.is_admin()))
      );
  end if;
end $$;

-- Convenience view: counts for badges
create or replace view public.support_counts as
select
  count(*) filter (where priority='urgent' and status <> 'closed') as urgent_open,
  count(*) filter (where status <> 'closed') as open_total
from public.support_requests;

-- support_canned_replies
do $$
begin
  if not public._table_exists('support_canned_replies') then
    create table public.support_canned_replies (
      id uuid primary key default gen_random_uuid(),
      title text not null,
      body text not null,
      tags text[] not null default '{}',
      created_at timestamptz default now()
    );
    create index on public.support_canned_replies (title);
    create index on public.support_canned_replies using gin (tags);
    alter table public.support_canned_replies enable row level security;
  end if;
end $$;

-- RLS policies for canned replies (admins only)
do $$
begin
  if not exists (select 1 from pg_policies where tablename='support_canned_replies' and policyname='scr_select') then
    create policy scr_select on public.support_canned_replies
      for select using (public.is_admin());
  end if;

  if not exists (select 1 from pg_policies where tablename='support_canned_replies' and policyname='scr_insert') then
    create policy scr_insert on public.support_canned_replies
      for insert with check (public.is_admin());
  end if;

  if not exists (select 1 from pg_policies where tablename='support_canned_replies' and policyname='scr_update') then
    create policy scr_update on public.support_canned_replies
      for update using (public.is_admin());
  end if;

  if not exists (select 1 from pg_policies where tablename='support_canned_replies' and policyname='scr_delete') then
    create policy scr_delete on public.support_canned_replies
      for delete using (public.is_admin());
  end if;
end $$;
