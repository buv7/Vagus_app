-- Health Integrations + OCR v1
-- Migration: 0017_health_ocr_v1.sql

-- Health Sources table (tracks connected health platforms)
CREATE TABLE IF NOT EXISTS health_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL CHECK (provider IN ('healthkit', 'healthconnect', 'googlefit', 'hms')),
    scopes JSONB DEFAULT '{}',
    last_sync_at TIMESTAMPTZ,
    cursor JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, provider)
);

-- Health Samples table (normalized health data)
CREATE TABLE IF NOT EXISTS health_samples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    value NUMERIC,
    unit TEXT,
    measured_at TIMESTAMPTZ NOT NULL,
    source TEXT,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Health Workouts table (structured workout data)
CREATE TABLE IF NOT EXISTS health_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sport TEXT NOT NULL,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    duration_s INTEGER,
    distance_m NUMERIC,
    avg_hr NUMERIC,
    kcal NUMERIC,
    source TEXT,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Sleep Segments table (detailed sleep tracking)
CREATE TABLE IF NOT EXISTS sleep_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    stage TEXT CHECK (stage IN ('awake', 'light', 'deep', 'rem')),
    source TEXT,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- OCR Cardio Logs table (for manual cardio entry via OCR)
CREATE TABLE IF NOT EXISTS ocr_cardio_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    photo_path TEXT,
    parsed JSONB,
    confirmed BOOLEAN DEFAULT false,
    workout_id UUID REFERENCES health_workouts(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Health Merges table (tracks data merging between platforms)
CREATE TABLE IF NOT EXISTS health_merges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ocr_log_id UUID REFERENCES ocr_cardio_logs(id),
    workout_id UUID REFERENCES health_workouts(id),
    strategy TEXT NOT NULL CHECK (strategy IN ('overlap70', 'manual')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Views for dashboard integration
CREATE OR REPLACE VIEW health_daily_v AS
SELECT
    user_id,
    DATE(measured_at) as date,
    SUM(CASE WHEN type = 'steps' THEN value ELSE 0 END) as steps,
    SUM(CASE WHEN type = 'distance' THEN value ELSE 0 END) / 1000 as distance_km,
    SUM(CASE WHEN type = 'calories' THEN value ELSE 0 END) as active_kcal,
    COUNT(DISTINCT CASE WHEN type = 'steps' THEN id END) as step_samples_count
FROM health_samples
WHERE measured_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY user_id, DATE(measured_at);

CREATE OR REPLACE VIEW sleep_quality_v AS
SELECT
    user_id,
    DATE(start_at) as date,
    SUM(EXTRACT(EPOCH FROM (end_at - start_at)) / 60) as sleep_minutes,
    COUNT(*) as sleep_segments_count,
    AVG(CASE WHEN stage = 'deep' THEN 1 ELSE 0 END) as deep_sleep_ratio,
    MIN(start_at) as bedtime,
    MAX(end_at) as risetime
FROM sleep_segments
WHERE start_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY user_id, DATE(start_at);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_health_samples_user_type_time ON health_samples(user_id, type, measured_at);
CREATE INDEX IF NOT EXISTS idx_health_workouts_user_start ON health_workouts(user_id, start_at);
CREATE INDEX IF NOT EXISTS idx_sleep_segments_user_start ON sleep_segments(user_id, start_at);

-- Row Level Security (RLS) Policies
ALTER TABLE health_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ocr_cardio_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_merges ENABLE ROW LEVEL SECURITY;

-- Users can read/write their own health data
CREATE POLICY "Users can manage own health sources" ON health_sources
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own health samples" ON health_samples
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own health workouts" ON health_workouts
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own sleep segments" ON sleep_segments
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own OCR logs" ON ocr_cardio_logs
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own health merges" ON health_merges
    FOR ALL USING (auth.uid() = user_id);

-- Coaches can read health rollups for linked clients (read-only, views only)
CREATE POLICY "Coaches can read client health rollups" ON health_sources
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_coach_links
            WHERE coach_id = auth.uid() AND client_id = health_sources.user_id
        )
    );

CREATE POLICY "Coaches can read client health samples" ON health_samples
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_coach_links
            WHERE coach_id = auth.uid() AND client_id = health_samples.user_id
        )
    );

CREATE POLICY "Coaches can read client health workouts" ON health_workouts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_coach_links
            WHERE coach_id = auth.uid() AND client_id = health_workouts.user_id
        )
    );

CREATE POLICY "Coaches can read client sleep segments" ON sleep_segments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_coach_links
            WHERE coach_id = auth.uid() AND client_id = sleep_segments.user_id
        )
    );

-- Admins can read all health data
CREATE POLICY "Admins can read all health data" ON health_sources
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can read all health samples" ON health_samples
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can read all health workouts" ON health_workouts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can read all sleep segments" ON sleep_segments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can read all OCR logs" ON ocr_cardio_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can read all health merges" ON health_merges
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Comments for documentation
COMMENT ON TABLE health_sources IS 'Tracks connected health platforms per user';
COMMENT ON TABLE health_samples IS 'Normalized health data samples from various platforms';
COMMENT ON TABLE health_workouts IS 'Structured workout data from health platforms';
COMMENT ON TABLE sleep_segments IS 'Detailed sleep tracking segments';
COMMENT ON TABLE ocr_cardio_logs IS 'OCR-processed cardio workout logs';
COMMENT ON TABLE health_merges IS 'Tracks data merging between health platforms';
COMMENT ON VIEW health_daily_v IS 'Daily health metrics rollup for dashboard';
COMMENT ON VIEW sleep_quality_v IS 'Sleep quality metrics rollup for dashboard';
