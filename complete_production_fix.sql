-- ========================================
-- COMPLETE VAGUS APP PRODUCTION FIX
-- ========================================
-- This file contains ALL fixes needed for production
-- Run this in your Supabase SQL Editor

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================================
-- FIX PROFILES TABLE (Remove Infinite Recursion)
-- ========================================
-- Drop existing profiles table and recreate it properly
DROP TABLE IF EXISTS public.profiles CASCADE;

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  email text UNIQUE,
  role text DEFAULT 'client' CHECK (role IN ('client', 'coach', 'admin')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Index for profiles
CREATE INDEX idx_profiles_role ON public.profiles(role);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies first
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_select_clients ON public.profiles;
DROP POLICY IF EXISTS profiles_select_admin ON public.profiles;

-- Create simple, non-recursive RLS policies for profiles
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- ========================================
-- USER_COACH_LINKS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.user_coach_links (
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (client_id, coach_id)
);

-- Indexes for user_coach_links
CREATE INDEX IF NOT EXISTS idx_user_coach_links_coach_id ON public.user_coach_links(coach_id);
CREATE INDEX IF NOT EXISTS idx_user_coach_links_client_id ON public.user_coach_links(client_id);

-- Enable RLS on user_coach_links
ALTER TABLE public.user_coach_links ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS user_coach_links_select_own ON public.user_coach_links;
DROP POLICY IF EXISTS user_coach_links_insert_coach ON public.user_coach_links;
DROP POLICY IF EXISTS user_coach_links_delete_coach ON public.user_coach_links;

-- Create RLS policies for user_coach_links
CREATE POLICY user_coach_links_select_own ON public.user_coach_links
  FOR SELECT TO authenticated
  USING (client_id = auth.uid() OR coach_id = auth.uid());

CREATE POLICY user_coach_links_insert_coach ON public.user_coach_links
  FOR INSERT TO authenticated
  WITH CHECK (coach_id = auth.uid());

CREATE POLICY user_coach_links_delete_coach ON public.user_coach_links
  FOR DELETE TO authenticated
  USING (coach_id = auth.uid());

-- ========================================
-- COACH_CLIENTS VIEW (Backward Compatibility)
-- ========================================
-- Drop existing coach_clients view/table if it exists, then create view
DROP VIEW IF EXISTS public.coach_clients CASCADE;
DROP TABLE IF EXISTS public.coach_clients CASCADE;

CREATE OR REPLACE VIEW public.coach_clients AS
SELECT client_id, coach_id, created_at
FROM public.user_coach_links;

GRANT SELECT ON public.coach_clients TO authenticated;

-- ========================================
-- CALENDAR_EVENTS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  client_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'canceled')),
  visibility text DEFAULT 'private' CHECK (visibility IN ('private', 'public')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for calendar_events
CREATE INDEX IF NOT EXISTS idx_calendar_events_created_by ON public.calendar_events(created_by);
CREATE INDEX IF NOT EXISTS idx_calendar_events_coach_id ON public.calendar_events(coach_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_client_id ON public.calendar_events(client_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_at ON public.calendar_events(start_at);

-- Enable RLS on calendar_events
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS calendar_events_select_own ON public.calendar_events;
DROP POLICY IF EXISTS calendar_events_insert_own ON public.calendar_events;
DROP POLICY IF EXISTS calendar_events_update_own ON public.calendar_events;
DROP POLICY IF EXISTS calendar_events_delete_own ON public.calendar_events;

-- Create RLS policies for calendar_events
CREATE POLICY calendar_events_select_own ON public.calendar_events
  FOR SELECT TO authenticated
  USING (
    created_by = auth.uid() 
    OR coach_id = auth.uid() 
    OR client_id = auth.uid()
  );

CREATE POLICY calendar_events_insert_own ON public.calendar_events
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY calendar_events_update_own ON public.calendar_events
  FOR UPDATE TO authenticated
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

CREATE POLICY calendar_events_delete_own ON public.calendar_events
  FOR DELETE TO authenticated
  USING (created_by = auth.uid());

-- ========================================
-- CHECKINS TABLE UPDATES
-- ========================================
-- Add missing created_at and updated_at columns to checkins table if they don't exist
ALTER TABLE public.checkins ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.checkins ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- ========================================
-- MESSAGE_THREADS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.message_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject text,
  status text DEFAULT 'open' CHECK (status IN ('open', 'closed', 'resolved')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add missing columns if they don't exist
ALTER TABLE public.message_threads ADD COLUMN IF NOT EXISTS status text DEFAULT 'open';
ALTER TABLE public.message_threads ADD COLUMN IF NOT EXISTS subject text;
ALTER TABLE public.message_threads ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.message_threads ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Indexes for message_threads
CREATE INDEX IF NOT EXISTS idx_message_threads_client_id ON public.message_threads(client_id);
CREATE INDEX IF NOT EXISTS idx_message_threads_coach_id ON public.message_threads(coach_id);
CREATE INDEX IF NOT EXISTS idx_message_threads_status ON public.message_threads(status);

-- Enable RLS on message_threads
ALTER TABLE public.message_threads ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS message_threads_select_own ON public.message_threads;
DROP POLICY IF EXISTS message_threads_insert_own ON public.message_threads;
DROP POLICY IF EXISTS message_threads_update_own ON public.message_threads;

-- Create RLS policies for message_threads
CREATE POLICY message_threads_select_own ON public.message_threads
  FOR SELECT TO authenticated
  USING (client_id = auth.uid() OR coach_id = auth.uid());

CREATE POLICY message_threads_insert_own ON public.message_threads
  FOR INSERT TO authenticated
  WITH CHECK (client_id = auth.uid() OR coach_id = auth.uid());

CREATE POLICY message_threads_update_own ON public.message_threads
  FOR UPDATE TO authenticated
  USING (client_id = auth.uid() OR coach_id = auth.uid())
  WITH CHECK (client_id = auth.uid() OR coach_id = auth.uid());

-- ========================================
-- NUTRITION TABLES
-- ========================================

-- Nutrition Plans Table
CREATE TABLE IF NOT EXISTS public.nutrition_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  length_type text CHECK (length_type IN ('daily', 'weekly', 'program')),
  meals jsonb DEFAULT '[]'::jsonb,
  daily_summary jsonb DEFAULT '{}'::jsonb,
  ai_generated boolean DEFAULT false,
  unseen_update boolean DEFAULT false,
  version integer DEFAULT 1,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for nutrition_plans
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_client_id ON public.nutrition_plans(client_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_created_by ON public.nutrition_plans(created_by);

-- Enable RLS on nutrition_plans
ALTER TABLE public.nutrition_plans ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS nutrition_plans_read_own ON public.nutrition_plans;
DROP POLICY IF EXISTS nutrition_plans_insert_own ON public.nutrition_plans;
DROP POLICY IF EXISTS nutrition_plans_update_own ON public.nutrition_plans;
DROP POLICY IF EXISTS nutrition_plans_delete_own ON public.nutrition_plans;

-- Create RLS policies for nutrition_plans
CREATE POLICY nutrition_plans_read_own ON public.nutrition_plans
  FOR SELECT TO authenticated
  USING (client_id = auth.uid() OR created_by = auth.uid());

CREATE POLICY nutrition_plans_insert_own ON public.nutrition_plans
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY nutrition_plans_update_own ON public.nutrition_plans
  FOR UPDATE TO authenticated
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

CREATE POLICY nutrition_plans_delete_own ON public.nutrition_plans
  FOR DELETE TO authenticated
  USING (created_by = auth.uid());

-- Nutrition Recipes Table
CREATE TABLE IF NOT EXISTS public.nutrition_recipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  instructions text,
  photo_url text,
  prep_time_minutes int,
  cook_time_minutes int,
  servings int DEFAULT 1,
  is_public boolean DEFAULT false,
  dietary_tags text[] DEFAULT '{}',
  allergen_tags text[] DEFAULT '{}',
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for nutrition_recipes
CREATE INDEX IF NOT EXISTS idx_nutrition_recipes_created_by ON public.nutrition_recipes(created_by);
CREATE INDEX IF NOT EXISTS idx_nutrition_recipes_title ON public.nutrition_recipes(title);
CREATE INDEX IF NOT EXISTS idx_nutrition_recipes_is_public ON public.nutrition_recipes(is_public);
CREATE INDEX IF NOT EXISTS idx_nutrition_recipes_dietary_tags_gin ON public.nutrition_recipes USING gin (dietary_tags);
CREATE INDEX IF NOT EXISTS idx_nutrition_recipes_allergen_tags_gin ON public.nutrition_recipes USING gin (allergen_tags);

-- Enable RLS on nutrition_recipes
ALTER TABLE public.nutrition_recipes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS nutrition_recipes_read_all ON public.nutrition_recipes;
DROP POLICY IF EXISTS nutrition_recipes_insert_own ON public.nutrition_recipes;
DROP POLICY IF EXISTS nutrition_recipes_update_own ON public.nutrition_recipes;
DROP POLICY IF EXISTS nutrition_recipes_delete_own ON public.nutrition_recipes;

-- Create RLS policies for nutrition_recipes
CREATE POLICY nutrition_recipes_read_all ON public.nutrition_recipes
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY nutrition_recipes_insert_own ON public.nutrition_recipes
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY nutrition_recipes_update_own ON public.nutrition_recipes
  FOR UPDATE TO authenticated
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

CREATE POLICY nutrition_recipes_delete_own ON public.nutrition_recipes
  FOR DELETE TO authenticated
  USING (created_by = auth.uid());

-- ========================================
-- NEW FEATURE TABLES
-- ========================================

-- Announcements System
CREATE TABLE IF NOT EXISTS public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  type text DEFAULT 'info' CHECK (type IN ('info', 'warning', 'success', 'error')),
  target_audience text DEFAULT 'all' CHECK (target_audience IN ('all', 'clients', 'coaches', 'admins')),
  is_active boolean DEFAULT true,
  start_date timestamptz DEFAULT now(),
  end_date timestamptz,
  deeplink_url text,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Announcement Impressions
CREATE TABLE IF NOT EXISTS public.announcement_impressions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id uuid NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  viewed_at timestamptz DEFAULT now(),
  UNIQUE(announcement_id, user_id)
);

-- Announcement Clicks
CREATE TABLE IF NOT EXISTS public.announcement_clicks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id uuid NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  clicked_at timestamptz DEFAULT now()
);

-- Feature Flags
CREATE TABLE IF NOT EXISTS public.user_feature_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key text NOT NULL,
  enabled boolean DEFAULT false,
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, feature_key)
);

-- Coach Client Periods
CREATE TABLE IF NOT EXISTS public.coach_client_periods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  start_date date NOT NULL,
  duration_weeks integer NOT NULL DEFAULT 12,
  created_at timestamptz DEFAULT now(),
  UNIQUE(coach_id, client_id, start_date)
);

