-- Migration: Add GIN Index for Equipment Array Filtering
-- Date: 2025-01-24
--
-- This migration adds a GIN index on the equipment_needed array column
-- in exercises_library to improve filtering performance for large datasets (2000+ exercises).
--
-- Purpose:
--   - Enable fast array overlap queries for equipment filtering
--   - Support efficient filtering at database level instead of in-memory
--   - Improve performance for paginated queries with equipment filters

-- =====================================================
-- INDEX: GIN Index for Equipment Array
-- =====================================================

-- GIN index for array overlap queries on equipment_needed
-- This enables fast filtering like: WHERE equipment_needed && ARRAY['barbell', 'dumbbells']
CREATE INDEX IF NOT EXISTS idx_exercises_library_equipment_gin
  ON exercises_library USING GIN (equipment_needed);

-- =====================================================
-- VERIFICATION
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: add_equipment_index_exercises_library';
  RAISE NOTICE '   - Created GIN index: idx_exercises_library_equipment_gin';
  RAISE NOTICE '   - Enables fast array overlap queries for equipment filtering';
END $$;
