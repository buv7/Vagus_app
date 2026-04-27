-- Comprehensive Database Fix for Vagus App
-- This script checks for missing tables, policies, and fixes any issues

-- ==============================================
-- CREATE MISSING TABLES
-- ==============================================

-- client_notes table
CREATE TABLE IF NOT EXISTS public.client_notes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    coach_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title text NOT NULL,
    content text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- workout_plan_exercises table
CREATE TABLE IF NOT EXISTS public.workout_plan_exercises (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id uuid NOT NULL REFERENCES public.workout_plans(id) ON DELETE CASCADE,
    exercise_name text NOT NULL,
    sets integer,
    reps integer,
    weight decimal,
    duration_minutes integer,
    rest_seconds integer,
    notes text,
    day_of_week integer CHECK (day_of_week >= 0 AND day_of_week <= 6),
    week_number integer DEFAULT 1,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- nutrition_plan_meals table
CREATE TABLE IF NOT EXISTS public.nutrition_plan_meals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id uuid NOT NULL REFERENCES public.nutrition_plans(id) ON DELETE CASCADE,
    meal_name text NOT NULL,
    meal_type text NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    calories integer,
    protein decimal,
    carbs decimal,
    fat decimal,
    fiber decimal,
    day_of_week integer CHECK (day_of_week >= 0 AND day_of_week <= 6),
    week_number integer DEFAULT 1,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- workout_sessions table
CREATE TABLE IF NOT EXISTS public.workout_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_id uuid REFERENCES public.workout_plans(id) ON DELETE SET NULL,
    session_name text NOT NULL,
    started_at timestamptz NOT NULL DEFAULT now(),
    ended_at timestamptz,
    total_duration_minutes integer,
    calories_burned integer,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- progress_photos table
CREATE TABLE IF NOT EXISTS public.progress_photos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    photo_url text NOT NULL,
    photo_type text NOT NULL CHECK (photo_type IN ('front', 'side', 'back', 'other')),
    taken_at timestamptz NOT NULL DEFAULT now(),
    weight decimal,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- client_metrics table
CREATE TABLE IF NOT EXISTS public.client_metrics (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    metric_type text NOT NULL,
    metric_value decimal NOT NULL,
    metric_unit text,
    recorded_at timestamptz NOT NULL DEFAULT now(),
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- health_samples table
CREATE TABLE IF NOT EXISTS public.health_samples (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sample_type text NOT NULL,
    value decimal NOT NULL,
    unit text,
    recorded_at timestamptz NOT NULL DEFAULT now(),
    source text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- sleep_segments table
CREATE TABLE IF NOT EXISTS public.sleep_segments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sleep_type text NOT NULL CHECK (sleep_type IN ('deep', 'light', 'rem', 'awake')),
    start_time timestamptz NOT NULL,
    end_time timestamptz NOT NULL,
    duration_minutes integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- health_workouts table
CREATE TABLE IF NOT EXISTS public.health_workouts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    workout_type text NOT NULL,
    start_time timestamptz NOT NULL,
    end_time timestamptz,
    duration_minutes integer,
    calories_burned integer,
    distance_km decimal,
    heart_rate_avg integer,
    heart_rate_max integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ==============================================
-- CREATE MISSING INDEXES
-- ==============================================

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_client_notes_client_id ON public.client_notes(client_id);
CREATE INDEX IF NOT EXISTS idx_client_notes_coach_id ON public.client_notes(coach_id);
CREATE INDEX IF NOT EXISTS idx_client_notes_created_at ON public.client_notes(created_at);

CREATE INDEX IF NOT EXISTS idx_workout_plan_exercises_plan_id ON public.workout_plan_exercises(plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_plan_exercises_day_week ON public.workout_plan_exercises(day_of_week, week_number);

CREATE INDEX IF NOT EXISTS idx_nutrition_plan_meals_plan_id ON public.nutrition_plan_meals(plan_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plan_meals_day_week ON public.nutrition_plan_meals(day_of_week, week_number);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id ON public.workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_started_at ON public.workout_sessions(started_at);

CREATE INDEX IF NOT EXISTS idx_progress_photos_user_id ON public.progress_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_photos_taken_at ON public.progress_photos(taken_at);

CREATE INDEX IF NOT EXISTS idx_client_metrics_user_id ON public.client_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_client_metrics_recorded_at ON public.client_metrics(recorded_at);

CREATE INDEX IF NOT EXISTS idx_health_samples_user_id ON public.health_samples(user_id);
CREATE INDEX IF NOT EXISTS idx_health_samples_recorded_at ON public.health_samples(recorded_at);

CREATE INDEX IF NOT EXISTS idx_sleep_segments_user_id ON public.sleep_segments(user_id);
CREATE INDEX IF NOT EXISTS idx_sleep_segments_start_time ON public.sleep_segments(start_time);

CREATE INDEX IF NOT EXISTS idx_health_workouts_user_id ON public.health_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_health_workouts_start_time ON public.health_workouts(start_time);

-- ==============================================
-- ENABLE ROW LEVEL SECURITY
-- ==============================================

ALTER TABLE public.client_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plan_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_plan_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_workouts ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- CREATE RLS POLICIES
-- ==============================================

-- client_notes policies
DROP POLICY IF EXISTS "client_notes_select_parties" ON public.client_notes;
CREATE POLICY "client_notes_select_parties" ON public.client_notes
FOR SELECT USING (auth.uid() = client_id OR auth.uid() = coach_id);

DROP POLICY IF EXISTS "client_notes_insert_coach" ON public.client_notes;
CREATE POLICY "client_notes_insert_coach" ON public.client_notes
FOR INSERT WITH CHECK (auth.uid() = coach_id);

DROP POLICY IF EXISTS "client_notes_update_coach" ON public.client_notes;
CREATE POLICY "client_notes_update_coach" ON public.client_notes
FOR UPDATE USING (auth.uid() = coach_id);

-- workout_plan_exercises policies
DROP POLICY IF EXISTS "workout_exercises_select_plan_access" ON public.workout_plan_exercises;
CREATE POLICY "workout_exercises_select_plan_access" ON public.workout_plan_exercises
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.workout_plans wp 
        WHERE wp.id = workout_plan_exercises.plan_id 
        AND (wp.coach_id = auth.uid() OR 
             EXISTS (
                 SELECT 1 FROM public.plan_assignments pa 
                 WHERE pa.plan_id = wp.id 
                 AND pa.plan_type = 'workout' 
                 AND pa.client_id = auth.uid()
             ))
    )
);

DROP POLICY IF EXISTS "workout_exercises_insert_coach" ON public.workout_plan_exercises;
CREATE POLICY "workout_exercises_insert_coach" ON public.workout_plan_exercises
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.workout_plans wp 
        WHERE wp.id = workout_plan_exercises.plan_id 
        AND wp.coach_id = auth.uid()
    )
);

-- nutrition_plan_meals policies
DROP POLICY IF EXISTS "nutrition_meals_select_plan_access" ON public.nutrition_plan_meals;
CREATE POLICY "nutrition_meals_select_plan_access" ON public.nutrition_plan_meals
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.nutrition_plans np 
        WHERE np.id = nutrition_plan_meals.plan_id 
        AND (np.coach_id = auth.uid() OR 
             EXISTS (
                 SELECT 1 FROM public.plan_assignments pa 
                 WHERE pa.plan_id = np.id 
                 AND pa.plan_type = 'nutrition' 
                 AND pa.client_id = auth.uid()
             ))
    )
);

