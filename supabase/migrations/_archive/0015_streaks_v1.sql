-- Streaks v1: Core schema for tracking user streaks and compliance
-- Migration: 0015_streaks_v1.sql

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===== STREAKS TABLE =====
-- Stores current and longest streak counts for users
CREATE TABLE public.streaks (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    current_count INTEGER NOT NULL DEFAULT 0 CHECK (current_count >= 0),
    longest_count INTEGER NOT NULL DEFAULT 0 CHECK (longest_count >= 0),
    shield_active BOOLEAN NOT NULL DEFAULT false,
    last_shield_awarded_on DATE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===== STREAK DAYS TABLE =====
-- Stores daily compliance records for streak calculations
CREATE TABLE public.streak_days (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    is_compliant BOOLEAN NOT NULL DEFAULT false,
    sources JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array of source strings
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, date)
);

-- ===== STREAK APPEALS TABLE =====
-- Stores user appeals for lost streaks
CREATE TABLE public.streak_appeals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lost_on DATE NOT NULL,
    reason TEXT NOT NULL CHECK (char_length(reason) >= 1 AND char_length(reason) <= 500),
    evidence_paths TEXT[] DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===== INDEXES =====
-- Performance optimization for common queries
CREATE INDEX idx_streak_days_user_date ON public.streak_days(user_id, date);
CREATE INDEX idx_streak_days_date ON public.streak_days(date);
CREATE INDEX idx_streak_days_compliant ON public.streak_days(is_compliant);

CREATE INDEX idx_streak_appeals_user_id ON public.streak_appeals(user_id);
CREATE INDEX idx_streak_appeals_lost_on ON public.streak_appeals(lost_on);
CREATE INDEX idx_streak_appeals_status ON public.streak_appeals(status);
CREATE INDEX idx_streak_appeals_user_lost ON public.streak_appeals(user_id, lost_on);

-- ===== ROW LEVEL SECURITY =====
-- Enable RLS on all tables
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streak_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streak_appeals ENABLE ROW LEVEL SECURITY;

-- ===== STREAKS POLICIES =====
-- Users can read and update their own streaks
CREATE POLICY "Users can view their own streaks" ON public.streaks
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own streaks" ON public.streaks
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own streaks" ON public.streaks
    FOR UPDATE USING (user_id = auth.uid());

-- Admins can read all streaks
CREATE POLICY "Admins can view all streaks" ON public.streaks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ===== STREAK DAYS POLICIES =====
-- Users can read and update their own streak days
CREATE POLICY "Users can view their own streak days" ON public.streak_days
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own streak days" ON public.streak_days
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own streak days" ON public.streak_days
    FOR UPDATE USING (user_id = auth.uid());

-- Admins can read all streak days
CREATE POLICY "Admins can view all streak days" ON public.streak_days
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ===== STREAK APPEALS POLICIES =====
-- Users can read and create their own appeals
CREATE POLICY "Users can view their own appeals" ON public.streak_appeals
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create appeals for themselves" ON public.streak_appeals
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Admins can read and update all appeals
CREATE POLICY "Admins can view all appeals" ON public.streak_appeals
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update appeals" ON public.streak_appeals
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ===== FUNCTIONS =====

-- Function to mark a day as compliant for a user
CREATE OR REPLACE FUNCTION mark_day_compliant(
    p_user_id UUID,
    p_date DATE,
    p_source TEXT
) RETURNS VOID AS $$
BEGIN
    -- Insert or update streak day record
    INSERT INTO public.streak_days (user_id, date, is_compliant, sources, computed_at)
    VALUES (p_user_id, p_date, true, jsonb_build_array(p_source), NOW())
    ON CONFLICT (user_id, date) DO UPDATE SET
        is_compliant = true,
        sources = streak_days.sources || jsonb_build_array(p_source),
        computed_at = NOW();
    
    -- Recompute streak for this user
    PERFORM recompute_streak(p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to recompute streak for a user
CREATE OR REPLACE FUNCTION recompute_streak(p_user_id UUID) RETURNS VOID AS $$
DECLARE
    v_current_count INTEGER := 0;
    v_longest_count INTEGER := 0;
    v_date DATE := CURRENT_DATE;
    v_day_record RECORD;
BEGIN
    -- Calculate current streak (consecutive days from today backwards)
    WHILE v_date >= CURRENT_DATE - INTERVAL '365 days' LOOP
        SELECT * INTO v_day_record
        FROM public.streak_days
        WHERE user_id = p_user_id AND date = v_date;
        
        IF v_day_record IS NULL OR NOT v_day_record.is_compliant THEN
            EXIT; -- Streak broken
        END IF;
        
        v_current_count := v_current_count + 1;
        v_date := v_date - INTERVAL '1 day';
    END LOOP;
    
    -- Calculate longest streak (scan all records)
    WITH streak_groups AS (
        SELECT 
            date,
            ROW_NUMBER() OVER (ORDER BY date) - ROW_NUMBER() OVER (PARTITION BY is_compliant ORDER BY date) as grp
        FROM public.streak_days
        WHERE user_id = p_user_id AND is_compliant = true
    ),
    streak_lengths AS (
        SELECT COUNT(*) as length
        FROM streak_groups
        GROUP BY grp
    )
    SELECT COALESCE(MAX(length), 0) INTO v_longest_count
    FROM streak_lengths;
    
    -- Update streaks table
    INSERT INTO public.streaks (user_id, current_count, longest_count, updated_at)
    VALUES (p_user_id, v_current_count, v_longest_count, NOW())
    ON CONFLICT (user_id) DO UPDATE SET
        current_count = EXCLUDED.current_count,
        longest_count = GREATEST(public.streaks.longest_count, EXCLUDED.longest_count),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get streak info for a user
CREATE OR REPLACE FUNCTION get_streak_info(p_user_id UUID)
RETURNS TABLE(
    current_count INTEGER,
    longest_count INTEGER,
    shield_active BOOLEAN,
    last_shield_awarded_on DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.current_count,
        s.longest_count,
        s.shield_active,
        s.last_shield_awarded_on
    FROM public.streaks s
    WHERE s.user_id = p_user_id;
    
    -- If no streak record exists, return zeros
    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 0, false, NULL::DATE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a day is compliant
CREATE OR REPLACE FUNCTION is_day_compliant(p_user_id UUID, p_date DATE)
RETURNS BOOLEAN AS $$
DECLARE
    v_compliant BOOLEAN;
BEGIN
    SELECT is_compliant INTO v_compliant
    FROM public.streak_days
    WHERE user_id = p_user_id AND date = p_date;
    
    RETURN COALESCE(v_compliant, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== TRIGGERS =====
-- Update updated_at timestamp on row update
CREATE OR REPLACE FUNCTION update_streaks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_streaks_updated_at
    BEFORE UPDATE ON public.streaks
    FOR EACH ROW EXECUTE FUNCTION update_streaks_updated_at();

-- ===== COMMENTS =====
COMMENT ON TABLE public.streaks IS 'Current and longest streak counts for users';
COMMENT ON TABLE public.streak_days IS 'Daily compliance records for streak calculations';
COMMENT ON TABLE public.streak_appeals IS 'User appeals for lost streaks';
COMMENT ON FUNCTION mark_day_compliant IS 'Mark a day as compliant and recompute streak';
COMMENT ON FUNCTION recompute_streak IS 'Recalculate streak counts for a user';
COMMENT ON FUNCTION get_streak_info IS 'Get current streak information for a user';
COMMENT ON FUNCTION is_day_compliant IS 'Check if a specific day is compliant for a user';
