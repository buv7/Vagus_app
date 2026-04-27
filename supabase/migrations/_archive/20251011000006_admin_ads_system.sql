-- Admin Ads / Poster System
-- Global banners and promotional content (additive only, safe for existing ads table)

-- 1. Add missing columns to existing ads table
ALTER TABLE IF EXISTS public.ads
  ADD COLUMN IF NOT EXISTS deep_link TEXT,
  ADD COLUMN IF NOT EXISTS placement TEXT DEFAULT 'home_banner',
  ADD COLUMN IF NOT EXISTS media_url TEXT,
  ADD COLUMN IF NOT EXISTS ends_at TIMESTAMPTZ;

-- 2. Create ad_impressions table
CREATE TABLE IF NOT EXISTS public.ad_impressions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id UUID NOT NULL REFERENCES public.ads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  occurred_at TIMESTAMPTZ DEFAULT NOW(),
  meta JSONB DEFAULT '{}'::JSONB
);

-- Only create indexes if columns exist
DO $$
BEGIN
  CREATE INDEX IF NOT EXISTS idx_ad_impressions_ad ON public.ad_impressions(ad_id);
  CREATE INDEX IF NOT EXISTS idx_ad_impressions_user ON public.ad_impressions(user_id);
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ad_impressions' AND column_name = 'occurred_at') THEN
    CREATE INDEX IF NOT EXISTS idx_ad_impressions_date ON public.ad_impressions(occurred_at DESC);
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END$$;

-- 3. Create ad_clicks table
CREATE TABLE IF NOT EXISTS public.ad_clicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id UUID NOT NULL REFERENCES public.ads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  occurred_at TIMESTAMPTZ DEFAULT NOW(),
  meta JSONB DEFAULT '{}'::JSONB
);

DO $$
BEGIN
  CREATE INDEX IF NOT EXISTS idx_ad_clicks_ad ON public.ad_clicks(ad_id);
  CREATE INDEX IF NOT EXISTS idx_ad_clicks_user ON public.ad_clicks(user_id);
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ad_clicks' AND column_name = 'occurred_at') THEN
    CREATE INDEX IF NOT EXISTS idx_ad_clicks_date ON public.ad_clicks(occurred_at DESC);
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END$$;

-- 4. Enable RLS
ALTER TABLE public.ad_impressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_clicks ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for ad_impressions
DROP POLICY IF EXISTS "public_insert_impressions" ON public.ad_impressions;
CREATE POLICY "public_insert_impressions" ON public.ad_impressions
  FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_read_impressions" ON public.ad_impressions;
CREATE POLICY "service_role_read_impressions" ON public.ad_impressions
  FOR SELECT
  TO service_role
  USING (true);

-- 6. RLS Policies for ad_clicks
DROP POLICY IF EXISTS "public_insert_clicks" ON public.ad_clicks;
CREATE POLICY "public_insert_clicks" ON public.ad_clicks
  FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_read_clicks" ON public.ad_clicks;
CREATE POLICY "service_role_read_clicks" ON public.ad_clicks
  FOR SELECT
  TO service_role
  USING (true);

-- 7. Function to get ad analytics
CREATE OR REPLACE FUNCTION public.get_ad_analytics(p_ad_id UUID)
RETURNS TABLE(
  impressions BIGINT,
  clicks BIGINT,
  ctr NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_impressions BIGINT;
  v_clicks BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_impressions
  FROM public.ad_impressions
  WHERE ad_id = p_ad_id;
  
  SELECT COUNT(*) INTO v_clicks
  FROM public.ad_clicks
  WHERE ad_id = p_ad_id;
  
  RETURN QUERY SELECT 
    v_impressions,
    v_clicks,
    CASE WHEN v_impressions > 0 
      THEN ROUND((v_clicks::NUMERIC / v_impressions) * 100, 2)
      ELSE 0
    END as ctr;
END;
$$;

-- 8. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated, anon;
GRANT INSERT ON public.ad_impressions TO authenticated, anon;
GRANT INSERT ON public.ad_clicks TO authenticated, anon;

-- 9. Comments
COMMENT ON TABLE public.ad_impressions IS 'Tracking ad views/impressions';
COMMENT ON TABLE public.ad_clicks IS 'Tracking ad clicks for CTR analytics';
COMMENT ON FUNCTION public.get_ad_analytics IS 'Returns impressions, clicks, and CTR for an ad';
