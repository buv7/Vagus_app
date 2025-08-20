-- AI Core: pgvector + embeddings (idempotent)
create extension if not exists vector;
create extension if not exists pgcrypto;

-- NOTE: Adjust ownership in USING/WITH CHECK below if coach_notes uses created_by instead of coach_id.

-- ===== NOTE EMBEDDINGS =====
create table if not exists public.note_embeddings (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.coach_notes(id) on delete cascade,
  model text not null default 'text-embedding-3-large',
  content text not null,
  embedding vector(1536) not null,
  created_at timestamptz not null default now()
);
create index if not exists note_embeddings_ivf on public.note_embeddings using ivfflat (embedding vector_cosine_ops);
alter table public.note_embeddings enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'note_emb_select_own') then
    create policy note_emb_select_own on public.note_embeddings
      for select to authenticated
      using (
        exists (
          select 1 from public.coach_notes n
          where n.id = note_embeddings.note_id
            and (n.coach_id = auth.uid() or n.created_by = auth.uid())
        )
      );
  end if;

  if not exists (select 1 from pg_policies where policyname = 'note_emb_insert_own') then
    create policy note_emb_insert_own on public.note_embeddings
      for insert to authenticated
      with check (
        exists (
          select 1 from public.coach_notes n
          where n.id = note_embeddings.note_id
            and (n.coach_id = auth.uid() or n.created_by = auth.uid())
        )
      );
  end if;
end $$;

-- ===== MESSAGE EMBEDDINGS (FK may vary; keep conservative RLS) =====
create table if not exists public.message_embeddings (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null,
  model text not null default 'text-embedding-3-large',
  content text not null,
  embedding vector(1536) not null,
  created_by uuid not null,
  created_at timestamptz not null default now()
);
create index if not exists message_embeddings_ivf on public.message_embeddings using ivfflat (embedding vector_cosine_ops);
alter table public.message_embeddings enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'msg_emb_select_own') then
    create policy msg_emb_select_own on public.message_embeddings
      for select to authenticated
      using (created_by = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'msg_emb_insert_own') then
    create policy msg_emb_insert_own on public.message_embeddings
      for insert to authenticated
      with check (created_by = auth.uid());
  end if;
end $$;

-- ===== WORKOUT EMBEDDINGS (FK may vary; keep conservative RLS) =====
create table if not exists public.workout_embeddings (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null,
  model text not null default 'text-embedding-3-large',
  content text not null,
  embedding vector(1536) not null,
  created_by uuid not null,
  created_at timestamptz not null default now()
);
create index if not exists workout_embeddings_ivf on public.workout_embeddings using ivfflat (embedding vector_cosine_ops);
alter table public.workout_embeddings enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'wo_emb_select_own') then
    create policy wo_emb_select_own on public.workout_embeddings
      for select to authenticated
      using (created_by = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'wo_emb_insert_own') then
    create policy wo_emb_insert_own on public.workout_embeddings
      for insert to authenticated
      with check (created_by = auth.uid());
  end if;
end $$;

-- ===== SIMILARITY SEARCH FUNCTION =====
create or replace function similar_notes(
  source_embedding vector(1536),
  exclude_note_id uuid default null,
  limit_count int default 5
)
returns table (
  note_id uuid,
  similarity float
)
language plpgsql
security definer
as $$
begin
  return query
  select 
    ne.note_id,
    1 - (ne.embedding <=> source_embedding) as similarity
  from public.note_embeddings ne
  where (exclude_note_id is null or ne.note_id != exclude_note_id)
    and exists (
      select 1 from public.coach_notes n
      where n.id = ne.note_id
        and (n.coach_id = auth.uid() or n.created_by = auth.uid())
    )
  order by ne.embedding <=> source_embedding
  limit limit_count;
end;
$$;

select 'AI core embeddings ready' as status;
