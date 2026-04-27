-- =====================================================
-- REMOVE MOCK DATA - ADD REAL DATABASE INFRASTRUCTURE
-- Migration to support real data instead of hardcoded mocks
-- Created: 2025-10-02
-- =====================================================

BEGIN;

-- =====================================================
-- PART 1: WORKOUT LOGS TABLE (Exercise History)
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  workout_plan_id UUID REFERENCES workout_plans(id) ON DELETE SET NULL,
  exercise_name TEXT NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,

  -- Set data
  weight NUMERIC(10,2), -- Weight in kg or lbs
  reps INTEGER,
  sets INTEGER,
  rir NUMERIC(3,1), -- Reps in reserve (0-5)

  -- Metadata
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for workout_logs
CREATE INDEX IF NOT EXISTS idx_workout_logs_client_id ON workout_logs(client_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_coach_id ON workout_logs(coach_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_exercise_name ON workout_logs(exercise_name);
CREATE INDEX IF NOT EXISTS idx_workout_logs_date ON workout_logs(date DESC);
CREATE INDEX IF NOT EXISTS idx_workout_logs_client_exercise ON workout_logs(client_id, exercise_name, date DESC);

-- RLS Policies for workout_logs
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;

-- Users can view their own workout logs
CREATE POLICY "Users can view their own workout logs"
  ON workout_logs FOR SELECT
  USING (auth.uid() = client_id);

-- Coaches can view their clients' workout logs
CREATE POLICY "Coaches can view client workout logs"
  ON workout_logs FOR SELECT
  USING (
    auth.uid() = coach_id
    OR auth.uid() IN (
      SELECT coach_id FROM coach_clients WHERE client_id = workout_logs.client_id
    )
  );

-- Clients can insert their own workout logs
CREATE POLICY "Clients can insert their own workout logs"
  ON workout_logs FOR INSERT
  WITH CHECK (auth.uid() = client_id);

-- Coaches can insert logs for their clients
CREATE POLICY "Coaches can insert logs for clients"
  ON workout_logs FOR INSERT
  WITH CHECK (
    auth.uid() = coach_id
    OR auth.uid() IN (
      SELECT coach_id FROM coach_clients WHERE client_id = workout_logs.client_id
    )
  );

-- Users can update their own logs
CREATE POLICY "Users can update their own workout logs"
  ON workout_logs FOR UPDATE
  USING (auth.uid() = client_id)
  WITH CHECK (auth.uid() = client_id);

-- Users can delete their own logs
CREATE POLICY "Users can delete their own workout logs"
  ON workout_logs FOR DELETE
  USING (auth.uid() = client_id);

-- =====================================================
-- PART 2: EXERCISES LIBRARY TABLE (Exercise Database)
-- =====================================================

CREATE TABLE IF NOT EXISTS exercises_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  name_ar TEXT, -- Arabic translation
  name_ku TEXT, -- Kurdish translation
  description TEXT,
  muscle_group TEXT NOT NULL, -- 'chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'full_body'
  secondary_muscles TEXT[], -- Array of secondary muscle groups
  equipment_needed TEXT[], -- Array of equipment: ['barbell', 'dumbbells', 'machine', 'bodyweight', 'cables', 'resistance_bands']
  difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),

  -- Media
  video_url TEXT,
  image_url TEXT,
  thumbnail_url TEXT,

  -- Metadata
  is_compound BOOLEAN DEFAULT false, -- Compound vs isolation exercise
  tags TEXT[] DEFAULT '{}', -- Additional tags for filtering
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Indexes for exercises_library
CREATE INDEX IF NOT EXISTS idx_exercises_library_muscle_group ON exercises_library(muscle_group);
CREATE INDEX IF NOT EXISTS idx_exercises_library_difficulty ON exercises_library(difficulty);
CREATE INDEX IF NOT EXISTS idx_exercises_library_name_trgm ON exercises_library USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_exercises_library_tags ON exercises_library USING gin (tags);

-- RLS Policies for exercises_library
ALTER TABLE exercises_library ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can view exercises library
CREATE POLICY "Anyone can view exercises library"
  ON exercises_library FOR SELECT
  USING (true);

-- Only admins can insert/update/delete (for now, allow coaches too)
CREATE POLICY "Coaches can add exercises to library"
  ON exercises_library FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('coach', 'admin')
    )
  );

