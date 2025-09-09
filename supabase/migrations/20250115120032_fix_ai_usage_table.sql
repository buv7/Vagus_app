-- Fix Missing AI Usage Table
-- This migration creates the missing ai_usage table

-- Create ai_usage table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.ai_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature text NOT NULL,
  tokens_used integer DEFAULT 0,
  cost_usd numeric(10,4) DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for ai_usage
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON public.ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_created_at ON public.ai_usage(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_usage_feature ON public.ai_usage(feature);

-- Enable RLS on ai_usage
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for ai_usage
DO $$
BEGIN
  -- Users can read their own AI usage
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'ai_usage_select_own') THEN
    CREATE POLICY ai_usage_select_own ON public.ai_usage
      FOR SELECT TO authenticated
      USING (user_id = auth.uid());
  END IF;

  -- Users can insert their own AI usage
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'ai_usage_insert_own') THEN
    CREATE POLICY ai_usage_insert_own ON public.ai_usage
      FOR INSERT TO authenticated
      WITH CHECK (user_id = auth.uid());
  END IF;

  -- Users can update their own AI usage
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'ai_usage_update_own') THEN
    CREATE POLICY ai_usage_update_own ON public.ai_usage
      FOR UPDATE TO authenticated
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;
