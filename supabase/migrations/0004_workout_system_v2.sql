-- =====================================================
-- WORKOUT SYSTEM V2 - COMPREHENSIVE MIGRATION
-- Following nutrition v2 patterns with proper versioning,
-- RLS policies, and AI integration support
-- =====================================================

BEGIN;

-- =====================================================
-- PART 1: WORKOUT PLANS TABLE (Main container)
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  duration_weeks INTEGER NOT NULL DEFAULT 1,
  start_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_template BOOLEAN DEFAULT FALSE,
  template_category TEXT,
  ai_generated BOOLEAN DEFAULT FALSE,
  unseen_update BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  metadata JSONB DEFAULT '{}',
  version_number INTEGER DEFAULT 1
);

-- =====================================================
-- PART 2: WORKOUT PLAN STRUCTURE (Weeks/Days hierarchy)
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_plan_weeks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  week_number INTEGER NOT NULL,
  notes TEXT,
  attachments JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(plan_id, week_number)
);

CREATE TABLE IF NOT EXISTS workout_plan_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_id UUID NOT NULL REFERENCES workout_plan_weeks(id) ON DELETE CASCADE,
  day_number INTEGER NOT NULL,
  label TEXT NOT NULL, -- e.g., "Push Day", "Upper Body", "Rest"
  client_comment TEXT,
  attachments JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(week_id, day_number)
);

-- =====================================================
-- PART 3: WORKOUT EXERCISES TABLE (Core training data)
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_id UUID NOT NULL REFERENCES workout_plan_days(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL,
  name TEXT NOT NULL,

  -- Volume parameters
  sets INTEGER,
  reps TEXT, -- Can be "8-12", "AMRAP", "8", etc.
  rest INTEGER, -- Rest in seconds

  -- Intensity parameters
  weight DECIMAL(10,2), -- Weight in kg/lbs
  percent_1rm INTEGER, -- Percentage of 1RM (0-100)
  rir INTEGER, -- Reps in reserve (0-5)
  tempo TEXT, -- e.g., "3-1-1-0"

  -- Calculated/tracked metrics
  tonnage DECIMAL(10,2), -- Total volume (sets × reps × weight)

  -- Exercise details
  notes TEXT,
  media_urls TEXT[], -- Video demonstrations, images

  -- Grouping (supersets, circuits, etc.)
  group_id TEXT, -- Identifier for grouping exercises
  group_type TEXT CHECK (group_type IN ('superset', 'circuit', 'giant_set', 'drop_set', 'rest_pause', 'none')),

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(day_id, order_index)
);

-- =====================================================
-- PART 4: CARDIO SESSIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_cardio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_id UUID NOT NULL REFERENCES workout_plan_days(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL,
  machine_type TEXT, -- 'treadmill', 'bike', 'rower', 'elliptical', 'stairmaster'

  -- Machine-specific settings stored as JSONB
  settings JSONB NOT NULL DEFAULT '{}',
  -- Example: {"speed": 6.0, "incline": 5, "duration_min": 30}
  -- Example: {"resistance": 8, "rpm": 80, "duration_min": 20}

  instructions TEXT,
  duration_minutes INTEGER,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(day_id, order_index)
);

-- =====================================================
-- PART 5: VERSION HISTORY (Track changes like nutrition)
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_plan_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  snapshot JSONB NOT NULL, -- Full plan data at this version
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  change_description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(plan_id, version_number)
);

-- =====================================================
-- PART 6: EXERCISE HISTORY (Track client performance)
-- =====================================================

