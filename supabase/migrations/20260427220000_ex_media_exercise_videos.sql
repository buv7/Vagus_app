-- EX-MEDIA — exercise_videos table + RLS + indexes
-- Migration owner: EX-MEDIA
-- Created: 2026-04-27 22:00 UTC
--
-- Depends on: EX-FORGE (exercises table). Apply EX-FORGE migration first.
-- CDN URL resolution: delegated to MASON's media_url_resolver; raw URLs stored here.
--
-- Idempotent. Rollback at the bottom.

-- ============================================================================
-- Extensions
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- Enum: video_source
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'video_source') THEN
    CREATE TYPE video_source AS ENUM (
      'own',
      'youtube',
      'instagram',
      'tiktok',
      'other'
    );
  END IF;
END$$;

-- ============================================================================
-- exercise_videos
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_videos (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  exercise_id       UUID        NOT NULL,
  video_url         TEXT        NOT NULL,
  source            video_source NOT NULL DEFAULT 'own',
  uploader_user_id  UUID        NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  duration_seconds  INTEGER,
  thumbnail_url     TEXT,
  language          TEXT        NOT NULL DEFAULT 'en',
  is_default        BOOLEAN     NOT NULL DEFAULT false,
  -- client_id NULL means "default for all clients of this coach";
  -- non-NULL means "override for this specific client"
  client_id         UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  title             TEXT,
  description       TEXT,
  is_active         BOOLEAN     NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- FK to exercises table (created by EX-FORGE). Added in a DO block so this
-- migration does not fail if EX-FORGE hasn't run yet in a fresh environment;
-- OXBAR must sequence EX-FORGE before EX-MEDIA in production.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'exercises'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'exercise_videos_exercise_id_fkey'
        AND table_name = 'exercise_videos'
    ) THEN
      ALTER TABLE exercise_videos
        ADD CONSTRAINT exercise_videos_exercise_id_fkey
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE;
    END IF;
  END IF;
END$$;

-- ============================================================================
-- Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_exercise_videos_exercise_id
  ON exercise_videos (exercise_id);

CREATE INDEX IF NOT EXISTS idx_exercise_videos_uploader
  ON exercise_videos (uploader_user_id);

CREATE INDEX IF NOT EXISTS idx_exercise_videos_exercise_client
  ON exercise_videos (exercise_id, client_id);

CREATE INDEX IF NOT EXISTS idx_exercise_videos_default
  ON exercise_videos (exercise_id, is_default) WHERE is_default = true;

-- ============================================================================
-- updated_at trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION ex_media_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_exercise_videos_updated_at ON exercise_videos;
CREATE TRIGGER trg_exercise_videos_updated_at
  BEFORE UPDATE ON exercise_videos
  FOR EACH ROW EXECUTE FUNCTION ex_media_set_updated_at();

-- ============================================================================
-- Row-level security
-- ============================================================================

ALTER TABLE exercise_videos ENABLE ROW LEVEL SECURITY;

-- Coaches can CRUD videos they uploaded.
DROP POLICY IF EXISTS exercise_videos_coach_all ON exercise_videos;
CREATE POLICY exercise_videos_coach_all ON exercise_videos
  FOR ALL
  USING (auth.uid() = uploader_user_id)
  WITH CHECK (auth.uid() = uploader_user_id);

-- Clients can read videos assigned to them (client_id = their id) or global defaults (client_id IS NULL).
DROP POLICY IF EXISTS exercise_videos_client_read ON exercise_videos;
CREATE POLICY exercise_videos_client_read ON exercise_videos
  FOR SELECT
  USING (
    is_active = true
    AND (client_id IS NULL OR client_id = auth.uid())
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON exercise_videos TO authenticated;

-- ============================================================================
-- exercise_image_overrides
-- ============================================================================
-- For the 350 yuhonas exercises, default image = yuhonas raw GitHub URL (stored
-- in exercises.thumbnail_url by EX-FORGE). A coach can override the image per
-- client by inserting a row here.

CREATE TABLE IF NOT EXISTS exercise_image_overrides (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  exercise_id      UUID        NOT NULL,
  coach_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id        UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url        TEXT        NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT exercise_image_overrides_unique UNIQUE (exercise_id, coach_id, client_id)
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'exercises'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'exercise_image_overrides_exercise_id_fkey'
        AND table_name = 'exercise_image_overrides'
    ) THEN
      ALTER TABLE exercise_image_overrides
        ADD CONSTRAINT exercise_image_overrides_exercise_id_fkey
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE;
    END IF;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_exercise_image_overrides_exercise_coach
  ON exercise_image_overrides (exercise_id, coach_id);

DROP TRIGGER IF EXISTS trg_exercise_image_overrides_updated_at ON exercise_image_overrides;
CREATE TRIGGER trg_exercise_image_overrides_updated_at
  BEFORE UPDATE ON exercise_image_overrides
  FOR EACH ROW EXECUTE FUNCTION ex_media_set_updated_at();

ALTER TABLE exercise_image_overrides ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS exercise_image_overrides_coach_all ON exercise_image_overrides;
CREATE POLICY exercise_image_overrides_coach_all ON exercise_image_overrides
  FOR ALL
  USING (auth.uid() = coach_id)
  WITH CHECK (auth.uid() = coach_id);

DROP POLICY IF EXISTS exercise_image_overrides_client_read ON exercise_image_overrides;
CREATE POLICY exercise_image_overrides_client_read ON exercise_image_overrides
  FOR SELECT
  USING (client_id IS NULL OR client_id = auth.uid());

GRANT SELECT, INSERT, UPDATE, DELETE ON exercise_image_overrides TO authenticated;

-- ============================================================================
-- Rollback (run manually if needed)
-- ============================================================================
-- DROP TABLE IF EXISTS exercise_image_overrides CASCADE;
-- DROP TABLE IF EXISTS exercise_videos CASCADE;
-- DROP FUNCTION IF EXISTS ex_media_set_updated_at();
-- DROP TYPE IF EXISTS video_source;
