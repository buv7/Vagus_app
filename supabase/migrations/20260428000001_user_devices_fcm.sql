-- SIGNAL v2: FCM token storage, notification templates, and per-category preferences.
-- Adds fcm_token to user_devices (existing table).
-- Creates notification_templates and notification_preferences tables.

-- ─────────────────────────────────────────────────────────────
-- 1. user_devices — add fcm_token column
-- ─────────────────────────────────────────────────────────────

ALTER TABLE user_devices
  ADD COLUMN IF NOT EXISTS fcm_token TEXT,
  ADD COLUMN IF NOT EXISTS device_id TEXT;

-- Unique constraint: one row per logical device (keyed by device_id + user_id).
-- session_service.dart already upserts on device_id; this formalises it.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_devices_device_id_unique'
  ) THEN
    ALTER TABLE user_devices ADD CONSTRAINT user_devices_device_id_unique UNIQUE (device_id);
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_user_devices_fcm_token ON user_devices (fcm_token)
  WHERE fcm_token IS NOT NULL;

-- ─────────────────────────────────────────────────────────────
-- 2. notification_templates
--    Stores localised push notification copy for each template key.
--    Server-side only — not user-scoped, so exempt from RLS.
-- ─────────────────────────────────────────────────────────────
-- vault-rls-exempt: notification_templates reason: global lookup table managed by SIGNAL/HARBOR; no user PII

CREATE TABLE IF NOT EXISTS notification_templates (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key TEXT NOT NULL,        -- e.g. 'workout_reminder', 'coach_message'
  locale      TEXT NOT NULL,         -- 'en', 'ar', 'ku'
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,         -- May contain {param} placeholders
  category    TEXT NOT NULL,         -- Matches NotificationCategory values
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (template_key, locale)
);

-- Seed default EN templates.
INSERT INTO notification_templates (template_key, locale, title, body, category) VALUES
  -- Workouts
  ('workout_reminder',      'en', 'Time to train 💪',             'Your {plan_name} session is scheduled — let''s go!', 'workouts'),
  ('workout_plan_assigned', 'en', 'New plan from {coach_name}',   'Your plan "{plan_name}" is ready to start.',           'workouts'),
  ('pr_celebration',        'en', 'New Personal Record! 🎉',       '{exercise_name}: {new_value}',                         'workouts'),
  -- Nutrition
  ('nutrition_reminder',    'en', 'Log your meal 🥗',              'Don''t forget to log what you ate.',                   'nutrition_reminders'),
  ('hydration_nudge',       'en', 'Stay hydrated 💧',              'You''re behind on your water goal today.',             'nutrition_reminders'),
  -- Coach messages
  ('coach_message',         'en', 'Message from {coach_name}',    '{preview}',                                             'coach_messages'),
  ('coach_feedback',        'en', '{coach_name} left feedback',   'On {exercise_name}: {preview}',                        'coach_messages'),
  -- Periods
  ('period_reminder',       'en', 'Period expected soon',         'Track your cycle to stay on top of your health.',      'periods'),
  -- Streaks
  ('streak_reminder',       'en', 'Don''t break your streak 🔥',   'Complete any activity today to keep it alive.',        'streaks'),
  -- Lab results (content is intentionally vague — SIGNAL FORBIDDEN: no values in push)
  ('lab_result_ready',      'en', 'New lab result available',     'Open the app to view your latest result.',             'lab_results'),
  -- Test
  ('test_push',             'en', 'Test notification ✅',          'SIGNAL FCM v2 is working correctly.',                  'coach_messages'),
  -- AR variants
  ('workout_reminder',      'ar', 'وقت التدريب 💪',               'جلسة {plan_name} مجدولة — هيا!',                       'workouts'),
  ('lab_result_ready',      'ar', 'نتيجة مختبر جديدة متاحة',     'افتح التطبيق لعرض نتيجتك الأخيرة.',                   'lab_results'),
  ('test_push',             'ar', 'إشعار تجريبي ✅',              'SIGNAL FCM v2 يعمل بشكل صحيح.',                        'coach_messages'),
  -- KU variants
  ('workout_reminder',      'ku', 'کاتی ڕاهێنان 💪',              'دانیشتنی {plan_name} پلانکراوه — با!',                 'workouts'),
  ('lab_result_ready',      'ku', 'ئەنجامی تاقیگەی نوێ بەردەستە', 'ئەپەکە بکەوە بۆ بینینی ئەنجامی دوایینت.',            'lab_results'),
  ('test_push',             'ku', 'ئاگادارکردنەوەی تاقیکردنەوە ✅', 'SIGNAL FCM v2 دروستە.',                              'coach_messages')
ON CONFLICT (template_key, locale) DO NOTHING;

-- ─────────────────────────────────────────────────────────────
-- 3. notification_preferences
--    Per-user, per-category opt-in flag.
-- ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notification_preferences (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category    TEXT NOT NULL,         -- Matches NotificationCategory values
  enabled     BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, category)
);

CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id
  ON notification_preferences (user_id);

-- RLS
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own notification preferences"
  ON notification_preferences
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON notification_preferences TO authenticated;

-- Default preferences for new users: marketplace OFF, everything else ON.
-- Inserted lazily by the app on first load (upsert), but we also provide
-- a helper function the Edge Function can call to check a user's preference.

CREATE OR REPLACE FUNCTION is_notification_enabled(p_user_id UUID, p_category TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT enabled FROM notification_preferences
     WHERE user_id = p_user_id AND category = p_category),
    -- Default: marketplace is OFF, everything else is ON.
    CASE WHEN p_category = 'marketplace' THEN FALSE ELSE TRUE END
  );
$$;

GRANT EXECUTE ON FUNCTION is_notification_enabled(UUID, TEXT) TO service_role;
