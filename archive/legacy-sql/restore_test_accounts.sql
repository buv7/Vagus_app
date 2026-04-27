-- Restore Test Accounts for Vagus App
-- This script creates the test accounts you've been using
-- Run this in Supabase SQL Editor

-- ==============================================
-- CREATE TEST USERS
-- ==============================================

-- Note: You'll need to create these users through Supabase Auth UI first
-- Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/auth/users
-- Create these users:
-- 1. client@vagus.com (password: password123)
-- 2. coach@vagus.com (password: password123) 
-- 3. admin@vagus.com (password: password123)

-- After creating the users, run this SQL to set up their profiles:

-- ==============================================
-- CLIENT ACCOUNT
-- ==============================================
-- Insert client profile (replace 'CLIENT_USER_ID' with actual user ID from auth.users)
INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
VALUES (
    'CLIENT_USER_ID', -- Replace with actual client user ID
    'Test Client',
    'client@vagus.com',
    'client',
    now(),
    now()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = now();

-- ==============================================
-- COACH ACCOUNT  
-- ==============================================
-- Insert coach profile (replace 'COACH_USER_ID' with actual user ID from auth.users)
INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
VALUES (
    'COACH_USER_ID', -- Replace with actual coach user ID
    'Test Coach',
    'coach@vagus.com',
    'coach',
    now(),
    now()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = now();

-- ==============================================
-- ADMIN ACCOUNT
-- ==============================================
-- Insert admin profile (replace 'ADMIN_USER_ID' with actual user ID from auth.users)
INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
VALUES (
    'ADMIN_USER_ID', -- Replace with actual admin user ID
    'Test Admin',
    'admin@vagus.com',
    'admin',
    now(),
    now()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    updated_at = now();

-- Add admin to admin_users table
INSERT INTO public.admin_users (user_id)
VALUES ('ADMIN_USER_ID') -- Replace with actual admin user ID
ON CONFLICT (user_id) DO NOTHING;

-- ==============================================
-- COACH-CLIENT RELATIONSHIP
-- ==============================================
-- Create coach-client relationship (replace with actual user IDs)
INSERT INTO public.coach_clients (coach_id, client_id, status, created_at, updated_at)
VALUES (
    'COACH_USER_ID', -- Replace with actual coach user ID
    'CLIENT_USER_ID', -- Replace with actual client user ID
    'active',
    now(),
    now()
) ON CONFLICT (coach_id, client_id) DO UPDATE SET
    status = EXCLUDED.status,
    updated_at = now();

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================
-- Run these to verify the accounts were created:

-- Check all profiles
SELECT id, name, email, role, created_at FROM public.profiles ORDER BY role, created_at;

-- Check admin users
SELECT user_id FROM public.admin_users;

-- Check coach-client relationships
SELECT coach_id, client_id, status FROM public.coach_clients;

-- ==============================================
-- INSTRUCTIONS
-- ==============================================
/*
STEP 1: Create Users in Supabase Auth UI
1. Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/auth/users
2. Click "Add user" and create:
   - Email: client@vagus.com, Password: password123
   - Email: coach@vagus.com, Password: password123  
   - Email: admin@vagus.com, Password: password123

STEP 2: Get User IDs
1. After creating users, note down their IDs from the users list
2. Replace 'CLIENT_USER_ID', 'COACH_USER_ID', 'ADMIN_USER_ID' in this script with actual IDs

STEP 3: Run This Script
1. Copy this script to Supabase SQL Editor
2. Replace the placeholder IDs with actual user IDs
3. Run the script

STEP 4: Test Login
1. Try logging in with client@vagus.com / password123
2. Try logging in with coach@vagus.com / password123
3. Try logging in with admin@vagus.com / password123
*/
