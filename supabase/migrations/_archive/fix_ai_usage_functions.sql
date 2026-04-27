-- Fix AI Usage Functions
-- This migration ensures the functions have the correct signatures

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS public.get_ai_usage_summary(UUID);
DROP FUNCTION IF EXISTS public.get_current_month_usage(UUID);

-- Create the get_ai_usage_summary function with the exact signature requested
CREATE OR REPLACE FUNCTION public.get_ai_usage_summary(uid uuid)
RETURNS TABLE(
  month int, 
  year int, 
  tokens_used bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    EXTRACT(MONTH FROM updated_at)::int AS month,
    EXTRACT(YEAR FROM updated_at)::int AS year,
    SUM(tokens_used)::bigint AS tokens_used
  FROM ai_usage
  WHERE user_id = uid
  GROUP BY year, month
  ORDER BY year DESC, month DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_ai_usage_summary(uuid) TO authenticated;

-- Create a more comprehensive function for the existing code that expects more fields
CREATE OR REPLACE FUNCTION public.get_ai_usage_summary_extended(uid uuid)
RETURNS TABLE(
  total_requests INTEGER,
  requests_this_month INTEGER,
  monthly_limit INTEGER,
  remaining_requests INTEGER,
  total_tokens INTEGER,
  tokens_this_month INTEGER,
  last_used TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(au.total_requests), 0) as total_requests,
    COALESCE(SUM(au.requests_this_month), 0) as requests_this_month,
    COALESCE(MAX(au.monthly_limit), 100) as monthly_limit,
    COALESCE(MAX(au.monthly_limit), 100) - COALESCE(SUM(au.requests_this_month), 0) as remaining_requests,
    COALESCE(SUM(au.tokens_used), 0) as total_tokens,
    COALESCE(SUM(CASE 
      WHEN au.month = EXTRACT(MONTH FROM NOW()) AND au.year = EXTRACT(YEAR FROM NOW()) 
      THEN au.tokens_used 
      ELSE 0 
    END), 0) as tokens_this_month,
    MAX(au.last_used) as last_used
  FROM ai_usage au
  WHERE au.user_id = uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the extended function
GRANT EXECUTE ON FUNCTION public.get_ai_usage_summary_extended(uuid) TO authenticated;

-- Create the get_current_month_usage function
CREATE OR REPLACE FUNCTION public.get_current_month_usage(uid uuid)
RETURNS TABLE(
  month INTEGER,
  year INTEGER,
  tokens_used INTEGER,
  requests_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    au.month,
    au.year,
    au.tokens_used,
    au.requests_this_month
  FROM ai_usage au
  WHERE au.user_id = uid
    AND au.month = EXTRACT(MONTH FROM NOW())
    AND au.year = EXTRACT(YEAR FROM NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.get_current_month_usage(uuid) TO authenticated;