CREATE TABLE IF NOT EXISTS exercise_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,

  -- Performance data
  completed_sets INTEGER,
  completed_reps TEXT, -- Can be array like "12,10,8" for different sets
  weight_used DECIMAL(10,2),
  rir_actual INTEGER,

  -- Tracking metadata
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT,
  form_rating INTEGER CHECK (form_rating BETWEEN 1 AND 5), -- Self-assessed form quality
  difficulty_rating INTEGER CHECK (difficulty_rating BETWEEN 1 AND 5),

  -- Progress tracking
  estimated_1rm DECIMAL(10,2), -- Calculated based on reps/weight
  volume DECIMAL(10,2), -- Sets × reps × weight

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PART 7: WORKOUT ATTACHMENTS (Media/files)
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_plan_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL, -- 'image', 'video', 'pdf', 'audio'
  file_name TEXT,
  file_size INTEGER, -- Size in bytes
  uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PART 8: INDEXES FOR PERFORMANCE
-- =====================================================

-- Workout plans indexes
CREATE INDEX IF NOT EXISTS idx_workout_plans_coach ON workout_plans(coach_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_client ON workout_plans(client_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_template ON workout_plans(is_template) WHERE is_template = true;
CREATE INDEX IF NOT EXISTS idx_workout_plans_archived ON workout_plans(is_archived);
CREATE INDEX IF NOT EXISTS idx_workout_plans_created_at ON workout_plans(created_at DESC);

-- Workout structure indexes
CREATE INDEX IF NOT EXISTS idx_workout_weeks_plan ON workout_plan_weeks(plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_days_week ON workout_plan_days(week_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_day ON workout_exercises(day_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_order ON workout_exercises(day_id, order_index);
CREATE INDEX IF NOT EXISTS idx_workout_cardio_day ON workout_cardio(day_id);

-- Exercise history indexes
CREATE INDEX IF NOT EXISTS idx_exercise_history_client ON exercise_history(client_id);
CREATE INDEX IF NOT EXISTS idx_exercise_history_exercise ON exercise_history(exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_history_completed ON exercise_history(completed_at DESC);

-- Version history indexes
CREATE INDEX IF NOT EXISTS idx_workout_versions_plan ON workout_plan_versions(plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_versions_created ON workout_plan_versions(created_at DESC);

-- Attachments indexes
CREATE INDEX IF NOT EXISTS idx_workout_attachments_plan ON workout_plan_attachments(plan_id);

-- =====================================================
-- PART 9: HELPER FUNCTIONS
-- =====================================================

-- Calculate estimated 1RM using Epley formula
CREATE OR REPLACE FUNCTION calculate_1rm(weight DECIMAL, reps INTEGER)
RETURNS DECIMAL AS $$
BEGIN
  IF reps = 1 THEN
    RETURN weight;
  ELSIF reps > 1 AND reps <= 15 THEN
    RETURN weight * (1 + reps / 30.0);
  ELSE
    RETURN NULL; -- Not accurate for high reps
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Calculate total workout volume for a day
CREATE OR REPLACE FUNCTION calculate_day_volume(p_day_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_volume DECIMAL := 0;
BEGIN
  SELECT COALESCE(SUM(tonnage), 0) INTO total_volume
  FROM workout_exercises
  WHERE day_id = p_day_id;

  RETURN total_volume;
END;
$$ LANGUAGE plpgsql;

-- Calculate total workout duration (approximate)
CREATE OR REPLACE FUNCTION calculate_day_duration(p_day_id UUID)
RETURNS INTEGER AS $$
DECLARE
  exercise_time INTEGER := 0;
  cardio_time INTEGER := 0;
BEGIN
  -- Estimate exercise time: sets × 30 seconds per set + rest time
  SELECT COALESCE(SUM(sets * 30 + rest * (sets - 1)), 0) INTO exercise_time
  FROM workout_exercises
  WHERE day_id = p_day_id AND sets IS NOT NULL;

  -- Add cardio time
  SELECT COALESCE(SUM(duration_minutes * 60), 0) INTO cardio_time
  FROM workout_cardio
  WHERE day_id = p_day_id;

  RETURN (exercise_time + cardio_time) / 60; -- Return in minutes
END;
$$ LANGUAGE plpgsql;

-- Update tonnage when exercise data changes
CREATE OR REPLACE FUNCTION update_exercise_tonnage()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate tonnage if we have all required values
  IF NEW.sets IS NOT NULL AND NEW.weight IS NOT NULL AND NEW.reps IS NOT NULL THEN
    -- Try to extract numeric value from reps (handles "8-12" or "8" format)
    DECLARE
      reps_numeric INTEGER;
    BEGIN
      -- Extract first number from reps string
      reps_numeric := (regexp_match(NEW.reps, '^\d+'))[1]::INTEGER;
      NEW.tonnage := NEW.sets * reps_numeric * NEW.weight;
    EXCEPTION WHEN OTHERS THEN
      NEW.tonnage := NULL;
    END;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_exercise_tonnage
  BEFORE INSERT OR UPDATE ON workout_exercises
  FOR EACH ROW
  EXECUTE FUNCTION update_exercise_tonnage();

-- Update timestamps on modification
CREATE OR REPLACE FUNCTION update_workout_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_workout_plans_updated_at
  BEFORE UPDATE ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_timestamp();

CREATE TRIGGER trigger_workout_weeks_updated_at
  BEFORE UPDATE ON workout_plan_weeks
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_timestamp();

CREATE TRIGGER trigger_workout_days_updated_at
  BEFORE UPDATE ON workout_plan_days
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_timestamp();

CREATE TRIGGER trigger_workout_exercises_updated_at
  BEFORE UPDATE ON workout_exercises
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_timestamp();

-- =====================================================
-- PART 10: ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plan_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plan_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_cardio ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plan_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plan_attachments ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PART 11: RLS POLICIES
-- =====================================================

-- WORKOUT PLANS POLICIES
-- Coaches can view their created plans
CREATE POLICY "Coaches can view their workout plans" ON workout_plans
  FOR SELECT USING (
    coach_id = auth.uid() OR
    created_by = auth.uid()
  );

-- Clients can view plans assigned to them
CREATE POLICY "Clients can view their assigned plans" ON workout_plans
  FOR SELECT USING (
    client_id = auth.uid()
  );

-- Coaches can create plans
CREATE POLICY "Coaches can create workout plans" ON workout_plans
  FOR INSERT WITH CHECK (
    coach_id = auth.uid() AND
    created_by = auth.uid()
  );

-- Coaches can update their plans
CREATE POLICY "Coaches can update their workout plans" ON workout_plans
  FOR UPDATE USING (
    coach_id = auth.uid() OR
    created_by = auth.uid()
  );

-- Coaches can delete their plans
CREATE POLICY "Coaches can delete their workout plans" ON workout_plans
  FOR DELETE USING (
    coach_id = auth.uid() OR
    created_by = auth.uid()
  );

-- WORKOUT WEEKS POLICIES
CREATE POLICY "Users can view weeks of accessible plans" ON workout_plan_weeks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM workout_plans wp
      WHERE wp.id = workout_plan_weeks.plan_id
      AND (wp.coach_id = auth.uid() OR wp.client_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

CREATE POLICY "Coaches can manage weeks" ON workout_plan_weeks
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM workout_plans wp
      WHERE wp.id = workout_plan_weeks.plan_id
      AND (wp.coach_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

-- WORKOUT DAYS POLICIES
CREATE POLICY "Users can view days of accessible weeks" ON workout_plan_days
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM workout_plan_weeks wpw
      JOIN workout_plans wp ON wp.id = wpw.plan_id
      WHERE wpw.id = workout_plan_days.week_id
      AND (wp.coach_id = auth.uid() OR wp.client_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

CREATE POLICY "Coaches can manage days" ON workout_plan_days
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM workout_plan_weeks wpw
      JOIN workout_plans wp ON wp.id = wpw.plan_id
      WHERE wpw.id = workout_plan_days.week_id
      AND (wp.coach_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

-- Clients can update their comments
CREATE POLICY "Clients can update day comments" ON workout_plan_days
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM workout_plan_weeks wpw
      JOIN workout_plans wp ON wp.id = wpw.plan_id
      WHERE wpw.id = workout_plan_days.week_id
      AND wp.client_id = auth.uid()
    )
  );

-- WORKOUT EXERCISES POLICIES
CREATE POLICY "Users can view exercises of accessible days" ON workout_exercises
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM workout_plan_days wpd
      JOIN workout_plan_weeks wpw ON wpw.id = wpd.week_id
      JOIN workout_plans wp ON wp.id = wpw.plan_id
      WHERE wpd.id = workout_exercises.day_id
      AND (wp.coach_id = auth.uid() OR wp.client_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

CREATE POLICY "Coaches can manage exercises" ON workout_exercises
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM workout_plan_days wpd
      JOIN workout_plan_weeks wpw ON wpw.id = wpd.week_id
      JOIN workout_plans wp ON wp.id = wpw.plan_id
      WHERE wpd.id = workout_exercises.day_id
      AND (wp.coach_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

-- WORKOUT CARDIO POLICIES
CREATE POLICY "Users can view cardio of accessible days" ON workout_cardio
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM workout_plan_days wpd
      JOIN workout_plan_weeks wpw ON wpw.id = wpd.week_id
      JOIN workout_plans wp ON wp.id = wpw.plan_id
      WHERE wpd.id = workout_cardio.day_id
      AND (wp.coach_id = auth.uid() OR wp.client_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

CREATE POLICY "Coaches can manage cardio" ON workout_cardio
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM workout_plan_days wpd
      JOIN workout_plan_weeks wpw ON wpw.id = wpd.week_id
      JOIN workout_plans wp ON wp.id = wpw.plan_id
      WHERE wpd.id = workout_cardio.day_id
      AND (wp.coach_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

-- VERSION HISTORY POLICIES
CREATE POLICY "Users can view version history of their plans" ON workout_plan_versions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM workout_plans wp
      WHERE wp.id = workout_plan_versions.plan_id
      AND (wp.coach_id = auth.uid() OR wp.client_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

CREATE POLICY "System can create version history" ON workout_plan_versions
  FOR INSERT WITH CHECK (true);

-- EXERCISE HISTORY POLICIES
CREATE POLICY "Clients can view their exercise history" ON exercise_history
  FOR SELECT USING (client_id = auth.uid());

CREATE POLICY "Coaches can view their clients' history" ON exercise_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM workout_plans wp
      WHERE wp.client_id = exercise_history.client_id
      AND wp.coach_id = auth.uid()
    )
  );

CREATE POLICY "Clients can create their exercise history" ON exercise_history
  FOR INSERT WITH CHECK (client_id = auth.uid());

CREATE POLICY "Clients can update their exercise history" ON exercise_history
  FOR UPDATE USING (client_id = auth.uid());

-- ATTACHMENTS POLICIES
CREATE POLICY "Users can view attachments of accessible plans" ON workout_plan_attachments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM workout_plans wp
      WHERE wp.id = workout_plan_attachments.plan_id
      AND (wp.coach_id = auth.uid() OR wp.client_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

CREATE POLICY "Coaches can manage attachments" ON workout_plan_attachments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM workout_plans wp
      WHERE wp.id = workout_plan_attachments.plan_id
      AND (wp.coach_id = auth.uid() OR wp.created_by = auth.uid())
    )
  );

-- =====================================================
-- PART 12: COMMENTS & METADATA
-- =====================================================

COMMENT ON TABLE workout_plans IS 'Main container for workout programs with versioning and template support';
COMMENT ON TABLE workout_plan_weeks IS 'Weekly structure within workout plans for progressive programming';
COMMENT ON TABLE workout_plan_days IS 'Individual training days with labels and client feedback';
COMMENT ON TABLE workout_exercises IS 'Resistance training exercises with sets, reps, intensity parameters';
COMMENT ON TABLE workout_cardio IS 'Cardiovascular training sessions with machine-specific settings';
COMMENT ON TABLE workout_plan_versions IS 'Version history for tracking plan changes over time';
COMMENT ON TABLE exercise_history IS 'Client performance tracking for progressive overload analysis';
COMMENT ON TABLE workout_plan_attachments IS 'Media files and documents attached to workout plans';

COMMENT ON FUNCTION calculate_1rm IS 'Calculate estimated one-rep max using Epley formula';
COMMENT ON FUNCTION calculate_day_volume IS 'Calculate total training volume for a specific day';
COMMENT ON FUNCTION calculate_day_duration IS 'Estimate total workout duration in minutes';

-- =====================================================
-- PART 13: EXERCISE LIBRARY SYSTEM
-- =====================================================

-- Main exercise library (public + coach-created)
CREATE TABLE IF NOT EXISTS exercise_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_ku TEXT,
  category TEXT NOT NULL CHECK (category IN ('compound', 'isolation', 'cardio', 'stretching', 'plyometric', 'olympic')),

  -- Muscle groups (array for multi-joint exercises)
  primary_muscle_groups TEXT[] DEFAULT '{}',
  secondary_muscle_groups TEXT[] DEFAULT '{}',

  -- Equipment and setup
  equipment_needed TEXT[] DEFAULT '{}', -- ['barbell', 'bench', 'rack']
  difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'expert')),

  -- Instructions and media
  instructions TEXT,
  instructions_ar TEXT,
  instructions_ku TEXT,
  video_url TEXT,
  thumbnail_url TEXT,

  -- Metadata
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Search optimization
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('english', coalesce(name, '') || ' ' || coalesce(instructions, ''))
  ) STORED,

  -- Analytics
  usage_count INTEGER DEFAULT 0,

  CONSTRAINT unique_public_exercise UNIQUE NULLS NOT DISTINCT (name, created_by, is_public)
);

CREATE INDEX idx_exercise_library_search ON exercise_library USING GIN(search_vector);
CREATE INDEX idx_exercise_library_category ON exercise_library(category);
CREATE INDEX idx_exercise_library_difficulty ON exercise_library(difficulty_level);
CREATE INDEX idx_exercise_library_public ON exercise_library(is_public) WHERE is_public = TRUE;
CREATE INDEX idx_exercise_library_creator ON exercise_library(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_exercise_library_primary_muscles ON exercise_library USING GIN(primary_muscle_groups);
CREATE INDEX idx_exercise_library_equipment ON exercise_library USING GIN(equipment_needed);

-- Exercise tags for flexible categorization
CREATE TABLE IF NOT EXISTS exercise_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id UUID NOT NULL REFERENCES exercise_library(id) ON DELETE CASCADE,
  tag TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(exercise_id, tag)
);

CREATE INDEX idx_exercise_tags_tag ON exercise_tags(tag);
CREATE INDEX idx_exercise_tags_exercise ON exercise_tags(exercise_id);

-- Exercise media for multiple demo angles
CREATE TABLE IF NOT EXISTS exercise_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id UUID NOT NULL REFERENCES exercise_library(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL CHECK (media_type IN ('video', 'image', 'gif')),
  url TEXT NOT NULL,
  angle TEXT, -- 'front', 'side', 'top', 'close-up'
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(exercise_id, order_index)
);

CREATE INDEX idx_exercise_media_exercise ON exercise_media(exercise_id);
CREATE INDEX idx_exercise_media_type ON exercise_media(media_type);

-- User favorites for quick access
CREATE TABLE IF NOT EXISTS exercise_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercise_library(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, exercise_id)
);

CREATE INDEX idx_exercise_favorites_user ON exercise_favorites(user_id);
CREATE INDEX idx_exercise_favorites_exercise ON exercise_favorites(exercise_id);

-- Exercise alternatives mapping
CREATE TABLE IF NOT EXISTS exercise_alternatives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id UUID NOT NULL REFERENCES exercise_library(id) ON DELETE CASCADE,
  alternative_id UUID NOT NULL REFERENCES exercise_library(id) ON DELETE CASCADE,
  reason TEXT, -- 'equipment', 'difficulty', 'injury', 'preference'
  similarity_score DECIMAL(3,2) DEFAULT 0.80, -- 0.0 to 1.0
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(exercise_id, alternative_id),
  CHECK (exercise_id != alternative_id)
);

CREATE INDEX idx_exercise_alternatives_exercise ON exercise_alternatives(exercise_id);
CREATE INDEX idx_exercise_alternatives_alternative ON exercise_alternatives(alternative_id);
CREATE INDEX idx_exercise_alternatives_similarity ON exercise_alternatives(similarity_score DESC);

-- =====================================================
-- EXERCISE LIBRARY RLS POLICIES
-- =====================================================

ALTER TABLE exercise_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_alternatives ENABLE ROW LEVEL SECURITY;

-- Everyone can view public exercises
CREATE POLICY "Public exercises are viewable by all" ON exercise_library
  FOR SELECT USING (is_public = TRUE);

-- Users can view their own custom exercises
CREATE POLICY "Users can view their own exercises" ON exercise_library
  FOR SELECT USING (created_by = auth.uid());

-- Coaches can create custom exercises
CREATE POLICY "Coaches can create exercises" ON exercise_library
  FOR INSERT WITH CHECK (created_by = auth.uid());

-- Users can update their own exercises
CREATE POLICY "Users can update their own exercises" ON exercise_library
  FOR UPDATE USING (created_by = auth.uid());

-- Users can delete their own exercises
CREATE POLICY "Users can delete their own exercises" ON exercise_library
  FOR DELETE USING (created_by = auth.uid());

-- Exercise tags policies
CREATE POLICY "Tags follow exercise visibility" ON exercise_tags
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM exercise_library el
      WHERE el.id = exercise_tags.exercise_id
      AND (el.is_public = TRUE OR el.created_by = auth.uid())
    )
  );

CREATE POLICY "Users can manage tags on their exercises" ON exercise_tags
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM exercise_library el
      WHERE el.id = exercise_tags.exercise_id
      AND el.created_by = auth.uid()
    )
  );

-- Exercise media policies
CREATE POLICY "Media follows exercise visibility" ON exercise_media
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM exercise_library el
      WHERE el.id = exercise_media.exercise_id
      AND (el.is_public = TRUE OR el.created_by = auth.uid())
    )
  );

