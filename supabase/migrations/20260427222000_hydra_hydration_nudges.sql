-- HYDRA: hydration nudge schedule log
-- Records when nudges were scheduled/suppressed for audit + analytics.
-- Migration: 20260427222000_hydra_hydration_nudges.sql

-- ============================================================
-- hydration_nudge_log
-- ============================================================
CREATE TABLE IF NOT EXISTS hydration_nudge_log (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scheduled_at  timestamptz NOT NULL,
  target_ml     int NOT NULL CHECK (target_ml > 0),
  suppressed    boolean NOT NULL DEFAULT false,
  suppressed_reason text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS hydration_nudge_log_user_day_idx
  ON hydration_nudge_log (user_id, scheduled_at);

-- Row-level security: users see only their own rows.
ALTER TABLE hydration_nudge_log ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'hydration_nudge_log'
      AND policyname = 'users_own_nudge_log'
  ) THEN
    CREATE POLICY users_own_nudge_log ON hydration_nudge_log
      USING (user_id = auth.uid());
  END IF;
END $$;

-- ============================================================
-- Hydration target override: coach can set explicit targets
-- outside the engine's safety rail with confirmation flag.
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'nutrition_preferences'
      AND column_name = 'hydration_target_ml'
  ) THEN
    ALTER TABLE nutrition_preferences
      ADD COLUMN hydration_target_ml int CHECK (hydration_target_ml BETWEEN 1500 AND 5000),
      ADD COLUMN hydration_coach_override boolean NOT NULL DEFAULT false;
  END IF;
END $$;

-- ============================================================
-- ROLLBACK (run manually, not via migration):
-- DROP TABLE IF EXISTS hydration_nudge_log;
-- ALTER TABLE nutrition_preferences
--   DROP COLUMN IF EXISTS hydration_target_ml,
--   DROP COLUMN IF EXISTS hydration_coach_override;
-- ============================================================
