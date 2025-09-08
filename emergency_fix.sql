-- ========================================
-- EMERGENCY FIX - STOP ALL USERS BEING CLIENTS
-- ========================================

-- 1. First, let's see ALL your users and their current roles
SELECT 'CURRENT USERS AND ROLES:' as info;
SELECT 
    email,
    name,
    role,
    created_at
FROM public.profiles 
ORDER BY created_at DESC;

-- 2. IMMEDIATE FIX - Update roles based on your actual users
-- You need to replace the email addresses below with your REAL user emails

-- Make yourself admin (replace with your actual email)
UPDATE public.profiles 
SET role = 'admin', updated_at = now()
WHERE email = 'YOUR_EMAIL_HERE';  -- PUT YOUR REAL EMAIL HERE

-- Make your coaches (replace with actual coach emails)
UPDATE public.profiles 
SET role = 'coach', updated_at = now()
WHERE email IN (
    'COACH_EMAIL_1',  -- PUT REAL COACH EMAIL HERE
    'COACH_EMAIL_2'   -- PUT REAL COACH EMAIL HERE
);

-- 3. Check if it worked
SELECT 'AFTER FIX - USER ROLES:' as info;
SELECT 
    email,
    name,
    role
FROM public.profiles 
ORDER BY role, email;

-- 4. If you want to set ALL users to a specific role temporarily:
-- UPDATE public.profiles SET role = 'admin' WHERE role = 'client';
-- UPDATE public.profiles SET role = 'coach' WHERE role = 'client';

SELECT 'DONE! Check the results above.' as result;
