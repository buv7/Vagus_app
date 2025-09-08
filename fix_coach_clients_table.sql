-- ========================================
-- FIX COACH_CLIENTS TABLE ISSUE
-- ========================================
-- This fixes the missing coach_clients table relationship

-- 1. Check if coach_clients table exists
SELECT 'Checking coach_clients table...' as info;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'coach_clients' AND table_schema = 'public')
        THEN 'coach_clients table exists'
        ELSE 'coach_clients table MISSING'
    END as table_status;

-- 2. Create coach_clients table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.coach_clients (
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

-- 3. Create indexes
CREATE INDEX IF NOT EXISTS idx_coach_clients_coach_id ON public.coach_clients(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_clients_client_id ON public.coach_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_coach_clients_status ON public.coach_clients(status);

-- 4. Enable RLS
ALTER TABLE public.coach_clients ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies
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

-- 6. Add comments
COMMENT ON TABLE public.coach_clients IS 'Relationship between coaches and their clients';
COMMENT ON COLUMN public.coach_clients.coach_id IS 'The coach user ID';
COMMENT ON COLUMN public.coach_clients.client_id IS 'The client user ID';
COMMENT ON COLUMN public.coach_clients.status IS 'Relationship status: active, inactive, or pending';

-- 7. Verify the table was created
SELECT 'Verifying coach_clients table...' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 8. Check foreign key relationships
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

SELECT '✅ coach_clients table fixed!' as result;
