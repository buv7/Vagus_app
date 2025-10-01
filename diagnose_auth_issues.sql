-- VAGUS App Authentication Diagnostic Script
-- Run this in your Supabase SQL Editor to identify authentication issues

-- ========================================
-- 1. CHECK AUTH USERS TABLE
-- ========================================
SELECT 
    'AUTH USERS CHECK' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users
FROM auth.users;

-- Show all users (for debugging)
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    last_sign_in_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- 2. CHECK PROFILES TABLE
-- ========================================
SELECT 
    'PROFILES TABLE CHECK' as check_type,
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN role = 'client' THEN 1 END) as client_profiles,
    COUNT(CASE WHEN role = 'coach' THEN 1 END) as coach_profiles,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_profiles
FROM public.profiles;

-- Check if profiles table exists and has correct structure
SELECT 
    'PROFILES STRUCTURE CHECK' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- 3. CHECK RLS POLICIES
-- ========================================
SELECT 
    'RLS POLICIES CHECK' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'profiles'
ORDER BY policyname;

-- ========================================
-- 4. CHECK FOR ORPHANED PROFILES
-- ========================================
SELECT 
    'ORPHANED PROFILES CHECK' as check_type,
    COUNT(*) as orphaned_profiles
FROM public.profiles p
LEFT JOIN auth.users u ON p.id = u.id
WHERE u.id IS NULL;

-- Show orphaned profiles
SELECT 
    p.id,
    p.email,
    p.name,
    p.role,
    p.created_at
FROM public.profiles p
LEFT JOIN auth.users u ON p.id = u.id
WHERE u.id IS NULL;

-- ========================================
-- 5. CHECK FOR USERS WITHOUT PROFILES
-- ========================================
SELECT 
    'USERS WITHOUT PROFILES CHECK' as check_type,
    COUNT(*) as users_without_profiles
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Show users without profiles
SELECT 
    u.id,
    u.email,
    u.email_confirmed_at,
    u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- ========================================
-- 6. CHECK AUTHENTICATION SETTINGS
-- ========================================
SELECT 
    'AUTH SETTINGS CHECK' as check_type,
    key,
    value
FROM auth.config
WHERE key IN (
    'SITE_URL',
    'DISABLE_SIGNUP',
    'ENABLE_EMAIL_CONFIRMATIONS',
    'ENABLE_PHONE_CONFIRMATIONS'
);

-- ========================================
-- 7. CHECK RECENT AUTH EVENTS
-- ========================================
SELECT 
    'RECENT AUTH EVENTS' as check_type,
    event_type,
    COUNT(*) as event_count
FROM auth.audit_log_entries
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY event_type
ORDER BY event_count DESC;

-- ========================================
-- 8. TEST AUTHENTICATION FLOW
-- ========================================
-- This will help identify if there are any issues with the auth flow
SELECT 
    'AUTH FLOW TEST' as check_type,
    'Check if auth.users table is accessible' as test_description,
    CASE 
        WHEN COUNT(*) >= 0 THEN 'PASS - auth.users accessible'
        ELSE 'FAIL - auth.users not accessible'
    END as result
FROM auth.users;

-- ========================================
-- 9. CHECK FOR COMMON ISSUES
-- ========================================
-- Check if there are any constraint violations
SELECT 
    'CONSTRAINT CHECK' as check_type,
    'Checking for foreign key violations' as test_description,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS - No foreign key violations'
        ELSE 'FAIL - Found foreign key violations'
    END as result
FROM public.profiles p
WHERE p.id NOT IN (SELECT id FROM auth.users);

-- ========================================
-- 10. SUMMARY REPORT
-- ========================================
SELECT 
    'SUMMARY REPORT' as check_type,
    'Total Users: ' || (SELECT COUNT(*) FROM auth.users) as total_users,
    'Confirmed Users: ' || (SELECT COUNT(*) FROM auth.users WHERE email_confirmed_at IS NOT NULL) as confirmed_users,
    'Total Profiles: ' || (SELECT COUNT(*) FROM public.profiles) as total_profiles,
    'Orphaned Profiles: ' || (SELECT COUNT(*) FROM public.profiles p LEFT JOIN auth.users u ON p.id = u.id WHERE u.id IS NULL) as orphaned_profiles,
    'Users Without Profiles: ' || (SELECT COUNT(*) FROM auth.users u LEFT JOIN public.profiles p ON u.id = p.id WHERE p.id IS NULL) as users_without_profiles;
