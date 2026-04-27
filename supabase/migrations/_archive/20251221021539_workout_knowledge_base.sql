-- Migration: Workout Knowledge Base - Unlimited Exercise & Intensifier Knowledge System
-- Phase: 4 (DB + Minimal UI)
-- Date: 2025-12-21
--
-- This migration creates three tables to support unlimited exercise and intensifier knowledge:
-- 1. exercise_knowledge - Exercises with multi-language support
-- 2. intensifier_knowledge - Training intensifiers/methods
-- 3. exercise_intensifier_links - Junction table linking exercises to intensifiers
--
-- All tables support versioning/moderation (draft → approved)
-- RLS: authenticated users can read approved, coaches/admins can create pending, admins can manage all

-- =====================================================
-- Enable required extensions
-- =====================================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- TABLE 1: exercise_knowledge
-- =====================================================
CREATE TABLE IF NOT EXISTS public.exercise_knowledge (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  aliases TEXT[] DEFAULT '{}',
  short_desc TEXT,
  how_to TEXT,
  cues TEXT[] DEFAULT '{}',
  common_mistakes TEXT[] DEFAULT '{}',
  primary_muscles TEXT[] DEFAULT '{}',
  secondary_muscles TEXT[] DEFAULT '{}',
  equipment TEXT[] DEFAULT '{}',
  movement_pattern TEXT, -- push/pull/hinge/squat/carry/rotation/locomotion/etc
  difficulty TEXT, -- free text, no CHECK constraint
  contraindications TEXT[] DEFAULT '{}',
  media JSONB DEFAULT '{}', -- {image_url, video_url}
  source TEXT, -- e.g. "NSCA", "coach_submitted"
  language TEXT DEFAULT 'en', -- free text
  status TEXT DEFAULT 'approved', -- approved/pending/rejected/draft (no CHECK constraint)
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for exercise_knowledge
CREATE INDEX IF NOT EXISTS idx_exercise_knowledge_name_search 
  ON public.exercise_knowledge USING GIN (to_tsvector('simple', name || ' ' || COALESCE(short_desc, '')));

CREATE INDEX IF NOT EXISTS idx_exercise_knowledge_aliases_gin 
  ON public.exercise_knowledge USING GIN (aliases);

CREATE INDEX IF NOT EXISTS idx_exercise_knowledge_primary_muscles_gin 
  ON public.exercise_knowledge USING GIN (primary_muscles);

CREATE INDEX IF NOT EXISTS idx_exercise_knowledge_equipment_gin 
  ON public.exercise_knowledge USING GIN (equipment);

CREATE INDEX IF NOT EXISTS idx_exercise_knowledge_status 
  ON public.exercise_knowledge(status);

CREATE INDEX IF NOT EXISTS idx_exercise_knowledge_language 
  ON public.exercise_knowledge(language);

CREATE INDEX IF NOT EXISTS idx_exercise_knowledge_created_by 
  ON public.exercise_knowledge(created_by);

-- =====================================================
-- TABLE 2: intensifier_knowledge
-- =====================================================
CREATE TABLE IF NOT EXISTS public.intensifier_knowledge (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  aliases TEXT[] DEFAULT '{}',
  short_desc TEXT,
  how_to TEXT,
  setup_steps TEXT[] DEFAULT '{}',
  best_for TEXT[] DEFAULT '{}', -- hypertrophy/strength/endurance/weakpoint/etc
  fatigue_cost TEXT, -- low/medium/high (free text)
  when_to_use TEXT,
  when_to_avoid TEXT,
  intensity_rules JSONB DEFAULT '{}', -- e.g. {rest_pause: {rest_seconds:15, mini_sets:3}}
  examples TEXT[] DEFAULT '{}',
  language TEXT DEFAULT 'en',
  status TEXT DEFAULT 'approved', -- approved/pending/rejected/draft (no CHECK constraint)
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for intensifier_knowledge
CREATE INDEX IF NOT EXISTS idx_intensifier_knowledge_name_search 
  ON public.intensifier_knowledge USING GIN (to_tsvector('simple', name || ' ' || COALESCE(short_desc, '')));

CREATE INDEX IF NOT EXISTS idx_intensifier_knowledge_aliases_gin 
  ON public.intensifier_knowledge USING GIN (aliases);

CREATE INDEX IF NOT EXISTS idx_intensifier_knowledge_status 
  ON public.intensifier_knowledge(status);

CREATE INDEX IF NOT EXISTS idx_intensifier_knowledge_language 
  ON public.intensifier_knowledge(language);

CREATE INDEX IF NOT EXISTS idx_intensifier_knowledge_created_by 
  ON public.intensifier_knowledge(created_by);

-- =====================================================
-- TABLE 3: exercise_intensifier_links
-- =====================================================
CREATE TABLE IF NOT EXISTS public.exercise_intensifier_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id UUID NOT NULL REFERENCES public.exercise_knowledge(id) ON DELETE CASCADE,
  intensifier_id UUID NOT NULL REFERENCES public.intensifier_knowledge(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(exercise_id, intensifier_id)
);

-- Indexes for exercise_intensifier_links
CREATE INDEX IF NOT EXISTS idx_exercise_intensifier_links_exercise_id 
  ON public.exercise_intensifier_links(exercise_id);

CREATE INDEX IF NOT EXISTS idx_exercise_intensifier_links_intensifier_id 
  ON public.exercise_intensifier_links(intensifier_id);

-- =====================================================
-- Enable RLS
-- =====================================================
ALTER TABLE public.exercise_knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intensifier_knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_intensifier_links ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES: exercise_knowledge
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT approved rows
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_knowledge' AND policyname = 'ek_select_approved') THEN
    CREATE POLICY ek_select_approved ON public.exercise_knowledge
      FOR SELECT
      TO authenticated
      USING (status = 'approved');
  END IF;

  -- Coaches/admins can INSERT pending rows
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_knowledge' AND policyname = 'ek_insert_coach_admin') THEN
    CREATE POLICY ek_insert_coach_admin ON public.exercise_knowledge
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role IN ('coach', 'admin')
        )
        AND (status = 'pending' OR status = 'draft')
        AND created_by = auth.uid()
      );
  END IF;

  -- Admins can UPDATE/DELETE all rows
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_knowledge' AND policyname = 'ek_update_admin') THEN
    CREATE POLICY ek_update_admin ON public.exercise_knowledge
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_knowledge' AND policyname = 'ek_delete_admin') THEN
    CREATE POLICY ek_delete_admin ON public.exercise_knowledge
      FOR DELETE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  -- Coaches can UPDATE their own pending/draft rows
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_knowledge' AND policyname = 'ek_update_own_pending') THEN
    CREATE POLICY ek_update_own_pending ON public.exercise_knowledge
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'coach'
        )
        AND created_by = auth.uid()
        AND (status = 'pending' OR status = 'draft')
      )
      WITH CHECK (
        created_by = auth.uid()
        AND (status = 'pending' OR status = 'draft')
      );
  END IF;
