-- ========================================
-- IMMEDIATE FIX - NO MORE CLIENTS!
-- ========================================
-- Run this RIGHT NOW to fix the user roles issue

-- Step 1: See what users you have
SELECT 'ALL YOUR USERS:' as info;
SELECT 
    id,
    email,
    name,
    role,
    created_at
FROM public.profiles 
ORDER BY created_at DESC;

-- Step 2: Fix the roles immediately
-- Replace the email addresses below with YOUR ACTUAL USER EMAILS

-- Set the first user as ADMIN (replace with your email)
UPDATE public.profiles 
SET role = 'admin', updated_at = now()
WHERE email = 'alhas@example.com';  -- CHANGE THIS TO YOUR EMAIL

-- Set other users as COACHES (replace with actual coach emails)
UPDATE public.profiles 
SET role = 'coach', updated_at = now()
WHERE email IN (
    'coach1@example.com',  -- CHANGE THESE TO ACTUAL COACH EMAILS
    'coach2@example.com'
);

-- Step 3: Verify the fix worked
SELECT 'FIXED USER ROLES:' as info;
SELECT 
    email,
    name,
    role
FROM public.profiles 
ORDER BY role, email;

-- Step 4: Show role count
SELECT 'ROLE DISTRIBUTION:' as info;
SELECT 
    role,
    COUNT(*) as count
FROM public.profiles 
GROUP BY role;
