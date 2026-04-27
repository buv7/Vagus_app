-- tables
create table if not exists public.admin_users (
  user_id uuid primary key
);

create table if not exists public.ad_banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text not null,
  link_url text,
  audience text not null check (audience in ('client','coach','both')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  is_active boolean not null default true,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ad_impressions (
  id uuid primary key default gen_random_uuid(),
  ad_id uuid not null references public.ad_banners(id) on delete cascade,
  user_id uuid,
  seen_at timestamptz not null default now()
);

create table if not exists public.ad_clicks (
  id uuid primary key default gen_random_uuid(),
  ad_id uuid not null references public.ad_banners(id) on delete cascade,
  user_id uuid,
  clicked_at timestamptz not null default now()
);

-- indexes
create index if not exists idx_ads_active_range on public.ad_banners (is_active, starts_at, ends_at);
create index if not exists idx_ads_audience on public.ad_banners (audience);
create index if not exists idx_ad_impr_ad on public.ad_impressions (ad_id, seen_at);
create index if not exists idx_ad_clicks_ad on public.ad_clicks (ad_id, clicked_at);

-- storage bucket for ad images
insert into storage.buckets (id, name, public) 
select 'ads','ads', true
where not exists (select 1 from storage.buckets where id='ads');

-- RLS
alter table public.ad_banners enable row level security;
alter table public.ad_impressions enable row level security;
alter table public.ad_clicks enable row level security;

-- Policies: only admin_users can write banners; anyone authenticated can read/impress/click
drop policy if exists "ads_select_all" on public.ad_banners;
create policy "ads_select_all" on public.ad_banners
for select using (true);

drop policy if exists "ads_admin_insert" on public.ad_banners;
create policy "ads_admin_insert" on public.ad_banners
for insert with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "ads_admin_update" on public.ad_banners;
create policy "ads_admin_update" on public.ad_banners
for update using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "ads_admin_delete" on public.ad_banners;
create policy "ads_admin_delete" on public.ad_banners
for delete using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- impressions/clicks: any authenticated user may write their own telemetry, reads allowed for admins
drop policy if exists "impr_insert_any_auth" on public.ad_impressions;
create policy "impr_insert_any_auth" on public.ad_impressions
for insert with check (auth.role() = 'authenticated');

drop policy if exists "impr_select_admin_only" on public.ad_impressions;
create policy "impr_select_admin_only" on public.ad_impressions
for select using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "click_insert_any_auth" on public.ad_clicks;
create policy "click_insert_any_auth" on public.ad_clicks
for insert with check (auth.role() = 'authenticated');

drop policy if exists "click_select_admin_only" on public.ad_clicks;
create policy "click_select_admin_only" on public.ad_clicks
for select using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- storage policies: public read, admin write
create policy if not exists "ads_public_read"
on storage.objects for select
to public
using ( bucket_id = 'ads' );

create policy if not exists "ads_admin_write"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'ads' and exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);

create policy if not exists "ads_admin_update"
on storage.objects for update to authenticated
using (bucket_id='ads' and exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (bucket_id='ads' and exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

create policy if not exists "ads_admin_delete"
on storage.objects for delete to authenticated
using (bucket_id='ads' and exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- helper view for current ads per audience
create or replace view public.v_current_ads as
select *
from public.ad_banners
where is_active
  and starts_at <= now()
  and (ends_at is null or ends_at >= now());
