-- VAULT — data_access_audit table + medical-data crypto helpers
-- Migration owner: VAULT (security agent)
-- Created: 2026-04-27 21:15 UTC
--
-- Purpose
--   Every read of medical-grade data (lab work, period tracking, wearable
--   signals, future medical_other) MUST insert an audit row. This is the
--   forensic record that lets a user (and the platform) answer the question
--   "who has read my data, and when?".
--
--   This migration also enables pgcrypto so column-level encryption is
--   available to LABKIT and PERIODS-FORGE for the raw biomarker / cycle data.
--   The actual encrypted columns live in their respective domain migrations.
--
-- Idempotent: safe to re-apply.
-- Rollback: see the bottom of this file.

-- ============================================================================
-- Extensions
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- Enums
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'vault_data_class') THEN
    CREATE TYPE vault_data_class AS ENUM (
      'lab_work',
      'period_tracking',
      'wearable',
      'medical_other'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'vault_access_action') THEN
    CREATE TYPE vault_access_action AS ENUM (
      'read',
      'write',
      'export',
      'share'
    );
  END IF;
END$$;

-- ============================================================================
-- data_access_audit
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.data_access_audit (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  accessor_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  accessed_user_id  uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data_class        vault_data_class    NOT NULL,
  action            vault_access_action NOT NULL DEFAULT 'read',
  resource_table    text        NOT NULL,
  resource_id       uuid        NULL,
  justification     text        NULL,
  source_ip         inet        NULL,
  client_info       jsonb       NOT NULL DEFAULT '{}'::jsonb,
  accessed_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.data_access_audit IS
  'VAULT-owned. Forensic audit log of every read/write of medical-grade data. '
  'Append-only — no UPDATE or DELETE policy. Rows survive the lifetime of the '
  'subject user (cascade on user delete is intentional under GDPR right-to-erasure).';

-- Indexes for the two common read patterns.
-- "Show me everyone who has accessed my data, newest first":
CREATE INDEX IF NOT EXISTS data_access_audit_subject_idx
  ON public.data_access_audit (accessed_user_id, accessed_at DESC);

-- "What has this coach/admin accessed lately" (forensic / abuse detection):
CREATE INDEX IF NOT EXISTS data_access_audit_actor_idx
  ON public.data_access_audit (accessor_id, accessed_at DESC);

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.data_access_audit ENABLE ROW LEVEL SECURITY;

-- SELECT: the data subject can always see who's accessed their data.
-- Admins (profiles.role = 'admin') can see everything.
DROP POLICY IF EXISTS data_access_audit_select_self ON public.data_access_audit;
CREATE POLICY data_access_audit_select_self
  ON public.data_access_audit
  FOR SELECT
  USING (
    accessed_user_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );

-- INSERT: any authenticated user can write a row, BUT only with themselves
-- as the accessor_id. This prevents one user from forging audit entries
-- attributed to someone else. Server-side helpers should call this with the
-- caller's auth context.
DROP POLICY IF EXISTS data_access_audit_insert_self ON public.data_access_audit;
CREATE POLICY data_access_audit_insert_self
  ON public.data_access_audit
  FOR INSERT
  WITH CHECK (accessor_id = auth.uid());

-- UPDATE / DELETE: nobody. Audit logs are immutable.
-- (No CREATE POLICY for UPDATE or DELETE means RLS denies them by default.)

-- ============================================================================
-- Helper function for callers
-- ============================================================================
--
-- `vault_audit_access` — the canonical way for application code (Dart side
-- via Supabase RPC, or server-side functions) to record an access event.
-- Using a SECURITY INVOKER function rather than direct INSERT keeps the API
-- shape stable even if the audit table evolves.

CREATE OR REPLACE FUNCTION public.vault_audit_access(
  p_accessed_user_id uuid,
  p_data_class       vault_data_class,
  p_action           vault_access_action DEFAULT 'read',
  p_resource_table   text                DEFAULT NULL,
  p_resource_id      uuid                DEFAULT NULL,
  p_justification    text                DEFAULT NULL,
  p_client_info      jsonb               DEFAULT '{}'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'vault_audit_access: caller is not authenticated';
  END IF;

  INSERT INTO public.data_access_audit (
    accessor_id,
    accessed_user_id,
    data_class,
    action,
    resource_table,
    resource_id,
    justification,
    client_info
  ) VALUES (
    auth.uid(),
    p_accessed_user_id,
    p_data_class,
    p_action,
    COALESCE(p_resource_table, ''),
    p_resource_id,
    p_justification,
    COALESCE(p_client_info, '{}'::jsonb)
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

COMMENT ON FUNCTION public.vault_audit_access IS
  'Canonical entry point for recording medical-data access. Always use this '
  'instead of direct INSERTs — the table shape may evolve.';

-- ============================================================================
-- Column-encryption helpers (for LABKIT / PERIODS-FORGE / WEARABLE-HUB)
-- ============================================================================
--
-- These wrap pgp_sym_encrypt / pgp_sym_decrypt so the call sites in domain
-- migrations stay short and consistent. The encryption KEY is read from a
-- per-environment GUC `app.vault_data_key` set at the role level for the
-- backend role (Supabase Vault → custom config). Never embed the key in
-- migration text.
--
-- Key rotation procedure lives in SECURITY.md.

CREATE OR REPLACE FUNCTION public.vault_encrypt_text(p_plaintext text)
RETURNS bytea
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_key text := current_setting('app.vault_data_key', true);
BEGIN
  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'vault_encrypt_text: app.vault_data_key is not set';
  END IF;
  IF p_plaintext IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN pgp_sym_encrypt(p_plaintext, v_key);
END;
$$;

CREATE OR REPLACE FUNCTION public.vault_decrypt_text(p_ciphertext bytea)
RETURNS text
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_key text := current_setting('app.vault_data_key', true);
BEGIN
  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'vault_decrypt_text: app.vault_data_key is not set';
  END IF;
  IF p_ciphertext IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN pgp_sym_decrypt(p_ciphertext, v_key);
END;
$$;

COMMENT ON FUNCTION public.vault_encrypt_text IS
  'Symmetric encryption for medical-grade text columns. Reads the key from '
  'GUC app.vault_data_key. LABKIT, PERIODS-FORGE, WEARABLE-HUB use this for '
  'biomarker values, cycle data, and raw wearable readings.';

-- ============================================================================
-- Rollback
-- ============================================================================
--
-- DROP FUNCTION IF EXISTS public.vault_decrypt_text(bytea);
-- DROP FUNCTION IF EXISTS public.vault_encrypt_text(text);
-- DROP FUNCTION IF EXISTS public.vault_audit_access(uuid, vault_data_class, vault_access_action, text, uuid, text, jsonb);
-- DROP TABLE IF EXISTS public.data_access_audit;
-- DROP TYPE  IF EXISTS vault_access_action;
-- DROP TYPE  IF EXISTS vault_data_class;
-- (pgcrypto is left enabled — other migrations depend on it.)
