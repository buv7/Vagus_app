-- ========================================
-- FIX COACH_CLIENTS PROPERLY
-- ========================================
-- This fixes the coach_clients issue by checking if it's a view or table

-- 1. Check what coach_clients actually is
SELECT 'Checking coach_clients object type...' as info;
SELECT 
    table_name,
    table_type,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- 2. If it's a view, show its definition
SELECT 'coach_clients view definition (if it exists):' as info;
SELECT 
    view_definition
FROM information_schema.views 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- 3. Drop the existing view if it exists and is problematic
DROP VIEW IF EXISTS public.coach_clients;

-- 4. Create the proper coach_clients TABLE
CREATE TABLE public.coach_clients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    started_at timestamptz DEFAULT now(),
    ended_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(coach_id, client_id)
);

-- 5. Create indexes (now that it's a proper table)
CREATE INDEX idx_coach_clients_coach_id ON public.coach_clients(coach_id);
CREATE INDEX idx_coach_clients_client_id ON public.coach_clients(client_id);
CREATE INDEX idx_coach_clients_status ON public.coach_clients(status);

-- 6. Enable RLS
ALTER TABLE public.coach_clients ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies
DO $$
BEGIN
    -- Coaches can see their clients
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='coach_clients_coach_access') THEN
        CREATE POLICY coach_clients_coach_access ON public.coach_clients
        FOR ALL TO authenticated
        USING (coach_id = auth.uid())
        WITH CHECK (coach_id = auth.uid());
    END IF;

    -- Clients can see their coach relationships
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='coach_clients_client_access') THEN
        CREATE POLICY coach_clients_client_access ON public.coach_clients
        FOR SELECT TO authenticated
        USING (client_id = auth.uid());
    END IF;

    -- Admins can see all relationships
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='coach_clients_admin_access') THEN
        CREATE POLICY coach_clients_admin_access ON public.coach_clients
        FOR ALL TO authenticated
        USING (EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.id = auth.uid() AND p.role = 'admin'
        ));
    END IF;
END $$;

-- 8. Add comments
COMMENT ON TABLE public.coach_clients IS 'Relationship between coaches and their clients';
COMMENT ON COLUMN public.coach_clients.coach_id IS 'The coach user ID';
COMMENT ON COLUMN public.coach_clients.client_id IS 'The client user ID';
COMMENT ON COLUMN public.coach_clients.status IS 'Relationship status: active, inactive, or pending';

-- 9. Verify the table was created properly
SELECT 'Verifying coach_clients table...' as info;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

-- 10. Check foreign key relationships
SELECT 'Checking foreign key relationships...' as info;
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

SELECT '✅ coach_clients table created successfully!' as result;
