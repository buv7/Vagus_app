-- Watermark settings per user.
-- Free users: enabled=TRUE always enforced server-side via the RLS policy below.
-- Pro/Ultimate users: can set enabled=FALSE.

CREATE TABLE IF NOT EXISTS watermark_settings (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  enabled     BOOLEAN     NOT NULL DEFAULT TRUE,
  template    TEXT        NOT NULL DEFAULT 'minimal'
                CHECK (template IN ('minimal', 'prominent', 'brand_first')),
  opacity     FLOAT       NOT NULL DEFAULT 0.7
                CHECK (opacity >= 0.1 AND opacity <= 1.0),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id)
);

ALTER TABLE watermark_settings ENABLE ROW LEVEL SECURITY;

-- Users can read their own row.
DROP POLICY IF EXISTS "watermark_settings_select_own" ON watermark_settings;
CREATE POLICY "watermark_settings_select_own"
  ON watermark_settings FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert/update their own row — but a DB function enforces
-- that free-tier users cannot set enabled=FALSE (belt-and-suspenders).
DROP POLICY IF EXISTS "watermark_settings_upsert_own" ON watermark_settings;
CREATE POLICY "watermark_settings_upsert_own"
  ON watermark_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "watermark_settings_update_own" ON watermark_settings;
CREATE POLICY "watermark_settings_update_own"
  ON watermark_settings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Prevent free-tier users disabling the watermark server-side.
-- Reads plan_code from entitlements_v (owned by billing team).
CREATE OR REPLACE FUNCTION enforce_watermark_for_free_tier()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_plan TEXT;
BEGIN
  SELECT plan_code INTO v_plan
  FROM entitlements_v
  WHERE user_id = NEW.user_id
  LIMIT 1;

  -- Free users (no row or plan_code = 'free') must keep enabled = TRUE.
  IF (v_plan IS NULL OR v_plan = 'free') AND NEW.enabled = FALSE THEN
    RAISE EXCEPTION 'Free-tier users cannot disable the watermark';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_watermark_free ON watermark_settings;
CREATE TRIGGER trg_enforce_watermark_free
  BEFORE INSERT OR UPDATE ON watermark_settings
  FOR EACH ROW EXECUTE FUNCTION enforce_watermark_for_free_tier();

-- ============================================================================
-- Rollback
-- ============================================================================
-- DROP TRIGGER IF EXISTS trg_enforce_watermark_free ON watermark_settings;
-- DROP FUNCTION IF EXISTS public.enforce_watermark_for_free_tier();
-- DROP POLICY IF EXISTS "watermark_settings_update_own" ON watermark_settings;
-- DROP POLICY IF EXISTS "watermark_settings_upsert_own" ON watermark_settings;
-- DROP POLICY IF EXISTS "watermark_settings_select_own" ON watermark_settings;
-- DROP TABLE IF EXISTS public.watermark_settings;
