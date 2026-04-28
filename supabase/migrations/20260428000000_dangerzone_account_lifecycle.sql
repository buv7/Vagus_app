-- DANGERZONE — account lifecycle: deactivate + delete with grace periods
-- Migration: 20260428000000_dangerzone_account_lifecycle.sql
-- Owner: DANGERZONE
-- Created: 2026-04-28 UTC
--
-- Implements right-to-be-forgotten (GDPR Art. 17) with mandatory grace periods:
--   deactivate → 30-day countdown, then purge on day 30
--   delete     → 7-day grace, then cascading purge on day 7
--
-- Restore: signing in during grace period lets the user cancel the schedule.
--
-- FORBIDDEN: hard-delete without grace, orphan rows after purge.
-- FORBIDDEN: mixing with subscription cancel (TIER owns that).
--
-- Idempotent: safe to re-apply.
-- Rollback: see bottom of file.

-- ============================================================================
-- Enums
-- ============================================================================

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lifecycle_action') THEN
    CREATE TYPE public.lifecycle_action AS ENUM ('deactivate', 'delete');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lifecycle_status') THEN
    CREATE TYPE public.lifecycle_status AS ENUM ('pending', 'restored', 'purged');
  END IF;
END $$;

-- ============================================================================
-- account_lifecycle
-- ============================================================================
-- NO foreign key ON DELETE CASCADE on user_id — this row must survive long
-- enough for the purge cron to mark it 'purged' after deleting auth.users.

