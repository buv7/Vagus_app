-- Corrected Test Account Setup for Vagus App
-- This script handles existing views/tables and sets up all test accounts
-- Run this in Supabase SQL Editor

-- ==============================================
-- STEP 1: CREATE MISSING TABLES (Handle Existing Views)
-- ==============================================

-- Create admin_users table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.admin_users (
    user_id uuid PRIMARY KEY
);

-- Handle coach_clients - drop view if it exists, then create table
DROP VIEW IF EXISTS public.coach_clients CASCADE;
DROP TABLE IF EXISTS public.coach_clients CASCADE;

-- Create the proper coach_clients table
CREATE TABLE public.coach_clients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    coach_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    client_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    started_at timestamptz DEFAULT now(),
    ended_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(coach_id, client_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_coach_clients_coach_id ON public.coach_clients(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_clients_client_id ON public.coach_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_coach_clients_status ON public.coach_clients(status);

-- Enable RLS on tables
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_clients ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for admin_users
DROP POLICY IF EXISTS "admin_users_select_own" ON public.admin_users;
CREATE POLICY "admin_users_select_own" ON public.admin_users
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "admin_users_insert_own" ON public.admin_users;
CREATE POLICY "admin_users_insert_own" ON public.admin_users
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for coach_clients
DROP POLICY IF EXISTS "coach_clients_coach_access" ON public.coach_clients;
CREATE POLICY "coach_clients_coach_access" ON public.coach_clients
FOR ALL TO authenticated
USING (coach_id = auth.uid())
WITH CHECK (coach_id = auth.uid());

DROP POLICY IF EXISTS "coach_clients_client_access" ON public.coach_clients;
CREATE POLICY "coach_clients_client_access" ON public.coach_clients
FOR SELECT TO authenticated
USING (client_id = auth.uid());

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.coach_clients TO authenticated;

-- ==============================================
-- STEP 2: VERIFY USERS WERE CREATED
-- ==============================================
SELECT 'Checking for existing users...' as status;
SELECT id, email, email_confirmed_at, created_at 
FROM auth.users 
WHERE email IN ('admin@vagus.com', 'client@vagus.com', 'client2@vagus.com', 'coach@vagus.com')
ORDER BY email;

-- ==============================================
-- STEP 3: CREATE PROFILES
-- ==============================================

-- Admin Profile
INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
SELECT 
    id,
    'Test Admin',
    'admin@vagus.com',
    'admin',
    now(),
    now()
FROM auth.users 
WHERE email = 'admin@vagus.com'
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = now();

-- Client Profile
INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
SELECT 
    id,
    'Test Client',
    'client@vagus.com',
    'client',
    now(),
    now()
FROM auth.users 
WHERE email = 'client@vagus.com'
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = now();

-- Client2 Profile
INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
SELECT 
    id,
    'Test Client 2',
    'client2@vagus.com',
    'client',
    now(),
    now()
FROM auth.users 
WHERE email = 'client2@vagus.com'
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = now();

-- Coach Profile
INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
SELECT 
    id,
    'Test Coach',
    'coach@vagus.com',
    'coach',
    now(),
    now()
FROM auth.users 
WHERE email = 'coach@vagus.com'
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = now();

-- ==============================================
-- STEP 4: SET UP ADMIN ACCESS
-- ==============================================

-- Add admin to admin_users table
INSERT INTO public.admin_users (user_id)
SELECT id FROM auth.users WHERE email = 'admin@vagus.com'
ON CONFLICT (user_id) DO NOTHING;

-- ==============================================
-- STEP 5: SET UP COACH-CLIENT RELATIONSHIPS
-- ==============================================

-- Coach-Client relationship
INSERT INTO public.coach_clients (coach_id, client_id, status, created_at, updated_at)
SELECT 
    coach.id,
    client.id,
    'active',
    now(),
    now()
FROM auth.users coach, auth.users client
WHERE coach.email = 'coach@vagus.com' 
AND client.email = 'client@vagus.com'
ON CONFLICT (coach_id, client_id) DO UPDATE SET
    status = EXCLUDED.status,
    updated_at = now();

-- Coach-Client2 relationship
INSERT INTO public.coach_clients (coach_id, client_id, status, created_at, updated_at)
SELECT 
    coach.id,
    client.id,
    'active',
    now(),
    now()
FROM auth.users coach, auth.users client
WHERE coach.email = 'coach@vagus.com' 
AND client.email = 'client2@vagus.com'
ON CONFLICT (coach_id, client_id) DO UPDATE SET
    status = EXCLUDED.status,
    updated_at = now();

-- ==============================================
-- STEP 6: VERIFICATION
-- ==============================================

-- Check all profiles
SELECT 'PROFILES CREATED:' as status;
SELECT id, name, email, role, created_at FROM public.profiles 
WHERE email IN ('admin@vagus.com', 'client@vagus.com', 'client2@vagus.com', 'coach@vagus.com')
ORDER BY role, email;

-- Check admin users
SELECT 'ADMIN USERS:' as status;
SELECT user_id FROM public.admin_users;

-- Check coach-client relationships
SELECT 'COACH-CLIENT RELATIONSHIPS:' as status;
SELECT 
    p1.email as coach_email,
    p2.email as client_email,
    cc.status
FROM public.coach_clients cc
JOIN public.profiles p1 ON cc.coach_id = p1.id
JOIN public.profiles p2 ON cc.client_id = p2.id;

-- ==============================================
-- STEP 7: SUCCESS MESSAGE
-- ==============================================
SELECT '🎉 ALL TEST ACCOUNTS SET UP SUCCESSFULLY! 🎉' as status;
SELECT 'You can now log in with:' as info;
SELECT '• admin@vagus.com / admin12' as admin_account;
SELECT '• client@vagus.com / client12' as client_account;
SELECT '• client2@vagus.com / client12' as client2_account;
SELECT '• coach@vagus.com / coach12' as coach_account;
