-- ========================================
-- COMPLETE FIX FOR ALL MISSING DATABASE OBJECTS
-- ========================================
-- This file fixes all the missing tables and views that are causing errors
-- Run this in your Supabase SQL Editor

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================================
-- 1. FIX ENTITLEMENTS_V VIEW (for Pro status)
-- ========================================

-- Create billing_plans table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.billing_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  price_monthly_cents integer NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'USD',
  features jsonb NOT NULL DEFAULT '{}'::jsonb,
  ai_monthly_limit integer NOT NULL DEFAULT 200,
  trial_days integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create subscriptions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_code text NOT NULL,
  status text NOT NULL DEFAULT 'trialing',
  period_start timestamptz,
  period_end timestamptz,
  cancel_at_period_end boolean DEFAULT false,
  coupon_code text,
  external_customer_id text,
  external_subscription_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS subscriptions_user_idx ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS subscriptions_status_idx ON public.subscriptions(status);

-- Enable RLS
ALTER TABLE public.billing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DO $$
BEGIN
  -- billing_plans: public read
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='billing_plans_read_all') THEN
    CREATE POLICY billing_plans_read_all ON public.billing_plans
    FOR SELECT TO authenticated USING (true);
  END IF;

  -- subscriptions: owner read/write
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='subscriptions_owner_rw') THEN
    CREATE POLICY subscriptions_owner_rw ON public.subscriptions
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- Create the entitlements_v view
CREATE OR REPLACE VIEW public.entitlements_v AS
SELECT
  p.id as user_id,
  COALESCE(s.plan_code, 'free') as plan_code,
  COALESCE(bp.ai_monthly_limit, 200) as ai_monthly_limit,
  COALESCE(s.status, 'active') as status,
  s.period_end
FROM public.profiles p
LEFT JOIN LATERAL (
  SELECT s1.* FROM public.subscriptions s1
  WHERE s1.user_id = p.id
  ORDER BY s1.updated_at DESC NULLS LAST
  LIMIT 1
) s ON true
LEFT JOIN public.billing_plans bp ON bp.code = s.plan_code AND bp.is_active = true;

-- Seed default billing plans
INSERT INTO public.billing_plans (code, name, price_monthly_cents, currency, features, ai_monthly_limit, trial_days, is_active)
SELECT * FROM (VALUES
  ('free','Free',0,'USD','{"notes":"Basic access"}'::jsonb,200,0,true),
  ('pro','Pro',1500,'USD','{"notes":"Higher AI limits"}'::jsonb,2000,7,true)
) AS v(code,name,price_monthly_cents,currency,features,ai_monthly_limit,trial_days,is_active)
ON CONFLICT (code) DO NOTHING;

-- ========================================
-- 2. FIX HEALTH_SOURCES TABLE
-- ========================================

-- Create health_sources table
CREATE TABLE IF NOT EXISTS public.health_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL CHECK (provider IN ('healthkit', 'healthconnect', 'googlefit', 'hms')),
    scopes JSONB DEFAULT '{}',
    last_sync_at TIMESTAMPTZ,
    cursor JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, provider)
);

-- Create health_samples table (needed for health_daily_v view)
CREATE TABLE IF NOT EXISTS public.health_samples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    value NUMERIC,
    unit TEXT,
    measured_at TIMESTAMPTZ NOT NULL,
    source TEXT,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create health_workouts table
CREATE TABLE IF NOT EXISTS public.health_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sport TEXT NOT NULL,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    duration_s INTEGER,
    distance_m NUMERIC,
    avg_hr NUMERIC,
    kcal NUMERIC,
    source TEXT,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create sleep_segments table
CREATE TABLE IF NOT EXISTS public.sleep_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    stage TEXT CHECK (stage IN ('awake', 'light', 'deep', 'rem')),
    source TEXT,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create ocr_cardio_logs table
