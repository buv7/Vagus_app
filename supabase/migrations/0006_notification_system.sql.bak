-- Migration: Notification System
-- Description: Tables and functions for workout notifications

-- ====================
-- Part 1: Notification Preferences Table
-- ====================

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferences JSONB NOT NULL DEFAULT '{
    "workout_reminders_enabled": true,
    "reminder_minutes_before": 30,
    "rest_day_reminders_enabled": true,
    "pr_celebration_enabled": true,
    "coach_feedback_enabled": true,
    "missed_workout_enabled": true,
    "weekly_summary_enabled": true,
    "weekly_summary_day": "Sunday",
    "weekly_summary_time": "18:00",
    "sound_enabled": true,
    "vibration_enabled": true,
    "timezone": "UTC"
  }'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS policies
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification preferences"
  ON notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification preferences"
  ON notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification preferences"
  ON notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

-- ====================
-- Part 2: Scheduled Notifications Table
-- ====================

CREATE TABLE IF NOT EXISTS scheduled_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
  day_id UUID,
  notification_type TEXT NOT NULL CHECK (notification_type IN (
    'plan_assigned',
    'workout_reminder',
    'rest_day_reminder',
    'deload_week_alert',
    'pr_celebration',
    'coach_feedback',
    'missed_workout',
    'weekly_summary',
    'workout_started',
    'workout_completed',
    'progress_milestone'
  )),
  send_at TIMESTAMPTZ NOT NULL,
  onesignal_notification_id TEXT,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'sent', 'cancelled', 'failed')),
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

-- Add indexes
CREATE INDEX idx_scheduled_notifications_user_id ON scheduled_notifications(user_id);
CREATE INDEX idx_scheduled_notifications_plan_id ON scheduled_notifications(plan_id);
CREATE INDEX idx_scheduled_notifications_status ON scheduled_notifications(status);
CREATE INDEX idx_scheduled_notifications_send_at ON scheduled_notifications(send_at);

-- Add RLS policies
ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own scheduled notifications"
  ON scheduled_notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage scheduled notifications"
  ON scheduled_notifications FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');

-- ====================
-- Part 3: Notification History Table
-- ====================

CREATE TABLE IF NOT EXISTS notification_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  opened_at TIMESTAMPTZ,
  action_taken TEXT,
  onesignal_notification_id TEXT
);

-- Add indexes
CREATE INDEX idx_notification_history_user_id ON notification_history(user_id);
CREATE INDEX idx_notification_history_sent_at ON notification_history(sent_at DESC);
CREATE INDEX idx_notification_history_type ON notification_history(notification_type);

-- Add RLS policies
ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification history"
  ON notification_history FOR SELECT
  USING (auth.uid() = user_id);

-- ====================
-- Part 4: Add OneSignal Player ID to Profiles
-- ====================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;
CREATE INDEX IF NOT EXISTS idx_profiles_onesignal_player_id ON profiles(onesignal_player_id);

-- ====================
-- Part 5: Helper Functions
-- ====================

-- Function to get user's notification preferences
CREATE OR REPLACE FUNCTION get_notification_preferences(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_preferences JSONB;
BEGIN
  SELECT preferences INTO v_preferences
  FROM notification_preferences
  WHERE user_id = p_user_id;

  -- Return default preferences if not found
  IF v_preferences IS NULL THEN
    RETURN '{
      "workout_reminders_enabled": true,
      "reminder_minutes_before": 30,
      "rest_day_reminders_enabled": true,
      "pr_celebration_enabled": true,
      "coach_feedback_enabled": true,
      "missed_workout_enabled": true,
      "weekly_summary_enabled": true,
      "weekly_summary_day": "Sunday",
      "weekly_summary_time": "18:00",
      "sound_enabled": true,
      "vibration_enabled": true,
      "timezone": "UTC"
    }'::jsonb;
  END IF;

  RETURN v_preferences;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notification as sent
CREATE OR REPLACE FUNCTION mark_notification_sent(p_notification_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE scheduled_notifications
  SET status = 'sent',
      sent_at = NOW()
  WHERE id = p_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notification as failed
CREATE OR REPLACE FUNCTION mark_notification_failed(p_notification_id UUID, p_error TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE scheduled_notifications
  SET status = 'failed',
      error_message = p_error
  WHERE id = p_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get upcoming notifications
CREATE OR REPLACE FUNCTION get_upcoming_notifications(p_hours_ahead INT DEFAULT 24)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  notification_type TEXT,
  send_at TIMESTAMPTZ,
  user_preferences JSONB,
  user_player_id TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    sn.id,
    sn.user_id,
    sn.notification_type,
    sn.send_at,
    np.preferences,
    p.onesignal_player_id
  FROM scheduled_notifications sn
  INNER JOIN notification_preferences np ON sn.user_id = np.user_id
  INNER JOIN profiles p ON sn.user_id = p.id
  WHERE sn.status = 'scheduled'
    AND sn.send_at BETWEEN NOW() AND NOW() + INTERVAL '1 hour' * p_hours_ahead
    AND p.onesignal_player_id IS NOT NULL
  ORDER BY sn.send_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log notification in history
CREATE OR REPLACE FUNCTION log_notification_history(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB,
  p_onesignal_id TEXT
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO notification_history (
    user_id,
    notification_type,
    title,
    body,
    data,
    onesignal_notification_id
  ) VALUES (
    p_user_id,
    p_type,
    p_title,
    p_body,
    p_data,
    p_onesignal_id
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================
-- Part 6: Triggers
-- ====================

-- Trigger to update updated_at on notification_preferences
CREATE OR REPLACE FUNCTION update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_notification_preferences_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_preferences_updated_at();

-- ====================
-- Part 7: Sample Data (Optional - Comment out for production)
-- ====================

-- Uncomment to insert sample notification preferences
-- INSERT INTO notification_preferences (user_id, preferences)
-- SELECT id, DEFAULT FROM auth.users LIMIT 10
-- ON CONFLICT (user_id) DO NOTHING;

-- ====================
-- Part 8: Cleanup Old Notifications (Maintenance)
-- ====================

-- Function to clean up old notification history (keep last 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_notification_history()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM notification_history
  WHERE sent_at < NOW() - INTERVAL '90 days';

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up cancelled scheduled notifications (keep last 30 days)
CREATE OR REPLACE FUNCTION cleanup_cancelled_notifications()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM scheduled_notifications
  WHERE status = 'cancelled'
    AND cancelled_at < NOW() - INTERVAL '30 days';

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_notification_preferences(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_notification_sent(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION mark_notification_failed(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION get_upcoming_notifications(INT) TO service_role;
GRANT EXECUTE ON FUNCTION log_notification_history(UUID, TEXT, TEXT, TEXT, JSONB, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_notification_history() TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_cancelled_notifications() TO service_role;

-- ====================
-- Migration Complete
-- ====================

COMMENT ON TABLE notification_preferences IS 'User notification preferences and settings';
COMMENT ON TABLE scheduled_notifications IS 'Scheduled notifications with OneSignal integration';
COMMENT ON TABLE notification_history IS 'History of sent notifications for analytics';
COMMENT ON FUNCTION get_notification_preferences IS 'Get user notification preferences with defaults';
COMMENT ON FUNCTION get_upcoming_notifications IS 'Get notifications scheduled in next X hours';
