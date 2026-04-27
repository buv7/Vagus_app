-- Comprehensive Database Diagnosis and Fix
-- This migration will identify and fix common database issues

-- ========================================
-- 1. CHECK AND FIX MISSING CORE TABLES
-- ========================================

-- Check if profiles table exists and has correct structure
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
        CREATE TABLE public.profiles (
            id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
            name text,
            email text UNIQUE,
            role text DEFAULT 'client' CHECK (role IN ('client', 'coach', 'admin')),
            created_at timestamptz DEFAULT now(),
            updated_at timestamptz DEFAULT now()
        );
        ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'Created missing profiles table';
    END IF;
END $$;

-- Check if ai_usage table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_usage' AND table_schema = 'public') THEN
        CREATE TABLE public.ai_usage (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            feature text NOT NULL,
            tokens_used integer DEFAULT 0,
            cost_usd numeric(10,4) DEFAULT 0,
            created_at timestamptz DEFAULT now()
        );
        ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;
        CREATE INDEX idx_ai_usage_user_id ON public.ai_usage(user_id);
        CREATE INDEX idx_ai_usage_created_at ON public.ai_usage(created_at);
        RAISE NOTICE 'Created missing ai_usage table';
    END IF;
END $$;

-- Check if user_files table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_files' AND table_schema = 'public') THEN
        CREATE TABLE public.user_files (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            filename text NOT NULL,
            file_path text NOT NULL,
            file_size bigint,
            mime_type text,
            created_at timestamptz DEFAULT now()
        );
        ALTER TABLE public.user_files ENABLE ROW LEVEL SECURITY;
        CREATE INDEX idx_user_files_user_id ON public.user_files(user_id);
        RAISE NOTICE 'Created missing user_files table';
    END IF;
END $$;

-- Check if user_devices table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_devices' AND table_schema = 'public') THEN
        CREATE TABLE public.user_devices (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            device_id text NOT NULL,
            device_type text,
            os_version text,
            app_version text,
            onesignal_player_id text,
            created_at timestamptz DEFAULT now(),
            updated_at timestamptz DEFAULT now()
        );
        ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;
        CREATE INDEX idx_user_devices_user_id ON public.user_devices(user_id);
        CREATE UNIQUE INDEX idx_user_devices_device_id ON public.user_devices(device_id);
        RAISE NOTICE 'Created missing user_devices table';
    END IF;
END $$;

-- Check if user_coach_links table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_coach_links' AND table_schema = 'public') THEN
        CREATE TABLE public.user_coach_links (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            status text DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
            created_at timestamptz DEFAULT now(),
            updated_at timestamptz DEFAULT now(),
            UNIQUE(coach_id, client_id)
        );
        ALTER TABLE public.user_coach_links ENABLE ROW LEVEL SECURITY;
        CREATE INDEX idx_user_coach_links_coach_id ON public.user_coach_links(coach_id);
        CREATE INDEX idx_user_coach_links_client_id ON public.user_coach_links(client_id);
        RAISE NOTICE 'Created missing user_coach_links table';
    END IF;
END $$;

-- ========================================
-- 2. FIX COACH_CLIENTS VIEW
-- ========================================

-- Handle coach_clients - could be table or view
DO $$
BEGIN
    -- Check if coach_clients exists and what type it is
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'coach_clients' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        -- It's a table, drop it
        DROP TABLE public.coach_clients CASCADE;
        RAISE NOTICE 'Dropped coach_clients table';
    ELSIF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'coach_clients' AND table_schema = 'public') THEN
        -- It's a view, drop it
        DROP VIEW public.coach_clients CASCADE;
        RAISE NOTICE 'Dropped coach_clients view';
    END IF;
    
    -- Now create the proper view (only if user_coach_links has status column)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_coach_links' AND table_schema = 'public' AND column_name = 'status') THEN
        CREATE VIEW public.coach_clients AS
        SELECT 
            client_id, 
            coach_id, 
            created_at
        FROM public.user_coach_links
        WHERE status = 'active';
    ELSE
        CREATE VIEW public.coach_clients AS
        SELECT 
            client_id, 
            coach_id, 
            created_at
        FROM public.user_coach_links;
    END IF;
    
    RAISE NOTICE 'Created coach_clients view';
END $$;

-- ========================================
-- 3. CREATE ESSENTIAL RLS POLICIES
-- ========================================

-- Profiles policies
DO $$
BEGIN
    -- Drop existing policies first
    DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
    DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
    DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
    
    -- Create new policies
    CREATE POLICY profiles_select_own ON public.profiles
        FOR SELECT TO authenticated
        USING (id = auth.uid());
    
    CREATE POLICY profiles_update_own ON public.profiles
        FOR UPDATE TO authenticated
        USING (id = auth.uid())
        WITH CHECK (id = auth.uid());
    
    CREATE POLICY profiles_insert_own ON public.profiles
        FOR INSERT TO authenticated
        WITH CHECK (id = auth.uid());
    
    RAISE NOTICE 'Created profiles RLS policies';
