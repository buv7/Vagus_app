-- ========================================
-- FIX DATABASE SCHEMA ISSUES
-- ========================================
-- This fixes the coach_clients relationship and entitlements_v plan_code issues

-- ========================================
-- 1. FIX COACH_CLIENTS RELATIONSHIP
-- ========================================

-- First, let's check what coach_clients currently is
SELECT 'Checking coach_clients current state...' as info;
SELECT 
    table_name,
    table_type,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- Drop the existing coach_clients (whether it's a view or table)
DROP VIEW IF EXISTS public.coach_clients CASCADE;
DROP TABLE IF EXISTS public.coach_clients CASCADE;

-- Check if user_coach_links table exists and has the right structure
SELECT 'Checking user_coach_links table...' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_coach_links' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Create the proper coach_clients table with correct relationships
CREATE TABLE public.coach_clients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    started_at timestamptz DEFAULT now(),
    ended_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(coach_id, client_id)
);

-- Create indexes for performance
CREATE INDEX idx_coach_clients_coach_id ON public.coach_clients(coach_id);
CREATE INDEX idx_coach_clients_client_id ON public.coach_clients(client_id);
CREATE INDEX idx_coach_clients_status ON public.coach_clients(status);

-- Enable RLS
ALTER TABLE public.coach_clients ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY coach_clients_coach_access ON public.coach_clients
FOR ALL TO authenticated
USING (coach_id = auth.uid())
WITH CHECK (coach_id = auth.uid());

CREATE POLICY coach_clients_client_access ON public.coach_clients
FOR SELECT TO authenticated
USING (client_id = auth.uid());

-- ========================================
-- 2. FIX ENTITLEMENTS_V VIEW
-- ========================================

-- Drop the existing entitlements_v view
DROP VIEW IF EXISTS public.entitlements_v CASCADE;

-- Check if required tables exist
SELECT 'Checking required tables for entitlements_v...' as info;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('profiles', 'subscriptions', 'billing_plans')
  AND table_schema = 'public';

-- Create billing_plans table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.billing_plans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text UNIQUE NOT NULL,
    name text NOT NULL,
    price_monthly_cents integer NOT NULL DEFAULT 0,
    currency text NOT NULL DEFAULT 'USD',
    features jsonb DEFAULT '{}',
    ai_monthly_limit integer DEFAULT 200,
    trial_days integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Create subscriptions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_code text NOT NULL,
    status text NOT NULL DEFAULT 'active',
    period_start timestamptz DEFAULT now(),
    period_end timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS on new tables
ALTER TABLE public.billing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for new tables
CREATE POLICY IF NOT EXISTS billing_plans_read_all ON public.billing_plans
FOR SELECT TO authenticated USING (true);

CREATE POLICY IF NOT EXISTS subscriptions_owner_rw ON public.subscriptions
FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Seed default billing plans
INSERT INTO public.billing_plans (code, name, price_monthly_cents, currency, features, ai_monthly_limit, trial_days, is_active)
VALUES
  ('free','Free',0,'USD','{"notes":"Basic access"}'::jsonb,200,0,true),
  ('pro','Pro',1500,'USD','{"notes":"Higher AI limits"}'::jsonb,2000,7,true)
ON CONFLICT (code) DO NOTHING;

-- Now create the proper entitlements_v view with plan_code
CREATE VIEW public.entitlements_v AS
SELECT
  p.id as user_id,
  COALESCE(s.plan_code, 'free') as plan_code,
  COALESCE(bp.ai_monthly_limit, 200) as ai_monthly_limit,
  COALESCE(s.status, 'active') as status,
  s.period_end,
  bp.name as plan_name,
  bp.price_monthly_cents,
  bp.currency,
  bp.features
FROM public.profiles p
LEFT JOIN LATERAL (
  SELECT s1.* FROM public.subscriptions s1
  WHERE s1.user_id = p.id
  ORDER BY s1.updated_at DESC NULLS LAST
  LIMIT 1
) s ON true
LEFT JOIN public.billing_plans bp ON bp.code = s.plan_code AND bp.is_active = true;

-- ========================================
-- 3. VERIFY FIXES
-- ========================================

-- Verify coach_clients table structure
SELECT 'coach_clients table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify entitlements_v view structure
SELECT 'entitlements_v view structure:' as info;
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'entitlements_v' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test the views work
SELECT 'Testing coach_clients query...' as info;
SELECT COUNT(*) as coach_clients_count FROM public.coach_clients;

SELECT 'Testing entitlements_v query...' as info;
SELECT COUNT(*) as entitlements_count FROM public.entitlements_v;

SELECT 'Database schema fixes completed successfully!' as result;
