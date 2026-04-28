-- Test Supabase Database Connection
-- Run this in Cursor IDE's database client to verify connection

-- Basic connection test
SELECT 
    'Connection successful!' as status,
    version() as postgres_version,
    current_database() as database_name,
    current_user as connected_user,
    now() as connection_time;

-- Check if we can access the main tables
SELECT 
    'Tables accessible' as status,
    count(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE';

-- List all public tables
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Test access to key tables (if they exist)
DO $$
BEGIN
    -- Test profiles table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
        RAISE NOTICE 'profiles table: accessible';
        PERFORM count(*) FROM profiles LIMIT 1;
    ELSE
        RAISE NOTICE 'profiles table: not found';
    END IF;
    
    -- Test ai_usage table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_usage') THEN
        RAISE NOTICE 'ai_usage table: accessible';
        PERFORM count(*) FROM ai_usage LIMIT 1;
    ELSE
        RAISE NOTICE 'ai_usage table: not found';
    END IF;
    
    -- Test user_files table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_files') THEN
        RAISE NOTICE 'user_files table: accessible';
        PERFORM count(*) FROM user_files LIMIT 1;
    ELSE
        RAISE NOTICE 'user_files table: not found';
    END IF;
END $$;

-- Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check current connection info
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    client_port,
    backend_start,
    state
FROM pg_stat_activity 
WHERE datname = current_database()
AND state = 'active';