CREATE POLICY "Coaches can update exercises in library"
  ON exercises_library FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('coach', 'admin')
    )
  );

-- =====================================================
-- PART 3: SEED INITIAL EXERCISE DATA
-- =====================================================

-- Insert basic exercises (safe to run multiple times - ON CONFLICT DO NOTHING)
INSERT INTO exercises_library (name, name_ar, name_ku, muscle_group, equipment_needed, difficulty, is_compound) VALUES
  -- CHEST
  ('Bench Press', 'ضغط الصدر', 'پرێس سینگ', 'chest', ARRAY['barbell'], 'intermediate', true),
  ('Incline Bench Press', 'ضغط صدر علوي', 'پرێسی سینگی سەرەوە', 'chest', ARRAY['barbell'], 'intermediate', true),
  ('Dumbbell Press', 'ضغط صدر دمبل', 'پرێس بە دەمبێڵ', 'chest', ARRAY['dumbbells'], 'beginner', true),
  ('Push-ups', 'تمارين الضغط', 'پاڵپشت', 'chest', ARRAY['bodyweight'], 'beginner', true),
  ('Dumbbell Flyes', 'تمارين الفتح', 'فڵای دەمبێڵ', 'chest', ARRAY['dumbbells'], 'intermediate', false),
  ('Cable Crossover', 'تمارين الكيبل', 'کراسۆڤەری کەیبڵ', 'chest', ARRAY['cables'], 'intermediate', false),

  -- BACK
  ('Pull-ups', 'شد عقلة', 'پوڵ ئەپ', 'back', ARRAY['bodyweight'], 'intermediate', true),
  ('Barbell Row', 'سحب بار', 'ڕۆی بار', 'back', ARRAY['barbell'], 'intermediate', true),
  ('Lat Pulldown', 'سحب لات', 'لات پوڵداون', 'back', ARRAY['machine'], 'beginner', true),
  ('Seated Row', 'سحب جالس', 'ڕۆی دانیشتوو', 'back', ARRAY['cables', 'machine'], 'beginner', true),
  ('Deadlift', 'رفعة ميتة', 'دێدلیفت', 'back', ARRAY['barbell'], 'advanced', true),

  -- LEGS
  ('Squat', 'قرفصاء', 'سکوات', 'legs', ARRAY['barbell'], 'beginner', true),
  ('Leg Press', 'ضغط رجل', 'لێگ پرێس', 'legs', ARRAY['machine'], 'beginner', true),
  ('Romanian Deadlift', 'رفعة ميتة رومانية', 'ڕۆمانیان دێدلیفت', 'legs', ARRAY['barbell'], 'intermediate', true),
  ('Lunges', 'اندفاع', 'لەنج', 'legs', ARRAY['dumbbells', 'bodyweight'], 'beginner', true),
  ('Leg Curl', 'لف ساق خلفي', 'لێگ کەرڵ', 'legs', ARRAY['machine'], 'beginner', false),
  ('Leg Extension', 'تمديد ساق', 'لێگ ئێکستێنشن', 'legs', ARRAY['machine'], 'beginner', false),
  ('Calf Raise', 'رفع سمانة', 'کاف ڕەیز', 'legs', ARRAY['machine', 'dumbbells'], 'beginner', false),

  -- SHOULDERS
  ('Overhead Press', 'ضغط فوق الرأس', 'ئۆڤەرهێد پرێس', 'shoulders', ARRAY['barbell'], 'intermediate', true),
  ('Dumbbell Shoulder Press', 'ضغط كتف دمبل', 'شانە پرێس', 'shoulders', ARRAY['dumbbells'], 'beginner', true),
  ('Lateral Raise', 'رفع جانبي', 'لاتراڵ ڕەیز', 'shoulders', ARRAY['dumbbells'], 'beginner', false),
  ('Front Raise', 'رفع أمامي', 'فرۆنت ڕەیز', 'shoulders', ARRAY['dumbbells'], 'beginner', false),
  ('Face Pull', 'سحب وجه', 'فەیس پوڵ', 'shoulders', ARRAY['cables'], 'beginner', false),

  -- ARMS
  ('Barbell Curl', 'لف بايسبس بار', 'بار کەرڵ', 'arms', ARRAY['barbell'], 'beginner', false),
  ('Dumbbell Curl', 'لف بايسبس دمبل', 'دەمبێڵ کەرڵ', 'arms', ARRAY['dumbbells'], 'beginner', false),
  ('Hammer Curl', 'لف مطرقة', 'هامەر کەرڵ', 'arms', ARRAY['dumbbells'], 'beginner', false),
  ('Tricep Dip', 'غطس تراي', 'تریسێپ دیپ', 'arms', ARRAY['bodyweight'], 'intermediate', true),
  ('Tricep Extension', 'تمديد تراي', 'تریسێپ ئێکستێنشن', 'arms', ARRAY['dumbbells', 'cables'], 'beginner', false),
  ('Close-Grip Bench', 'ضغط قبضة ضيقة', 'کلۆز گریپ بێنچ', 'arms', ARRAY['barbell'], 'intermediate', true),

  -- CORE
  ('Plank', 'تمرين اللوح', 'پلانک', 'core', ARRAY['bodyweight'], 'beginner', false),
  ('Crunches', 'تمارين البطن', 'کرانچ', 'core', ARRAY['bodyweight'], 'beginner', false),
  ('Russian Twist', 'التواء روسي', 'ڕەشیان تویست', 'core', ARRAY['bodyweight', 'dumbbells'], 'beginner', false),
  ('Hanging Leg Raise', 'رفع ساق معلق', 'هانگینگ لێگ ڕەیز', 'core', ARRAY['bodyweight'], 'intermediate', false),
  ('Ab Wheel', 'عجلة البطن', 'ئاب ویڵ', 'core', ARRAY['bodyweight'], 'advanced', false)

ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- PART 4: VERIFY FOOD_ITEMS TABLE EXISTS
-- =====================================================

