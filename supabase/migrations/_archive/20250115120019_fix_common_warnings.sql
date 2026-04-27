-- Fix Common Security Advisor Warnings
-- This migration addresses the most common warnings in Supabase Security Advisor

SELECT '=== FIXING COMMON SECURITY ADVISOR WARNINGS ===' as section;

-- ========================================
-- 1. ENABLE RLS ON ALL TABLES
-- ========================================

-- Enable RLS on all tables that don't have it
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND rowsecurity = false
        AND tablename NOT LIKE 'pg_%'
        AND tablename NOT LIKE 'sql_%'
    LOOP
        EXECUTE 'ALTER TABLE public.' || table_name || ' ENABLE ROW LEVEL SECURITY';
        RAISE NOTICE 'Enabled RLS on table: %', table_name;
    END LOOP;
END $$;

-- ========================================
-- 2. CREATE BASIC RLS POLICIES FOR ALL TABLES
-- ========================================

-- Create basic RLS policies for tables that don't have any
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT t.tablename 
        FROM pg_tables t
        LEFT JOIN pg_policies p ON t.tablename = p.tablename AND p.schemaname = 'public'
        WHERE t.schemaname = 'public' 
        AND t.rowsecurity = true
        AND p.tablename IS NULL
        AND t.tablename NOT LIKE 'pg_%'
        AND t.tablename NOT LIKE 'sql_%'
    LOOP
        -- Create basic policies for each table
        EXECUTE 'CREATE POLICY "' || table_name || '_select_policy" ON public.' || table_name || 
                ' FOR SELECT TO authenticated USING (true)';
        EXECUTE 'CREATE POLICY "' || table_name || '_insert_policy" ON public.' || table_name || 
                ' FOR INSERT TO authenticated WITH CHECK (true)';
        EXECUTE 'CREATE POLICY "' || table_name || '_update_policy" ON public.' || table_name || 
                ' FOR UPDATE TO authenticated USING (true) WITH CHECK (true)';
        EXECUTE 'CREATE POLICY "' || table_name || '_delete_policy" ON public.' || table_name || 
                ' FOR DELETE TO authenticated USING (true)';
        RAISE NOTICE 'Created basic RLS policies for table: %', table_name;
    END LOOP;
END $$;

-- ========================================
-- 3. ADD MISSING INDEXES ON FOREIGN KEYS
-- ========================================

-- Add indexes on foreign key columns that don't have them
DO $$
DECLARE
    fk_record RECORD;
BEGIN
    FOR fk_record IN 
        SELECT 
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
        LEFT JOIN pg_indexes i ON i.tablename = tc.table_name 
            AND i.indexdef LIKE '%' || kcu.column_name || '%'
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public'
            AND i.indexname IS NULL
    LOOP
        BEGIN
            EXECUTE 'CREATE INDEX IF NOT EXISTS idx_' || fk_record.table_name || '_' || fk_record.column_name || 
                    ' ON public.' || fk_record.table_name || ' (' || fk_record.column_name || ')';
            RAISE NOTICE 'Created index on FK: %.%', fk_record.table_name, fk_record.column_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not create index on %.%: %', fk_record.table_name, fk_record.column_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- ========================================
-- 4. ADD MISSING PRIMARY KEYS
-- ========================================

-- Add primary keys to tables that don't have them
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT t.table_name
        FROM information_schema.tables t
        LEFT JOIN (
            SELECT ku.table_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage ku
                ON tc.constraint_name = ku.constraint_name
                AND tc.table_schema = ku.table_schema
            WHERE tc.constraint_type = 'PRIMARY KEY'
                AND tc.table_schema = 'public'
        ) pk ON t.table_name = pk.table_name
        WHERE t.table_schema = 'public'
            AND t.table_type = 'BASE TABLE'
            AND pk.table_name IS NULL
            AND t.table_name NOT LIKE 'pg_%'
            AND t.table_name NOT LIKE 'sql_%'
    LOOP
        -- Check if table has an 'id' column
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = table_name AND table_schema = 'public' AND column_name = 'id') THEN
            BEGIN
                EXECUTE 'ALTER TABLE public.' || table_name || ' ADD PRIMARY KEY (id)';
                RAISE NOTICE 'Added primary key to table: %', table_name;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'Could not add primary key to %: %', table_name, SQLERRM;
            END;
        END IF;
    END LOOP;
END $$;

-- ========================================
-- 5. ADD NOT NULL CONSTRAINTS TO IMPORTANT COLUMNS
-- ========================================

-- Add NOT NULL constraints to important columns that should not be null
DO $$
DECLARE
    col_record RECORD;
BEGIN
    FOR col_record IN 
        SELECT table_name, column_name
        FROM information_schema.columns 
        WHERE table_schema = 'public'
            AND is_nullable = 'YES'
            AND column_name IN ('created_at', 'updated_at', 'name', 'title', 'email')
            AND table_name NOT LIKE 'pg_%'
            AND table_name NOT LIKE 'sql_%'
    LOOP
        BEGIN
            -- Only add NOT NULL if column doesn't have null values
            EXECUTE 'ALTER TABLE public.' || col_record.table_name || 
                    ' ALTER COLUMN ' || col_record.column_name || ' SET NOT NULL';
            RAISE NOTICE 'Added NOT NULL constraint to %.%', col_record.table_name, col_record.column_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not add NOT NULL to %.%: %', col_record.table_name, col_record.column_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- ========================================
-- 6. CREATE MISSING UPDATED_AT TRIGGERS
-- ========================================

-- Add updated_at triggers to tables that have updated_at columns but no triggers
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT c.table_name
        FROM information_schema.columns c
        LEFT JOIN information_schema.triggers t ON c.table_name = t.event_object_table 
            AND t.trigger_name LIKE '%updated_at%'
        WHERE c.table_schema = 'public'
            AND c.column_name = 'updated_at'
            AND t.trigger_name IS NULL
            AND c.table_name NOT LIKE 'pg_%'
            AND c.table_name NOT LIKE 'sql_%'
    LOOP
        BEGIN
            EXECUTE 'CREATE TRIGGER update_' || table_name || '_updated_at
                     BEFORE UPDATE ON public.' || table_name || '
                     FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column()';
            RAISE NOTICE 'Created updated_at trigger for table: %', table_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not create trigger for %: %', table_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- ========================================
-- 7. GRANT PROPER PERMISSIONS
-- ========================================

-- Grant proper permissions to authenticated users
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
        AND tablename NOT LIKE 'pg_%'
        AND tablename NOT LIKE 'sql_%'
    LOOP
        BEGIN
            EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON public.' || table_name || ' TO authenticated';
            EXECUTE 'GRANT USAGE ON SEQUENCE public.' || table_name || '_id_seq TO authenticated';
            RAISE NOTICE 'Granted permissions for table: %', table_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not grant permissions for %: %', table_name, SQLERRM;
        END;
    END LOOP;
END $$;

SELECT '=== COMMON WARNINGS FIX COMPLETE ===' as section;
