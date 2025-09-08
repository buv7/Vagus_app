-- Fix Supplement Functions
-- Recreate supplement functions that may have been dropped during extension migration

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_next_supplement_due(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_supplements_due_today(UUID) TO authenticated;

-- Add comments
COMMENT ON FUNCTION get_next_supplement_due IS 'Calculate next due time for a supplement based on schedule and last taken';
COMMENT ON FUNCTION get_supplements_due_today IS 'Get all supplements due for a user today with status information';
