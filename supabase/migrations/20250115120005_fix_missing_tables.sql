-- Fix Missing Database Tables and Relationships
-- This migration creates missing tables and fixes relationship issues

-- ========================================
-- PROFILES TABLE
-- ========================================
-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  email text,
  role text DEFAULT 'client' CHECK (role IN ('admin', 'coach', 'client')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Index for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS policies for profiles
DO $$
BEGIN
  -- Users can read their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_own') THEN
    CREATE POLICY profiles_select_own ON public.profiles
      FOR SELECT TO authenticated
      USING (id = auth.uid());
  END IF;

  -- Users can update their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_update_own') THEN
    CREATE POLICY profiles_update_own ON public.profiles
      FOR UPDATE TO authenticated
      USING (id = auth.uid())
      WITH CHECK (id = auth.uid());
  END IF;

  -- Users can insert their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_insert_own') THEN
    CREATE POLICY profiles_insert_own ON public.profiles
      FOR INSERT TO authenticated
      WITH CHECK (id = auth.uid());
  END IF;

  -- Coaches can read profiles of their clients
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_clients') THEN
    CREATE POLICY profiles_select_clients ON public.profiles
      FOR SELECT TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.user_coach_links ucl
          WHERE ucl.coach_id = auth.uid() AND ucl.client_id = profiles.id
        )
      );
  END IF;

  -- Admins can read all profiles
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_admin') THEN
    CREATE POLICY profiles_select_admin ON public.profiles
      FOR SELECT TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid() AND p.role = 'admin'
        )
      );
  END IF;
END $$;

-- ========================================
-- COACH_CLIENTS TABLE (ALIAS FOR USER_COACH_LINKS)
-- ========================================
-- Create a view that aliases user_coach_links as coach_clients for backward compatibility
CREATE OR REPLACE VIEW public.coach_clients AS
SELECT 
  client_id,
  coach_id,
  created_at
FROM public.user_coach_links;

-- Grant permissions on the view
GRANT SELECT ON public.coach_clients TO authenticated;

-- ========================================
-- CALENDAR_EVENTS TABLE
-- ========================================
-- Create calendar_events table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  visibility text DEFAULT 'private' CHECK (visibility IN ('private', 'public')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for calendar_events
CREATE INDEX IF NOT EXISTS idx_calendar_events_created_by ON public.calendar_events(created_by);
CREATE INDEX IF NOT EXISTS idx_calendar_events_coach_id ON public.calendar_events(coach_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_client_id ON public.calendar_events(client_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_at ON public.calendar_events(start_at);

-- Enable RLS on calendar_events
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- RLS policies for calendar_events
DO $$
BEGIN
  -- Users can read their own events
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'calendar_events_select_own') THEN
    CREATE POLICY calendar_events_select_own ON public.calendar_events
      FOR SELECT TO authenticated
      USING (created_by = auth.uid() OR client_id = auth.uid());
  END IF;

  -- Coaches can read events for their clients
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'calendar_events_select_coach') THEN
    CREATE POLICY calendar_events_select_coach ON public.calendar_events
      FOR SELECT TO authenticated
      USING (
        coach_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.user_coach_links ucl
          WHERE ucl.coach_id = auth.uid() AND ucl.client_id = calendar_events.client_id
        )
      );
  END IF;

  -- Users can insert their own events
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'calendar_events_insert_own') THEN
    CREATE POLICY calendar_events_insert_own ON public.calendar_events
      FOR INSERT TO authenticated
      WITH CHECK (created_by = auth.uid());
  END IF;

  -- Users can update their own events
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'calendar_events_update_own') THEN
    CREATE POLICY calendar_events_update_own ON public.calendar_events
      FOR UPDATE TO authenticated
      USING (created_by = auth.uid())
      WITH CHECK (created_by = auth.uid());
  END IF;

  -- Users can delete their own events
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'calendar_events_delete_own') THEN
    CREATE POLICY calendar_events_delete_own ON public.calendar_events
      FOR DELETE TO authenticated
      USING (created_by = auth.uid());
  END IF;
END $$;

-- ========================================
-- FIX CHECKINS TABLE RELATIONSHIPS
-- ========================================
-- The checkins table already exists, but we need to ensure it has proper relationships
-- Add any missing columns to checkins table
ALTER TABLE public.checkins 
ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- ========================================
-- TRIGGERS FOR UPDATED_AT
-- ========================================
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
DO $$
BEGIN
  -- profiles
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'profiles_updated_at') THEN
    CREATE TRIGGER profiles_updated_at
      BEFORE UPDATE ON public.profiles
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- calendar_events
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'calendar_events_updated_at') THEN
    CREATE TRIGGER calendar_events_updated_at
      BEFORE UPDATE ON public.calendar_events
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- checkins
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'checkins_updated_at') THEN
    CREATE TRIGGER checkins_updated_at
      BEFORE UPDATE ON public.checkins
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- ========================================
-- COMPLETION MESSAGE
-- ========================================
SELECT 'Missing database tables and relationships fixed successfully' as status;