CREATE TABLE IF NOT EXISTS public.account_lifecycle (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid        NOT NULL,
  action              public.lifecycle_action NOT NULL,
  requested_at        timestamptz NOT NULL DEFAULT now(),
  scheduled_purge_at  timestamptz NOT NULL,
  status              public.lifecycle_status NOT NULL DEFAULT 'pending',
  reason              text,
  restored_at         timestamptz,
  purged_at           timestamptz,
  -- tracks which scheduled notifications have been dispatched
  notification_flags  jsonb       NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE public.account_lifecycle IS
  'DANGERZONE-owned. Grace-period ledger for account deactivation and deletion. '
  'At most one pending row per user (partial unique index). '
  'NO ON DELETE CASCADE on user_id — the purge cron needs this row after auth.users is gone.';

-- At most one pending lifecycle action per user at any time.
CREATE UNIQUE INDEX IF NOT EXISTS account_lifecycle_one_pending_per_user
  ON public.account_lifecycle (user_id)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS account_lifecycle_user_status_idx
  ON public.account_lifecycle (user_id, status);

-- Cron index: quickly find rows due for purge or notification.
CREATE INDEX IF NOT EXISTS account_lifecycle_purge_schedule_idx
  ON public.account_lifecycle (scheduled_purge_at)
  WHERE status = 'pending';

-- ============================================================================
-- account_lifecycle_audit
-- ============================================================================
-- Every state change is recorded here immutably. Rows survive user deletion
-- (no FK on user_id) to satisfy compliance / forensic requirements.

CREATE TABLE IF NOT EXISTS public.account_lifecycle_audit (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL,  -- intentionally no FK; user may be gone
  action        public.lifecycle_action NOT NULL,
  status        text        NOT NULL,  -- 'requested','restored','purged','notified_*'
  performed_at  timestamptz NOT NULL DEFAULT now(),
  performed_by  text        NOT NULL DEFAULT 'user',  -- 'user','cron','admin'
  details       jsonb       NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE public.account_lifecycle_audit IS
  'DANGERZONE-owned. Immutable audit trail for every lifecycle state change. '
  'No FK on user_id so rows persist after user deletion. Append-only — no UPDATE/DELETE policies.';

CREATE INDEX IF NOT EXISTS account_lifecycle_audit_user_idx
  ON public.account_lifecycle_audit (user_id, performed_at DESC);

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.account_lifecycle       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_lifecycle_audit ENABLE ROW LEVEL SECURITY;

-- Users can read their own lifecycle row (to show countdown in the UI).
DROP POLICY IF EXISTS lifecycle_select_self ON public.account_lifecycle;
CREATE POLICY lifecycle_select_self
  ON public.account_lifecycle FOR SELECT
  USING (user_id = auth.uid());

-- No direct INSERT/UPDATE/DELETE from the client — all mutations go through
-- the RPCs below (SECURITY INVOKER) or the cron (service role, bypasses RLS).

-- Users can read their own audit trail.
DROP POLICY IF EXISTS lifecycle_audit_select_self ON public.account_lifecycle_audit;
CREATE POLICY lifecycle_audit_select_self
  ON public.account_lifecycle_audit FOR SELECT
  USING (user_id = auth.uid());

-- Audit log is append-only — no UPDATE/DELETE policies exist, so RLS denies them.

-- ============================================================================
-- View: active_profiles
-- Excludes users who have a pending deactivation from coach/discovery queries.
-- ============================================================================

CREATE OR REPLACE VIEW public.active_profiles AS
  SELECT p.*
  FROM   public.profiles p
  WHERE  NOT EXISTS (
    SELECT 1
    FROM   public.account_lifecycle al
    WHERE  al.user_id = p.id
      AND  al.status  = 'pending'
      AND  al.action  = 'deactivate'
  );

COMMENT ON VIEW public.active_profiles IS
  'DANGERZONE. Profiles filtered to exclude pending-deactivated users. '
  'Coach lists and discovery MUST query this view instead of profiles directly.';

-- ============================================================================
-- RPC: request_account_deactivation
-- Initiates a 30-day deactivation grace period.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.request_account_deactivation(
  p_reason text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_id  uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'request_account_deactivation: caller is not authenticated';
  END IF;

  INSERT INTO public.account_lifecycle (
    user_id, action, scheduled_purge_at, reason
  ) VALUES (
    v_uid, 'deactivate', now() + INTERVAL '30 days', p_reason
  )
  RETURNING id INTO v_id;

  INSERT INTO public.account_lifecycle_audit (
    user_id, action, status, performed_by, details
  ) VALUES (
    v_uid, 'deactivate', 'requested', 'user',
    jsonb_build_object(
      'lifecycle_id',       v_id,
      'scheduled_purge_at', (now() + INTERVAL '30 days')
    )
  );

  RETURN v_id;
END;
$$;

COMMENT ON FUNCTION public.request_account_deactivation IS
  'Creates a 30-day deactivation grace period. User is hidden from coach lists '
  'immediately via active_profiles view. Purge runs on day 30 unless restored.';

-- ============================================================================
-- RPC: request_account_deletion
-- Initiates a 7-day deletion grace period. Full cascading purge on day 7.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.request_account_deletion(
  p_reason text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_id  uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'request_account_deletion: caller is not authenticated';
  END IF;

  INSERT INTO public.account_lifecycle (
    user_id, action, scheduled_purge_at, reason
  ) VALUES (
    v_uid, 'delete', now() + INTERVAL '7 days', p_reason
  )
  RETURNING id INTO v_id;

  INSERT INTO public.account_lifecycle_audit (
    user_id, action, status, performed_by, details
  ) VALUES (
    v_uid, 'delete', 'requested', 'user',
    jsonb_build_object(
      'lifecycle_id',       v_id,
      'scheduled_purge_at', (now() + INTERVAL '7 days')
    )
  );

  RETURN v_id;
END;
$$;

COMMENT ON FUNCTION public.request_account_deletion IS
  'Creates a 7-day deletion grace period. Full cascading purge (all user data, '
  'auth.users row, storage) runs on day 7 unless the user signs in to restore.';

-- ============================================================================
-- RPC: restore_account
-- Called when a user signs in during their grace period to cancel the schedule.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.restore_account()
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_uid      uuid := auth.uid();
  v_row      public.account_lifecycle;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'restore_account: caller is not authenticated';
  END IF;

  SELECT * INTO v_row
  FROM   public.account_lifecycle
  WHERE  user_id = v_uid
    AND  status  = 'pending'
  LIMIT  1;

  IF NOT FOUND THEN
    RETURN false;  -- nothing to restore
  END IF;

  UPDATE public.account_lifecycle
  SET    status      = 'restored',
         restored_at = now()
  WHERE  id = v_row.id;

  INSERT INTO public.account_lifecycle_audit (
    user_id, action, status, performed_by, details
  ) VALUES (
    v_uid, v_row.action, 'restored', 'user',
    jsonb_build_object('lifecycle_id', v_row.id)
  );

  RETURN true;
END;
$$;

COMMENT ON FUNCTION public.restore_account IS
  'Cancels the pending deactivation or deletion during the grace period. '
  'Idempotent: returns false if no pending action exists.';

-- ============================================================================
-- RPC: get_account_lifecycle_status
-- UI calls this on sign-in and settings open to render the countdown banner.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_account_lifecycle_status()
RETURNS TABLE (
  lifecycle_id        uuid,
  action              public.lifecycle_action,
  requested_at        timestamptz,
  scheduled_purge_at  timestamptz,
  days_remaining      int,
  status              public.lifecycle_status
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'get_account_lifecycle_status: caller is not authenticated';
  END IF;

  RETURN QUERY
  SELECT
    al.id,
    al.action,
    al.requested_at,
    al.scheduled_purge_at,
    GREATEST(0, EXTRACT(DAY FROM (al.scheduled_purge_at - now()))::int),
    al.status
  FROM  public.account_lifecycle al
  WHERE al.user_id = auth.uid()
    AND al.status  = 'pending'
  ORDER BY al.requested_at DESC
  LIMIT 1;
END;
$$;

COMMENT ON FUNCTION public.get_account_lifecycle_status IS
  'Returns the current pending lifecycle action for the caller, with days_remaining. '
  'Returns empty set if no pending action exists.';

-- ============================================================================
-- Rollback
-- ============================================================================
-- DROP FUNCTION IF EXISTS public.get_account_lifecycle_status();
-- DROP FUNCTION IF EXISTS public.restore_account();
-- DROP FUNCTION IF EXISTS public.request_account_deletion(text);
-- DROP FUNCTION IF EXISTS public.request_account_deactivation(text);
-- DROP VIEW  IF EXISTS public.active_profiles;
-- DROP TABLE IF EXISTS public.account_lifecycle_audit;
-- DROP TABLE IF EXISTS public.account_lifecycle;
-- DROP TYPE  IF EXISTS public.lifecycle_status;
-- DROP TYPE  IF EXISTS public.lifecycle_action;