-- The food_items table already exists from 0005_nutrition_food_catalog.sql
-- We'll just verify it has the right structure and add any missing columns

-- Ensure food_items has all necessary columns (safe - will only add if missing)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'food_items' AND column_name = 'category'
  ) THEN
    ALTER TABLE food_items ADD COLUMN category TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'food_items' AND column_name = 'fiber_g'
  ) THEN
    ALTER TABLE food_items ADD COLUMN fiber_g NUMERIC(10,2);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'food_items' AND column_name = 'is_mena_food'
  ) THEN
    ALTER TABLE food_items ADD COLUMN is_mena_food BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Add some additional MENA foods if they don't exist
INSERT INTO food_items (name_en, name_ar, name_ku, kcal, protein_g, carbs_g, fat_g, sodium_mg, potassium_mg, tags, is_mena_food)
SELECT * FROM (VALUES
  ('Basmati Rice (cooked)', 'أرز بسمتي مطبوخ', 'برنجی بازماتی پێوە', 121, 2.7, 28.0, 0.3, 1, 35, ARRAY['carb', 'grain', 'regional'], true),
  ('Bulgur Wheat', 'برغل', 'بورگول', 83, 3.1, 18.0, 0.2, 5, 68, ARRAY['carb', 'grain', 'regional'], true),
  ('Falafel', 'فلافل', 'فەلافەڵ', 333, 13.3, 31.8, 17.8, 294, 585, ARRAY['protein', 'vegetarian', 'regional'], true),
  ('Hummus', 'حمص', 'هەمووس', 166, 7.9, 14.3, 9.6, 379, 228, ARRAY['protein', 'vegetarian', 'regional'], true),
  ('Tabbouleh', 'تبولة', 'تەبوولە', 36, 1.3, 5.9, 1.0, 164, 148, ARRAY['vegetable', 'salad', 'regional'], true),
  ('Labneh', 'لبنة', 'لەبنە', 100, 4.0, 4.0, 7.0, 85, 150, ARRAY['dairy', 'protein', 'regional'], true),
  ('Shawarma (chicken)', 'شاورما دجاج', 'شەوەرمای مریشک', 175, 28.0, 5.0, 6.0, 520, 320, ARRAY['protein', 'meat', 'regional'], true),
  ('Pita Bread', 'خبز عربي', 'نانی پیتا', 275, 9.1, 55.7, 1.2, 536, 120, ARRAY['carb', 'bread', 'regional'], true),
  ('Dolma', 'دولما', 'دۆڵمە', 90, 2.5, 12.0, 3.5, 310, 180, ARRAY['vegetable', 'rice', 'regional'], true)
) AS t(name_en, name_ar, name_ku, kcal, protein_g, carbs_g, fat_g, sodium_mg, potassium_mg, tags, is_mena_food)
WHERE NOT EXISTS (
  SELECT 1 FROM food_items f WHERE f.name_en = t.name_en
);

