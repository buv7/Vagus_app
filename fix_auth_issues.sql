-- VAGUS App Authentication Fix Script
-- Run this in your Supabase SQL Editor to fix common authentication issues

-- ========================================
-- 1. ENSURE REQUIRED EXTENSIONS
-- ========================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================================
-- 2. FIX PROFILES TABLE
-- ========================================
-- Drop and recreate profiles table to ensure clean state
DROP TABLE IF EXISTS public.profiles CASCADE;

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  email text UNIQUE,
  role text DEFAULT 'client' CHECK (role IN ('client', 'coach', 'admin')),
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_email ON public.profiles(email);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 3. CREATE RLS POLICIES FOR PROFILES
-- ========================================
-- Drop existing policies first
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
DROP POLICY IF EXISTS profiles_select_admin ON public.profiles;

-- Create RLS policies
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

-- Admin can read all profiles
CREATE POLICY profiles_select_admin ON public.profiles
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ========================================
-- 4. CREATE PROFILE TRIGGER FUNCTION
-- ========================================
-- Function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    'client'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- 5. CREATE MISSING TABLES
-- ========================================
-- Create ai_usage table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.ai_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature text NOT NULL,
  tokens_used integer DEFAULT 0,
  cost_usd numeric(10,4) DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on ai_usage
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for ai_usage
CREATE POLICY ai_usage_own ON public.ai_usage
  FOR ALL TO authenticated
  USING (user_id = auth.uid());

-- Create user_devices table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id text,
  platform text CHECK (platform IN ('ios', 'android', 'web')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, device_id)
);

-- Enable RLS on user_devices
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for user_devices
CREATE POLICY user_devices_own ON public.user_devices
  FOR ALL TO authenticated
  USING (user_id = auth.uid());

-- ========================================
-- 6. FIX EXISTING USERS WITHOUT PROFILES
-- ========================================
-- Create profiles for existing users who don't have them
INSERT INTO public.profiles (id, email, name, role)
SELECT 
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'name', u.email),
  'client'
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- ========================================
-- 7. CLEAN UP ORPHANED PROFILES
-- ========================================
-- Remove profiles that don't have corresponding auth users
DELETE FROM public.profiles 
WHERE id NOT IN (SELECT id FROM auth.users);

-- ========================================
-- 8. CREATE HELPER FUNCTIONS
-- ========================================
-- Function to get user role
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text AS $$
BEGIN
  RETURN (
    SELECT role 
    FROM public.profiles 
    WHERE id = user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT role = 'admin' 
    FROM public.profiles 
    WHERE id = user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 9. VERIFY FIXES
-- ========================================
-- Check that all users have profiles
SELECT 
  'VERIFICATION' as check_type,
  'Users without profiles: ' || COUNT(*) as result
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Check that all profiles have users
SELECT 
  'VERIFICATION' as check_type,
  'Orphaned profiles: ' || COUNT(*) as result
FROM public.profiles p
LEFT JOIN auth.users u ON p.id = u.id
WHERE u.id IS NULL;

-- ========================================
-- 10. FINAL SUMMARY
-- ========================================
SELECT 
  'FINAL SUMMARY' as check_type,
  'Total Users: ' || (SELECT COUNT(*) FROM auth.users) as total_users,
  'Total Profiles: ' || (SELECT COUNT(*) FROM public.profiles) as total_profiles,
  'Confirmed Users: ' || (SELECT COUNT(*) FROM auth.users WHERE email_confirmed_at IS NOT NULL) as confirmed_users,
  'Admin Users: ' || (SELECT COUNT(*) FROM public.profiles WHERE role = 'admin') as admin_users,
  'Coach Users: ' || (SELECT COUNT(*) FROM public.profiles WHERE role = 'coach') as coach_users,
  'Client Users: ' || (SELECT COUNT(*) FROM public.profiles WHERE role = 'client') as client_users;
