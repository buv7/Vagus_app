-- SHEETIFY — Bidirectional Google Sheets sync
-- Migration owner: SHEETIFY agent
-- Created: 2026-04-28
--
-- Tables
--   coach_google_credentials  encrypted OAuth tokens per coach
--   client_sheets             Google Sheet ID per coach+client pair
--   sheets_sync_queue         offline-safe outbound sync queue (DRIFTKIT integration deferred)
--   sheets_sync_conflicts     rows where sheet diverges from app (coach reviews manually)
--
-- Encryption
--   OAuth tokens are encrypted in the edge function (AES-256-GCM, key = SHEETIFY_ENCRYPT_KEY
--   edge secret) before storage. vault_encrypt_text is NOT used here because app.vault_data_key
--   GUC is not settable on managed Supabase (see decisions.md). Swap to vault_encrypt_text when
--   VAULT ships the vault.decrypted_secrets refactor.
--
-- Idempotent: safe to re-apply.

-- ============================================================================
-- coach_google_credentials
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.coach_google_credentials (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id            uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  google_email        text        NOT NULL,
  refresh_token_enc   text        NOT NULL,   -- AES-256-GCM base64(iv || ciphertext)
  access_token_enc    text,                   -- cached, nullable
  token_expires_at    timestamptz,
  connected_at        timestamptz NOT NULL DEFAULT now(),
  revoked_at          timestamptz,            -- null = active connection
  UNIQUE (coach_id)
);

COMMENT ON TABLE public.coach_google_credentials IS
  'SHEETIFY-owned. One row per coach. Stores encrypted Google OAuth tokens. '
  'Never expose refresh_token_enc or access_token_enc to the Dart client.';

CREATE INDEX IF NOT EXISTS coach_google_credentials_coach_idx
  ON public.coach_google_credentials (coach_id);

ALTER TABLE public.coach_google_credentials ENABLE ROW LEVEL SECURITY;

-- Coach can read their own row (to know if they are connected).
-- No direct SELECT of token columns — that is intentional (edge function uses service role).
DROP POLICY IF EXISTS coach_google_credentials_read_self ON public.coach_google_credentials;
CREATE POLICY coach_google_credentials_read_self
  ON public.coach_google_credentials
  FOR SELECT
  USING (coach_id = auth.uid());

-- INSERT / UPDATE / DELETE only via service role (edge function). RLS blocks direct writes.
-- vault-rls-exempt: coach_google_credentials reason: write path is service-role only (edge fn)

-- ============================================================================
-- client_sheets
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.client_sheets (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id         uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id        uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sheet_id         text        NOT NULL,   -- Google Spreadsheet ID
  sheet_url        text        NOT NULL,
  last_synced_at   timestamptz,
  last_revision_id text,                  -- Drive file version for cheap change detection
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (coach_id, client_id)
);

COMMENT ON TABLE public.client_sheets IS
  'SHEETIFY-owned. One row per coach+client pair. '
  'sheet_id is the Google Spreadsheet ID created in coach Drive.';

CREATE INDEX IF NOT EXISTS client_sheets_coach_idx
  ON public.client_sheets (coach_id);

CREATE INDEX IF NOT EXISTS client_sheets_client_idx
  ON public.client_sheets (client_id);

ALTER TABLE public.client_sheets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS client_sheets_coach_select ON public.client_sheets;
CREATE POLICY client_sheets_coach_select
  ON public.client_sheets
  FOR SELECT
  USING (coach_id = auth.uid());

DROP POLICY IF EXISTS client_sheets_coach_insert ON public.client_sheets;
CREATE POLICY client_sheets_coach_insert
  ON public.client_sheets
  FOR INSERT
  WITH CHECK (coach_id = auth.uid());

DROP POLICY IF EXISTS client_sheets_coach_update ON public.client_sheets;
CREATE POLICY client_sheets_coach_update
  ON public.client_sheets
  FOR UPDATE
  USING (coach_id = auth.uid())
  WITH CHECK (coach_id = auth.uid());

DROP POLICY IF EXISTS client_sheets_coach_delete ON public.client_sheets;
CREATE POLICY client_sheets_coach_delete
  ON public.client_sheets
  FOR DELETE
  USING (coach_id = auth.uid());

-- ============================================================================
-- sheets_sync_queue  (lightweight offline queue; DRIFTKIT integration deferred)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.sheets_sync_queue (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sheet_id     text        NOT NULL,
  tab          text        NOT NULL CHECK (tab IN ('check_ins', 'workout', 'nutrition')),
  payload      jsonb       NOT NULL DEFAULT '[]'::jsonb,
  status       text        NOT NULL DEFAULT 'queued'
                           CHECK (status IN ('queued', 'processing', 'done', 'failed')),
  retry_count  int         NOT NULL DEFAULT 0,
  error_msg    text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz
);

COMMENT ON TABLE public.sheets_sync_queue IS
  'SHEETIFY-owned. Outbound sync queue: rows are written here when the app saves data '
  'and the edge function drains them to Google Sheets. '
  'DRIFTKIT integration is deferred — see .oxbar/decisions.md.';

CREATE INDEX IF NOT EXISTS sheets_sync_queue_coach_status_idx
  ON public.sheets_sync_queue (coach_id, status, created_at);

ALTER TABLE public.sheets_sync_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sheets_sync_queue_coach ON public.sheets_sync_queue;
CREATE POLICY sheets_sync_queue_coach
  ON public.sheets_sync_queue
  FOR ALL
  USING (coach_id = auth.uid())
  WITH CHECK (coach_id = auth.uid());

-- ============================================================================
-- sheets_sync_conflicts
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.sheets_sync_conflicts (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sheet_id     text        NOT NULL,
  tab          text        NOT NULL CHECK (tab IN ('check_ins', 'workout', 'nutrition')),
  row_id       text,               -- Supabase row UUID (null if row only exists in sheet)
  local_value  jsonb       NOT NULL,
  sheet_value  jsonb       NOT NULL,
  detected_at  timestamptz NOT NULL DEFAULT now(),
  resolved_at  timestamptz,        -- null = awaiting coach review
  resolution   text        CHECK (resolution IN ('keep_app', 'keep_sheet', 'dismissed'))
);

COMMENT ON TABLE public.sheets_sync_conflicts IS
  'SHEETIFY-owned. Rows where sheet content diverges from app data. '
  'App is source of truth — conflicts are flagged for coach review, never auto-resolved.';

CREATE INDEX IF NOT EXISTS sheets_sync_conflicts_coach_idx
  ON public.sheets_sync_conflicts (coach_id, resolved_at NULLS FIRST, detected_at DESC);

ALTER TABLE public.sheets_sync_conflicts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sheets_sync_conflicts_coach ON public.sheets_sync_conflicts;
CREATE POLICY sheets_sync_conflicts_coach
  ON public.sheets_sync_conflicts
  FOR ALL
  USING (coach_id = auth.uid())
  WITH CHECK (coach_id = auth.uid());

-- ============================================================================
-- Rollback
-- ============================================================================
--
-- DROP TABLE IF EXISTS public.sheets_sync_conflicts;
-- DROP TABLE IF EXISTS public.sheets_sync_queue;
-- DROP TABLE IF EXISTS public.client_sheets;
-- DROP TABLE IF EXISTS public.coach_google_credentials;
