-- DANGERZONE supplemental — pg_cron schedule + notification flag merge helper
-- Migration: 20260428250001_dangerzone_cron.sql
-- Owner: DANGERZONE
-- Created: 2026-04-28 UTC
--
-- Depends on: 20260428250000_dangerzone_account_lifecycle.sql
--
-- Idempotent: safe to re-apply.

-- ============================================================================
-- RPC: merge_lifecycle_flag
-- Atomically sets a single notification flag without overwriting the rest.
-- The edge function calls this instead of patching the column directly so that
-- parallel runs (however unlikely) cannot race-overwrite each other's flags.
-- SECURITY DEFINER + service-role caller: the cron function runs as the
-- service role which bypasses RLS, but we still use a named function so the
-- call site stays readable.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.merge_lifecycle_flag(
  p_id   uuid,
  p_flag text
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  UPDATE public.account_lifecycle
  SET    notification_flags = notification_flags || jsonb_build_object(p_flag, true)
  WHERE  id     = p_id
    AND  status = 'pending';
$$;

COMMENT ON FUNCTION public.merge_lifecycle_flag IS
  'DANGERZONE (service-role only). Merges a single boolean flag into notification_flags '
  'using the JSONB || operator to avoid overwriting previously set flags.';

-- Revoke from anon/authenticated — only service role should call this.
REVOKE EXECUTE ON FUNCTION public.merge_lifecycle_flag(uuid, text) FROM anon, authenticated;

-- ============================================================================
-- pg_cron: daily lifecycle-purge at 03:00 UTC
--
-- Requires the pg_cron + pg_net extensions to be enabled in the Supabase
-- dashboard (Database → Extensions → pg_cron / pg_net).
--
-- The SUPABASE_URL and SERVICE_ROLE_KEY are passed via GUC settings that
-- Supabase populates at the role level. If your project has not set these
-- custom GUCs, register the cron manually in the Supabase dashboard instead:
--   Cron jobs → + New cron job → "lifecycle-purge" → "0 3 * * *"
--   HTTP → POST → <project-url>/functions/v1/lifecycle-purge
--   Headers: Authorization: Bearer <service-role-key>
-- ============================================================================

DO $$
DECLARE
  v_url     text;
  v_key     text;
BEGIN
  -- Only register if pg_cron and pg_net are available.
  IF NOT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_net'
  ) THEN
    RAISE NOTICE
      'DANGERZONE cron: pg_cron or pg_net not installed. '
      'Register the lifecycle-purge cron job manually in the Supabase dashboard.';
    RETURN;
  END IF;

  -- Guard: skip if already registered.
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'dangerzone-lifecycle-purge'
  ) THEN
    RAISE NOTICE 'DANGERZONE cron: dangerzone-lifecycle-purge already registered, skipping.';
    RETURN;
  END IF;

  v_url := current_setting('app.supabase_url',     true);
  v_key := current_setting('app.supabase_service_role_key', true);

  IF v_url IS NULL OR v_key IS NULL THEN
    RAISE NOTICE
      'DANGERZONE cron: app.supabase_url / app.supabase_service_role_key GUCs not set. '
      'Register the lifecycle-purge cron job manually in the Supabase dashboard.';
    RETURN;
  END IF;

  PERFORM cron.schedule(
    'dangerzone-lifecycle-purge',
    '0 3 * * *',
    format(
      $cron$
      SELECT net.http_post(
        url     := %L,
        headers := '{"Authorization":"Bearer %s","Content-Type":"application/json"}'::jsonb,
        body    := '{}'::jsonb
      )
      $cron$,
      v_url || '/functions/v1/lifecycle-purge',
      v_key
    )
  );

  RAISE NOTICE 'DANGERZONE cron: dangerzone-lifecycle-purge registered (daily 03:00 UTC).';
END;
$$;

-- ============================================================================
-- Rollback
-- ============================================================================
-- SELECT cron.unschedule('dangerzone-lifecycle-purge');
-- DROP FUNCTION IF EXISTS public.merge_lifecycle_flag(uuid, text);
