-- Phase 2 Part I: Pantry Mode & Leftovers
-- Create pantry items table for tracking user's food inventory

-- Create pantry items table
CREATE TABLE IF NOT EXISTS public.nutrition_pantry_items (
  user_id uuid NOT NULL,
  key text NOT NULL,           -- canonical key (normalized)
  name text NOT NULL,
  qty numeric NOT NULL,        -- base units (g / ml / pcs)
  unit text NOT NULL,          -- 'g','ml','pcs'
  expires_at date,             -- optional expiration date
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, key)
);

-- Add helpful indexes
CREATE INDEX IF NOT EXISTS idx_pantry_user ON public.nutrition_pantry_items(user_id);
CREATE INDEX IF NOT EXISTS idx_pantry_expires ON public.nutrition_pantry_items(expires_at);
CREATE INDEX IF NOT EXISTS idx_pantry_updated ON public.nutrition_pantry_items(updated_at);

-- Enable RLS
ALTER TABLE public.nutrition_pantry_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for pantry items (user + their coach read/write; admin full)
DO $$
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS nutrition_pantry_items_select ON public.nutrition_pantry_items;
  DROP POLICY IF EXISTS nutrition_pantry_items_insert ON public.nutrition_pantry_items;
  DROP POLICY IF EXISTS nutrition_pantry_items_update ON public.nutrition_pantry_items;
  DROP POLICY IF EXISTS nutrition_pantry_items_delete ON public.nutrition_pantry_items;

  -- Create policies
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'nutrition_pantry_items_select') THEN
    CREATE POLICY nutrition_pantry_items_select ON public.nutrition_pantry_items
      FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.user_coach_links WHERE coach_id = auth.uid() AND client_id = user_id) OR
        auth.role() = 'service_role'
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'nutrition_pantry_items_insert') THEN
    CREATE POLICY nutrition_pantry_items_insert ON public.nutrition_pantry_items
      FOR INSERT TO authenticated
      WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.user_coach_links WHERE coach_id = auth.uid() AND client_id = user_id) OR
        auth.role() = 'service_role'
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'nutrition_pantry_items_update') THEN
    CREATE POLICY nutrition_pantry_items_update ON public.nutrition_pantry_items
      FOR UPDATE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.user_coach_links WHERE coach_id = auth.uid() AND client_id = user_id) OR
        auth.role() = 'service_role'
      )
      WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.user_coach_links WHERE coach_id = auth.uid() AND client_id = user_id) OR
        auth.role() = 'service_role'
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'nutrition_pantry_items_delete') THEN
    CREATE POLICY nutrition_pantry_items_delete ON public.nutrition_pantry_items
      FOR DELETE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.user_coach_links WHERE coach_id = auth.uid() AND client_id = user_id) OR
        auth.role() = 'service_role'
      );
  END IF;
END $$;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.nutrition_pantry_items TO authenticated;
GRANT ALL ON public.nutrition_pantry_items TO service_role;

-- Create updated_at trigger (idempotent)
CREATE OR REPLACE FUNCTION update_nutrition_pantry_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating timestamps
DROP TRIGGER IF EXISTS trigger_update_nutrition_pantry_items_updated_at ON public.nutrition_pantry_items;
CREATE TRIGGER trigger_update_nutrition_pantry_items_updated_at
  BEFORE UPDATE ON public.nutrition_pantry_items
  FOR EACH ROW
  EXECUTE FUNCTION update_nutrition_pantry_items_updated_at();

-- Add comments for documentation
COMMENT ON TABLE public.nutrition_pantry_items IS 'User pantry inventory for tracking food items and leftovers';
COMMENT ON COLUMN public.nutrition_pantry_items.user_id IS 'Owner of the pantry item';
COMMENT ON COLUMN public.nutrition_pantry_items.key IS 'Canonical normalized key for the food item';
COMMENT ON COLUMN public.nutrition_pantry_items.name IS 'Display name of the food item';
COMMENT ON COLUMN public.nutrition_pantry_items.qty IS 'Quantity in base units (g/ml/pcs)';
COMMENT ON COLUMN public.nutrition_pantry_items.unit IS 'Unit of measurement (g, ml, pcs)';
COMMENT ON COLUMN public.nutrition_pantry_items.expires_at IS 'Optional expiration date';

-- Create view for pantry analytics (optional)
CREATE OR REPLACE VIEW nutrition_pantry_summary AS
SELECT 
  user_id,
  COUNT(*) as total_items,
  COUNT(*) FILTER (WHERE expires_at IS NOT NULL) as items_with_expiry,
  COUNT(*) FILTER (WHERE expires_at <= CURRENT_DATE + INTERVAL '7 days') as expiring_soon,
  COUNT(*) FILTER (WHERE expires_at <= CURRENT_DATE) as expired,
  SUM(qty) as total_quantity
FROM public.nutrition_pantry_items
GROUP BY user_id;

-- Add RLS for the summary view
ALTER VIEW nutrition_pantry_summary SET (security_invoker = true);

-- Grant access to the view
GRANT SELECT ON nutrition_pantry_summary TO authenticated;
