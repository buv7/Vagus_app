-- ========================================
-- FORCE FIX COACH_CLIENTS - NUCLEAR OPTION
-- ========================================
-- This will completely recreate the coach_clients table with proper relationships

-- 1. Drop everything related to coach_clients
DROP TABLE IF EXISTS public.coach_clients CASCADE;

-- 2. Create the coach_clients table from scratch
CREATE TABLE public.coach_clients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    coach_id uuid NOT NULL,
    client_id uuid NOT NULL,
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    started_at timestamptz DEFAULT now(),
    ended_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(coach_id, client_id)
);

-- 3. Add foreign key constraints explicitly
ALTER TABLE public.coach_clients 
ADD CONSTRAINT fk_coach_clients_coach_id 
FOREIGN KEY (coach_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.coach_clients 
ADD CONSTRAINT fk_coach_clients_client_id 
FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. Create indexes
CREATE INDEX idx_coach_clients_coach_id ON public.coach_clients(coach_id);
CREATE INDEX idx_coach_clients_client_id ON public.coach_clients(client_id);
CREATE INDEX idx_coach_clients_status ON public.coach_clients(status);

-- 5. Enable RLS
ALTER TABLE public.coach_clients ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies
CREATE POLICY coach_clients_coach_access ON public.coach_clients
FOR ALL TO authenticated
USING (coach_id = auth.uid())
WITH CHECK (coach_id = auth.uid());

CREATE POLICY coach_clients_client_access ON public.coach_clients
FOR SELECT TO authenticated
USING (client_id = auth.uid());

CREATE POLICY coach_clients_admin_access ON public.coach_clients
FOR ALL TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.id = auth.uid() AND p.role = 'admin'
));

-- 7. Add comments
COMMENT ON TABLE public.coach_clients IS 'Relationship between coaches and their clients';
COMMENT ON COLUMN public.coach_clients.coach_id IS 'The coach user ID';
COMMENT ON COLUMN public.coach_clients.client_id IS 'The client user ID';
COMMENT ON COLUMN public.coach_clients.status IS 'Relationship status: active, inactive, or pending';

-- 8. Verify everything was created correctly
SELECT 'Verification - coach_clients table info:' as info;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'coach_clients' 
  AND table_schema = 'public';

SELECT 'Verification - foreign key constraints:' as info;
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

SELECT '✅ coach_clients table completely recreated!' as result;
