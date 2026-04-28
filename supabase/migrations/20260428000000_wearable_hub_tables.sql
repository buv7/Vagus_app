-- WEARABLE-HUB — wearable_daily + wearable_sources tables
-- Migration owner: WEARABLE-HUB
-- Created: 2026-04-28 UTC
--
-- Purpose
--   On-device ingestion path: device → health SDK → app → Supabase.
--   HRV and VO2max are diagnostic-grade; they are encrypted at rest using
--   vault_encrypt_text() from VAULT (pgcrypto + app.vault_data_key GUC).
--   All other daily aggregates (steps, RHR, sleep minutes) are plaintext
--   but RLS-protected — they are not PII alone and bloating the audit log
--   per-sample would balloon storage (VAULT guidance).
--
--   Audit-log semantics: coach reads emit ONE audit row per dashboard view,
--   not one per metric. Background sync uses accessor_id = user_id and
--   justification 'background_sync'.
--
-- Requires: VAULT migration 20260427211500_vault_audit_table.sql (pgcrypto + helpers).
-- Idempotent: safe to re-apply.

-- ============================================================================
-- wearable_sources — which providers a user has connected
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.wearable_sources (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider     text        NOT NULL,   -- 'apple_health' | 'google_health_connect' | 'garmin' | 'whoop' | 'oura'
  connected_at timestamptz NOT NULL DEFAULT now(),
  last_sync_at timestamptz NULL,
  meta         jsonb       NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (user_id, provider)
);

COMMENT ON TABLE public.wearable_sources IS
  'WEARABLE-HUB. One row per user per connected provider. '
  'Cloud providers (garmin/whoop/oura) additionally store oauth_token_key in '
  'flutter_secure_storage on the device; the token is never stored in this table.';

ALTER TABLE public.wearable_sources ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS wearable_sources_user ON public.wearable_sources;
CREATE POLICY wearable_sources_user
  ON public.wearable_sources
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS wearable_sources_user_idx
  ON public.wearable_sources (user_id);

-- ============================================================================
-- wearable_daily — daily aggregates, with encrypted medical-grade columns
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.wearable_daily (
  id             uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid  NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day            date  NOT NULL,
  source         text  NOT NULL,    -- 'apple_health' | 'google_health_connect'
  steps          int   NULL,        -- aggregate counts; plaintext — not PII alone
  resting_hr     int   NULL,        -- avg RHR in bpm; plaintext
  hrv_ms_enc     bytea NULL,        -- HRV RMSSD in ms; diagnostic → encrypt
  sleep_minutes  int   NULL,        -- total sleep minutes; plaintext
  active_kcal    int   NULL,        -- active energy burned; plaintext
  workouts_count int   NULL,
  vo2max_enc     bytea NULL,        -- VO2max ml/kg/min; medical-grade → encrypt
  ingested_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, day, source)
);

COMMENT ON TABLE public.wearable_daily IS
  'WEARABLE-HUB. Daily aggregated wearable data. '
  'hrv_ms_enc and vo2max_enc are PGP-encrypted via vault_encrypt_text(). '
  'Raw per-minute streams are never stored here — only daily rollups.';

ALTER TABLE public.wearable_daily ENABLE ROW LEVEL SECURITY;

-- Users can read and write their own rows.
DROP POLICY IF EXISTS wearable_daily_user ON public.wearable_daily;
CREATE POLICY wearable_daily_user
  ON public.wearable_daily
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Coaches can SELECT (not insert/update) rows for their clients, via coach_clients
-- relationship. The audit function must be called before this is reached.
DROP POLICY IF EXISTS wearable_daily_coach_read ON public.wearable_daily;
CREATE POLICY wearable_daily_coach_read
  ON public.wearable_daily
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.coach_clients cc
      WHERE cc.client_id = wearable_daily.user_id
        AND cc.coach_id  = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS wearable_daily_user_day_idx
  ON public.wearable_daily (user_id, day DESC);

-- ============================================================================
-- wearable_upsert_daily — server-side helper that encrypts HRV + VO2max
-- ============================================================================
--
-- Dart client calls this instead of a raw upsert so that sensitive values
-- never need to be serialized as encrypted bytea on the client side.

