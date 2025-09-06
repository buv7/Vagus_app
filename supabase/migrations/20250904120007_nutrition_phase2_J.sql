-- Phase 2 / Part J: Costing & Budget
-- Add cost tracking to recipe ingredients and custom food items

-- Cost fields on recipe ingredients
ALTER TABLE IF EXISTS public.nutrition_recipe_ingredients
  ADD COLUMN IF NOT EXISTS cost_per_unit numeric, -- cost per canonical unit
  ADD COLUMN IF NOT EXISTS currency text;

-- Cost fields for custom food items (if table exists; guard with IF EXISTS)
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'food_items') THEN
    ALTER TABLE public.food_items
      ADD COLUMN IF NOT EXISTS cost_per_unit numeric,
      ADD COLUMN IF NOT EXISTS currency text;
  END IF;
END $$;

-- Optional shared price list for keys (e.g., pantry/catalog)
CREATE TABLE IF NOT EXISTS public.nutrition_prices (
  key text PRIMARY KEY,
  cost_per_unit numeric NOT NULL,
  currency text NOT NULL DEFAULT 'USD',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_nutrition_prices_currency ON public.nutrition_prices(currency);
CREATE INDEX IF NOT EXISTS idx_nutrition_recipe_ingredients_cost ON public.nutrition_recipe_ingredients(cost_per_unit) WHERE cost_per_unit IS NOT NULL;

-- Updated_at trigger for nutrition_prices
CREATE OR REPLACE FUNCTION update_nutrition_prices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_nutrition_prices_updated_at') THEN
    CREATE TRIGGER trigger_update_nutrition_prices_updated_at
      BEFORE UPDATE ON public.nutrition_prices
      FOR EACH ROW
      EXECUTE FUNCTION update_nutrition_prices_updated_at();
  END IF;
END $$;

-- Create user_roles table if it doesn't exist (for role-based access control)
CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role)
);

-- Index for user_roles lookups
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);

-- RLS policies for nutrition_prices
ALTER TABLE public.nutrition_prices ENABLE ROW LEVEL SECURITY;

-- Allow read access to all authenticated users (shared price data)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nutrition_prices' AND policyname = 'nutrition_prices_read_all') THEN
    CREATE POLICY nutrition_prices_read_all ON public.nutrition_prices
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Allow write access to coaches and admins only
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nutrition_prices' AND policyname = 'nutrition_prices_write_coach_admin') THEN
    CREATE POLICY nutrition_prices_write_coach_admin ON public.nutrition_prices
      FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.user_roles ur
          WHERE ur.user_id = auth.uid()
          AND ur.role IN ('coach', 'admin')
        )
      );
  END IF;
END $$;

-- Add cost tracking to existing nutrition_items if it doesn't have cost fields
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'nutrition_items' 
    AND column_name = 'cost_per_unit'
  ) THEN
    ALTER TABLE public.nutrition_items
      ADD COLUMN IF NOT EXISTS cost_per_unit numeric,
      ADD COLUMN IF NOT EXISTS currency text;
  END IF;
END $$;

-- Index for nutrition_items cost queries
CREATE INDEX IF NOT EXISTS idx_nutrition_items_cost ON public.nutrition_items(cost_per_unit) WHERE cost_per_unit IS NOT NULL;

-- Analytics view for cost tracking (created after columns are added)
CREATE OR REPLACE VIEW nutrition_cost_summary AS
SELECT 
  nd.plan_id,
  nd.day_number,
  COUNT(DISTINCT ni.id) as total_items,
  COUNT(DISTINCT ni.id) FILTER (WHERE ni.cost_per_unit IS NOT NULL) as items_with_cost,
  SUM(ni.cost_per_unit * ni.amount_grams) as estimated_daily_cost,
  STRING_AGG(DISTINCT ni.currency, ', ') as currencies_used
FROM public.nutrition_items ni
JOIN public.nutrition_meals nm ON nm.id = ni.meal_id
JOIN public.nutrition_days nd ON nd.id = nm.day_id
WHERE ni.cost_per_unit IS NOT NULL
GROUP BY nd.plan_id, nd.day_number;

-- Grant access to the view
GRANT SELECT ON public.nutrition_cost_summary TO authenticated;
