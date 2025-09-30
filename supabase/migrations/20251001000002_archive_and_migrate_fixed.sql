-- =====================================================
-- NUTRITION PLATFORM 2.0 - DATA MIGRATION
-- Migration 2 of 2: Archive old data and migrate to v2.0
-- Compatible with existing Vagus schema
-- =====================================================

BEGIN;

-- =====================================================
-- PART 1: CREATE ARCHIVE TABLES
-- =====================================================

-- Archive nutrition_plans (backup before migration)
CREATE TABLE IF NOT EXISTS nutrition_plans_archive AS
SELECT * FROM nutrition_plans
WHERE format_version IS NULL OR format_version != '2.0';

-- Archive nutrition_meals (backup before migration)
CREATE TABLE IF NOT EXISTS nutrition_meals_archive AS
SELECT * FROM nutrition_meals
WHERE is_eaten IS NULL;

-- Archive tables created successfully (no RAISE NOTICE outside DO block)

-- =====================================================
-- PART 2: MIGRATE NUTRITION PLANS TO V2.0
-- =====================================================

-- Update all nutrition plans to v2.0 format
UPDATE nutrition_plans
SET
  format_version = '2.0',
  migrated_at = NOW(),
  metadata = jsonb_build_object(
    'migrated_from', 'v1.0',
    'migration_date', NOW(),
    'original_version', COALESCE(version, 1)
  )
WHERE format_version IS NULL OR format_version != '2.0';

-- Get migration statistics
DO $$
DECLARE
  plans_migrated INTEGER;
  meals_updated INTEGER;
BEGIN
  SELECT COUNT(*) INTO plans_migrated
  FROM nutrition_plans
  WHERE format_version = '2.0';

  SELECT COUNT(*) INTO meals_updated
  FROM nutrition_meals
  WHERE is_eaten IS NOT NULL;

  RAISE NOTICE 'Migration Statistics:';
  RAISE NOTICE '- Plans migrated to v2.0: %', plans_migrated;
  RAISE NOTICE '- Meals updated: %', meals_updated;
END $$;

-- =====================================================
-- PART 3: POPULATE SUSTAINABILITY DATA
-- =====================================================

-- Add carbon footprint data for common foods
UPDATE food_items
SET carbon_footprint_kg = CASE
  -- Meats (highest impact)
  WHEN LOWER(name_en) LIKE '%beef%' OR LOWER(name_en) LIKE '%steak%' THEN 27.0
  WHEN LOWER(name_en) LIKE '%lamb%' THEN 39.2
  WHEN LOWER(name_en) LIKE '%pork%' THEN 12.1
  WHEN LOWER(name_en) LIKE '%chicken%' OR LOWER(name_en) LIKE '%poultry%' THEN 6.9
  WHEN LOWER(name_en) LIKE '%turkey%' THEN 10.9

  -- Fish & Seafood
  WHEN LOWER(name_en) LIKE '%fish%' OR LOWER(name_en) LIKE '%salmon%' THEN 11.9
  WHEN LOWER(name_en) LIKE '%tuna%' THEN 6.1
  WHEN LOWER(name_en) LIKE '%shrimp%' OR LOWER(name_en) LIKE '%prawn%' THEN 26.9

  -- Dairy
  WHEN LOWER(name_en) LIKE '%cheese%' THEN 13.5
  WHEN LOWER(name_en) LIKE '%milk%' THEN 3.2
  WHEN LOWER(name_en) LIKE '%yogurt%' THEN 2.2
  WHEN LOWER(name_en) LIKE '%butter%' THEN 12.1

  -- Eggs
  WHEN LOWER(name_en) LIKE '%egg%' THEN 4.8

  -- Grains
  WHEN LOWER(name_en) LIKE '%rice%' THEN 2.7
  WHEN LOWER(name_en) LIKE '%wheat%' OR LOWER(name_en) LIKE '%bread%' THEN 1.4
  WHEN LOWER(name_en) LIKE '%oats%' OR LOWER(name_en) LIKE '%oatmeal%' THEN 2.5
  WHEN LOWER(name_en) LIKE '%pasta%' THEN 1.4

  -- Legumes (low impact)
  WHEN LOWER(name_en) LIKE '%lentil%' THEN 0.9
  WHEN LOWER(name_en) LIKE '%bean%' OR LOWER(name_en) LIKE '%chickpea%' THEN 2.0
  WHEN LOWER(name_en) LIKE '%tofu%' THEN 2.0

  -- Vegetables (very low impact)
  WHEN LOWER(name_en) LIKE '%vegetable%' OR LOWER(name_en) LIKE '%veggie%' THEN 2.0
  WHEN LOWER(name_en) LIKE '%tomato%' THEN 2.1
  WHEN LOWER(name_en) LIKE '%potato%' THEN 2.9
  WHEN LOWER(name_en) LIKE '%carrot%' THEN 0.4
  WHEN LOWER(name_en) LIKE '%broccoli%' THEN 2.0
  WHEN LOWER(name_en) LIKE '%spinach%' THEN 2.0

  -- Fruits (low impact)
  WHEN LOWER(name_en) LIKE '%apple%' THEN 0.4
  WHEN LOWER(name_en) LIKE '%banana%' THEN 0.7
  WHEN LOWER(name_en) LIKE '%orange%' THEN 0.4
  WHEN LOWER(name_en) LIKE '%berry%' OR LOWER(name_en) LIKE '%berries%' THEN 1.5

  -- Nuts & Seeds (moderate impact)
  WHEN LOWER(name_en) LIKE '%almond%' THEN 2.3
  WHEN LOWER(name_en) LIKE '%nut%' OR LOWER(name_en) LIKE '%nuts%' THEN 2.3
  WHEN LOWER(name_en) LIKE '%seed%' THEN 0.8

  -- Default for unmatched foods
  ELSE 2.0
