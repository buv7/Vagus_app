-- UX-ADAPT: Add adaptive UX mode columns to user_settings
--
-- ux_mode_override: explicit user choice ('simple', 'default_', 'insane')
--                   NULL means follow auto-computed mode
-- ux_usage_hours:   total foreground hours synced from client
-- ux_last_advanced_at: last time the user interacted with an Insane-tier feature
--                      (used for 30-day demotion check)

ALTER TABLE user_settings
  ADD COLUMN IF NOT EXISTS ux_mode_override     TEXT,
  ADD COLUMN IF NOT EXISTS ux_usage_hours       FLOAT8  NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS ux_last_advanced_at  TIMESTAMPTZ;

-- Constrain override to known values
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_ux_mode_override'
  ) THEN
    ALTER TABLE user_settings
      ADD CONSTRAINT chk_ux_mode_override
        CHECK (ux_mode_override IS NULL OR
               ux_mode_override IN ('simple', 'default_', 'insane'));
  END IF;
END $$;

COMMENT ON COLUMN user_settings.ux_mode_override
  IS 'User-chosen UX tier override. NULL = auto from usage hours.';

COMMENT ON COLUMN user_settings.ux_usage_hours
  IS 'Accumulated foreground app hours synced from SharedPreferences on the client.';

COMMENT ON COLUMN user_settings.ux_last_advanced_at
  IS 'Timestamp of the most recent Insane-tier feature interaction for demotion detection.';
