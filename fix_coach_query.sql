-- ========================================
-- FIX COACH QUERY - ALTERNATIVE APPROACH
-- ========================================
-- This shows how to query coach_clients without relying on foreign key relationships

-- 1. Test the current query that's failing
SELECT 'Testing the failing query:' as info;
SELECT 
    cc.client_id,
    p.id,
    p.name,
    p.email,
    p.avatar_url
FROM public.coach_clients cc
JOIN public.profiles p ON p.id = cc.client_id
WHERE cc.coach_id = 'daa784d6-eade-4beb-acf5-2acd7c06f1fa'  -- Replace with actual coach ID
LIMIT 5;

-- 2. Test if we can insert a test relationship
SELECT 'Testing insert of coach-client relationship:' as info;
-- First, get a client ID to test with
SELECT id, email, role FROM public.profiles WHERE role = 'client' LIMIT 1;

-- 3. Insert a test relationship (uncomment and modify as needed)
-- INSERT INTO public.coach_clients (coach_id, client_id, status)
-- VALUES (
--     'daa784d6-eade-4beb-acf5-2acd7c06f1fa',  -- Your coach ID
--     'CLIENT_ID_HERE',  -- Replace with actual client ID
--     'active'
-- );

-- 4. Verify the relationship was created
SELECT 'Verifying coach-client relationships:' as info;
SELECT 
    cc.id,
    cc.coach_id,
    cc.client_id,
    cc.status,
    p.name as client_name,
    p.email as client_email
FROM public.coach_clients cc
JOIN public.profiles p ON p.id = cc.client_id
ORDER BY cc.created_at DESC;

SELECT '✅ Coach query test completed!' as result;
