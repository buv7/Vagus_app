-- Direct SQL execution to fix missing tables
-- Execute this in Supabase SQL Editor

-- Create missing tables that the app expects
CREATE TABLE IF NOT EXISTS public.client_notes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    coach_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title text NOT NULL,
    content text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

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

-- Enable RLS
ALTER TABLE public.client_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plan_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_plan_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_workouts ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies
CREATE POLICY "client_notes_select_parties" ON public.client_notes
FOR SELECT USING (auth.uid() = client_id OR auth.uid() = coach_id);

CREATE POLICY "client_notes_insert_coach" ON public.client_notes
FOR INSERT WITH CHECK (auth.uid() = coach_id);

CREATE POLICY "workout_sessions_select_own" ON public.workout_sessions
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "workout_sessions_insert_own" ON public.workout_sessions
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "progress_photos_select_own" ON public.progress_photos
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "progress_photos_insert_own" ON public.progress_photos
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "client_metrics_select_own" ON public.client_metrics
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "client_metrics_insert_own" ON public.client_metrics
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "health_samples_select_own" ON public.health_samples
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "health_samples_insert_own" ON public.health_samples
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "sleep_segments_select_own" ON public.sleep_segments
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "sleep_segments_insert_own" ON public.sleep_segments
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "health_workouts_select_own" ON public.health_workouts
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "health_workouts_insert_own" ON public.health_workouts
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.client_notes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_plan_exercises TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.nutrition_plan_meals TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.progress_photos TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.client_metrics TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_samples TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sleep_segments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_workouts TO authenticated;

SELECT 'Database fix completed successfully!' as status;
