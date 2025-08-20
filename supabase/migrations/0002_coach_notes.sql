-- VAGUS Progress System - Coach Notes Migration
-- Section 4: coach_notes column guards, coach_note_versions, coach_note_attachments, indexes, RLS + policies, and storage policies

-- 4. Coach Notes Version History and Attachments Tables
-- Add missing columns to existing coach_notes table if they don't exist
do $$
begin
  -- Add updated_at column if it doesn't exist
  if not exists (select 1 from information_schema.columns 
                where table_name = 'coach_notes' and column_name = 'updated_at') then
    alter table public.coach_notes add column updated_at timestamptz default now();
  end if;

  -- Add updated_by column if it doesn't exist
  if not exists (select 1 from information_schema.columns 
                where table_name = 'coach_notes' and column_name = 'updated_by') then
    alter table public.coach_notes add column updated_by uuid references auth.users(id);
  end if;

  -- Add is_deleted column if it doesn't exist
  if not exists (select 1 from information_schema.columns 
                where table_name = 'coach_notes' and column_name = 'is_deleted') then
    alter table public.coach_notes add column is_deleted boolean default false;
  end if;

  -- Add version column if it doesn't exist
  if not exists (select 1 from information_schema.columns 
                where table_name = 'coach_notes' and column_name = 'version') then
    alter table public.coach_notes add column version int default 1;
  end if;
end $$;

-- Create coach_note_versions table for version history
create table if not exists public.coach_note_versions (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.coach_notes(id) on delete cascade,
  version_index int not null,
  content text not null,
  metadata jsonb default '{}',
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id)
);

create index if not exists coach_note_versions_note_id_idx on public.coach_note_versions(note_id, version_index desc);
create index if not exists coach_note_versions_created_by_idx on public.coach_note_versions(created_by);

alter table public.coach_note_versions enable row level security;

-- Create coach_note_attachments table for file attachments
create table if not exists public.coach_note_attachments (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.coach_notes(id) on delete cascade,
  storage_path text not null,
  mime_type text not null,
  file_name text not null,
  size_bytes bigint not null,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id)
);

create index if not exists coach_note_attachments_note_id_idx on public.coach_note_attachments(note_id);
create index if not exists coach_note_attachments_created_by_idx on public.coach_note_attachments(created_by);

alter table public.coach_note_attachments enable row level security;

-- RLS policies for coach_note_versions
do $$
begin
  -- Coach can select versions of their own notes
  if not exists (select 1 from pg_policies where policyname = 'cnv_coach_select') then
    create policy cnv_coach_select on public.coach_note_versions
      for select to authenticated
      using (
        exists (
          select 1 from public.coach_notes n
          where n.id = coach_note_versions.note_id and n.coach_id = auth.uid()
        )
      );
  end if;

  -- Coach can insert versions for their own notes
  if not exists (select 1 from pg_policies where policyname = 'cnv_coach_insert') then
    create policy cnv_coach_insert on public.coach_note_versions
      for insert to authenticated
      with check (
        created_by = auth.uid()
        and exists (
          select 1 from public.coach_notes n
          where n.id = coach_note_versions.note_id and n.coach_id = auth.uid()
        )
      );
  end if;
end $$;

-- RLS policies for coach_note_attachments
do $$
begin
  -- Coach can select attachments of their own notes
  if not exists (select 1 from pg_policies where policyname = 'cna_coach_select') then
    create policy cna_coach_select on public.coach_note_attachments
      for select to authenticated
      using (
        exists (
          select 1 from public.coach_notes n
          where n.id = coach_note_attachments.note_id and n.coach_id = auth.uid()
        )
      );
  end if;

  -- Coach can insert attachments for their own notes
  if not exists (select 1 from pg_policies where policyname = 'cna_coach_insert') then
    create policy cna_coach_insert on public.coach_note_attachments
      for insert to authenticated
      with check (
        created_by = auth.uid()
        and exists (
          select 1 from public.coach_notes n
          where n.id = coach_note_attachments.note_id and n.coach_id = auth.uid()
        )
      );
  end if;

  -- Coach can delete attachments of their own notes
  if not exists (select 1 from pg_policies where policyname = 'cna_coach_delete') then
    create policy cna_coach_delete on public.coach_note_attachments
      for delete to authenticated
      using (
        exists (
          select 1 from public.coach_notes n
          where n.id = coach_note_attachments.note_id and n.coach_id = auth.uid()
        )
      );
  end if;
end $$;

-- 5. Storage policies for vagus-media bucket (only add if missing)
-- Ensure bucket exists: 'vagus-media'
-- In storage.objects, enable RLS and add policies:

-- Read: owner or linked coach
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'storage_read_vagus_media') then
    create policy storage_read_vagus_media
      on storage.objects for select to authenticated
      using (
        bucket_id = 'vagus-media'
        and (
          owner = auth.uid()
          or exists (
            select 1 from public.coach_clients l
            where l.coach_id = auth.uid()
              and l.client_id = owner
          )
        )
      );
  end if;

  if not exists (select 1 from pg_policies where policyname = 'storage_insert_vagus_media') then
    create policy storage_insert_vagus_media
      on storage.objects for insert to authenticated
      with check (bucket_id = 'vagus-media' and owner = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'storage_delete_vagus_media') then
    create policy storage_delete_vagus_media
      on storage.objects for delete to authenticated
      using (bucket_id = 'vagus-media' and owner = auth.uid());
  end if;
end $$;