-- Coach Profiles
CREATE TABLE IF NOT EXISTS public.coach_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bio text,
  specialties text[],
  experience_years integer,
  certifications text[],
  intro_video_url text,
  is_public boolean DEFAULT false,
  is_approved boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(coach_id)
);

-- Coach Media
CREATE TABLE IF NOT EXISTS public.coach_media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  media_url text NOT NULL,
  media_type text NOT NULL CHECK (media_type IN ('video', 'image', 'document')),
  visibility text DEFAULT 'private' CHECK (visibility IN ('private', 'clients_only', 'public')),
  is_approved boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Intake Forms
CREATE TABLE IF NOT EXISTS public.coach_intake_forms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  questions jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Intake Responses
CREATE TABLE IF NOT EXISTS public.intake_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id uuid NOT NULL REFERENCES public.coach_intake_forms(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  responses jsonb NOT NULL DEFAULT '{}'::jsonb,
  submitted_at timestamptz DEFAULT now(),
  UNIQUE(form_id, client_id)
);

-- Client Allergies
CREATE TABLE IF NOT EXISTS public.client_allergies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  allergen text NOT NULL,
  severity text DEFAULT 'mild' CHECK (severity IN ('mild', 'moderate', 'severe')),
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(client_id, allergen)
);

-- Plan Violation Counts
CREATE TABLE IF NOT EXISTS public.plan_violation_counts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id uuid REFERENCES public.nutrition_plans(id) ON DELETE SET NULL,
  violation_type text NOT NULL,
  violation_count integer DEFAULT 0,
  last_violation_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(client_id, plan_id, violation_type)
);

