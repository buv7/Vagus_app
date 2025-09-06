-- Phase 2 Part H: Barcode scanning support
-- Create local barcode cache table for scanned products

-- Create barcodes table for caching scanned products
CREATE TABLE IF NOT EXISTS public.nutrition_barcodes (
  code text PRIMARY KEY,
  name text NOT NULL,
  per_100g jsonb NOT NULL DEFAULT '{}',
  brand text,
  category text,
  last_seen timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_nutrition_barcodes_name ON public.nutrition_barcodes (name);
CREATE INDEX IF NOT EXISTS idx_nutrition_barcodes_category ON public.nutrition_barcodes (category);
CREATE INDEX IF NOT EXISTS idx_nutrition_barcodes_last_seen ON public.nutrition_barcodes (last_seen);

-- Enable RLS
ALTER TABLE public.nutrition_barcodes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for barcodes (read-only for all authenticated users, write for service)
DO $$
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS nutrition_barcodes_select ON public.nutrition_barcodes;
  DROP POLICY IF EXISTS nutrition_barcodes_insert ON public.nutrition_barcodes;
  DROP POLICY IF EXISTS nutrition_barcodes_update ON public.nutrition_barcodes;
  DROP POLICY IF EXISTS nutrition_barcodes_delete ON public.nutrition_barcodes;

  -- Create policies
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'nutrition_barcodes_select') THEN
    CREATE POLICY nutrition_barcodes_select ON public.nutrition_barcodes
      FOR SELECT USING (auth.role() = 'authenticated' OR auth.role() = 'service_role');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'nutrition_barcodes_insert') THEN
    CREATE POLICY nutrition_barcodes_insert ON public.nutrition_barcodes
      FOR INSERT TO authenticated
      WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'service_role');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'nutrition_barcodes_update') THEN
    CREATE POLICY nutrition_barcodes_update ON public.nutrition_barcodes
      FOR UPDATE USING (auth.role() = 'authenticated' OR auth.role() = 'service_role');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'nutrition_barcodes_delete') THEN
    CREATE POLICY nutrition_barcodes_delete ON public.nutrition_barcodes
      FOR DELETE USING (auth.role() = 'service_role');
  END IF;
END $$;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.nutrition_barcodes TO authenticated;
GRANT ALL ON public.nutrition_barcodes TO service_role;

-- Add comment for documentation
COMMENT ON TABLE public.nutrition_barcodes IS 'Local cache of scanned barcode products with nutrition data';
COMMENT ON COLUMN public.nutrition_barcodes.code IS 'Barcode/UPC/EAN code';
COMMENT ON COLUMN public.nutrition_barcodes.name IS 'Product name';
COMMENT ON COLUMN public.nutrition_barcodes.per_100g IS 'Nutrition data per 100g in JSON format';
COMMENT ON COLUMN public.nutrition_barcodes.brand IS 'Product brand';
COMMENT ON COLUMN public.nutrition_barcodes.category IS 'Product category';
COMMENT ON COLUMN public.nutrition_barcodes.last_seen IS 'When this barcode was last scanned';

-- Create function to update last_seen timestamp
CREATE OR REPLACE FUNCTION update_nutrition_barcodes_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_seen = now();
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating timestamps
DROP TRIGGER IF EXISTS trigger_update_nutrition_barcodes_last_seen ON public.nutrition_barcodes;
CREATE TRIGGER trigger_update_nutrition_barcodes_last_seen
  BEFORE UPDATE ON public.nutrition_barcodes
  FOR EACH ROW
  EXECUTE FUNCTION update_nutrition_barcodes_last_seen();

-- Create view for barcode analytics (optional)
CREATE OR REPLACE VIEW nutrition_barcode_stats AS
SELECT 
  COUNT(*) as total_barcodes,
  COUNT(*) FILTER (WHERE last_seen > now() - interval '7 days') as recent_scans,
  COUNT(DISTINCT category) as unique_categories,
  COUNT(DISTINCT brand) as unique_brands
FROM public.nutrition_barcodes;

-- Grant access to the view
GRANT SELECT ON nutrition_barcode_stats TO authenticated;
