-- ========================================
-- FIX AI USAGE VIEW (SIMPLE)
-- ========================================

-- 1. Create a simple view for AI usage summary (using only existing columns)
CREATE OR REPLACE VIEW public.ai_usage_summary AS
SELECT 
    user_id,
    DATE(created_at) as usage_date,
    COUNT(*) as usage_count
FROM public.ai_usage
WHERE user_id = auth.uid()
GROUP BY user_id, DATE(created_at)
ORDER BY usage_date DESC;

-- Enable RLS on the view
ALTER VIEW public.ai_usage_summary SET (security_invoker = true);
