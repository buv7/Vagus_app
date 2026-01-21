-- Enhanced Health Daily View
-- Migration: 20250121000000_health_daily_view_enhanced.sql
-- Adds exercise_minutes and stand_hours to support full health rings display

-- Drop and recreate the view with additional metrics
CREATE OR REPLACE VIEW health_daily_v AS
SELECT
    hs.user_id,
    DATE(hs.measured_at) as date,
    SUM(CASE WHEN hs.type = 'steps' THEN hs.value ELSE 0 END) as steps,
    SUM(CASE WHEN hs.type = 'distance' THEN hs.value ELSE 0 END) / 1000 as distance_km,
    SUM(CASE WHEN hs.type = 'calories' THEN hs.value ELSE 0 END) as active_kcal,
    COUNT(DISTINCT CASE WHEN hs.type = 'steps' THEN hs.id END) as step_samples_count,
    -- Exercise minutes: sum of workout durations for the day
    COALESCE((
        SELECT SUM(hw.duration_s) / 60
        FROM health_workouts hw
        WHERE hw.user_id = hs.user_id
          AND DATE(hw.start_at) = DATE(hs.measured_at)
    ), 0) as exercise_minutes,
    -- Stand hours: count of distinct hours with step activity (> 50 steps)
    COALESCE((
        SELECT COUNT(DISTINCT EXTRACT(HOUR FROM hs2.measured_at))
        FROM health_samples hs2
        WHERE hs2.user_id = hs.user_id
          AND DATE(hs2.measured_at) = DATE(hs.measured_at)
          AND hs2.type = 'steps'
          AND hs2.value > 50
    ), 0) as stand_hours
FROM health_samples hs
WHERE hs.measured_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY hs.user_id, DATE(hs.measured_at);

-- Update comment
COMMENT ON VIEW health_daily_v IS 'Daily health metrics rollup for dashboard, including steps, calories, exercise minutes, and stand hours';