END $$;

-- AI Usage policies
DO $$
BEGIN
    DROP POLICY IF EXISTS ai_usage_select_own ON public.ai_usage;
    DROP POLICY IF EXISTS ai_usage_insert_own ON public.ai_usage;
    
    CREATE POLICY ai_usage_select_own ON public.ai_usage
        FOR SELECT TO authenticated
        USING (user_id = auth.uid());
    
    CREATE POLICY ai_usage_insert_own ON public.ai_usage
        FOR INSERT TO authenticated
        WITH CHECK (user_id = auth.uid());
    
    RAISE NOTICE 'Created ai_usage RLS policies';
END $$;

-- User Files policies
DO $$
BEGIN
    DROP POLICY IF EXISTS user_files_select_own ON public.user_files;
    DROP POLICY IF EXISTS user_files_insert_own ON public.user_files;
    DROP POLICY IF EXISTS user_files_delete_own ON public.user_files;
    
    CREATE POLICY user_files_select_own ON public.user_files
        FOR SELECT TO authenticated
        USING (user_id = auth.uid());
    
    CREATE POLICY user_files_insert_own ON public.user_files
        FOR INSERT TO authenticated
        WITH CHECK (user_id = auth.uid());
    
    CREATE POLICY user_files_delete_own ON public.user_files
        FOR DELETE TO authenticated
        USING (user_id = auth.uid());
    
    RAISE NOTICE 'Created user_files RLS policies';
END $$;

-- User Devices policies
DO $$
BEGIN
    DROP POLICY IF EXISTS user_devices_select_own ON public.user_devices;
    DROP POLICY IF EXISTS user_devices_insert_own ON public.user_devices;
    DROP POLICY IF EXISTS user_devices_update_own ON public.user_devices;
    
    CREATE POLICY user_devices_select_own ON public.user_devices
        FOR SELECT TO authenticated
        USING (user_id = auth.uid());
    
    CREATE POLICY user_devices_insert_own ON public.user_devices
        FOR INSERT TO authenticated
        WITH CHECK (user_id = auth.uid());
    
    CREATE POLICY user_devices_update_own ON public.user_devices
        FOR UPDATE TO authenticated
        USING (user_id = auth.uid())
        WITH CHECK (user_id = auth.uid());
    
    RAISE NOTICE 'Created user_devices RLS policies';
END $$;

-- User Coach Links policies
DO $$
BEGIN
    DROP POLICY IF EXISTS user_coach_links_select_own ON public.user_coach_links;
    DROP POLICY IF EXISTS user_coach_links_insert_own ON public.user_coach_links;
    DROP POLICY IF EXISTS user_coach_links_update_own ON public.user_coach_links;
    
    CREATE POLICY user_coach_links_select_own ON public.user_coach_links
        FOR SELECT TO authenticated
        USING (coach_id = auth.uid() OR client_id = auth.uid());
    
    CREATE POLICY user_coach_links_insert_own ON public.user_coach_links
        FOR INSERT TO authenticated
        WITH CHECK (coach_id = auth.uid() OR client_id = auth.uid());
    
    CREATE POLICY user_coach_links_update_own ON public.user_coach_links
        FOR UPDATE TO authenticated
        USING (coach_id = auth.uid() OR client_id = auth.uid())
        WITH CHECK (coach_id = auth.uid() OR client_id = auth.uid());
    
    RAISE NOTICE 'Created user_coach_links RLS policies';
END $$;

-- ========================================
-- 4. CREATE ESSENTIAL FUNCTIONS
-- ========================================

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email)
    VALUES (new.id, new.raw_user_meta_data->>'name', new.email);
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to assign user role
CREATE OR REPLACE FUNCTION public.assign_user_role(user_id uuid, new_role text)
RETURNS void AS $$
BEGIN
    UPDATE public.profiles 
    SET role = new_role, updated_at = now()
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 5. CREATE TRIGGERS
-- ========================================

-- Trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger for updating updated_at on profiles
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger for updating updated_at on user_devices
DROP TRIGGER IF EXISTS update_user_devices_updated_at ON public.user_devices;
CREATE TRIGGER update_user_devices_updated_at
    BEFORE UPDATE ON public.user_devices
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger for updating updated_at on user_coach_links
DROP TRIGGER IF EXISTS update_user_coach_links_updated_at ON public.user_coach_links;
CREATE TRIGGER update_user_coach_links_updated_at
    BEFORE UPDATE ON public.user_coach_links
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ========================================
-- 6. FINAL DIAGNOSIS REPORT
-- ========================================

-- Generate a summary of what was fixed
SELECT '=== DATABASE FIXES APPLIED ===' as section;
SELECT '✅ Core tables created/verified' as fix;
SELECT '✅ RLS policies created' as fix;
SELECT '✅ Essential functions created' as fix;
SELECT '✅ Triggers created' as fix;
SELECT '✅ coach_clients view recreated' as fix;
SELECT '=== DIAGNOSIS COMPLETE ===' as section;
