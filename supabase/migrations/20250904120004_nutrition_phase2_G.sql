-- Phase 2 Part G: Photo → Food Vision/OCR stub
-- Add estimated flag to nutrition items for AI-generated food entries

-- Add estimated flag to nutrition_items table
ALTER TABLE public.nutrition_items 
ADD COLUMN IF NOT EXISTS estimated boolean NOT NULL DEFAULT false;

-- Add index for estimated items (useful for filtering/analytics)
CREATE INDEX IF NOT EXISTS idx_nutrition_items_estimated 
ON public.nutrition_items (estimated);

-- Add comment for documentation
COMMENT ON COLUMN public.nutrition_items.estimated IS 'True if this food item was estimated from photo/vision AI rather than manually entered';

-- Update RLS policies to include estimated column (no changes needed as it's just a boolean flag)
-- Existing policies already cover nutrition_items access patterns

-- Optional: Add a view for estimated items analytics (for future admin dashboards)
CREATE OR REPLACE VIEW nutrition_estimated_items_summary AS
SELECT 
  nd.plan_id,
  COUNT(*) as total_estimated_items,
  COUNT(*) FILTER (WHERE ni.estimated = true) as estimated_count,
  ROUND(
    (COUNT(*) FILTER (WHERE ni.estimated = true)::numeric / COUNT(*)) * 100, 
    2
  ) as estimated_percentage
FROM public.nutrition_items ni
JOIN public.nutrition_meals nm ON nm.id = ni.meal_id
JOIN public.nutrition_days nd ON nd.id = nm.day_id
GROUP BY nd.plan_id;

-- Add RLS for the summary view
ALTER VIEW nutrition_estimated_items_summary SET (security_invoker = true);

-- Grant access to authenticated users
GRANT SELECT ON nutrition_estimated_items_summary TO authenticated;
