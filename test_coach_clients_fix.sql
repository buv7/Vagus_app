-- ========================================
-- TEST COACH_CLIENTS FIX
-- ========================================
-- This tests if the coach_clients table is working properly

-- 1. Check if coach_clients table exists and has the right structure
SELECT 'coach_clients table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check foreign key constraints
SELECT 'Foreign key constraints on coach_clients:' as info;
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'coach_clients'
    AND tc.table_schema = 'public';

-- 3. Test the query that was failing
SELECT 'Testing the fixed query approach:' as info;
SELECT 
    cc.client_id,
    p.id,
    p.name,
    p.email,
    p.avatar_url
FROM public.coach_clients cc
JOIN public.profiles p ON p.id = cc.client_id
WHERE cc.coach_id = 'daa784d6-eade-4beb-acf5-2acd7c06f1fa'  -- Your coach ID
LIMIT 5;

-- 4. Check if there are any coach-client relationships
SELECT 'Current coach-client relationships:' as info;
SELECT 
    cc.id,
    cc.coach_id,
    cc.client_id,
    cc.status,
    p.name as client_name,
    p.email as client_email
FROM public.coach_clients cc
LEFT JOIN public.profiles p ON p.id = cc.client_id
ORDER BY cc.created_at DESC
LIMIT 10;

-- 5. Test inserting a sample relationship (if needed)
-- Uncomment and modify as needed:
-- INSERT INTO public.coach_clients (coach_id, client_id, status)
-- VALUES (
--     'daa784d6-eade-4beb-acf5-2acd7c06f1fa',  -- Your coach ID
--     'SOME_CLIENT_ID_HERE',  -- Replace with actual client ID
--     'active'
-- );

SELECT '✅ Coach clients test completed!' as result;
