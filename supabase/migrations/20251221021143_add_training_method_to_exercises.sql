-- Migration: Add training_method column to exercises table
-- Phase: 3.3.2 - Persist TrainingMethod safely
-- Date: 2025-12-21
--
-- This migration adds a training_method column to the exercises table
-- to support unlimited training method values (no CHECK constraint).
-- Backward compatible: existing exercises will have NULL training_method.

-- =====================================================
-- Add training_method column
-- =====================================================

DO $$
BEGIN
  -- Check if column already exists
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'exercises'
      AND column_name = 'training_method'
  ) THEN
    ALTER TABLE public.exercises
    ADD COLUMN training_method TEXT;

    RAISE NOTICE '✓ Added training_method column to public.exercises';
  ELSE
    RAISE NOTICE 'ℹ Column training_method already exists in public.exercises (skipping)';
  END IF;
END $$;

-- =====================================================
-- Verification
-- =====================================================

-- Verify column exists
DO $$
DECLARE
  col_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'exercises'
      AND column_name = 'training_method'
  ) INTO col_exists;

  IF col_exists THEN
    RAISE NOTICE '✅ VERIFICATION: training_method column exists in public.exercises';
  ELSE
    RAISE WARNING '❌ VERIFICATION FAILED: training_method column not found';
  END IF;
END $$;