-- =====================================================
-- PART 5: ADD HELPFUL FUNCTIONS
-- =====================================================

-- Function to get recent exercise history for a client
CREATE OR REPLACE FUNCTION get_exercise_history(
  p_client_id UUID,
  p_exercise_name TEXT,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  date DATE,
  weight NUMERIC,
  reps INTEGER,
  sets INTEGER,
  rir NUMERIC,
  est_1rm NUMERIC,
  notes TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    wl.date,
    wl.weight,
    wl.reps,
    wl.sets,
    wl.rir,
    -- Calculate estimated 1RM using Epley formula: weight * (1 + reps/30)
    CASE
      WHEN wl.weight IS NOT NULL AND wl.reps IS NOT NULL AND wl.reps > 0 AND wl.reps <= 12
      THEN wl.weight * (1.0 + wl.reps / 30.0)
      ELSE NULL
    END AS est_1rm,
    wl.notes
  FROM workout_logs wl
  WHERE wl.client_id = p_client_id
    AND LOWER(TRIM(wl.exercise_name)) = LOWER(TRIM(p_exercise_name))
  ORDER BY wl.date DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search exercises by muscle group
CREATE OR REPLACE FUNCTION search_exercises(
  p_muscle_group TEXT DEFAULT NULL,
  p_difficulty TEXT DEFAULT NULL,
  p_search_term TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  name_ar TEXT,
  name_ku TEXT,
  description TEXT,
  muscle_group TEXT,
  equipment_needed TEXT[],
  difficulty TEXT,
  is_compound BOOLEAN,
  video_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.name,
    e.name_ar,
    e.name_ku,
    e.description,
    e.muscle_group,
    e.equipment_needed,
    e.difficulty,
    e.is_compound,
    e.video_url
  FROM exercises_library e
  WHERE
    (p_muscle_group IS NULL OR e.muscle_group = p_muscle_group)
    AND (p_difficulty IS NULL OR e.difficulty = p_difficulty)
    AND (
      p_search_term IS NULL
      OR e.name ILIKE '%' || p_search_term || '%'
      OR e.name_ar ILIKE '%' || p_search_term || '%'
      OR e.name_ku ILIKE '%' || p_search_term || '%'
    )
  ORDER BY
    CASE WHEN e.is_compound THEN 0 ELSE 1 END, -- Compound exercises first
    e.name
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PART 6: UPDATE TRIGGERS
-- =====================================================

-- Trigger to update updated_at on workout_logs
CREATE OR REPLACE FUNCTION update_workout_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workout_logs_updated_at
  BEFORE UPDATE ON workout_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_logs_updated_at();

-- Trigger to update updated_at on exercises_library
CREATE OR REPLACE FUNCTION update_exercises_library_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exercises_library_updated_at
  BEFORE UPDATE ON exercises_library
  FOR EACH ROW
  EXECUTE FUNCTION update_exercises_library_updated_at();

COMMIT;

-- =====================================================
-- VERIFICATION
-- =====================================================

SELECT 'Mock data infrastructure migration completed successfully!' AS status;
SELECT COUNT(*) AS exercise_count FROM exercises_library;
SELECT COUNT(*) AS food_count FROM food_items;
