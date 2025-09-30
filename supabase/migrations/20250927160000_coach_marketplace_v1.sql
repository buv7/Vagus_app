-- Coach Marketplace v1: Username system and QR tokens
-- Migration: 20250927160000_coach_marketplace_v1.sql

-- 2.1 Add username column to profiles (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'username'
  ) THEN
    ALTER TABLE profiles ADD COLUMN username TEXT;
  END IF;
END
$$;

-- Create unique index for username (case-insensitive, idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'idx_profiles_username'
  ) THEN
    CREATE UNIQUE INDEX idx_profiles_username ON profiles((lower(username)));
  END IF;
END
$$;

-- 2.2 Create QR tokens table (idempotent)
CREATE TABLE IF NOT EXISTS coach_qr_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token text UNIQUE NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS on coach_qr_tokens
ALTER TABLE coach_qr_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policy: only the coach can create tokens for themselves (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'coach_qr_tokens' AND policyname = 'coach_qr_tokens_insert_self'
  ) THEN
    CREATE POLICY coach_qr_tokens_insert_self ON coach_qr_tokens
    FOR INSERT TO authenticated
    WITH CHECK (coach_id = auth.uid());
  END IF;
END
$$;

-- 2.3 RPC to resolve QR token -> coach public payload (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION resolve_coach_qr_token(_token text)
RETURNS TABLE (coach_id uuid, username text)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT cqt.coach_id, p.username
  FROM coach_qr_tokens cqt
  JOIN profiles p ON p.id = cqt.coach_id
  WHERE cqt.token = _token AND cqt.expires_at > now();
END;
$$;

-- Grant permissions on the function
REVOKE ALL ON FUNCTION resolve_coach_qr_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION resolve_coach_qr_token(text) TO authenticated;

-- Add index on token for performance
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'idx_coach_qr_tokens_token'
  ) THEN
    CREATE INDEX idx_coach_qr_tokens_token ON coach_qr_tokens(token);
  END IF;
END
$$;

-- Add index on expires_at for cleanup
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'idx_coach_qr_tokens_expires_at'
  ) THEN
    CREATE INDEX idx_coach_qr_tokens_expires_at ON coach_qr_tokens(expires_at);
  END IF;
END
$$;