CREATE POLICY "Users can manage media on their exercises" ON exercise_media
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM exercise_library el
      WHERE el.id = exercise_media.exercise_id
      AND el.created_by = auth.uid()
    )
  );

-- Favorites policies
CREATE POLICY "Users can view their own favorites" ON exercise_favorites
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own favorites" ON exercise_favorites
  FOR ALL USING (user_id = auth.uid());

-- Alternatives policies (follow exercise visibility)
CREATE POLICY "Alternatives follow exercise visibility" ON exercise_alternatives
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM exercise_library el
      WHERE el.id = exercise_alternatives.exercise_id
      AND (el.is_public = TRUE OR el.created_by = auth.uid())
    )
  );

CREATE POLICY "Users can manage alternatives for their exercises" ON exercise_alternatives
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM exercise_library el
      WHERE el.id = exercise_alternatives.exercise_id
      AND el.created_by = auth.uid()
    )
  );

-- =====================================================
-- EXERCISE LIBRARY HELPER FUNCTIONS
-- =====================================================

-- Function to increment usage count when exercise is added to workout
CREATE OR REPLACE FUNCTION increment_exercise_usage()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE exercise_library
  SET usage_count = usage_count + 1
  WHERE name = NEW.name;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_increment_exercise_usage
  AFTER INSERT ON workout_exercises
  FOR EACH ROW
  EXECUTE FUNCTION increment_exercise_usage();

