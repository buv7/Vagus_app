-- ========================================
-- QUICK FIX FOR USER ROLES
-- ========================================
-- Run this script to quickly fix user roles
-- Replace the email addresses with your actual user emails

-- IMPORTANT: Replace these email addresses with your actual user emails
-- You can find the correct emails by running: SELECT email, name, role FROM public.profiles ORDER BY created_at;

-- 1. Set specific users as ADMINS (replace with your admin emails)
UPDATE public.profiles 
SET role = 'admin', updated_at = now()
WHERE email IN (
    -- Replace these with your actual admin emails:
    'your-admin-email@example.com',
    'another-admin@example.com'
    -- Add more admin emails here
);

-- 2. Set specific users as COACHES (replace with your coach emails)
UPDATE public.profiles 
SET role = 'coach', updated_at = now()
WHERE email IN (
    -- Replace these with your actual coach emails:
    'coach1@example.com',
    'coach2@example.com'
    -- Add more coach emails here
);

-- 3. Verify the changes
SELECT 'Updated user roles:' as info;
SELECT 
    email,
    name,
    role,
    updated_at
FROM public.profiles 
ORDER BY role, email;

-- 4. Show role distribution
SELECT 'Final role distribution:' as info;
SELECT 
    role,
    COUNT(*) as user_count
FROM public.profiles 
GROUP BY role
ORDER BY role;

-- 5. If you need to set a specific user as admin by email:
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'specific-email@example.com';

-- 6. If you need to set a specific user as coach by email:
-- UPDATE public.profiles SET role = 'coach' WHERE email = 'specific-email@example.com';

SELECT '✅ Quick fix completed! Check the results above.' as result;
