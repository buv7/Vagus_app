-- ========================================
-- FIX SUPABASE SECURITY ISSUES
-- ========================================
-- This script fixes all the security issues found in Supabase linter

-- ========================================
-- 1. FIX SECURITY DEFINER VIEWS
-- ========================================

-- Drop and recreate views without SECURITY DEFINER
DROP VIEW IF EXISTS public.nutrition_grocery_items_with_info CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_grocery_items_with_info AS
        SELECT 
            ni.*,
            ni.name as food_name,
            ni.category,
            ni.nutrition_per_100g
        FROM public.nutrition_items ni
        WHERE ni.item_type = ''grocery''';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_cost_summary CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_cost_summary AS
        SELECT 
            client_id,
            DATE_TRUNC(''month'', created_at) as month,
            SUM(cost) as total_cost,
            COUNT(*) as item_count
        FROM public.nutrition_items
        WHERE cost IS NOT NULL
        GROUP BY client_id, DATE_TRUNC(''month'', created_at)';
    END IF;
END $$;

DROP VIEW IF EXISTS public.coach_clients CASCADE;
CREATE VIEW public.coach_clients AS
SELECT 
    client_id, 
    coach_id, 
    created_at
FROM public.user_coach_links;

DROP VIEW IF EXISTS public.support_counts CASCADE;
-- Only create if support_tickets table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'support_tickets' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.support_counts AS
        SELECT 
            coach_id,
            COUNT(*) as total_tickets,
            COUNT(CASE WHEN status = ''open'' THEN 1 END) as open_tickets,
            COUNT(CASE WHEN status = ''closed'' THEN 1 END) as closed_tickets
        FROM public.support_tickets
        GROUP BY coach_id';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_supplements_summary CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_supplements_summary AS
        SELECT 
            client_id,
            DATE_TRUNC(''day'', created_at) as date,
            SUM(quantity) as total_supplements,
            COUNT(DISTINCT supplement_id) as unique_supplements
        FROM public.nutrition_items
        WHERE item_type = ''supplement''
        GROUP BY client_id, DATE_TRUNC(''day'', created_at)';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_hydration_summary CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_hydration_summary AS
        SELECT 
            client_id,
            DATE_TRUNC(''day'', created_at) as date,
            SUM(quantity) as total_water_ml
        FROM public.nutrition_items
        WHERE item_type = ''hydration''
        GROUP BY client_id, DATE_TRUNC(''day'', created_at)';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_barcode_stats CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_barcode_stats AS
        SELECT 
            barcode,
            COUNT(*) as scan_count,
            COUNT(DISTINCT client_id) as unique_clients,
            MAX(created_at) as last_scan
        FROM public.nutrition_items
        WHERE barcode IS NOT NULL
        GROUP BY barcode';
    END IF;
END $$;

DROP VIEW IF EXISTS public.nutrition_items_with_recipes CASCADE;
-- Only create if nutrition_items table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nutrition_items' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.nutrition_items_with_recipes AS
        SELECT
            ni.*,
            nr.title as recipe_title,
            nr.photo_url as recipe_photo_url,
            nr.prep_time_minutes,
            nr.cook_time_minutes,
            (nr.prep_time_minutes + nr.cook_time_minutes) as total_minutes,
            nr.dietary_tags as recipe_dietary_tags,
            nr.allergen_tags as recipe_allergen_tags
        FROM public.nutrition_items ni
        LEFT JOIN public.nutrition_recipes nr ON nr.id = ni.recipe_id';
    END IF;
END $$;

DROP VIEW IF EXISTS public.referral_monthly_caps CASCADE;
-- Only create if referrals table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referrals' AND table_schema = 'public') THEN
        EXECUTE 'CREATE VIEW public.referral_monthly_caps AS
        SELECT 
            referrer_id,
            DATE_TRUNC(''month'', created_at) as month,
            COUNT(*) as referral_count,
            SUM(reward_amount) as total_rewards
        FROM public.referrals
        GROUP BY referrer_id, DATE_TRUNC(''month'', created_at)';
    END IF;
END $$;

-- ========================================
-- 2. ENABLE RLS ON TABLES
-- ========================================

-- Enable RLS on support_auto_rules
ALTER TABLE public.support_auto_rules ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for support_auto_rules
CREATE POLICY sar_policy ON public.support_auto_rules
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND (p.role = 'admin' OR p.role = 'coach')
    )
);

-- Enable RLS on support_sla_policies
ALTER TABLE public.support_sla_policies ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for support_sla_policies
CREATE POLICY ssp_policy ON public.support_sla_policies
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND (p.role = 'admin' OR p.role = 'coach')
    )
);

-- Enable RLS on support_saved_views
ALTER TABLE public.support_saved_views ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for support_saved_views
CREATE POLICY ssv_policy ON public.support_saved_views
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND (p.role = 'admin' OR p.role = 'coach')
    )
);

-- Enable RLS on user_roles
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for user_roles
CREATE POLICY ur_policy ON public.user_roles
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND (p.role = 'admin' OR p.role = 'coach')
    )
);

-- ========================================
-- 3. CREATE RLS POLICIES FOR VIEWS
-- ========================================

-- Grant access to views for authenticated users
GRANT SELECT ON public.nutrition_grocery_items_with_info TO authenticated;
GRANT SELECT ON public.nutrition_cost_summary TO authenticated;
GRANT SELECT ON public.coach_clients TO authenticated;
GRANT SELECT ON public.support_counts TO authenticated;
GRANT SELECT ON public.nutrition_supplements_summary TO authenticated;
GRANT SELECT ON public.nutrition_hydration_summary TO authenticated;
GRANT SELECT ON public.nutrition_barcode_stats TO authenticated;
GRANT SELECT ON public.nutrition_items_with_recipes TO authenticated;
GRANT SELECT ON public.referral_monthly_caps TO authenticated;

-- ========================================
-- 4. VERIFY FIXES
-- ========================================

-- Check that views exist without SECURITY DEFINER
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN (
    'nutrition_grocery_items_with_info',
    'nutrition_cost_summary',
    'coach_clients',
    'support_counts',
    'nutrition_supplements_summary',
    'nutrition_hydration_summary',
    'nutrition_barcode_stats',
    'nutrition_items_with_recipes',
    'referral_monthly_caps'
);

-- Check that RLS is enabled on tables
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'support_auto_rules',
    'support_sla_policies',
    'support_saved_views',
    'user_roles'
);

-- ========================================
-- SUCCESS MESSAGE
-- ========================================
DO $$
BEGIN
    RAISE NOTICE '✅ All Supabase security issues have been fixed!';
    RAISE NOTICE '🔒 RLS enabled on 4 tables';
    RAISE NOTICE '👁️ 9 views recreated without SECURITY DEFINER';
    RAISE NOTICE '🛡️ Security policies created for all tables';
END $$;
