-- ========================================
-- FIX USER ROLES - RESTORE PROPER ROLES FOR ALL USERS
-- ========================================
-- This script fixes the issue where all users are showing as 'client'
-- instead of their proper roles (coach, admin, etc.)

-- First, let's see what we're working with
SELECT 'Current user roles in database:' as info;
SELECT 
    p.id,
    p.email,
    p.name,
    p.role,
    p.created_at,
    p.updated_at
FROM public.profiles p
ORDER BY p.created_at DESC;

-- ========================================
-- 1. IDENTIFY USERS WHO SHOULD BE ADMINS
-- ========================================
-- Look for users who might be admins based on email patterns or other indicators
SELECT 'Potential admins (based on email patterns):' as info;
SELECT 
    p.id,
    p.email,
    p.name,
    p.role,
    'Should be admin' as suggested_role
FROM public.profiles p
WHERE p.email ILIKE '%admin%' 
   OR p.email ILIKE '%@vagus%'
   OR p.name ILIKE '%admin%'
   OR p.email = 'alhas@example.com'  -- Replace with your actual admin email
ORDER BY p.created_at;

-- ========================================
-- 2. IDENTIFY USERS WHO SHOULD BE COACHES
-- ========================================
-- Look for users who might be coaches based on email patterns or other indicators
SELECT 'Potential coaches (based on email patterns):' as info;
SELECT 
    p.id,
    p.email,
    p.name,
    p.role,
    'Should be coach' as suggested_role
FROM public.profiles p
WHERE p.email ILIKE '%coach%' 
   OR p.name ILIKE '%coach%'
   OR p.email ILIKE '%trainer%'
   OR p.name ILIKE '%trainer%'
ORDER BY p.created_at;

-- ========================================
-- 3. MANUAL ROLE ASSIGNMENTS
-- ========================================
-- You need to manually update these based on your actual users
-- Replace the email addresses and user IDs with your actual data

-- Example: Set specific users as admins
-- UPDATE public.profiles 
-- SET role = 'admin', updated_at = now()
-- WHERE email IN (
--     'your-admin-email@example.com',
--     'another-admin@example.com'
-- );

-- Example: Set specific users as coaches
-- UPDATE public.profiles 
-- SET role = 'coach', updated_at = now()
-- WHERE email IN (
--     'coach1@example.com',
--     'coach2@example.com'
-- );

-- ========================================
-- 4. VERIFY THE FIX
-- ========================================
-- After running the updates above, verify the roles are correct
SELECT 'Final user roles after fix:' as info;
SELECT 
    p.role,
    COUNT(*) as user_count
FROM public.profiles p
GROUP BY p.role
ORDER BY p.role;

-- Show all users with their roles
SELECT 
    p.id,
    p.email,
    p.name,
    p.role,
    p.created_at
FROM public.profiles p
ORDER BY p.role, p.created_at DESC;

-- ========================================
-- 5. FIX THE DEFAULT ROLE ISSUE
-- ========================================
-- Remove the default 'client' role from the table definition
-- This prevents new profiles from automatically getting 'client' role
ALTER TABLE public.profiles ALTER COLUMN role DROP DEFAULT;

-- Add a comment to explain the change
COMMENT ON COLUMN public.profiles.role IS 'User role: client, coach, or admin. No default value to prevent automatic client assignment.';

-- ========================================
-- 6. CREATE A HELPER FUNCTION FOR ROLE ASSIGNMENT
-- ========================================
CREATE OR REPLACE FUNCTION public.assign_user_role(
    user_email text,
    new_role text
) RETURNS boolean AS $$
BEGIN
    -- Validate role
    IF new_role NOT IN ('client', 'coach', 'admin') THEN
        RAISE EXCEPTION 'Invalid role: %. Must be client, coach, or admin', new_role;
    END IF;
    
    -- Update the user's role
    UPDATE public.profiles 
    SET role = new_role, updated_at = now()
    WHERE email = user_email;
    
    -- Check if update was successful
    IF FOUND THEN
        RAISE NOTICE 'Successfully updated role for % to %', user_email, new_role;
        RETURN true;
    ELSE
        RAISE NOTICE 'No user found with email: %', user_email;
        RETURN false;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.assign_user_role(text, text) TO authenticated;

-- ========================================
-- 7. USAGE EXAMPLES
-- ========================================
-- Use the helper function to assign roles:
-- SELECT public.assign_user_role('admin@example.com', 'admin');
-- SELECT public.assign_user_role('coach@example.com', 'coach');
-- SELECT public.assign_user_role('client@example.com', 'client');

SELECT '🎉 User role fix script completed!' as result;
SELECT 'Next steps:' as info;
SELECT '1. Review the current roles above' as step;
SELECT '2. Uncomment and update the manual role assignments' as step;
SELECT '3. Run the UPDATE statements for your specific users' as step;
SELECT '4. Use the assign_user_role() function for future role changes' as step;
