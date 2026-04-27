-- Migration: Fatigue Explanations - Multilingual Intelligence Layer
-- Phase: 4.8-F (Fatigue Intelligence Layer)
-- Date: 2025-01-23
--
-- This migration creates the fatigue_explanations table to provide
-- human-readable, multilingual explanations for fatigue states.
--
-- Purpose:
--   - Explain WHY fatigue is high/medium/low
--   - Describe WHAT it affects (CNS, joints, local muscle, recovery)
--   - Provide coaching tips on WHEN to use/avoid
--   - Support AI coach explanations, deload logic, warnings
--
-- Design principles:
--   - Read-only intelligence layer (does NOT calculate fatigue)
--   - Multilingual support (English + Arabic)
--   - Links to intensifiers, exercises, or global states
--   - AI-ready structured data

-- =====================================================
-- TABLE: fatigue_explanations
-- =====================================================
CREATE TABLE IF NOT EXISTS public.fatigue_explanations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('intensifier', 'exercise', 'global')),
  entity_id UUID NULL, -- NULL for global explanations, UUID for intensifier/exercise
  fatigue_level TEXT NOT NULL CHECK (fatigue_level IN ('low', 'medium', 'high')),
  language TEXT NOT NULL,
  title TEXT NOT NULL,
  explanation TEXT NOT NULL,
  impact JSONB DEFAULT '{}', -- {cns: "high", joints: "medium", local_muscle: "high", recovery_days: 2}
  coaching_tip TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one explanation per entity+level+language combination
  UNIQUE (entity_type, entity_id, fatigue_level, language)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Index for language filtering
CREATE INDEX IF NOT EXISTS idx_fatigue_expl_lang
  ON public.fatigue_explanations (language);

-- Index for entity lookup
CREATE INDEX IF NOT EXISTS idx_fatigue_expl_entity
  ON public.fatigue_explanations (entity_type, entity_id);

-- Composite index for common queries (entity + level + language)
CREATE INDEX IF NOT EXISTS idx_fatigue_expl_lookup
  ON public.fatigue_explanations (entity_type, entity_id, fatigue_level, language);

-- GIN index for impact JSONB queries
CREATE INDEX IF NOT EXISTS idx_fatigue_expl_impact_gin
  ON public.fatigue_explanations USING GIN (impact);

-- =====================================================
-- Enable RLS
-- =====================================================
ALTER TABLE public.fatigue_explanations ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES: fatigue_explanations
-- =====================================================
DO $$
BEGIN
  -- Authenticated users can SELECT all explanations (read-only intelligence layer)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fatigue_explanations' AND policyname = 'fe_select_authenticated') THEN
    CREATE POLICY fe_select_authenticated ON public.fatigue_explanations
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  -- Admins can INSERT/UPDATE/DELETE (for seeding and maintenance)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fatigue_explanations' AND policyname = 'fe_insert_admin') THEN
    CREATE POLICY fe_insert_admin ON public.fatigue_explanations
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
          AND p.role = 'admin'
        )
      );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fatigue_explanations' AND policyname = 'fe_update_admin') THEN
    CREATE POLICY fe_update_admin ON public.fatigue_explanations
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

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fatigue_explanations' AND policyname = 'fe_delete_admin') THEN
    CREATE POLICY fe_delete_admin ON public.fatigue_explanations
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
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: fatigue_explanations_multilang';
  RAISE NOTICE 'Table: fatigue_explanations created with RLS policies';
  RAISE NOTICE 'Indexes: language, entity, lookup, impact_gin';
END $$;