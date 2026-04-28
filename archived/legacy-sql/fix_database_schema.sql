-- VAGUS App Database Schema Fix
-- This script creates all missing tables and columns identified from app logs

-- 1. Create progress_entries table
CREATE TABLE IF NOT EXISTS public.progress_entries (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    entry_type text NOT NULL, -- 'weight', 'measurement', 'photo', etc.
    value jsonb, -- Flexible data storage
    notes text,
    recorded_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 2. Create user_ranks table
CREATE TABLE IF NOT EXISTS public.user_ranks (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    rank_type text NOT NULL DEFAULT 'overall', -- 'overall', 'weekly', 'monthly'
    rank_value integer DEFAULT 0,
    total_score integer DEFAULT 0,
    rank_date date DEFAULT CURRENT_DATE,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(user_id, rank_type, rank_date)
);

-- 3. Create user_streaks table
CREATE TABLE IF NOT EXISTS public.user_streaks (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    streak_type text NOT NULL, -- 'workout', 'nutrition', 'checkin', 'overall'
    current_streak integer DEFAULT 0,
    longest_streak integer DEFAULT 0,
    last_activity_date date,
    streak_start_date date,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(user_id, streak_type)
);

-- 4. Create ads table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.ads (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text NOT NULL,
    description text,
    image_url text,
    link_url text,
    target_audience jsonb, -- {'roles': ['client', 'coach'], 'demographics': {...}}
    active boolean DEFAULT true,
    priority integer DEFAULT 0,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 5. Create v_current_ads view
CREATE OR REPLACE VIEW public.v_current_ads AS
SELECT *
FROM public.ads
WHERE active = true
  AND (start_date IS NULL OR start_date <= now())
  AND (end_date IS NULL OR end_date >= now())
ORDER BY priority DESC, created_at DESC;

-- 6. Add revoke column to user_devices table (if it exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_devices') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                      WHERE table_name = 'user_devices' AND column_name = 'revoke') THEN
            ALTER TABLE public.user_devices ADD COLUMN revoke boolean DEFAULT false;
        END IF;
    END IF;
END $$;

-- 7. Enable Row Level Security on new tables
ALTER TABLE public.progress_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_ranks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ads ENABLE ROW LEVEL SECURITY;

-- 8. Create RLS policies for progress_entries
CREATE POLICY "Users can view own progress entries" ON public.progress_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress entries" ON public.progress_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress entries" ON public.progress_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own progress entries" ON public.progress_entries
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Create RLS policies for user_ranks
CREATE POLICY "Users can view own ranks" ON public.user_ranks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can manage user ranks" ON public.user_ranks
    FOR ALL USING (true); -- Allow system operations

-- 10. Create RLS policies for user_streaks
CREATE POLICY "Users can view own streaks" ON public.user_streaks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own streaks" ON public.user_streaks
    FOR ALL USING (auth.uid() = user_id);

-- 11. Create RLS policies for ads
CREATE POLICY "Anyone can view active ads" ON public.ads
    FOR SELECT USING (active = true);

CREATE POLICY "Admins can manage ads" ON public.ads
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 12. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_progress_entries_user_id ON public.progress_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_entries_type_date ON public.progress_entries(entry_type, recorded_at);
CREATE INDEX IF NOT EXISTS idx_user_ranks_user_type ON public.user_ranks(user_id, rank_type);
CREATE INDEX IF NOT EXISTS idx_user_streaks_user_type ON public.user_streaks(user_id, streak_type);
CREATE INDEX IF NOT EXISTS idx_ads_active_priority ON public.ads(active, priority) WHERE active = true;

-- 13. Insert sample data for testing (optional)
INSERT INTO public.ads (title, description, active, priority) VALUES
('Welcome to VAGUS', 'Start your fitness journey today!', true, 1),
('Premium Features', 'Upgrade to unlock advanced analytics', true, 2)
ON CONFLICT DO NOTHING;

-- 14. Create functions for common operations
CREATE OR REPLACE FUNCTION public.update_user_streak(
    p_user_id uuid,
    p_streak_type text,
    p_activity_date date DEFAULT CURRENT_DATE
) RETURNS void AS $$
BEGIN
    INSERT INTO public.user_streaks (user_id, streak_type, current_streak, last_activity_date, streak_start_date)
    VALUES (p_user_id, p_streak_type, 1, p_activity_date, p_activity_date)
    ON CONFLICT (user_id, streak_type)
    DO UPDATE SET
        current_streak = CASE
            WHEN user_streaks.last_activity_date = p_activity_date - INTERVAL '1 day'
            THEN user_streaks.current_streak + 1
            WHEN user_streaks.last_activity_date = p_activity_date
            THEN user_streaks.current_streak
            ELSE 1
        END,
        longest_streak = GREATEST(
            user_streaks.longest_streak,
            CASE
                WHEN user_streaks.last_activity_date = p_activity_date - INTERVAL '1 day'
                THEN user_streaks.current_streak + 1
                WHEN user_streaks.last_activity_date = p_activity_date
                THEN user_streaks.current_streak
                ELSE 1
            END
        ),
        last_activity_date = p_activity_date,
        streak_start_date = CASE
            WHEN user_streaks.last_activity_date != p_activity_date - INTERVAL '1 day'
            AND user_streaks.last_activity_date != p_activity_date
            THEN p_activity_date
            ELSE user_streaks.streak_start_date
        END,
        updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- VAGUS App Database Schema Fix - Creates missing tables and resolves app errors