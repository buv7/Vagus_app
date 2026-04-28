-- PERIODS-FORGE — period tracking consent, logs, and cycle records
-- Migration owner: PERIODS-FORGE
-- Created: 2026-04-28 UTC
--
-- Depends on: 20260427211500_vault_audit_table.sql (VAULT)
--   vault_encrypt_text() / vault_decrypt_text() / vault_audit_access()
--   vault_data_class 'period_tracking'
--
-- All health data is encrypted at rest. No row is written until the user has
-- explicitly set opted_in = true in period_tracking_consent.
--
-- Idempotent: safe to re-apply.
-- Rollback: see bottom of file.

-- ============================================================================
-- period_tracking_consent — explicit opt-in gate
-- ============================================================================
-- opted_in defaults FALSE. No log/cycle data may be written without this.
-- coach_share is a separate per-feature consent; also defaults FALSE.

CREATE TABLE IF NOT EXISTS public.period_tracking_consent (
  user_id                uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  opted_in               boolean     NOT NULL DEFAULT false,
  opted_in_at            timestamptz NULL,
  opted_out_at           timestamptz NULL,
  coach_share            boolean     NOT NULL DEFAULT false,
  coach_share_updated_at timestamptz NULL,
  updated_at             timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.period_tracking_consent IS
  'PERIODS-FORGE. Explicit opt-in gate — opted_in defaults false so no data '
  'is ever collected without affirmative user action. coach_share is a separate '
  'per-feature consent for sharing cycle data with the assigned coach.';

ALTER TABLE public.period_tracking_consent ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS period_consent_select_self ON public.period_tracking_consent;
CREATE POLICY period_consent_select_self
  ON public.period_tracking_consent FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS period_consent_insert_self ON public.period_tracking_consent;
CREATE POLICY period_consent_insert_self
  ON public.period_tracking_consent FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS period_consent_update_self ON public.period_tracking_consent;
CREATE POLICY period_consent_update_self
  ON public.period_tracking_consent FOR UPDATE
  USING (user_id = auth.uid());

-- ============================================================================
-- period_logs — day-by-day tracking (flow, symptoms, notes)
-- ============================================================================
-- flow_enc / symptoms_enc / notes_enc are encrypted via vault_encrypt_text().
-- log_date is plaintext — the calendar date alone is not PII.
-- UNIQUE(user_id, log_date) ensures at most one log per day per user.

CREATE TABLE IF NOT EXISTS public.period_logs (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  log_date      date        NOT NULL,
  flow_enc      bytea       NULL,
  symptoms_enc  bytea       NULL,
  notes_enc     bytea       NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT period_logs_user_date_unique UNIQUE (user_id, log_date)
);

COMMENT ON TABLE public.period_logs IS
  'PERIODS-FORGE. Daily period tracking entries. flow_enc, symptoms_enc, '
  'and notes_enc are encrypted at rest using vault_encrypt_text(). '
  'Every SELECT of encrypted columns must trigger a vault_audit_access() call.';

COMMENT ON COLUMN public.period_logs.flow_enc IS
  'Encrypted text: one of none|light|medium|heavy';
COMMENT ON COLUMN public.period_logs.symptoms_enc IS
  'Encrypted JSON array of symptom keys, e.g. ["cramps","fatigue"]';
COMMENT ON COLUMN public.period_logs.notes_enc IS
  'Encrypted free-text note. May contain PII — never include in analytics.';

CREATE INDEX IF NOT EXISTS period_logs_user_date_idx
  ON public.period_logs (user_id, log_date DESC);

ALTER TABLE public.period_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS period_logs_select_self ON public.period_logs;
CREATE POLICY period_logs_select_self
  ON public.period_logs FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS period_logs_insert_self ON public.period_logs;
CREATE POLICY period_logs_insert_self
  ON public.period_logs FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS period_logs_update_self ON public.period_logs;
CREATE POLICY period_logs_update_self
  ON public.period_logs FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS period_logs_delete_self ON public.period_logs;
CREATE POLICY period_logs_delete_self
  ON public.period_logs FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- cycles — one row per menstrual cycle
-- ============================================================================
-- cycle_end is NULL until the following cycle starts (closed by periods_start_cycle).
-- avg_length_days is the rolling average of the 6 most recent completed cycles,
-- snapshotted at the moment this cycle is closed.
-- irregular_flag = true when stddev of recent cycle lengths exceeds 7 days.

CREATE TABLE IF NOT EXISTS public.cycles (
  id               uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_start      date         NOT NULL,
  cycle_end        date         NULL,
  avg_length_days  numeric(5,1) NULL,
  irregular_flag   boolean      NOT NULL DEFAULT false,
  created_at       timestamptz  NOT NULL DEFAULT now(),
  updated_at       timestamptz  NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.cycles IS
  'PERIODS-FORGE. One row per menstrual cycle. cycle_end is null until the '
  'next period starts. avg_length_days is a rolling snapshot of the last 6 '
  'completed cycle lengths. irregular_flag = true when stddev > 7 days.';

COMMENT ON COLUMN public.cycles.avg_length_days IS
  'Rolling average of the last 6 completed cycle lengths, snapshotted at cycle close.';
COMMENT ON COLUMN public.cycles.irregular_flag IS
  'true when stddev of last 6 completed cycle lengths exceeds 7 days.';

CREATE INDEX IF NOT EXISTS cycles_user_start_idx
  ON public.cycles (user_id, cycle_start DESC);

ALTER TABLE public.cycles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cycles_select_self ON public.cycles;
CREATE POLICY cycles_select_self
  ON public.cycles FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS cycles_insert_self ON public.cycles;
CREATE POLICY cycles_insert_self
  ON public.cycles FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS cycles_update_self ON public.cycles;
CREATE POLICY cycles_update_self
  ON public.cycles FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS cycles_delete_self ON public.cycles;
CREATE POLICY cycles_delete_self
  ON public.cycles FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- RPC: periods_upsert_log
-- ============================================================================
-- Encrypts plaintext fields with vault_encrypt_text() before storage so
-- plaintext data never lands in the column. Consent-gated and audited.
-- SECURITY INVOKER: runs as the calling user; RLS handles row scope.

CREATE OR REPLACE FUNCTION public.periods_upsert_log(
  p_log_date      date,
  p_flow          text DEFAULT NULL,
  p_symptoms      text DEFAULT NULL,
  p_notes         text DEFAULT NULL,
  p_justification text DEFAULT 'self_write'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_id      uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'periods_upsert_log: caller is not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.period_tracking_consent
    WHERE user_id = v_user_id AND opted_in = true
  ) THEN
    RAISE EXCEPTION 'periods_upsert_log: user has not consented to period tracking';
  END IF;

  PERFORM public.vault_audit_access(
    p_accessed_user_id := v_user_id,
    p_data_class       := 'period_tracking',
    p_action           := 'write',
    p_resource_table   := 'period_logs',
    p_justification    := p_justification
  );

  INSERT INTO public.period_logs (user_id, log_date, flow_enc, symptoms_enc, notes_enc)
  VALUES (
    v_user_id,
    p_log_date,
    CASE WHEN p_flow     IS NOT NULL THEN public.vault_encrypt_text(p_flow)     ELSE NULL END,
    CASE WHEN p_symptoms IS NOT NULL THEN public.vault_encrypt_text(p_symptoms) ELSE NULL END,
    CASE WHEN p_notes    IS NOT NULL THEN public.vault_encrypt_text(p_notes)    ELSE NULL END
  )
  ON CONFLICT (user_id, log_date) DO UPDATE SET
    flow_enc     = CASE WHEN p_flow     IS NOT NULL THEN public.vault_encrypt_text(p_flow)     ELSE period_logs.flow_enc     END,
    symptoms_enc = CASE WHEN p_symptoms IS NOT NULL THEN public.vault_encrypt_text(p_symptoms) ELSE period_logs.symptoms_enc END,
    notes_enc    = CASE WHEN p_notes    IS NOT NULL THEN public.vault_encrypt_text(p_notes)    ELSE period_logs.notes_enc    END,
    updated_at   = now()
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

COMMENT ON FUNCTION public.periods_upsert_log IS
  'Consent-gated upsert for daily period logs. Encrypts all sensitive fields '
  'server-side with vault_encrypt_text() so plaintext never reaches a column.';

-- ============================================================================
-- RPC: periods_get_logs_decrypted
-- ============================================================================
-- Returns decrypted logs for a date range with a single batch audit row.
-- SECURITY INVOKER: user can only read their own rows (enforced by RLS).

CREATE OR REPLACE FUNCTION public.periods_get_logs_decrypted(
  p_start_date    date,
  p_end_date      date,
  p_justification text DEFAULT 'self_view'
)
RETURNS TABLE (
  id         uuid,
  log_date   date,
  flow       text,
  symptoms   text,
  notes      text,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'periods_get_logs_decrypted: caller is not authenticated';
  END IF;

  -- One audit row covers the entire batch read
  PERFORM public.vault_audit_access(
    p_accessed_user_id := v_user_id,
    p_data_class       := 'period_tracking',
    p_action           := 'read',
    p_resource_table   := 'period_logs',
    p_justification    := p_justification
  );

  RETURN QUERY
  SELECT
    pl.id,
    pl.log_date,
    public.vault_decrypt_text(pl.flow_enc)     AS flow,
    public.vault_decrypt_text(pl.symptoms_enc) AS symptoms,
    public.vault_decrypt_text(pl.notes_enc)    AS notes,
    pl.created_at,
    pl.updated_at
  FROM public.period_logs pl
  WHERE pl.user_id = v_user_id
    AND pl.log_date BETWEEN p_start_date AND p_end_date
  ORDER BY pl.log_date DESC;
END;
$$;

COMMENT ON FUNCTION public.periods_get_logs_decrypted IS
  'Decrypt and return period logs for a date range. Emits one audit row for '
  'the entire batch — callers must not issue per-row reads.';

-- ============================================================================
-- RPC: periods_get_logs_for_coach
-- ============================================================================
-- Coach access path. Verifies coach_share consent on the client. Runs as
-- SECURITY DEFINER (bypasses RLS) because the coach is not the row owner;
-- consent enforcement is done explicitly inside the function body.

CREATE OR REPLACE FUNCTION public.periods_get_logs_for_coach(
  p_client_user_id uuid,
  p_start_date     date,
  p_end_date       date,
  p_justification  text DEFAULT NULL
)
RETURNS TABLE (
  id         uuid,
  log_date   date,
  flow       text,
  symptoms   text,
  notes      text,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_coach_id uuid := auth.uid();
BEGIN
  IF v_coach_id IS NULL THEN
    RAISE EXCEPTION 'periods_get_logs_for_coach: caller is not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.period_tracking_consent
    WHERE user_id = p_client_user_id
      AND opted_in    = true
      AND coach_share = true
  ) THEN
    RAISE EXCEPTION 'periods_get_logs_for_coach: client has not granted coach access to period data';
  END IF;

  PERFORM public.vault_audit_access(
    p_accessed_user_id := p_client_user_id,
    p_data_class       := 'period_tracking',
    p_action           := 'read',
    p_resource_table   := 'period_logs',
    p_justification    := COALESCE(p_justification, 'coach_view')
  );

  RETURN QUERY
  SELECT
    pl.id,
    pl.log_date,
    public.vault_decrypt_text(pl.flow_enc)     AS flow,
    public.vault_decrypt_text(pl.symptoms_enc) AS symptoms,
    public.vault_decrypt_text(pl.notes_enc)    AS notes,
    pl.created_at,
    pl.updated_at
  FROM public.period_logs pl
  WHERE pl.user_id = p_client_user_id
    AND pl.log_date BETWEEN p_start_date AND p_end_date
  ORDER BY pl.log_date DESC;
END;
$$;

COMMENT ON FUNCTION public.periods_get_logs_for_coach IS
  'Coach access path. Requires explicit coach_share consent from the client. '
  'SECURITY DEFINER so the coach (non-owner) can read the row; consent check '
  'inside the function enforces authorization.';

-- ============================================================================
-- RPC: periods_start_cycle
-- ============================================================================
-- Opens a new cycle row, closes any currently open cycle, and snapshots the
-- rolling avg_length_days + irregular_flag onto the previous (closed) cycle.
-- Consent-gated. All in one transaction.

CREATE OR REPLACE FUNCTION public.periods_start_cycle(
  p_cycle_start date
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_new_id  uuid;
  v_lengths numeric[];
  v_avg     numeric;
  v_stddev  numeric;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'periods_start_cycle: caller is not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.period_tracking_consent
    WHERE user_id = v_user_id AND opted_in = true
  ) THEN
    RAISE EXCEPTION 'periods_start_cycle: user has not consented to period tracking';
  END IF;

  -- Close any open cycle that started before p_cycle_start.
  -- cycle_end = p_cycle_start - 1 (last day of previous cycle).
  UPDATE public.cycles
  SET cycle_end  = p_cycle_start - 1,
      updated_at = now()
  WHERE user_id    = v_user_id
    AND cycle_end  IS NULL
    AND cycle_start < p_cycle_start;

  -- Snapshot rolling avg of last 6 completed cycle lengths onto the cycle
  -- we just closed, so the avg reflects cycles up to and including it.
  SELECT ARRAY(
    SELECT (c.cycle_end - c.cycle_start + 1)::numeric
    FROM public.cycles c
    WHERE c.user_id   = v_user_id
      AND c.cycle_end IS NOT NULL
    ORDER BY c.cycle_start DESC
    LIMIT 6
  ) INTO v_lengths;

  IF array_length(v_lengths, 1) > 0 THEN
    SELECT AVG(u) INTO v_avg     FROM UNNEST(v_lengths) AS u;
    SELECT STDDEV_POP(u) INTO v_stddev FROM UNNEST(v_lengths) AS u;
  ELSE
    v_avg    := NULL;
    v_stddev := 0;
  END IF;

  -- Update the just-closed cycle with computed stats
  UPDATE public.cycles
  SET avg_length_days = v_avg,
      irregular_flag  = COALESCE(v_stddev, 0) > 7,
      updated_at      = now()
  WHERE user_id    = v_user_id
    AND cycle_end  = p_cycle_start - 1
    AND cycle_start = (
      SELECT MAX(c2.cycle_start)
      FROM public.cycles c2
      WHERE c2.user_id   = v_user_id
        AND c2.cycle_end = p_cycle_start - 1
    );

  -- Insert new open cycle
  INSERT INTO public.cycles (user_id, cycle_start, avg_length_days, irregular_flag)
  VALUES (v_user_id, p_cycle_start, v_avg, COALESCE(v_stddev, 0) > 7)
  RETURNING id INTO v_new_id;

  RETURN v_new_id;
END;
$$;

COMMENT ON FUNCTION public.periods_start_cycle IS
  'Opens a new menstrual cycle, closes the previous open cycle, and snapshots '
  'the rolling 6-cycle avg_length_days + irregular_flag. All in one transaction.';

-- ============================================================================
-- Rollback
-- ============================================================================
-- DROP FUNCTION IF EXISTS public.periods_start_cycle(date);
-- DROP FUNCTION IF EXISTS public.periods_get_logs_for_coach(uuid, date, date, text);
-- DROP FUNCTION IF EXISTS public.periods_get_logs_decrypted(date, date, text);
-- DROP FUNCTION IF EXISTS public.periods_upsert_log(date, text, text, text, text);
-- DROP TABLE IF EXISTS public.cycles;
-- DROP TABLE IF EXISTS public.period_logs;
-- DROP TABLE IF EXISTS public.period_tracking_consent;