END $$;

-- =====================================================
-- RLS POLICIES: intensifier_knowledge
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT approved rows
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_knowledge' AND policyname = 'ik_select_approved') THEN
    CREATE POLICY ik_select_approved ON public.intensifier_knowledge
      FOR SELECT
      TO authenticated
      USING (status = 'approved');
  END IF;

  -- Coaches/admins can INSERT pending rows
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_knowledge' AND policyname = 'ik_insert_coach_admin') THEN
    CREATE POLICY ik_insert_coach_admin ON public.intensifier_knowledge
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role IN ('coach', 'admin')
        )
        AND (status = 'pending' OR status = 'draft')
        AND created_by = auth.uid()
      );
  END IF;

  -- Admins can UPDATE/DELETE all rows
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_knowledge' AND policyname = 'ik_update_admin') THEN
    CREATE POLICY ik_update_admin ON public.intensifier_knowledge
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_knowledge' AND policyname = 'ik_delete_admin') THEN
    CREATE POLICY ik_delete_admin ON public.intensifier_knowledge
      FOR DELETE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  -- Coaches can UPDATE their own pending/draft rows
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'intensifier_knowledge' AND policyname = 'ik_update_own_pending') THEN
    CREATE POLICY ik_update_own_pending ON public.intensifier_knowledge
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'coach'
        )
        AND created_by = auth.uid()
        AND (status = 'pending' OR status = 'draft')
      )
      WITH CHECK (
        created_by = auth.uid()
        AND (status = 'pending' OR status = 'draft')
      );
  END IF;
END $$;

-- =====================================================
-- RLS POLICIES: exercise_intensifier_links
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT links for approved exercises/intensifiers
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_intensifier_links' AND policyname = 'eil_select_approved') THEN
    CREATE POLICY eil_select_approved ON public.exercise_intensifier_links
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.exercise_knowledge ek
          WHERE ek.id = exercise_intensifier_links.exercise_id
          AND ek.status = 'approved'
        )
        AND EXISTS (
          SELECT 1 FROM public.intensifier_knowledge ik
          WHERE ik.id = exercise_intensifier_links.intensifier_id
          AND ik.status = 'approved'
        )
      );
  END IF;

  -- Coaches/admins can INSERT links
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_intensifier_links' AND policyname = 'eil_insert_coach_admin') THEN
    CREATE POLICY eil_insert_coach_admin ON public.exercise_intensifier_links
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role IN ('coach', 'admin')
        )
      );
  END IF;

  -- Admins can UPDATE/DELETE all links
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_intensifier_links' AND policyname = 'eil_update_admin') THEN
    CREATE POLICY eil_update_admin ON public.exercise_intensifier_links
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exercise_intensifier_links' AND policyname = 'eil_delete_admin') THEN
    CREATE POLICY eil_delete_admin ON public.exercise_intensifier_links
      FOR DELETE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;
END $$;

-- =====================================================
-- Trigger function to update updated_at timestamp
-- =====================================================
CREATE OR REPLACE FUNCTION update_exercise_knowledge_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_intensifier_knowledge_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_update_exercise_knowledge_updated_at ON public.exercise_knowledge;
CREATE TRIGGER trigger_update_exercise_knowledge_updated_at
  BEFORE UPDATE ON public.exercise_knowledge
  FOR EACH ROW
  EXECUTE FUNCTION update_exercise_knowledge_updated_at();

DROP TRIGGER IF EXISTS trigger_update_intensifier_knowledge_updated_at ON public.intensifier_knowledge;
CREATE TRIGGER trigger_update_intensifier_knowledge_updated_at
  BEFORE UPDATE ON public.intensifier_knowledge
  FOR EACH ROW
  EXECUTE FUNCTION update_intensifier_knowledge_updated_at();

-- =====================================================
-- Verification
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: workout_knowledge_base';
  RAISE NOTICE '   - Created table: exercise_knowledge';
  RAISE NOTICE '   - Created table: intensifier_knowledge';
  RAISE NOTICE '   - Created table: exercise_intensifier_links';
  RAISE NOTICE '   - RLS policies created';
  RAISE NOTICE '   - Indexes created';
  RAISE NOTICE '   - Triggers created';
END $$;