DROP POLICY IF EXISTS "nutrition_meals_insert_coach" ON public.nutrition_plan_meals;
CREATE POLICY "nutrition_meals_insert_coach" ON public.nutrition_plan_meals
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.nutrition_plans np 
        WHERE np.id = nutrition_plan_meals.plan_id 
        AND np.coach_id = auth.uid()
    )
);

-- workout_sessions policies
DROP POLICY IF EXISTS "workout_sessions_select_own" ON public.workout_sessions;
CREATE POLICY "workout_sessions_select_own" ON public.workout_sessions
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "workout_sessions_insert_own" ON public.workout_sessions;
CREATE POLICY "workout_sessions_insert_own" ON public.workout_sessions
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- progress_photos policies
DROP POLICY IF EXISTS "progress_photos_select_own" ON public.progress_photos;
CREATE POLICY "progress_photos_select_own" ON public.progress_photos
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "progress_photos_insert_own" ON public.progress_photos;
CREATE POLICY "progress_photos_insert_own" ON public.progress_photos
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- client_metrics policies
DROP POLICY IF EXISTS "client_metrics_select_own" ON public.client_metrics;
CREATE POLICY "client_metrics_select_own" ON public.client_metrics
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "client_metrics_insert_own" ON public.client_metrics;
CREATE POLICY "client_metrics_insert_own" ON public.client_metrics
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- health_samples policies
DROP POLICY IF EXISTS "health_samples_select_own" ON public.health_samples;
CREATE POLICY "health_samples_select_own" ON public.health_samples
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "health_samples_insert_own" ON public.health_samples;
CREATE POLICY "health_samples_insert_own" ON public.health_samples
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- sleep_segments policies
DROP POLICY IF EXISTS "sleep_segments_select_own" ON public.sleep_segments;
CREATE POLICY "sleep_segments_select_own" ON public.sleep_segments
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "sleep_segments_insert_own" ON public.sleep_segments;
CREATE POLICY "sleep_segments_insert_own" ON public.sleep_segments
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- health_workouts policies
DROP POLICY IF EXISTS "health_workouts_select_own" ON public.health_workouts;
CREATE POLICY "health_workouts_select_own" ON public.health_workouts
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "health_workouts_insert_own" ON public.health_workouts;
CREATE POLICY "health_workouts_insert_own" ON public.health_workouts
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ==============================================
-- CREATE UPDATED_AT TRIGGERS
-- ==============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_client_notes_updated_at ON public.client_notes;
CREATE TRIGGER update_client_notes_updated_at
    BEFORE UPDATE ON public.client_notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_workout_plan_exercises_updated_at ON public.workout_plan_exercises;
