-- Create file_feedback table
create table if not exists public.file_feedback (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references public.user_files(id) on delete cascade,
  coach_id uuid not null references auth.users(id) on delete cascade,
  comment text not null,
  tags text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.file_feedback enable row level security;

-- Create policies
create policy "coaches can manage their feedback"
on public.file_feedback
for all
to authenticated
using (auth.uid() = coach_id)
with check (auth.uid() = coach_id);

-- Optional read for file owners (if you store file owner in user_files.user_id)
create policy "file owners can read feedback"
on public.file_feedback
for select
to authenticated
using (exists (
  select 1 from public.user_files uf
  where uf.id = file_feedback.file_id
    and uf.user_id = auth.uid()
));

-- Create indexes for better performance
create index if not exists idx_file_feedback_file_id on public.file_feedback(file_id);
create index if not exists idx_file_feedback_coach_id on public.file_feedback(coach_id);
create index if not exists idx_file_feedback_created_at on public.file_feedback(created_at);

-- Add updated_at trigger
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_file_feedback_updated_at
  before update on public.file_feedback
  for each row
  execute function update_updated_at_column();
