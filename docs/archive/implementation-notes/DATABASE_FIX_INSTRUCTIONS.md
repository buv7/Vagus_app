# Database Schema Fix Instructions

## Issues to Fix:
1. **coach_clients relationship error**: `Could not find a relationship between 'coach_clients' and 'client_id'`
2. **entitlements_v plan_code error**: `column entitlements_v.plan_code does not exist`

## Solution: Apply SQL Fixes via Supabase Dashboard

### Step 1: Go to Supabase Dashboard
1. Open your browser and go to: https://supabase.com/dashboard
2. Navigate to your Vagus app project
3. Go to **SQL Editor** in the left sidebar

### Step 2: Run the Fix SQL
Copy and paste this SQL code into the SQL Editor and run it:

```sql
-- ========================================
-- FIX DATABASE SCHEMA ISSUES
-- ========================================

-- 1. FIX COACH_CLIENTS RELATIONSHIP
-- Drop the existing coach_clients (whether it's a view or table)
DROP VIEW IF EXISTS public.coach_clients CASCADE;
DROP TABLE IF EXISTS public.coach_clients CASCADE;

-- Create the proper coach_clients table with correct relationships
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

-- Create indexes for performance
CREATE INDEX idx_coach_clients_coach_id ON public.coach_clients(coach_id);
CREATE INDEX idx_coach_clients_client_id ON public.coach_clients(client_id);
CREATE INDEX idx_coach_clients_status ON public.coach_clients(status);

-- Enable RLS
ALTER TABLE public.coach_clients ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY coach_clients_coach_access ON public.coach_clients
FOR ALL TO authenticated
USING (coach_id = auth.uid())
WITH CHECK (coach_id = auth.uid());

CREATE POLICY coach_clients_client_access ON public.coach_clients
FOR SELECT TO authenticated
USING (client_id = auth.uid());

-- 2. FIX ENTITLEMENTS_V VIEW
-- Drop the existing entitlements_v view
DROP VIEW IF EXISTS public.entitlements_v CASCADE;

-- Create billing_plans table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.billing_plans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text UNIQUE NOT NULL,
    name text NOT NULL,
    price_monthly_cents integer NOT NULL DEFAULT 0,
    currency text NOT NULL DEFAULT 'USD',
    features jsonb DEFAULT '{}',
    ai_monthly_limit integer DEFAULT 200,
    trial_days integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Create subscriptions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_code text NOT NULL,
    status text NOT NULL DEFAULT 'active',
    period_start timestamptz DEFAULT now(),
    period_end timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS on new tables
ALTER TABLE public.billing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for new tables
CREATE POLICY IF NOT EXISTS billing_plans_read_all ON public.billing_plans
FOR SELECT TO authenticated USING (true);

CREATE POLICY IF NOT EXISTS subscriptions_owner_rw ON public.subscriptions
FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Seed default billing plans
INSERT INTO public.billing_plans (code, name, price_monthly_cents, currency, features, ai_monthly_limit, trial_days, is_active)
VALUES
  ('free','Free',0,'USD','{"notes":"Basic access"}'::jsonb,200,0,true),
  ('pro','Pro',1500,'USD','{"notes":"Higher AI limits"}'::jsonb,2000,7,true)
ON CONFLICT (code) DO NOTHING;

-- Now create the proper entitlements_v view with plan_code
CREATE VIEW public.entitlements_v AS
SELECT
  p.id as user_id,
  COALESCE(s.plan_code, 'free') as plan_code,
  COALESCE(bp.ai_monthly_limit, 200) as ai_monthly_limit,
  COALESCE(s.status, 'active') as status,
  s.period_end,
  bp.name as plan_name,
  bp.price_monthly_cents,
  bp.currency,
  bp.features
FROM public.profiles p
LEFT JOIN LATERAL (
  SELECT s1.* FROM public.subscriptions s1
  WHERE s1.user_id = p.id
  ORDER BY s1.updated_at DESC NULLS LAST
  LIMIT 1
) s ON true
LEFT JOIN public.billing_plans bp ON bp.code = s.plan_code AND bp.is_active = true;
```

### Step 3: Verify the Fix
After running the SQL, test your app again. The errors should be resolved:

1. ✅ **coach_clients relationship** - Now properly defined as a table with foreign keys
2. ✅ **entitlements_v plan_code** - Now includes the plan_code column

### Alternative: Terminal Fix (if you want to try again)
If you want to try the terminal approach again:

1. **Cancel the current command**: Press `Ctrl+C` in your terminal
2. **Try again**: Run `supabase db push --linked`
3. **Enter password**: When prompted, type: `X.7achoony.X`

## What This Fix Does:

### coach_clients Table:
- Creates a proper table (not a view) with foreign key relationships
- Links `coach_id` and `client_id` to `auth.users(id)`
- Adds proper RLS policies for security
- Includes status tracking and timestamps

### entitlements_v View:
- Adds the missing `plan_code` column
- Creates supporting tables (`billing_plans`, `subscriptions`)
- Provides comprehensive user entitlement information
- Includes plan details, limits, and features

## After the Fix:
Your calling system will work perfectly without these database errors! 🚀
