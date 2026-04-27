-- Announcements System
-- Admin posters/announcements with insights and deeplink support

-- Announcements table
CREATE TABLE IF NOT EXISTS public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text,
  image_url text,
  cta_type text CHECK (cta_type IN ('none','url','coach')) DEFAULT 'none',
  cta_value text, -- URL or coach_id depending on cta_type
  start_at timestamptz DEFAULT now(),
  end_at timestamptz,
  is_active boolean DEFAULT true,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- Announcement impressions tracking
CREATE TABLE IF NOT EXISTS public.announcement_impressions (
  id bigserial PRIMARY KEY,
  announcement_id uuid REFERENCES public.announcements(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id),
  seen_at timestamptz DEFAULT now()
);

-- Announcement clicks tracking
CREATE TABLE IF NOT EXISTS public.announcement_clicks (
  id bigserial PRIMARY KEY,
  announcement_id uuid REFERENCES public.announcements(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id),
  clicked_at timestamptz DEFAULT now(),
  target text
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_announcements_active ON public.announcements(is_active, start_at, end_at);
CREATE INDEX IF NOT EXISTS idx_announcements_created_by ON public.announcements(created_by);
CREATE INDEX IF NOT EXISTS idx_announcement_impressions_announcement ON public.announcement_impressions(announcement_id);
CREATE INDEX IF NOT EXISTS idx_announcement_impressions_user ON public.announcement_impressions(user_id);
CREATE INDEX IF NOT EXISTS idx_announcement_clicks_announcement ON public.announcement_clicks(announcement_id);
CREATE INDEX IF NOT EXISTS idx_announcement_clicks_user ON public.announcement_clicks(user_id);

-- Enable RLS
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_impressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_clicks ENABLE ROW LEVEL SECURITY;

-- RLS Policies for announcements
-- Everyone can read active/current announcements
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcements' AND policyname='ann_read_active') THEN
    CREATE POLICY ann_read_active ON public.announcements FOR SELECT
    USING (
      is_active = true
      AND (start_at IS NULL OR start_at <= now())
      AND (end_at IS NULL OR end_at >= now())
    );
  END IF;
END $$;

-- Only admins can insert/update/delete announcements
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcements' AND policyname='ann_admin_write') THEN
    CREATE POLICY ann_admin_write ON public.announcements
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

-- RLS Policies for announcement_impressions
-- Any logged-in user can insert their own impression
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcement_impressions' AND policyname='imp_insert_self') THEN
    CREATE POLICY imp_insert_self ON public.announcement_impressions FOR INSERT
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- Allow admins to select analytics
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcement_impressions' AND policyname='imp_admin_read') THEN
    CREATE POLICY imp_admin_read ON public.announcement_impressions FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;

-- RLS Policies for announcement_clicks
-- Any logged-in user can insert their own click
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcement_clicks' AND policyname='clk_insert_self') THEN
    CREATE POLICY clk_insert_self ON public.announcement_clicks FOR INSERT
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- Allow admins to select analytics
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcement_clicks' AND policyname='clk_admin_read') THEN
    CREATE POLICY clk_admin_read ON public.announcement_clicks FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('admin', 'superadmin')
      )
    );
  END IF;
END $$;
