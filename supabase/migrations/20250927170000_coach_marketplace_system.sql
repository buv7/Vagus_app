-- Coach Marketplace System
-- Adds username support, QR tokens, and marketplace functionality

-- Add username field to profiles table
DO $$
BEGIN
  -- Add username column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'username' AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN username TEXT UNIQUE;
    CREATE INDEX idx_profiles_username ON public.profiles(username);
  END IF;
END $$;

-- QR Tokens table for secure coach sharing
CREATE TABLE IF NOT EXISTS public.qr_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now(),
  used_count INTEGER DEFAULT 0
);

-- Index for QR token lookups
CREATE INDEX IF NOT EXISTS idx_qr_tokens_token ON public.qr_tokens(token);
CREATE INDEX IF NOT EXISTS idx_qr_tokens_coach ON public.qr_tokens(coach_id);
CREATE INDEX IF NOT EXISTS idx_qr_tokens_expires ON public.qr_tokens(expires_at);

-- Enable RLS on QR tokens
ALTER TABLE public.qr_tokens ENABLE ROW LEVEL SECURITY;

-- RLS policies for QR tokens
DO $$
BEGIN
  -- Coaches can read/write their own QR tokens
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'qr_tokens_own') THEN
    CREATE POLICY qr_tokens_own ON public.qr_tokens
      FOR ALL TO authenticated
      USING (coach_id = auth.uid())
      WITH CHECK (coach_id = auth.uid());
  END IF;

  -- Anyone can read valid QR tokens (for scanning)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'qr_tokens_scan') THEN
    CREATE POLICY qr_tokens_scan ON public.qr_tokens
      FOR SELECT TO authenticated
      USING (expires_at IS NULL OR expires_at > now());
  END IF;
END $$;

-- Function to generate QR token
CREATE OR REPLACE FUNCTION generate_qr_token(
  p_coach_id uuid,
  p_expires_hours integer DEFAULT 24
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_token TEXT;
  v_expires_at timestamptz;
BEGIN
  -- Generate a secure random token
  v_token := encode(gen_random_bytes(32), 'base64url');
  
  -- Set expiry if specified
  IF p_expires_hours > 0 THEN
    v_expires_at := now() + (p_expires_hours || ' hours')::interval;
  END IF;
  
  -- Insert the token
  INSERT INTO public.qr_tokens (coach_id, token, expires_at)
  VALUES (p_coach_id, v_token, v_expires_at);
  
  RETURN v_token;
END;
$$;

-- Function to resolve QR token to coach
CREATE OR REPLACE FUNCTION resolve_qr_token(p_token TEXT)
RETURNS TABLE (
  coach_id uuid,
  username TEXT,
  name TEXT,
  expires_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update usage count and return coach info
  UPDATE public.qr_tokens 
  SET used_count = used_count + 1 
  WHERE token = p_token;
  
  RETURN QUERY
  SELECT 
    p.id as coach_id,
    p.username,
    p.name,
    qt.expires_at
  FROM public.qr_tokens qt
  JOIN public.profiles p ON p.id = qt.coach_id
  WHERE qt.token = p_token
    AND (qt.expires_at IS NULL OR qt.expires_at > now());
END;
$$;

-- Add username validation function
CREATE OR REPLACE FUNCTION validate_username(p_username TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  -- Username must be 3-20 characters, alphanumeric + underscore, start with letter
  RETURN p_username ~ '^[a-zA-Z][a-zA-Z0-9_]{2,19}$';
END;
$$;

-- Add trigger to validate username format
CREATE OR REPLACE FUNCTION check_username_format()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.username IS NOT NULL AND NOT validate_username(NEW.username) THEN
    RAISE EXCEPTION 'Username must be 3-20 characters, start with a letter, and contain only letters, numbers, and underscores';
  END IF;
  RETURN NEW;
END;
$$;

-- Create trigger if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'username_format_check') THEN
    CREATE TRIGGER username_format_check
      BEFORE INSERT OR UPDATE ON public.profiles
      FOR EACH ROW
      EXECUTE FUNCTION check_username_format();
  END IF;
END $$;

-- Update existing RLS policies to include username in coach search
DO $$
BEGIN
  -- Allow searching coaches by username
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_search_coaches') THEN
    CREATE POLICY profiles_search_coaches ON public.profiles
      FOR SELECT TO authenticated
      USING (role = 'coach' AND username IS NOT NULL);
  END IF;
END $$;
