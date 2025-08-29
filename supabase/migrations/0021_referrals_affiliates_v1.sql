-- Referrals & Affiliates v1 Schema
-- Sprint H: Referral codes, milestones, rewards, anti-abuse, coach payouts

-- Referral codes table
create table if not exists public.referral_codes (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  code text unique not null,
  status text not null check (status in ('active', 'disabled')) default 'active',
  created_at timestamptz default now()
);

-- Referrals table
create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.profiles(id) on delete cascade,
  referee_id uuid not null references public.profiles(id) on delete cascade,
  code text not null,
  source text,
  milestone text check (milestone in ('checklist', 'payment')),
  rewarded_at timestamptz null,
  reward_type text[] default '{}',
  reward_values jsonb default '{}'::jsonb,
  fraud_flag bool default false,
  created_at timestamptz default now()
);

-- Affiliate links table
create table if not exists public.affiliate_links (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.profiles(id) on delete cascade,
  slug text unique not null,
  bounty_usd numeric(8,2) default 20.00,
  status text not null check (status in ('active', 'disabled')) default 'active',
  created_at timestamptz default now()
);

-- Affiliate conversions table
create table if not exists public.affiliate_conversions (
  id uuid primary key default gen_random_uuid(),
  link_id uuid not null references public.affiliate_links(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(10,2) not null,
  status text not null check (status in ('pending', 'approved', 'paid')) default 'pending',
  payout_batch_id uuid null,
  created_at timestamptz default now()
);

-- Affiliate payout batches table (admin managed)
create table if not exists public.affiliate_payout_batches (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  note text,
  created_at timestamptz default now()
);

-- Supporting view: monthly referral caps
create or replace view public.referral_monthly_caps as
select 
  referrer_id,
  date_trunc('month', created_at) as month,
  count(*) as referral_count
from public.referrals
where milestone is not null
group by referrer_id, date_trunc('month', created_at);

-- Indexes for performance
create index if not exists idx_referrals_referrer_created 
  on public.referrals(referrer_id, created_at desc);

create index if not exists idx_referrals_referee 
  on public.referrals(referee_id);

create index if not exists idx_affiliate_links_coach 
  on public.affiliate_links(coach_id);

create index if not exists idx_affiliate_conversions_link_status 
  on public.affiliate_conversions(link_id, status);

create index if not exists idx_referral_codes_code 
  on public.referral_codes(code);

-- Enable RLS
alter table public.referral_codes enable row level security;
alter table public.referrals enable row level security;
alter table public.affiliate_links enable row level security;
alter table public.affiliate_conversions enable row level security;
alter table public.affiliate_payout_batches enable row level security;

-- RLS Policies for referral_codes
create policy referral_codes_select_policy on public.referral_codes
  for select using (user_id = auth.uid());

create policy referral_codes_insert_policy on public.referral_codes
  for insert with check (user_id = auth.uid());

create policy referral_codes_update_policy on public.referral_codes
  for update using (user_id = auth.uid());

create policy referral_codes_delete_policy on public.referral_codes
  for delete using (user_id = auth.uid());

-- RLS Policies for referrals
create policy referrals_select_policy on public.referrals
  for select using (
    referrer_id = auth.uid() or referee_id = auth.uid()
  );

create policy referrals_insert_policy on public.referrals
  for insert with check (
    referrer_id = auth.uid() or referee_id = auth.uid()
  );

create policy referrals_update_policy on public.referrals
  for update using (
    referrer_id = auth.uid() or referee_id = auth.uid()
  );

create policy referrals_delete_policy on public.referrals
  for delete using (
    referrer_id = auth.uid() or referee_id = auth.uid()
  );

-- RLS Policies for affiliate_links
create policy affiliate_links_select_policy on public.affiliate_links
  for select using (coach_id = auth.uid());

create policy affiliate_links_insert_policy on public.affiliate_links
  for insert with check (coach_id = auth.uid());

create policy affiliate_links_update_policy on public.affiliate_links
  for update using (coach_id = auth.uid());

create policy affiliate_links_delete_policy on public.affiliate_links
  for delete using (coach_id = auth.uid());

-- RLS Policies for affiliate_conversions
create policy affiliate_conversions_select_policy on public.affiliate_conversions
  for select using (
    exists (
      select 1 from public.affiliate_links al 
      where al.id = affiliate_conversions.link_id and al.coach_id = auth.uid()
    )
  );

create policy affiliate_conversions_insert_policy on public.affiliate_conversions
  for insert with check (
    exists (
      select 1 from public.affiliate_links al 
      where al.id = affiliate_conversions.link_id and al.coach_id = auth.uid()
    )
  );

create policy affiliate_conversions_update_policy on public.affiliate_conversions
  for update using (
    exists (
      select 1 from public.affiliate_links al 
      where al.id = affiliate_conversions.link_id and al.coach_id = auth.uid()
    )
  );

create policy affiliate_conversions_delete_policy on public.affiliate_conversions
  for delete using (
    exists (
      select 1 from public.affiliate_links al 
      where al.id = affiliate_conversions.link_id and al.coach_id = auth.uid()
    )
  );

-- RLS Policies for affiliate_payout_batches (admin only)
create policy affiliate_payout_batches_select_policy on public.affiliate_payout_batches
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy affiliate_payout_batches_insert_policy on public.affiliate_payout_batches
  for insert with check (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy affiliate_payout_batches_update_policy on public.affiliate_payout_batches
  for update using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy affiliate_payout_batches_delete_policy on public.affiliate_payout_batches
  for delete using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- Admin policies (read-all for admin users)
create policy referral_codes_admin_select_policy on public.referral_codes
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy referrals_admin_select_policy on public.referrals
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy affiliate_links_admin_select_policy on public.affiliate_links
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy affiliate_conversions_admin_select_policy on public.affiliate_conversions
  for select using (
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- Functions (safe, idempotent)

-- Ensure referral code exists for user
create or replace function public.ensure_referral_code(p_user uuid)
returns text
language plpgsql
security definer
as $$
declare
  v_code text;
begin
  -- Check if user already has a code
  select code into v_code
  from public.referral_codes
  where user_id = p_user and status = 'active';
  
  if v_code is not null then
    return v_code;
  end if;
  
  -- Generate new code (simple format: USER123)
  v_code := 'USER' || substr(p_user::text, 1, 8);
  
  -- Insert new code
  insert into public.referral_codes (user_id, code)
  values (p_user, v_code)
  on conflict (user_id) do update set
    code = excluded.code,
    status = 'active';
  
  return v_code;
end;
$$;

-- Upsert affiliate link
create or replace function public.upsert_affiliate_link(
  p_coach uuid,
  p_slug text,
  p_bounty numeric default 20.00
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_link_id uuid;
begin
  -- Check if coach already has a link with this slug
  select id into v_link_id
  from public.affiliate_links
  where coach_id = p_coach and slug = p_slug;
  
  if v_link_id is not null then
    -- Update existing link
    update public.affiliate_links
    set bounty_usd = p_bounty,
        status = 'active'
    where id = v_link_id;
    return v_link_id;
  end if;
  
  -- Create new link
  insert into public.affiliate_links (coach_id, slug, bounty_usd)
  values (p_coach, p_slug, p_bounty)
  returning id into v_link_id;
  
  return v_link_id;
end;
$$;

-- Mark affiliate conversions as paid
create or replace function public.mark_affiliate_paid(
  p_batch uuid,
  p_ids uuid[]
)
returns integer
language plpgsql
security definer
as $$
declare
  v_count integer;
begin
  update public.affiliate_conversions
  set status = 'paid',
      payout_batch_id = p_batch
  where id = any(p_ids)
    and status = 'approved';
  
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
