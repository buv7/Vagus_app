-- Coach Portfolio & Media System
-- Coach profiles, intro videos, and private videos/courses with admin moderation

-- Coach profiles table
CREATE TABLE IF NOT EXISTS public.coach_profiles (
  coach_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  headline text,
  bio text,
  specialties text[], -- array of specialty strings
  intro_video_url text, -- 30s "Why choose me?" video
  updated_at timestamptz DEFAULT now()
);

-- Coach media table (videos/courses)
CREATE TABLE IF NOT EXISTS public.coach_media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  media_url text NOT NULL,
  media_type text CHECK (media_type IN ('video','course')) NOT NULL,
  visibility text CHECK (visibility IN ('public','clients_only')) DEFAULT 'clients_only',
  is_approved boolean DEFAULT false, -- admin moderation
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_coach_profiles_coach ON public.coach_profiles(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_media_coach ON public.coach_media(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_media_approved ON public.coach_media(is_approved, visibility);
CREATE INDEX IF NOT EXISTS idx_coach_media_type ON public.coach_media(media_type);

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_coach_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_coach_media_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_coach_profiles_updated_at') THEN
    CREATE TRIGGER trigger_update_coach_profiles_updated_at
      BEFORE UPDATE ON public.coach_profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_coach_profiles_updated_at();
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_coach_media_updated_at') THEN
    CREATE TRIGGER trigger_update_coach_media_updated_at
      BEFORE UPDATE ON public.coach_media
      FOR EACH ROW
      EXECUTE FUNCTION update_coach_media_updated_at();
  END IF;
END $$;

-- Enable RLS
ALTER TABLE public.coach_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_media ENABLE ROW LEVEL SECURITY;

-- RLS Policies for coach_profiles
-- Coach can read/write their own profile
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_profiles' AND policyname='cp_rw_own') THEN
    CREATE POLICY cp_rw_own ON public.coach_profiles
    FOR ALL
    USING (coach_id = auth.uid())
    WITH CHECK (coach_id = auth.uid());
  END IF;
END $$;

-- Everyone can read public coach profiles
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_profiles' AND policyname='cp_read_public') THEN
    CREATE POLICY cp_read_public ON public.coach_profiles FOR SELECT
    USING (true);
  END IF;
END $$;

-- RLS Policies for coach_media
-- Coach can read/write their own media
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_media' AND policyname='cm_rw_own') THEN
    CREATE POLICY cm_rw_own ON public.coach_media
    FOR ALL
    USING (coach_id = auth.uid())
    WITH CHECK (coach_id = auth.uid());
  END IF;
END $$;

-- Everyone can read approved public media
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_media' AND policyname='cm_read_approved_public') THEN
    CREATE POLICY cm_read_approved_public ON public.coach_media FOR SELECT
    USING (is_approved = true AND visibility = 'public');
  END IF;
END $$;

-- Clients can read approved media for their connected coaches
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_media' AND policyname='cm_read_approved_clients') THEN
    CREATE POLICY cm_read_approved_clients ON public.coach_media FOR SELECT
    USING (
      is_approved = true 
      AND visibility = 'clients_only'
      AND EXISTS (
        -- Check if current user is a client connected to this coach
        SELECT 1 FROM public.user_coach_links ucl
        WHERE ucl.client_id = auth.uid()
        AND ucl.coach_id = coach_media.coach_id
      )
    );
  END IF;
END $$;

-- Admins can read all media and approve/reject
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='coach_media' AND policyname='cm_admin_all') THEN
    CREATE POLICY cm_admin_all ON public.coach_media
    FOR ALL
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    )
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;
