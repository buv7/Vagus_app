-- Fix Auth-Related Security Warnings
-- This migration addresses the remaining auth security warnings

SELECT '=== FIXING AUTH SECURITY WARNINGS ===' as section;

-- ========================================
-- NOTE: AUTH SETTINGS CANNOT BE CHANGED VIA SQL
-- ========================================

-- The following warnings cannot be fixed via SQL migrations:
-- 1. auth_otp_long_expiry - OTP expiry time
-- 2. auth_leaked_password_protection - Leaked password protection

-- These settings must be changed in the Supabase Dashboard:
-- 1. Go to Authentication → Settings
-- 2. Set OTP expiry to less than 1 hour (recommended: 15-30 minutes)
-- 3. Enable "Leaked password protection" in Password Security settings

-- ========================================
-- CREATE HELPER FUNCTIONS FOR AUTH
-- ========================================

-- Create a function to check if user has valid session
CREATE OR REPLACE FUNCTION public.is_valid_session()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN auth.uid() IS NOT NULL;
END;
$$;

-- Create a function to get current user profile
CREATE OR REPLACE FUNCTION public.get_current_user_profile()
RETURNS TABLE(
    id UUID,
    email TEXT,
    name TEXT,
    role TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.email,
        p.name,
        COALESCE(ur.role, 'user') as role
    FROM public.profiles p
    LEFT JOIN public.user_roles ur ON p.id = ur.user_id
    WHERE p.id = auth.uid();
END;
$$;

-- Create a function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_user_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    );
END;
$$;

-- Create a function to check if user is coach
CREATE OR REPLACE FUNCTION public.is_user_coach()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'coach'
    );
END;
$$;

-- ========================================
-- CREATE SECURITY POLICIES FOR AUTH FUNCTIONS
-- ========================================

-- Grant execute permissions on auth helper functions
GRANT EXECUTE ON FUNCTION public.is_valid_session() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_user_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_user_coach() TO authenticated;

-- ========================================
-- CREATE AUDIT LOGGING FOR AUTH EVENTS
-- ========================================

-- Create audit log table for auth events
CREATE TABLE IF NOT EXISTS public.auth_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    event_type TEXT NOT NULL,
    event_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on auth audit log
ALTER TABLE public.auth_audit_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for auth audit log
CREATE POLICY "auth_audit_log_select_policy" ON public.auth_audit_log
    FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR is_user_admin());

CREATE POLICY "auth_audit_log_insert_policy" ON public.auth_audit_log
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- Create function to log auth events
CREATE OR REPLACE FUNCTION public.log_auth_event(
    event_type TEXT,
    event_data JSONB DEFAULT NULL,
    ip_address INET DEFAULT NULL,
    user_agent TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.auth_audit_log (
        user_id,
        event_type,
        event_data,
        ip_address,
        user_agent
    ) VALUES (
        auth.uid(),
        event_type,
        event_data,
        ip_address,
        user_agent
    );
END;
$$;

-- Grant execute permission on log function
GRANT EXECUTE ON FUNCTION public.log_auth_event(TEXT, JSONB, INET, TEXT) TO authenticated;

-- ========================================
-- CREATE SECURITY RECOMMENDATIONS VIEW
-- ========================================

-- Create a view to show security recommendations
CREATE OR REPLACE VIEW public.security_recommendations AS
SELECT 
    'auth_otp_expiry' as recommendation_type,
    'Set OTP expiry to less than 1 hour' as description,
    'Go to Authentication → Settings and set OTP expiry to 15-30 minutes' as action_required,
    'HIGH' as priority
UNION ALL
SELECT 
    'auth_leaked_password_protection' as recommendation_type,
    'Enable leaked password protection' as description,
    'Go to Authentication → Settings → Password Security and enable leaked password protection' as action_required,
    'HIGH' as priority
UNION ALL
SELECT 
    'function_search_path' as recommendation_type,
    'All functions now have secure search_path settings' as description,
    'No action required - functions have been secured' as action_required,
    'RESOLVED' as priority
UNION ALL
SELECT 
    'extensions_schema' as recommendation_type,
    'Extensions moved to dedicated schema' as description,
    'No action required - extensions are now in extensions schema' as action_required,
    'RESOLVED' as priority;

-- Grant select permission on security recommendations view
GRANT SELECT ON public.security_recommendations TO authenticated;

SELECT '=== AUTH SECURITY WARNINGS ADDRESSED ===' as section;
