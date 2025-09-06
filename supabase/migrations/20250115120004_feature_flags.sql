-- User Feature Flags System
-- Per-user feature toggles for insider features

CREATE TABLE IF NOT EXISTS public.user_feature_flags (
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, feature_key)
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_user_feature_flags_user ON public.user_feature_flags(user_id);
CREATE INDEX IF NOT EXISTS idx_user_feature_flags_key ON public.user_feature_flags(feature_key);

-- Enable RLS
ALTER TABLE public.user_feature_flags ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can read/write their own feature flags
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_feature_flags' AND policyname='uff_rw_self') THEN
    CREATE POLICY uff_rw_self ON public.user_feature_flags
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;
