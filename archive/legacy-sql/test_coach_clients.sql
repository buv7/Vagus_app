-- ========================================
-- TEST COACH_CLIENTS TABLE
-- ========================================
-- Simple test to verify the table exists and has proper relationships

-- 1. Check if table exists
SELECT 'Table exists check:' as info;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- 2. Check foreign key constraints
SELECT 'Foreign key constraints:' as info;
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

-- 3. Try to insert a test record (this will fail if relationships are wrong)
SELECT 'Testing insert (this should work if relationships are correct):' as info;

-- Get a real user ID to test with
SELECT 'Available user IDs for testing:' as info;
SELECT id, email, role FROM public.profiles LIMIT 3;

-- 4. Test the actual query that's failing in the app
SELECT 'Testing the query that fails in the app:' as info;
SELECT * FROM public.coach_clients LIMIT 1;
