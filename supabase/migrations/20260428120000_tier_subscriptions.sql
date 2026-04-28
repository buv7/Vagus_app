-- TIER — subscriptions table + server-authoritative tier resolver
-- Migration owner: TIER agent (agent/tier-v2)
-- Created: 2026-04-28 12:00 UTC
--
-- Purpose
--   Single subscription record per coach user. Tier defaults to 'free' when
--   absent. The `get_user_tier` RPC is the server's source of truth — client
--   code must never derive the tier from purchase receipts alone.
--
--   receipt_data MUST be encrypted via vault_encrypt_text() before insert;
--   the column stores only the opaque ciphertext (bytea).
--
-- RLS
--   Users can SELECT their own row. INSERT/UPDATE/DELETE is reserved for the
--   service-role (IAP webhook Edge Functions and admin_grant path). This is
--   intentional: clients cannot self-promote their tier.
--
-- Depends on: 20260427211500_vault_audit_table.sql (pgcrypto, vault_encrypt_text)
--
-- Idempotent: safe to re-apply.
-- Rollback: see bottom of file.

-- ============================================================================
-- Enums
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_tier') THEN
    CREATE TYPE subscription_tier AS ENUM ('free', 'pro', 'ultimate');
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_status') THEN
    CREATE TYPE subscription_status AS ENUM ('active', 'trial', 'past_due', 'canceled');
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_store') THEN
    CREATE TYPE subscription_store AS ENUM ('apple', 'google', 'admin_grant');
  END IF;
END$$;

-- ============================================================================
-- subscriptions
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id                  uuid             PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid             NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tier                subscription_tier  NOT NULL DEFAULT 'free',
  status              subscription_status NOT NULL DEFAULT 'active',
  current_period_end  timestamptz      NULL,
  store               subscription_store NOT NULL DEFAULT 'admin_grant',

  -- Encrypted via vault_encrypt_text(). Never store the raw receipt string.
  -- Decrypt only in a trusted context using vault_decrypt_text().
  receipt_data        bytea            NULL,

  created_at          timestamptz      NOT NULL DEFAULT now(),
  updated_at          timestamptz      NOT NULL DEFAULT now(),

  -- One active subscription row per user. IAP webhooks UPSERT on this key.
  CONSTRAINT subscriptions_user_id_unique UNIQUE (user_id)
);

COMMENT ON TABLE public.subscriptions IS
  'TIER-owned. One row per coach user. Tier defaults to free when absent. '
  'INSERT/UPDATE is performed by IAP Edge Functions (service-role only). '
  'receipt_data must be encrypted via vault_encrypt_text() before insert.';

-- Backfill column for pre-existing tables: CREATE TABLE IF NOT EXISTS skips
-- all column definitions when the table already exists, so we add explicitly.
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS receipt_data bytea NULL;

COMMENT ON COLUMN public.subscriptions.receipt_data IS
  'Encrypted via vault_encrypt_text(). NEVER store the raw App Store / Play '
  'receipt string. Decrypt with vault_decrypt_text() in a trusted context.';

-- Indexes
CREATE INDEX IF NOT EXISTS subscriptions_user_id_idx
  ON public.subscriptions (user_id);

CREATE INDEX IF NOT EXISTS subscriptions_status_idx
  ON public.subscriptions (status);

-- ============================================================================
-- updated_at trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can read their own subscription row.
DROP POLICY IF EXISTS subscriptions_select_self ON public.subscriptions;
CREATE POLICY subscriptions_select_self
  ON public.subscriptions
  FOR SELECT
  USING (user_id = auth.uid());

-- No INSERT / UPDATE / DELETE policy for authenticated role.
-- Only the service-role key (bypasses RLS) may write — used by:
--   • IAP-APPLE webhook Edge Function (apple store receipts)
--   • IAP-GOOGLE webhook Edge Function (google play purchase tokens)
--   • Admin grant path (superadmin panel)

-- ============================================================================
-- Server-authoritative tier resolver
-- ============================================================================
--
-- get_user_tier(p_user_id) returns the canonical tier string for any user.
-- Returns 'free' if:
--   • no row exists in subscriptions for this user
--   • status is 'canceled' or 'past_due'
--   • current_period_end has passed
--
-- SECURITY DEFINER so it can be called by authenticated users without
-- needing SELECT access to other users' rows (reads only the one row for
-- p_user_id, which is still subject to internal logic, not exposed raw).
--
-- Client code must call: await supabase.rpc('get_user_tier', {'p_user_id': uid})
-- Do NOT read the subscriptions table directly from the client.

CREATE OR REPLACE FUNCTION public.get_user_tier(p_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tier text;
BEGIN
  SELECT tier::text INTO v_tier
  FROM public.subscriptions
  WHERE user_id = p_user_id
    AND status IN ('active', 'trial')
    AND (current_period_end IS NULL OR current_period_end > now())
  LIMIT 1;

  RETURN COALESCE(v_tier, 'free');
END;
$$;

COMMENT ON FUNCTION public.get_user_tier IS
  'TIER-owned. Server-authoritative tier resolution. Always returns a valid '
  'tier string (free / pro / ultimate). Returns free when no active '
  'subscription exists. Called by TierService.dart via Supabase RPC.';

-- ============================================================================
-- Rollback
-- ============================================================================
--
-- DROP TRIGGER IF EXISTS subscriptions_updated_at ON public.subscriptions;
-- DROP FUNCTION IF EXISTS public.get_user_tier(uuid);
-- DROP FUNCTION IF EXISTS public.set_updated_at();
-- DROP TABLE  IF EXISTS public.subscriptions;
-- DROP TYPE   IF EXISTS subscription_store;
-- DROP TYPE   IF EXISTS subscription_status;
-- DROP TYPE   IF EXISTS subscription_tier;
-- (vault_encrypt_text / pgcrypto left in place — owned by VAULT migration.)