-- Function to search exercises with filters
CREATE OR REPLACE FUNCTION search_exercises(
  search_query TEXT DEFAULT NULL,
  muscle_groups_filter TEXT[] DEFAULT NULL,
  equipment_filter TEXT[] DEFAULT NULL,
  difficulty_filter TEXT DEFAULT NULL,
  category_filter TEXT DEFAULT NULL,
  include_custom BOOLEAN DEFAULT TRUE,
  user_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  category TEXT,
  primary_muscle_groups TEXT[],
  equipment_needed TEXT[],
  difficulty_level TEXT,
  video_url TEXT,
  thumbnail_url TEXT,
  is_public BOOLEAN,
  usage_count INTEGER,
  is_favorite BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    el.id,
    el.name,
    el.category,
    el.primary_muscle_groups,
    el.equipment_needed,
    el.difficulty_level,
    el.video_url,
    el.thumbnail_url,
    el.is_public,
    el.usage_count,
    EXISTS(
      SELECT 1 FROM exercise_favorites ef
      WHERE ef.exercise_id = el.id AND ef.user_id = user_id
    ) as is_favorite
  FROM exercise_library el
  WHERE
    -- Public or user's custom exercises
    (el.is_public = TRUE OR (include_custom AND el.created_by = user_id))
    -- Search query
    AND (search_query IS NULL OR el.search_vector @@ plainto_tsquery('english', search_query))
    -- Muscle groups filter
    AND (muscle_groups_filter IS NULL OR el.primary_muscle_groups && muscle_groups_filter)
    -- Equipment filter
    AND (equipment_filter IS NULL OR el.equipment_needed && equipment_filter)
    -- Difficulty filter
    AND (difficulty_filter IS NULL OR el.difficulty_level = difficulty_filter)
    -- Category filter
    AND (category_filter IS NULL OR el.category = category_filter)
  ORDER BY
    -- Favorites first
    is_favorite DESC,
    -- Then by usage
    el.usage_count DESC,
    -- Then alphabetically
    el.name ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get exercise alternatives
CREATE OR REPLACE FUNCTION get_exercise_alternatives(
  p_exercise_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  category TEXT,
  primary_muscle_groups TEXT[],
  equipment_needed TEXT[],
  difficulty_level TEXT,
  video_url TEXT,
  thumbnail_url TEXT,
  similarity_score DECIMAL,
  reason TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    el.id,
    el.name,
    el.category,
    el.primary_muscle_groups,
    el.equipment_needed,
    el.difficulty_level,
    el.video_url,
    el.thumbnail_url,
    ea.similarity_score,
    ea.reason
  FROM exercise_alternatives ea
  JOIN exercise_library el ON ea.alternative_id = el.id
  WHERE
    ea.exercise_id = p_exercise_id
    AND (p_reason IS NULL OR ea.reason = p_reason)
    AND (el.is_public = TRUE OR el.created_by = auth.uid())
  ORDER BY ea.similarity_score DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- EXERCISE LIBRARY COMMENTS
-- =====================================================

COMMENT ON TABLE exercise_library IS 'Comprehensive exercise database with multilingual support and custom exercises';
COMMENT ON TABLE exercise_tags IS 'Flexible tagging system for exercise categorization';
COMMENT ON TABLE exercise_media IS 'Multiple media files for exercise demonstrations from different angles';
COMMENT ON TABLE exercise_favorites IS 'User favorites for quick access to frequently used exercises';
COMMENT ON TABLE exercise_alternatives IS 'Exercise alternatives mapping with similarity scores';
COMMENT ON FUNCTION search_exercises IS 'Advanced exercise search with multiple filters';
COMMENT ON FUNCTION get_exercise_alternatives IS 'Retrieve alternative exercises based on similarity and reason';

COMMIT;