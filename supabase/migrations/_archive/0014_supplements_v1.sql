-- Supplements v1: Core schema for supplement tracking and scheduling
-- Migration: 0014_supplements_v1.sql

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===== SUPPLEMENTS TABLE =====
-- Stores supplement definitions (name, dosage, instructions, etc.)
CREATE TABLE public.supplements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL CHECK (char_length(name) >= 1 AND char_length(name) <= 100),
    dosage TEXT NOT NULL CHECK (char_length(dosage) >= 1 AND char_length(dosage) <= 100),
    instructions TEXT CHECK (char_length(instructions) <= 500),
    category TEXT NOT NULL DEFAULT 'general' CHECK (category IN ('vitamin', 'mineral', 'protein', 'pre_workout', 'post_workout', 'omega', 'probiotic', 'herbal', 'general')),
    color TEXT DEFAULT '#6C83F7' CHECK (char_length(color) <= 7), -- Hex color for UI
    icon TEXT DEFAULT 'medication' CHECK (char_length(icon) <= 50), -- Material icon name
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL for coach-created templates
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===== SUPPLEMENT SCHEDULES TABLE =====
-- Stores when and how often supplements should be taken
CREATE TABLE public.supplement_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplement_id UUID NOT NULL REFERENCES public.supplements(id) ON DELETE CASCADE,
    schedule_type TEXT NOT NULL CHECK (schedule_type IN ('daily', 'weekly', 'custom')),
    frequency TEXT NOT NULL CHECK (char_length(frequency) <= 100), -- e.g., "2x daily", "every 8 hours"
    times_per_day INTEGER NOT NULL CHECK (times_per_day >= 1 AND times_per_day <= 10),
    specific_times TIME[], -- Array of specific times (e.g., ['08:00', '20:00'])
    interval_hours INTEGER CHECK (interval_hours >= 1 AND interval_hours <= 24), -- For "every N hours" (Pro feature)
    days_of_week INTEGER[] CHECK (array_length(days_of_week, 1) <= 7), -- 1=Monday, 7=Sunday
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE, -- NULL for indefinite
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===== SUPPLEMENT LOGS TABLE =====
-- Stores actual supplement intake records
CREATE TABLE public.supplement_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplement_id UUID NOT NULL REFERENCES public.supplements(id) ON DELETE CASCADE,
    schedule_id UUID REFERENCES public.supplement_schedules(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'taken' CHECK (status IN ('taken', 'skipped', 'snoozed')),
    notes TEXT CHECK (char_length(notes) <= 500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===== INDEXES =====
-- Performance optimization for common queries
CREATE INDEX idx_supplements_created_by ON public.supplements(created_by);
CREATE INDEX idx_supplements_client_id ON public.supplements(client_id);
CREATE INDEX idx_supplements_is_active ON public.supplements(is_active);
CREATE INDEX idx_supplements_category ON public.supplements(category);

CREATE INDEX idx_supplement_schedules_supplement_id ON public.supplement_schedules(supplement_id);
CREATE INDEX idx_supplement_schedules_created_by ON public.supplement_schedules(created_by);
CREATE INDEX idx_supplement_schedules_is_active ON public.supplement_schedules(is_active);
CREATE INDEX idx_supplement_schedules_start_date ON public.supplement_schedules(start_date);

CREATE INDEX idx_supplement_logs_user_id ON public.supplement_logs(user_id);
CREATE INDEX idx_supplement_logs_supplement_id ON public.supplement_logs(supplement_id);
CREATE INDEX idx_supplement_logs_taken_at ON public.supplement_logs(taken_at);
CREATE INDEX idx_supplement_logs_status ON public.supplement_logs(status);
CREATE INDEX idx_supplement_logs_user_date ON public.supplement_logs(user_id, taken_at);

-- ===== ROW LEVEL SECURITY =====
-- Enable RLS on all tables
ALTER TABLE public.supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplement_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplement_logs ENABLE ROW LEVEL SECURITY;

-- ===== SUPPLEMENTS POLICIES =====
-- Users can see supplements they created or that were created for them
CREATE POLICY "Users can view their own supplements" ON public.supplements
    FOR SELECT USING (
        created_by = auth.uid() OR 
        client_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'coach'
        )
    );

-- Users can create supplements
CREATE POLICY "Users can create supplements" ON public.supplements
    FOR INSERT WITH CHECK (created_by = auth.uid());

-- Users can update supplements they created
CREATE POLICY "Users can update their own supplements" ON public.supplements
    FOR UPDATE USING (created_by = auth.uid());

-- Users can delete supplements they created
CREATE POLICY "Users can delete their own supplements" ON public.supplements
    FOR DELETE USING (created_by = auth.uid());

-- ===== SUPPLEMENT SCHEDULES POLICIES =====
-- Users can see schedules for supplements they can see
CREATE POLICY "Users can view supplement schedules" ON public.supplement_schedules
    FOR SELECT USING (
        created_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.supplements s 
            WHERE s.id = supplement_id AND 
            (s.created_by = auth.uid() OR s.client_id = auth.uid())
        )
    );

-- Users can create schedules
CREATE POLICY "Users can create supplement schedules" ON public.supplement_schedules
    FOR INSERT WITH CHECK (created_by = auth.uid());

-- Users can update schedules they created
CREATE POLICY "Users can update their own schedules" ON public.supplement_schedules
    FOR UPDATE USING (created_by = auth.uid());

