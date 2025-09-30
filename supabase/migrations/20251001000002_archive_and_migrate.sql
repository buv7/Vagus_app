-- =====================================================
-- NUTRITION PLATFORM 2.0 - DATA ARCHIVE & MIGRATION
-- =====================================================
-- This migration archives old data and migrates to new format
-- Run this AFTER the foundation migration
-- Migration: 002_archive_and_migrate.sql
-- =====================================================

BEGIN;

-- =====================================================
-- ARCHIVE OLD DATA
-- =====================================================

-- Create archive tables for rollback safety
CREATE TABLE IF NOT EXISTS nutrition_plans_archive AS
SELECT * FROM nutrition_plans
WHERE format_version IS NULL OR format_version = '1.0'
  OR format_version != '2.0';

CREATE TABLE IF NOT EXISTS meals_archive AS
SELECT m.* FROM meals m
JOIN nutrition_plans np ON m.plan_id = np.id
WHERE np.format_version IS NULL OR np.format_version = '1.0'
  OR np.format_version != '2.0';

-- =====================================================
-- MIGRATE EXISTING DATA TO V2.0
-- =====================================================

-- Update all existing plans to v2.0 format
UPDATE nutrition_plans
SET
  format_version = '2.0',
  migrated_at = NOW(),
  metadata = jsonb_build_object(
    'migrated_from', COALESCE(format_version, 'v1.0'),
    'migration_date', NOW(),
    'original_id', id,
    'migration_notes', 'Automatically migrated to Nutrition Platform 2.0'
  )
WHERE format_version IS NULL
   OR format_version = '1.0'
   OR format_version != '2.0';

-- Set default values for new meal fields
UPDATE meals
SET
  is_eaten = FALSE,
  meal_comments = '[]',
  attachments = '[]'
WHERE is_eaten IS NULL;

-- =====================================================
-- DATA QUALITY FIXES
-- =====================================================

-- Fix any null values in critical fields
UPDATE nutrition_plans
SET metadata = '{}'
WHERE metadata IS NULL;

UPDATE meals
SET
  meal_comments = '[]'
WHERE meal_comments IS NULL;

UPDATE meals
SET attachments = '[]'
WHERE attachments IS NULL;

-- =====================================================
-- POPULATE SUSTAINABILITY DATA FOR COMMON FOODS
-- =====================================================

-- Insert sustainability data for common protein sources
INSERT INTO ethical_food_items (food_item_id, food_name, labels, is_local_seasonal)
SELECT
  id,
  name,
  ARRAY[]::TEXT[],
  FALSE
FROM food_items
WHERE name ILIKE '%chicken%'
   OR name ILIKE '%beef%'
   OR name ILIKE '%fish%'
   OR name ILIKE '%tofu%'
ON CONFLICT (food_item_id) DO NOTHING;

-- Update carbon footprint for common foods (approximate values)
UPDATE food_items
SET
  carbon_footprint_kg = CASE
    WHEN LOWER(name) LIKE '%beef%' THEN 27.0
    WHEN LOWER(name) LIKE '%lamb%' THEN 39.2
    WHEN LOWER(name) LIKE '%pork%' THEN 12.1
    WHEN LOWER(name) LIKE '%chicken%' THEN 6.9
    WHEN LOWER(name) LIKE '%fish%' THEN 5.0
    WHEN LOWER(name) LIKE '%egg%' THEN 4.8
    WHEN LOWER(name) LIKE '%cheese%' THEN 13.5
    WHEN LOWER(name) LIKE '%milk%' THEN 3.2
    WHEN LOWER(name) LIKE '%rice%' THEN 4.0
    WHEN LOWER(name) LIKE '%vegetable%' THEN 2.0
    WHEN LOWER(name) LIKE '%fruit%' THEN 1.1
    ELSE 2.0
  END,
  water_usage_liters = CASE
    WHEN LOWER(name) LIKE '%beef%' THEN 15415.0
    WHEN LOWER(name) LIKE '%lamb%' THEN 10400.0
    WHEN LOWER(name) LIKE '%pork%' THEN 5988.0
    WHEN LOWER(name) LIKE '%chicken%' THEN 4325.0
    WHEN LOWER(name) LIKE '%fish%' THEN 3000.0
    WHEN LOWER(name) LIKE '%egg%' THEN 3265.0
    WHEN LOWER(name) LIKE '%cheese%' THEN 5000.0
    WHEN LOWER(name) LIKE '%milk%' THEN 628.0
    WHEN LOWER(name) LIKE '%rice%' THEN 2497.0
    WHEN LOWER(name) LIKE '%vegetable%' THEN 322.0
    WHEN LOWER(name) LIKE '%fruit%' THEN 962.0
    ELSE 1000.0
  END,
  sustainability_rating = CASE
    WHEN LOWER(name) LIKE '%beef%' OR LOWER(name) LIKE '%lamb%' THEN 'veryPoor'
    WHEN LOWER(name) LIKE '%pork%' OR LOWER(name) LIKE '%cheese%' THEN 'poor'
    WHEN LOWER(name) LIKE '%chicken%' OR LOWER(name) LIKE '%fish%' OR LOWER(name) LIKE '%egg%' THEN 'fair'
    WHEN LOWER(name) LIKE '%vegetable%' OR LOWER(name) LIKE '%fruit%' THEN 'excellent'
    ELSE 'good'
  END
WHERE carbon_footprint_kg IS NULL;

-- =====================================================
-- INITIALIZE USER STREAKS
-- =====================================================

-- Create streak records for all users who have logged meals
INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_logged_date)
SELECT DISTINCT
  user_id,
  0,
  0,
  NULL
FROM meals
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- CREATE DEFAULT ALLERGY PROFILES
-- =====================================================

-- Create empty allergy profiles for all users
-- This ensures the table is ready when users want to add allergies
INSERT INTO allergy_profiles (user_id, allergens, conditions, custom_restrictions)
SELECT DISTINCT
  id,
  '[]'::JSONB,
  '[]'::JSONB,
  ARRAY[]::TEXT[]
FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- VERIFICATION AND STATS
-- =====================================================

-- Log migration statistics
DO $$
DECLARE
  v_plans_migrated INTEGER;
  v_meals_updated INTEGER;
  v_foods_with_sustainability INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_plans_migrated
  FROM nutrition_plans
  WHERE format_version = '2.0' AND migrated_at IS NOT NULL;

  SELECT COUNT(*) INTO v_meals_updated
  FROM meals
  WHERE is_eaten = FALSE;

  SELECT COUNT(*) INTO v_foods_with_sustainability
  FROM food_items
  WHERE carbon_footprint_kg IS NOT NULL;

  RAISE NOTICE 'Migration Statistics:';
  RAISE NOTICE '- Plans migrated to v2.0: %', v_plans_migrated;
  RAISE NOTICE '- Meals updated: %', v_meals_updated;
  RAISE NOTICE '- Foods with sustainability data: %', v_foods_with_sustainability;
END $$;

COMMIT;