-- BRAIN — ai_quota_usage: per-provider daily quota tracking
-- Ensures concurrent app instances do not exceed API daily limits.
-- Owned by: BRAIN (AI tier-router agent)
-- Created: 2026-04-28 UTC
--
-- THRIFT (cache agent) will read this table to decide whether a cached
-- response should be returned proactively.
--
-- Idempotent: safe to re-apply.
-- Rollback: see the bottom of this file.

-- ============================================================================
-- Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ai_quota_usage (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  provider      text        NOT NULL,
  usage_date    date        NOT NULL DEFAULT CURRENT_DATE,
  tokens_used   bigint      NOT NULL DEFAULT 0,
  request_count int         NOT NULL DEFAULT 0,
  updated_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT ai_quota_usage_provider_date UNIQUE (provider, usage_date)
);

COMMENT ON TABLE public.ai_quota_usage IS
  'BRAIN-owned. Tracks daily token and request counts per AI provider '
  '(cerebras, groq, gemini, openrouter). Written only via brain_upsert_quota() '
  'to ensure atomic increments across concurrent Flutter instances.';

CREATE INDEX IF NOT EXISTS ai_quota_usage_provider_date_idx
  ON public.ai_quota_usage (provider, usage_date DESC);

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.ai_quota_usage ENABLE ROW LEVEL SECURITY;

-- Any authenticated client can read quota stats (not sensitive — just counts).
DROP POLICY IF EXISTS ai_quota_usage_select_any ON public.ai_quota_usage;
CREATE POLICY ai_quota_usage_select_any
  ON public.ai_quota_usage
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- INSERT / UPDATE are done exclusively through brain_upsert_quota() SECURITY
-- DEFINER below. No direct-write policy is needed (and intentionally omitted).

-- ============================================================================
-- Atomic upsert function
-- ============================================================================
-- SECURITY DEFINER so the Flutter client (authenticated role) can write without
-- needing a direct INSERT/UPDATE policy on the table.

CREATE OR REPLACE FUNCTION public.brain_upsert_quota(
  p_provider  text,
  p_date      date,
  p_tokens    bigint DEFAULT 0,
  p_requests  int    DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.ai_quota_usage (provider, usage_date, tokens_used, request_count, updated_at)
  VALUES (p_provider, p_date, p_tokens, p_requests, now())
  ON CONFLICT (provider, usage_date) DO UPDATE
    SET tokens_used   = ai_quota_usage.tokens_used   + EXCLUDED.tokens_used,
        request_count = ai_quota_usage.request_count + EXCLUDED.request_count,
        updated_at    = now();
END;
$$;

COMMENT ON FUNCTION public.brain_upsert_quota IS
  'Atomic upsert for AI provider quota tracking. SECURITY DEFINER — clients '
  'must use this function; direct table writes are blocked by RLS.';

-- Grant EXECUTE to authenticated and anon so the Flutter Supabase client can
-- call this RPC regardless of auth state.
GRANT EXECUTE ON FUNCTION public.brain_upsert_quota TO authenticated, anon;

-- ============================================================================
-- Rollback
-- ============================================================================
-- REVOKE EXECUTE ON FUNCTION public.brain_upsert_quota FROM authenticated, anon;
-- DROP FUNCTION IF EXISTS public.brain_upsert_quota(text, date, bigint, int);
-- DROP TABLE  IF EXISTS public.ai_quota_usage;
