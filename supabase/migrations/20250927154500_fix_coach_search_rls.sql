-- Fix RLS policy to allow clients to search for coaches
-- This migration adds a policy that allows all authenticated users to see coach profiles

-- Add policy to allow clients to see coach profiles for search purposes
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_coaches') THEN
    CREATE POLICY profiles_select_coaches ON public.profiles
      FOR SELECT TO authenticated
      USING (role = 'coach');
  END IF;
END $$;

-- Verify the policy was created
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_coaches') THEN
    RAISE NOTICE 'Successfully created profiles_select_coaches policy';
  ELSE
    RAISE WARNING 'Failed to create profiles_select_coaches policy';
  END IF;
END $$;