CREATE TRIGGER update_workout_plan_exercises_updated_at
    BEFORE UPDATE ON public.workout_plan_exercises
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_nutrition_plan_meals_updated_at ON public.nutrition_plan_meals;
CREATE TRIGGER update_nutrition_plan_meals_updated_at
    BEFORE UPDATE ON public.nutrition_plan_meals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_workout_sessions_updated_at ON public.workout_sessions;
CREATE TRIGGER update_workout_sessions_updated_at
    BEFORE UPDATE ON public.workout_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_progress_photos_updated_at ON public.progress_photos;
CREATE TRIGGER update_progress_photos_updated_at
    BEFORE UPDATE ON public.progress_photos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_client_metrics_updated_at ON public.client_metrics;
CREATE TRIGGER update_client_metrics_updated_at
    BEFORE UPDATE ON public.client_metrics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_health_samples_updated_at ON public.health_samples;
CREATE TRIGGER update_health_samples_updated_at
    BEFORE UPDATE ON public.health_samples
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sleep_segments_updated_at ON public.sleep_segments;
CREATE TRIGGER update_sleep_segments_updated_at
    BEFORE UPDATE ON public.sleep_segments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_health_workouts_updated_at ON public.health_workouts;
CREATE TRIGGER update_health_workouts_updated_at
    BEFORE UPDATE ON public.health_workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- GRANT PERMISSIONS
-- ==============================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.client_notes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_plan_exercises TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.nutrition_plan_meals TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.progress_photos TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.client_metrics TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_samples TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sleep_segments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_workouts TO authenticated;

-- ==============================================
-- VERIFICATION
-- ==============================================

SELECT 'Comprehensive database fix completed successfully!' as status;