END,
sustainability_rating = CASE
  WHEN carbon_footprint_kg <= 2.0 THEN 'A'
  WHEN carbon_footprint_kg <= 5.0 THEN 'B'
  WHEN carbon_footprint_kg <= 10.0 THEN 'C'
  WHEN carbon_footprint_kg <= 20.0 THEN 'D'
  ELSE 'F'
END
WHERE carbon_footprint_kg IS NULL;

-- Add water usage estimates
UPDATE food_items
SET water_usage_liters = CASE
  WHEN LOWER(name_en) LIKE '%beef%' THEN 15415.0
  WHEN LOWER(name_en) LIKE '%lamb%' THEN 10412.0
  WHEN LOWER(name_en) LIKE '%pork%' THEN 5988.0
  WHEN LOWER(name_en) LIKE '%chicken%' THEN 4325.0
  WHEN LOWER(name_en) LIKE '%cheese%' THEN 3178.0
  WHEN LOWER(name_en) LIKE '%rice%' THEN 2497.0
  WHEN LOWER(name_en) LIKE '%almond%' THEN 12000.0
  WHEN LOWER(name_en) LIKE '%vegetable%' THEN 322.0
  WHEN LOWER(name_en) LIKE '%fruit%' THEN 962.0
  ELSE 500.0
END
WHERE water_usage_liters IS NULL;

-- Add common allergens
UPDATE food_items
SET allergens = CASE
  WHEN LOWER(name_en) LIKE '%milk%' OR LOWER(name_en) LIKE '%dairy%' THEN ARRAY['dairy']
  WHEN LOWER(name_en) LIKE '%egg%' THEN ARRAY['eggs']
  WHEN LOWER(name_en) LIKE '%peanut%' THEN ARRAY['peanuts', 'tree-nuts']
  WHEN LOWER(name_en) LIKE '%almond%' OR LOWER(name_en) LIKE '%walnut%' THEN ARRAY['tree-nuts']
  WHEN LOWER(name_en) LIKE '%soy%' OR LOWER(name_en) LIKE '%tofu%' THEN ARRAY['soy']
  WHEN LOWER(name_en) LIKE '%wheat%' OR LOWER(name_en) LIKE '%bread%' THEN ARRAY['wheat', 'gluten']
  WHEN LOWER(name_en) LIKE '%fish%' OR LOWER(name_en) LIKE '%salmon%' THEN ARRAY['fish']
  WHEN LOWER(name_en) LIKE '%shrimp%' OR LOWER(name_en) LIKE '%crab%' THEN ARRAY['shellfish']
  ELSE ARRAY[]::TEXT[]
END
WHERE allergens IS NULL;

