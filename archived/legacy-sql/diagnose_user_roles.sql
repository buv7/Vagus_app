-- ========================================
-- DIAGNOSE USER ROLES ISSUE
-- ========================================
-- This script helps diagnose why all users are showing as 'client'

-- 1. Check current user roles distribution
SELECT 'Current role distribution:' as info;
SELECT 
    role,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM public.profiles 
GROUP BY role
ORDER BY user_count DESC;

-- 2. Check if there are any users with NULL roles
SELECT 'Users with NULL roles:' as info;
SELECT 
    id,
    email,
    name,
    role,
    created_at,
    updated_at
FROM public.profiles 
WHERE role IS NULL;

-- 3. Check recent profile updates (might show when roles were changed)
SELECT 'Recent profile updates (last 30 days):' as info;
SELECT 
    id,
    email,
    name,
    role,
    created_at,
    updated_at,
    CASE 
        WHEN updated_at > created_at THEN 'Updated after creation'
        ELSE 'Never updated'
    END as update_status
FROM public.profiles 
WHERE updated_at >= NOW() - INTERVAL '30 days'
ORDER BY updated_at DESC;

-- 4. Check for any database triggers on profiles table
SELECT 'Triggers on profiles table:' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'profiles' 
  AND event_object_schema = 'public';

-- 5. Check for any functions that might modify profiles
SELECT 'Functions that might modify profiles:' as info;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_definition ILIKE '%profiles%'
  AND routine_definition ILIKE '%role%';

-- 6. Check the table structure and constraints
SELECT 'Profiles table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'profiles' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 7. Check for any check constraints on the role column
SELECT 'Check constraints on role column:' as info;
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.profiles'::regclass 
  AND contype = 'c';

-- 8. Look for any recent migrations that might have affected roles
SELECT 'Recent migrations (if available):' as info;
SELECT 
    version,
    name
FROM supabase_migrations.schema_migrations 
ORDER BY version DESC
LIMIT 10;

-- 9. Check if there are any users who should be admins based on email patterns
SELECT 'Potential admins (email patterns):' as info;
SELECT 
    id,
    email,
    name,
    role,
    'Should be admin?' as suggestion
FROM public.profiles 
WHERE email ILIKE '%admin%' 
   OR email ILIKE '%@vagus%'
   OR name ILIKE '%admin%'
   OR email ILIKE '%owner%'
   OR email ILIKE '%founder%'
ORDER BY created_at;

-- 10. Check if there are any users who should be coaches based on email patterns
SELECT 'Potential coaches (email patterns):' as info;
SELECT 
    id,
    email,
    name,
    role,
    'Should be coach?' as suggestion
FROM public.profiles 
WHERE email ILIKE '%coach%' 
   OR email ILIKE '%trainer%'
   OR name ILIKE '%coach%'
   OR name ILIKE '%trainer%'
ORDER BY created_at;

-- 11. Check for any audit logs or activity logs (if they exist)
SELECT 'Checking for audit logs...' as info;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs' AND table_schema = 'public')
        THEN 'Audit logs table exists - check for role changes'
        ELSE 'No audit logs table found'
    END as audit_status;

-- 12. Summary and recommendations
SELECT 'SUMMARY AND RECOMMENDATIONS:' as info;
SELECT '1. If all users show as "client", run the fix_user_roles.sql script' as recommendation;
SELECT '2. Check the email patterns above to identify who should be admin/coach' as recommendation;
SELECT '3. Update roles manually using the assign_user_role() function' as recommendation;
SELECT '4. Consider adding role assignment during user registration' as recommendation;
