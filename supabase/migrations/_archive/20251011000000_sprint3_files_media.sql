-- Sprint 3: Files & Media 1.0
-- Add tables for file tags, comments, versions, and pinning

-- 1. Add pinning support to user_files
ALTER TABLE IF EXISTS public.user_files
ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;

-- 2. Create file_tags table
CREATE TABLE IF NOT EXISTS public.file_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES public.user_files(id) ON DELETE CASCADE,
  tag TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_file_tags_file_id ON public.file_tags(file_id);
CREATE INDEX IF NOT EXISTS idx_file_tags_tag ON public.file_tags(tag);

-- 3. Create file_comments table
CREATE TABLE IF NOT EXISTS public.file_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES public.user_files(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_file_comments_file_id ON public.file_comments(file_id);
CREATE INDEX IF NOT EXISTS idx_file_comments_author ON public.file_comments(author_id);

-- 4. Create file_versions table
CREATE TABLE IF NOT EXISTS public.file_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES public.user_files(id) ON DELETE CASCADE,
  version_no INTEGER NOT NULL,
  storage_path TEXT NOT NULL,
  file_size BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  UNIQUE(file_id, version_no)
);

CREATE INDEX IF NOT EXISTS idx_file_versions_file_id ON public.file_versions(file_id);
CREATE INDEX IF NOT EXISTS idx_file_versions_created_at ON public.file_versions(created_at);

-- 5. Enable RLS on new tables
ALTER TABLE public.file_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.file_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.file_versions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for file_tags
-- Users can view tags on files they own
DROP POLICY IF EXISTS "Users can view tags on accessible files" ON public.file_tags;
CREATE POLICY "Users can view tags on accessible files"
ON public.file_tags FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_files
    WHERE id = file_tags.file_id
    AND user_id = auth.uid()
  )
);

-- Users can add tags to their own files
DROP POLICY IF EXISTS "Users can add tags to own files" ON public.file_tags;
CREATE POLICY "Users can add tags to own files"
ON public.file_tags FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_files
    WHERE id = file_tags.file_id
    AND user_id = auth.uid()
  )
);

-- Users can delete tags on their own files
DROP POLICY IF EXISTS "Users can delete tags from own files" ON public.file_tags;
CREATE POLICY "Users can delete tags from own files"
ON public.file_tags FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_files
    WHERE id = file_tags.file_id
    AND user_id = auth.uid()
  )
);

-- 7. RLS Policies for file_comments
-- Users can view comments on files they own
DROP POLICY IF EXISTS "Users can view comments on accessible files" ON public.file_comments;
CREATE POLICY "Users can view comments on accessible files"
ON public.file_comments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_files
    WHERE id = file_comments.file_id
    AND user_id = auth.uid()
  )
);

-- Users can comment on their own files
DROP POLICY IF EXISTS "Users can comment on accessible files" ON public.file_comments;
CREATE POLICY "Users can comment on accessible files"
ON public.file_comments FOR INSERT
TO authenticated
WITH CHECK (
  author_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.user_files
    WHERE id = file_comments.file_id
    AND user_id = auth.uid()
  )
);

-- Users can update their own comments
DROP POLICY IF EXISTS "Users can update own comments" ON public.file_comments;
CREATE POLICY "Users can update own comments"
ON public.file_comments FOR UPDATE
TO authenticated
USING (author_id = auth.uid())
WITH CHECK (author_id = auth.uid());

-- Users can delete their own comments or comments on their files
DROP POLICY IF EXISTS "Users can delete own comments or on own files" ON public.file_comments;
CREATE POLICY "Users can delete own comments or on own files"
ON public.file_comments FOR DELETE
TO authenticated
USING (
  author_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.user_files
    WHERE id = file_comments.file_id
    AND user_id = auth.uid()
  )
);

-- 8. RLS Policies for file_versions
-- Users can view versions of files they own
DROP POLICY IF EXISTS "Users can view versions of own files" ON public.file_versions;
CREATE POLICY "Users can view versions of own files"
ON public.file_versions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_files
    WHERE id = file_versions.file_id
    AND user_id = auth.uid()
  )
);

-- Service role can manage versions
DROP POLICY IF EXISTS "Service role can manage versions" ON public.file_versions;
CREATE POLICY "Service role can manage versions"
ON public.file_versions FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 9. Function to auto-increment version number
CREATE OR REPLACE FUNCTION public.get_next_file_version(p_file_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_version INTEGER;
BEGIN
  SELECT COALESCE(MAX(version_no), 0) + 1
  INTO v_next_version
  FROM public.file_versions
  WHERE file_id = p_file_id;
  
  RETURN v_next_version;
END;
$$;

-- 10. Trigger to update file_comments updated_at
CREATE OR REPLACE FUNCTION public.update_file_comment_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_file_comment_timestamp ON public.file_comments;
CREATE TRIGGER trigger_update_file_comment_timestamp
BEFORE UPDATE ON public.file_comments
FOR EACH ROW
EXECUTE FUNCTION public.update_file_comment_timestamp();

-- 11. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.file_tags TO authenticated;
GRANT ALL ON public.file_comments TO authenticated;
GRANT SELECT ON public.file_versions TO authenticated;

COMMENT ON TABLE public.file_tags IS 'Tags for categorizing and searching files';
COMMENT ON TABLE public.file_comments IS 'Comments and feedback on files from coaches and clients';
COMMENT ON TABLE public.file_versions IS 'Version history for file tracking';
COMMENT ON COLUMN public.user_files.is_pinned IS 'Whether file is pinned to top of list';