-- Users can delete schedules they created
CREATE POLICY "Users can delete their own schedules" ON public.supplement_schedules
    FOR DELETE USING (created_by = auth.uid());

-- ===== SUPPLEMENT LOGS POLICIES =====
-- Users can see their own logs
CREATE POLICY "Users can view their own supplement logs" ON public.supplement_logs
    FOR SELECT USING (user_id = auth.uid());

-- Users can create logs for themselves
CREATE POLICY "Users can create supplement logs" ON public.supplement_logs
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own logs
CREATE POLICY "Users can update their own supplement logs" ON public.supplement_logs
    FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own logs
CREATE POLICY "Users can delete their own supplement logs" ON public.supplement_logs
    FOR DELETE USING (user_id = auth.uid());

-- ===== FUNCTIONS =====
-- Function to get next due time for a supplement
CREATE OR REPLACE FUNCTION get_next_supplement_due(
    p_supplement_id UUID,
    p_user_id UUID
) RETURNS TIMESTAMPTZ AS $$
DECLARE
    v_schedule RECORD;
    v_last_taken TIMESTAMPTZ;
    v_next_due TIMESTAMPTZ;
    v_interval_hours INTEGER;
BEGIN
    -- Get the active schedule for this supplement
    SELECT * INTO v_schedule
    FROM public.supplement_schedules
    WHERE supplement_id = p_supplement_id 
    AND is_active = true
    AND (end_date IS NULL OR end_date >= CURRENT_DATE)
    LIMIT 1;
    
    IF v_schedule IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Get the last time this supplement was taken
    SELECT MAX(taken_at) INTO v_last_taken
    FROM public.supplement_logs
    WHERE supplement_id = p_supplement_id 
    AND user_id = p_user_id
    AND status = 'taken';
    
    -- Calculate next due time based on schedule type
    IF v_schedule.interval_hours IS NOT NULL THEN
        -- "Every N hours" schedule (Pro feature)
        IF v_last_taken IS NULL THEN
            v_next_due := CURRENT_TIMESTAMP;
        ELSE
            v_next_due := v_last_taken + (v_schedule.interval_hours || ' hours')::INTERVAL;
        END IF;
    ELSE
        -- Daily schedule with specific times
        IF v_last_taken IS NULL THEN
            -- First time, use today's first scheduled time
            IF array_length(v_schedule.specific_times, 1) > 0 THEN
                v_next_due := CURRENT_DATE + v_schedule.specific_times[1];
            ELSE
                v_next_due := CURRENT_DATE + '08:00'::TIME;
            END IF;
        ELSE
            -- Find next scheduled time after last taken
            SELECT MIN(CURRENT_DATE + time) INTO v_next_due
            FROM unnest(v_schedule.specific_times) AS time
            WHERE CURRENT_DATE + time > v_last_taken;
            
            -- If no time today, use tomorrow's first time
            IF v_next_due IS NULL THEN
                v_next_due := (CURRENT_DATE + INTERVAL '1 day') + v_schedule.specific_times[1];
            END IF;
        END IF;
    END IF;
    
    RETURN v_next_due;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get supplements due for a user today
CREATE OR REPLACE FUNCTION get_supplements_due_today(
    p_user_id UUID
) RETURNS TABLE(
    supplement_id UUID,
    supplement_name TEXT,
    dosage TEXT,
    instructions TEXT,
    category TEXT,
    color TEXT,
    icon TEXT,
    schedule_id UUID,
    times_per_day INTEGER,
    specific_times TIME[],
    next_due TIMESTAMPTZ,
    last_taken TIMESTAMPTZ,
    taken_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.dosage,
        s.instructions,
        s.category,
        s.color,
        s.icon,
        ss.id,
        ss.times_per_day,
        ss.specific_times,
        get_next_supplement_due(s.id, p_user_id) as next_due,
        (SELECT MAX(taken_at) FROM public.supplement_logs 
         WHERE supplement_id = s.id AND user_id = p_user_id AND status = 'taken') as last_taken,
        (SELECT COUNT(*) FROM public.supplement_logs 
         WHERE supplement_id = s.id AND user_id = p_user_id 
         AND status = 'taken' 
         AND taken_at::DATE = CURRENT_DATE) as taken_count
    FROM public.supplements s
    INNER JOIN public.supplement_schedules ss ON s.id = ss.supplement_id
    WHERE s.is_active = true 
    AND ss.is_active = true
    AND (ss.end_date IS NULL OR ss.end_date >= CURRENT_DATE)
    AND (s.client_id = p_user_id OR s.created_by = p_user_id)
    ORDER BY s.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== TRIGGERS =====
-- Update updated_at timestamp on row update
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_supplements_updated_at
    BEFORE UPDATE ON public.supplements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_supplement_schedules_updated_at
    BEFORE UPDATE ON public.supplement_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===== COMMENTS =====
COMMENT ON TABLE public.supplements IS 'Supplement definitions and metadata';
COMMENT ON TABLE public.supplement_schedules IS 'When and how often supplements should be taken';
COMMENT ON TABLE public.supplement_logs IS 'Actual supplement intake records';
COMMENT ON FUNCTION get_next_supplement_due IS 'Calculate next due time for a supplement based on schedule and last taken';
COMMENT ON FUNCTION get_supplements_due_today IS 'Get all supplements due for a user today with status information';
