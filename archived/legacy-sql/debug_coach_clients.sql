-- ========================================
-- DEBUG COACH_CLIENTS ISSUE
-- ========================================
-- Let's see exactly what's wrong with coach_clients

-- 1. Check if coach_clients exists and what type it is
SELECT 'coach_clients object info:' as info;
SELECT 
    table_name,
    table_type,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- 2. If it's a view, show its definition
SELECT 'coach_clients view definition:' as info;
SELECT 
    view_definition
FROM information_schema.views 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- 3. Check all foreign key constraints on coach_clients
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

-- 4. Check all columns in coach_clients
SELECT 'coach_clients columns:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Check if there are any other tables that might be related
SELECT 'Tables with "client" in name:' as info;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name ILIKE '%client%' 
  AND table_schema = 'public';

-- 6. Check if there are any other tables with "coach" in name
SELECT 'Tables with "coach" in name:' as info;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name ILIKE '%coach%' 
  AND table_schema = 'public';
