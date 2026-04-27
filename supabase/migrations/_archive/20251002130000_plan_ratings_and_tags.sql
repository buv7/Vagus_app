-- =====================================================
-- PLAN RATINGS AND TAGS SYSTEM
-- Tables to support plan ratings, reviews, and tags
-- Created: 2025-10-02
-- =====================================================

BEGIN;

-- =====================================================
-- PART 1: PLAN RATINGS TABLE
-- For both workout and nutrition plan ratings
-- =====================================================

CREATE TABLE IF NOT EXISTS plan_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('workout', 'nutrition')),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating NUMERIC(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(plan_id, user_id, plan_type)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_plan_ratings_plan ON plan_ratings(plan_id, plan_type);
CREATE INDEX IF NOT EXISTS idx_plan_ratings_user ON plan_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_plan_ratings_rating ON plan_ratings(rating DESC);

-- RLS Policies
ALTER TABLE plan_ratings ENABLE ROW LEVEL SECURITY;

-- Users can view all ratings
CREATE POLICY "Users can view all ratings"
  ON plan_ratings FOR SELECT
  USING (true);

-- Users can create ratings for plans they use
CREATE POLICY "Users can create ratings"
  ON plan_ratings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own ratings
CREATE POLICY "Users can update their own ratings"
  ON plan_ratings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own ratings
CREATE POLICY "Users can delete their own ratings"
  ON plan_ratings FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- PART 2: WORKOUT PLAN TAGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_plan_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  tag_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(plan_id, tag_name)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_workout_plan_tags_plan ON workout_plan_tags(plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_plan_tags_name ON workout_plan_tags(tag_name);

-- RLS Policies
ALTER TABLE workout_plan_tags ENABLE ROW LEVEL SECURITY;

-- Anyone can view workout plan tags
CREATE POLICY "Anyone can view workout plan tags"
  ON workout_plan_tags FOR SELECT
  USING (true);

-- Coaches can manage tags for their plans
CREATE POLICY "Coaches can manage tags for their plans"
  ON workout_plan_tags FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans wp
      WHERE wp.id = plan_id AND wp.created_by = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workout_plans wp
      WHERE wp.id = plan_id AND wp.created_by = auth.uid()
    )
  );

-- =====================================================
-- PART 3: NUTRITION PLAN TAGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS nutrition_plan_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES nutrition_plans(id) ON DELETE CASCADE,
  tag_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(plan_id, tag_name)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_nutrition_plan_tags_plan ON nutrition_plan_tags(plan_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plan_tags_name ON nutrition_plan_tags(tag_name);

-- RLS Policies
ALTER TABLE nutrition_plan_tags ENABLE ROW LEVEL SECURITY;

-- Anyone can view nutrition plan tags
CREATE POLICY "Anyone can view nutrition plan tags"
  ON nutrition_plan_tags FOR SELECT
  USING (true);

-- Coaches can manage tags for their plans
CREATE POLICY "Coaches can manage tags for their plans"
  ON nutrition_plan_tags FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM nutrition_plans np
      WHERE np.id = plan_id AND np.coach_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM nutrition_plans np
      WHERE np.id = plan_id AND np.coach_id = auth.uid()
    )
  );

-- =====================================================
-- PART 4: ADD COLUMNS TO EXISTING TABLES
-- =====================================================

-- Add difficulty column to workout_plans if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'workout_plans' AND column_name = 'difficulty'
  ) THEN
    ALTER TABLE workout_plans
    ADD COLUMN difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced'));
  END IF;
END $$;

-- Add difficulty column to nutrition_plans if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'nutrition_plans' AND column_name = 'difficulty'
  ) THEN
    ALTER TABLE nutrition_plans
    ADD COLUMN difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced'));
  END IF;
END $$;

-- =====================================================
-- PART 5: UPDATE TRIGGERS
-- =====================================================

-- Trigger to update updated_at on plan_ratings
CREATE OR REPLACE FUNCTION update_plan_ratings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER plan_ratings_updated_at
  BEFORE UPDATE ON plan_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_plan_ratings_updated_at();

-- =====================================================
-- PART 6: HELPER FUNCTIONS
-- =====================================================

-- Function to get average rating for a plan
CREATE OR REPLACE FUNCTION get_plan_average_rating(
  p_plan_id UUID,
  p_plan_type TEXT
)
RETURNS NUMERIC AS $$
DECLARE
  avg_rating NUMERIC;
BEGIN
  SELECT AVG(rating)
  INTO avg_rating
  FROM plan_ratings
  WHERE plan_id = p_plan_id
    AND plan_type = p_plan_type;

  RETURN COALESCE(avg_rating, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get rating count for a plan
CREATE OR REPLACE FUNCTION get_plan_rating_count(
  p_plan_id UUID,
  p_plan_type TEXT
)
RETURNS INTEGER AS $$
DECLARE
  rating_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO rating_count
  FROM plan_ratings
  WHERE plan_id = p_plan_id
    AND plan_type = p_plan_type;

  RETURN rating_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;

-- =====================================================
-- VERIFICATION
-- =====================================================

SELECT 'Plan ratings and tags migration completed successfully!' AS status;
SELECT COUNT(*) AS rating_count FROM plan_ratings;
SELECT COUNT(*) AS workout_tag_count FROM workout_plan_tags;
SELECT COUNT(*) AS nutrition_tag_count FROM nutrition_plan_tags;