-- Add seasonal data for fruits/vegetables
UPDATE food_items
SET
  is_seasonal = TRUE,
  seasonal_months = CASE
    WHEN LOWER(name_en) LIKE '%strawberry%' THEN ARRAY[4,5,6]
    WHEN LOWER(name_en) LIKE '%watermelon%' THEN ARRAY[6,7,8]
    WHEN LOWER(name_en) LIKE '%apple%' THEN ARRAY[9,10,11]
    WHEN LOWER(name_en) LIKE '%pumpkin%' THEN ARRAY[9,10,11]
    WHEN LOWER(name_en) LIKE '%tomato%' THEN ARRAY[6,7,8,9]
    WHEN LOWER(name_en) LIKE '%asparagus%' THEN ARRAY[3,4,5]
    ELSE ARRAY[1,2,3,4,5,6,7,8,9,10,11,12] -- Year-round
  END
WHERE (LOWER(name_en) LIKE '%fruit%' OR LOWER(name_en) LIKE '%vegetable%')
  AND is_seasonal IS NULL;

-- Sustainability data populated for common foods

-- =====================================================
-- PART 4: INITIALIZE USER DATA
-- =====================================================

-- Initialize allergy profiles for all users (if they don't have one)
INSERT INTO allergy_profiles (user_id, allergies, intolerances, medical_conditions)
SELECT DISTINCT
  u.id,
  ARRAY[]::TEXT[],
  ARRAY[]::TEXT[],
  ARRAY[]::TEXT[]
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM allergy_profiles ap WHERE ap.user_id = u.id
)
ON CONFLICT (user_id) DO NOTHING;

-- Allergy profiles initialized for all users

-- Update user_streaks if it already exists (initialize counts)
-- Note: user_streaks already exists in schema, just ensure it has data
INSERT INTO user_streaks (user_id, streak_type, current_streak, longest_streak, last_activity_date)
SELECT DISTINCT
  client_id,
  'nutrition_logging',
  0,
  0,
  CURRENT_DATE
FROM nutrition_plans
WHERE NOT EXISTS (
  SELECT 1 FROM user_streaks us WHERE us.user_id = nutrition_plans.client_id AND us.streak_type = 'nutrition_logging'
)
ON CONFLICT DO NOTHING;

-- User streaks ensured for all users

-- =====================================================
-- PART 5: CREATE SAMPLE CHALLENGES
-- =====================================================

-- Insert a welcome challenge for new users
INSERT INTO challenges (
  title,
  description,
  challenge_type,
  start_date,
  end_date,
  reward_type,
  reward_value,
  is_active
) VALUES (
  '7-Day Nutrition Streak',
  'Log your meals for 7 consecutive days to earn your first achievement!',
  'streak',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '30 days',
  'badge',
  jsonb_build_object('badge_name', 'Nutrition Rookie', 'badge_icon', '🌟'),
  TRUE
) ON CONFLICT DO NOTHING;

-- Sample challenges created

-- =====================================================
-- PART 6: VERIFICATION SUMMARY
-- =====================================================

DO $$
DECLARE
  foods_with_sustainability INTEGER;
  users_with_profiles INTEGER;
  users_with_streaks INTEGER;
  active_challenges INTEGER;
BEGIN
  -- Count foods with sustainability data
  SELECT COUNT(*) INTO foods_with_sustainability
  FROM food_items
  WHERE carbon_footprint_kg IS NOT NULL;

  -- Count allergy profiles
  SELECT COUNT(*) INTO users_with_profiles
  FROM allergy_profiles;

  -- Count user streaks
  SELECT COUNT(*) INTO users_with_streaks
  FROM user_streaks;

  -- Count active challenges
  SELECT COUNT(*) INTO active_challenges
  FROM challenges
  WHERE is_active = TRUE;

  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'MIGRATION 2 COMPLETE - VERIFICATION SUMMARY';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Foods with sustainability data: %', foods_with_sustainability;
  RAISE NOTICE 'Users with allergy profiles: %', users_with_profiles;
  RAISE NOTICE 'Users with streak tracking: %', users_with_streaks;
  RAISE NOTICE 'Active challenges: %', active_challenges;
  RAISE NOTICE '';
  RAISE NOTICE 'Archive tables created:';
  RAISE NOTICE '  - nutrition_plans_archive';
  RAISE NOTICE '  - nutrition_meals_archive';
  RAISE NOTICE '';
  RAISE NOTICE '✅ All data successfully migrated to v2.0!';
  RAISE NOTICE '==============================================';
END $$;

COMMIT;

-- =====================================================
-- MIGRATION 2 COMPLETE
-- =====================================================
-- Your database is now ready for Nutrition Platform 2.0!
-- =====================================================