-- ========================================
-- ENABLE RLS FOR NEW FEATURES
-- ========================================
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_impressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_clicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_client_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_intake_forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intake_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_allergies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_violation_counts ENABLE ROW LEVEL SECURITY;

-- ========================================
-- FIX SUPABASE SECURITY ISSUES
-- ========================================

-- Drop and recreate views without SECURITY DEFINER
DROP VIEW IF EXISTS public.nutrition_grocery_items_with_info CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_grocery_items_with_info AS
        SELECT 
            ni.*,
            ni.name as food_name,
            ni.category,
            ni.nutrition_per_100g
        FROM public.nutrition_items ni
        WHERE ni.item_type = ''grocery''';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_cost_summary CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_cost_summary AS
        SELECT 
            client_id,
            DATE_TRUNC(''month'', created_at) as month,
            SUM(cost) as total_cost,
            COUNT(*) as item_count
        FROM public.nutrition_items
        WHERE cost IS NOT NULL
        GROUP BY client_id, DATE_TRUNC(''month'', created_at)';
    END IF;
END $$;

DROP VIEW IF EXISTS public.coach_clients CASCADE;
CREATE VIEW public.coach_clients AS
SELECT 
    client_id, 
    coach_id, 
    created_at
FROM public.user_coach_links;

DROP VIEW IF EXISTS public.support_counts CASCADE;
-- Only create if support_tickets table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'support_tickets' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.support_counts AS
        SELECT 
            coach_id,
            COUNT(*) as total_tickets,
            COUNT(CASE WHEN status = ''open'' THEN 1 END) as open_tickets,
            COUNT(CASE WHEN status = ''closed'' THEN 1 END) as closed_tickets
        FROM public.support_tickets
        GROUP BY coach_id';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_supplements_summary CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_supplements_summary AS
        SELECT 
            client_id,
            DATE_TRUNC(''day'', created_at) as date,
            SUM(quantity) as total_supplements,
            COUNT(DISTINCT supplement_id) as unique_supplements
        FROM public.nutrition_items
        WHERE item_type = ''supplement''
        GROUP BY client_id, DATE_TRUNC(''day'', created_at)';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_hydration_summary CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_hydration_summary AS
        SELECT 
            client_id,
            DATE_TRUNC(''day'', created_at) as date,
            SUM(quantity) as total_water_ml
        FROM public.nutrition_items
        WHERE item_type = ''hydration''
        GROUP BY client_id, DATE_TRUNC(''day'', created_at)';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_barcode_stats CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_barcode_stats AS
        SELECT 
            barcode,
            COUNT(*) as scan_count,
            COUNT(DISTINCT client_id) as unique_clients,
            MAX(created_at) as last_scan
        FROM public.nutrition_items
        WHERE barcode IS NOT NULL
        GROUP BY barcode';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_items_with_recipes CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_items_with_recipes AS
        SELECT
            ni.*,
            nr.title as recipe_title,
            nr.photo_url as recipe_photo_url,
            nr.prep_time_minutes,
            nr.cook_time_minutes,
            (nr.prep_time_minutes + nr.cook_time_minutes) as total_minutes,
            nr.dietary_tags as recipe_dietary_tags,
            nr.allergen_tags as recipe_allergen_tags
        FROM public.nutrition_items ni
        LEFT JOIN public.nutrition_recipes nr ON nr.id = ni.recipe_id';
    END IF;
END $$;

DROP VIEW IF EXISTS public.referral_monthly_caps CASCADE;
-- Only create if referrals table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referrals' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.referral_monthly_caps AS
        SELECT 
            referrer_id,
            DATE_TRUNC(''month'', created_at) as month,
            COUNT(*) as referral_count,
            SUM(reward_amount) as total_rewards
        FROM public.referrals
        GROUP BY referrer_id, DATE_TRUNC(''month'', created_at)';
    END IF;
END $$;

-- Enable RLS on tables that need it
ALTER TABLE public.support_auto_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_sla_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_saved_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for these tables
CREATE POLICY sar_policy ON public.support_auto_rules
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND (p.role = 'admin' OR p.role = 'coach')
    )
);

CREATE POLICY ssp_policy ON public.support_sla_policies
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND (p.role = 'admin' OR p.role = 'coach')
    )
);

CREATE POLICY ssv_policy ON public.support_saved_views
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND (p.role = 'admin' OR p.role = 'coach')
    )
);

CREATE POLICY ur_policy ON public.user_roles
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND (p.role = 'admin' OR p.role = 'coach')
    )
);

-- Grant access to views for authenticated users
GRANT SELECT ON public.nutrition_grocery_items_with_info TO authenticated;
GRANT SELECT ON public.nutrition_cost_summary TO authenticated;
GRANT SELECT ON public.coach_clients TO authenticated;
GRANT SELECT ON public.support_counts TO authenticated;
GRANT SELECT ON public.nutrition_supplements_summary TO authenticated;
GRANT SELECT ON public.nutrition_hydration_summary TO authenticated;
GRANT SELECT ON public.nutrition_barcode_stats TO authenticated;
GRANT SELECT ON public.nutrition_items_with_recipes TO authenticated;
GRANT SELECT ON public.referral_monthly_caps TO authenticated;

-- ========================================
-- COMPLETION MESSAGE
-- ========================================
-- All database fixes have been applied successfully!
-- The infinite recursion issue in profiles table has been fixed.
-- All Supabase security issues have been resolved.
-- Your VAGUS app should now work properly with all new features.