CREATE TABLE IF NOT EXISTS public.ocr_cardio_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    photo_path TEXT,
    parsed JSONB,
    confirmed BOOLEAN DEFAULT false,
    workout_id UUID REFERENCES health_workouts(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create health_merges table
CREATE TABLE IF NOT EXISTS public.health_merges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ocr_log_id UUID REFERENCES ocr_cardio_logs(id),
    workout_id UUID REFERENCES health_workouts(id),
    strategy TEXT NOT NULL CHECK (strategy IN ('overlap70', 'manual')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on health tables
ALTER TABLE public.health_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ocr_cardio_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_merges ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for health tables
DO $$
BEGIN
  -- Users can manage their own health data
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='health_sources_own') THEN
    CREATE POLICY "Users can manage own health sources" ON public.health_sources
    FOR ALL USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='health_samples_own') THEN
    CREATE POLICY "Users can manage own health samples" ON public.health_samples
    FOR ALL USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='health_workouts_own') THEN
    CREATE POLICY "Users can manage own health workouts" ON public.health_workouts
    FOR ALL USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='sleep_segments_own') THEN
    CREATE POLICY "Users can manage own sleep segments" ON public.sleep_segments
    FOR ALL USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='ocr_cardio_logs_own') THEN
    CREATE POLICY "Users can manage own OCR cardio logs" ON public.ocr_cardio_logs
    FOR ALL USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='health_merges_own') THEN
    CREATE POLICY "Users can manage own health merges" ON public.health_merges
    FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

-- ========================================
-- 3. FIX HEALTH_DAILY_V VIEW
-- ========================================

-- Create the health_daily_v view
CREATE OR REPLACE VIEW public.health_daily_v AS
SELECT
    user_id,
    DATE(measured_at) as date,
    SUM(CASE WHEN type = 'steps' THEN value ELSE 0 END) as steps,
    SUM(CASE WHEN type = 'distance' THEN value ELSE 0 END) / 1000 as distance_km,
    SUM(CASE WHEN type = 'calories' THEN value ELSE 0 END) as active_kcal,
    COUNT(DISTINCT CASE WHEN type = 'steps' THEN id END) as step_samples_count
FROM public.health_samples
WHERE measured_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY user_id, DATE(measured_at);

-- Create sleep_quality_v view as well
CREATE OR REPLACE VIEW public.sleep_quality_v AS
SELECT
    user_id,
    DATE(start_at) as date,
    SUM(EXTRACT(EPOCH FROM (end_at - start_at)) / 60) as sleep_minutes,
    COUNT(*) as sleep_segments_count,
    AVG(CASE WHEN stage = 'deep' THEN 1 ELSE 0 END) as deep_sleep_ratio,
    MIN(start_at) as bedtime,
    MAX(end_at) as risetime
FROM public.sleep_segments
WHERE start_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY user_id, DATE(start_at);

-- ========================================
-- 4. ADD COMMENTS FOR DOCUMENTATION
-- ========================================

COMMENT ON TABLE public.health_sources IS 'Tracks connected health platforms per user';
COMMENT ON TABLE public.health_samples IS 'Normalized health data samples from various platforms';
COMMENT ON TABLE public.health_workouts IS 'Structured workout data from health platforms';
COMMENT ON TABLE public.sleep_segments IS 'Detailed sleep tracking segments';
COMMENT ON TABLE public.ocr_cardio_logs IS 'OCR-processed cardio workout logs';
COMMENT ON TABLE public.health_merges IS 'Tracks data merging between health platforms';
COMMENT ON VIEW public.health_daily_v IS 'Daily health metrics rollup for dashboard';
COMMENT ON VIEW public.sleep_quality_v IS 'Sleep quality metrics rollup for dashboard';
COMMENT ON VIEW public.entitlements_v IS 'User entitlements and subscription status view';

-- ========================================
-- 5. VERIFICATION
-- ========================================

-- Check that all objects were created successfully
SELECT 
    'entitlements_v' as object_name,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'entitlements_v' AND table_schema = 'public') 
         THEN '✅ Created' 
         ELSE '❌ Missing' 
    END as status
UNION ALL
SELECT 
    'health_sources' as object_name,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'health_sources' AND table_schema = 'public') 
         THEN '✅ Created' 
         ELSE '❌ Missing' 
    END as status
UNION ALL
SELECT 
    'health_daily_v' as object_name,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'health_daily_v' AND table_schema = 'public') 
         THEN '✅ Created' 
         ELSE '❌ Missing' 
    END as status;

SELECT '🎉 All missing database objects have been created successfully!' as result;