CREATE OR REPLACE FUNCTION public.wearable_upsert_daily(
  p_user_id       uuid,
  p_day           date,
  p_source        text,
  p_steps         int     DEFAULT NULL,
  p_resting_hr    int     DEFAULT NULL,
  p_hrv_ms        text    DEFAULT NULL,  -- plaintext, will be encrypted
  p_sleep_minutes int     DEFAULT NULL,
  p_active_kcal   int     DEFAULT NULL,
  p_workouts_count int    DEFAULT NULL,
  p_vo2max        text    DEFAULT NULL   -- plaintext, will be encrypted
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_id        uuid;
  v_hrv_enc   bytea := NULL;
  v_vo2_enc   bytea := NULL;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'wearable_upsert_daily: caller is not authenticated';
  END IF;

  -- Only the user themselves (or a server-side service role) may write their own rows
  IF p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'wearable_upsert_daily: user_id mismatch';
  END IF;

  IF p_hrv_ms IS NOT NULL THEN
    v_hrv_enc := public.vault_encrypt_text(p_hrv_ms);
  END IF;

  IF p_vo2max IS NOT NULL THEN
    v_vo2_enc := public.vault_encrypt_text(p_vo2max);
  END IF;

  INSERT INTO public.wearable_daily (
    user_id, day, source,
    steps, resting_hr, hrv_ms_enc, sleep_minutes, active_kcal, workouts_count, vo2max_enc,
    ingested_at
  )
  VALUES (
    p_user_id, p_day, p_source,
    p_steps, p_resting_hr, v_hrv_enc, p_sleep_minutes, p_active_kcal, p_workouts_count, v_vo2_enc,
    now()
  )
  ON CONFLICT (user_id, day, source) DO UPDATE SET
    steps          = COALESCE(EXCLUDED.steps,          wearable_daily.steps),
    resting_hr     = COALESCE(EXCLUDED.resting_hr,     wearable_daily.resting_hr),
    hrv_ms_enc     = COALESCE(EXCLUDED.hrv_ms_enc,     wearable_daily.hrv_ms_enc),
    sleep_minutes  = COALESCE(EXCLUDED.sleep_minutes,  wearable_daily.sleep_minutes),
    active_kcal    = COALESCE(EXCLUDED.active_kcal,    wearable_daily.active_kcal),
    workouts_count = COALESCE(EXCLUDED.workouts_count, wearable_daily.workouts_count),
    vo2max_enc     = COALESCE(EXCLUDED.vo2max_enc,     wearable_daily.vo2max_enc),
    ingested_at    = now()
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

COMMENT ON FUNCTION public.wearable_upsert_daily IS
  'WEARABLE-HUB. Upserts a daily wearable aggregate. Encrypts HRV and VO2max '
  'server-side via vault_encrypt_text(). Call from Dart instead of a raw upsert.';

-- ============================================================================
-- wearable_read_daily — coach read helper with mandatory audit
-- ============================================================================

CREATE OR REPLACE FUNCTION public.wearable_read_daily(
  p_client_id uuid,
  p_days      int  DEFAULT 7,
  p_consent_id text DEFAULT NULL
)
RETURNS TABLE (
  id            uuid,
  day           date,
  source        text,
  steps         int,
  resting_hr    int,
  sleep_minutes int,
  active_kcal   int,
  workouts_count int
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'wearable_read_daily: caller is not authenticated';
  END IF;

  -- Coaches may only read clients they manage; own data is always readable.
  IF p_client_id != auth.uid() THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.coach_clients cc
      WHERE cc.client_id = p_client_id AND cc.coach_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'wearable_read_daily: not authorized for this client';
    END IF;
  END IF;

  -- Emit a single audit row for the whole session-level read
  PERFORM public.vault_audit_access(
    p_accessed_user_id := p_client_id,
    p_data_class       := 'wearable',
    p_action           := 'read',
    p_resource_table   := 'wearable_daily',
    p_justification    := CASE
                            WHEN p_client_id = auth.uid() THEN 'self_read'
                            ELSE 'coach_dashboard; consent=' || COALESCE(p_consent_id, 'none')
                          END
  );

  -- Return non-encrypted columns only (coach sees aggregates, not raw biomarkers)
  RETURN QUERY
    SELECT
      wd.id, wd.day, wd.source,
      wd.steps, wd.resting_hr, wd.sleep_minutes, wd.active_kcal, wd.workouts_count
    FROM public.wearable_daily wd
    WHERE wd.user_id = p_client_id
      AND wd.day >= CURRENT_DATE - p_days
    ORDER BY wd.day DESC;
END;
$$;

COMMENT ON FUNCTION public.wearable_read_daily IS
  'WEARABLE-HUB. Read aggregate wearable data for a client with automatic audit logging. '
  'Does NOT return encrypted columns (HRV, VO2max) — those require explicit user consent flow.';

-- ============================================================================
-- Rollback
-- ============================================================================
--
-- DROP FUNCTION IF EXISTS public.wearable_read_daily(uuid, int, text);
-- DROP FUNCTION IF EXISTS public.wearable_upsert_daily(uuid, date, text, int, int, text, int, int, int, text);
-- DROP TABLE IF EXISTS public.wearable_daily;
-- DROP TABLE IF EXISTS public.wearable_sources;
