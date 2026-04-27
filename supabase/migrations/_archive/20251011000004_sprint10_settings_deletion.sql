-- Sprint 10: Settings, Themes, i18n, Data Export, Account Deletion
-- User preferences and account deletion workflow

-- 1. Create user_settings table
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  theme TEXT DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
  language TEXT DEFAULT 'en' CHECK (language IN ('en', 'ar', 'ku')),
  reminder_quiet_hours JSONB DEFAULT '{"start":"22:00","end":"08:00"}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::JSONB
);

-- Create index only if language column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_settings' AND column_name = 'language'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_user_settings_language ON public.user_settings(language);
  END IF;
END$$;

-- 2. Create delete_requests table
CREATE TABLE IF NOT EXISTS public.delete_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'done', 'rejected')),
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  processed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_delete_requests_user ON public.delete_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_delete_requests_status ON public.delete_requests(status) WHERE status = 'pending';

-- 3. Create data_exports table to track export requests
CREATE TABLE IF NOT EXISTS public.data_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'ready', 'expired', 'failed')),
  export_url TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_data_exports_user ON public.data_exports(user_id);
CREATE INDEX IF NOT EXISTS idx_data_exports_status ON public.data_exports(status);

-- 4. Enable RLS
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delete_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_exports ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for user_settings
DROP POLICY IF EXISTS "owner_crud_settings" ON public.user_settings;
CREATE POLICY "owner_crud_settings" ON public.user_settings
  FOR ALL 
  TO authenticated
  USING (auth.uid() = user_id) 
  WITH CHECK (auth.uid() = user_id);

-- 6. RLS Policies for delete_requests
DROP POLICY IF EXISTS "owner_crud_delete_req" ON public.delete_requests;
CREATE POLICY "owner_crud_delete_req" ON public.delete_requests
  FOR ALL 
  TO authenticated
  USING (auth.uid() = user_id) 
  WITH CHECK (auth.uid() = user_id);

-- Admin can view all delete requests
DROP POLICY IF EXISTS "admin_view_delete_requests" ON public.delete_requests;
CREATE POLICY "admin_view_delete_requests" ON public.delete_requests
  FOR SELECT 
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 7. RLS Policies for data_exports
DROP POLICY IF EXISTS "owner_view_exports" ON public.data_exports;
CREATE POLICY "owner_view_exports" ON public.data_exports
  FOR SELECT 
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "owner_create_exports" ON public.data_exports;
CREATE POLICY "owner_create_exports" ON public.data_exports
  FOR INSERT 
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Service role can manage exports
DROP POLICY IF EXISTS "service_role_manage_exports" ON public.data_exports;
CREATE POLICY "service_role_manage_exports" ON public.data_exports
  FOR ALL 
  TO service_role
  USING (true) 
  WITH CHECK (true);

-- 8. Function to get or create user settings
CREATE OR REPLACE FUNCTION public.get_or_create_user_settings(p_user_id UUID)
RETURNS public.user_settings
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_settings public.user_settings;
BEGIN
  SELECT * INTO v_settings
  FROM public.user_settings
  WHERE user_id = p_user_id;
  
  IF v_settings IS NULL THEN
    INSERT INTO public.user_settings (user_id)
    VALUES (p_user_id)
    RETURNING * INTO v_settings;
  END IF;
  
  RETURN v_settings;
END;
$$;

-- 9. Trigger to update user_settings timestamp
CREATE OR REPLACE FUNCTION public.update_user_settings_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_user_settings_timestamp ON public.user_settings;
CREATE TRIGGER trigger_update_user_settings_timestamp
BEFORE UPDATE ON public.user_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_user_settings_timestamp();

-- 10. Function to initiate account deletion (soft delete)
CREATE OR REPLACE FUNCTION public.request_account_deletion(
  p_user_id UUID,
  p_reason TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_request_id UUID;
BEGIN
  -- Only allow users to delete their own account
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Can only delete own account';
  END IF;
  
  -- Check if there's already a pending request
  SELECT id INTO v_request_id
  FROM public.delete_requests
  WHERE user_id = p_user_id
  AND status = 'pending'
  LIMIT 1;
  
  IF v_request_id IS NOT NULL THEN
    RETURN v_request_id;
  END IF;
  
  -- Create new delete request
  INSERT INTO public.delete_requests (user_id, reason, status)
  VALUES (p_user_id, p_reason, 'pending')
  RETURNING id INTO v_request_id;
  
  RETURN v_request_id;
END;
$$;

-- 11. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.user_settings TO authenticated;
GRANT ALL ON public.delete_requests TO authenticated;
GRANT SELECT, INSERT ON public.data_exports TO authenticated;

-- 12. Comments
COMMENT ON TABLE public.user_settings IS 'User preferences for theme, language, and reminders';
COMMENT ON TABLE public.delete_requests IS 'User account deletion requests (72h processing)';
COMMENT ON TABLE public.data_exports IS 'User data export requests and download links';
COMMENT ON FUNCTION public.get_or_create_user_settings IS 'Returns existing settings or creates default settings for user';
COMMENT ON FUNCTION public.request_account_deletion IS 'Initiates account deletion request with 72h grace period';

