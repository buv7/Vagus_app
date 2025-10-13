-- Sprint 11: QA, Tests, Performance & Launch
-- Add performance indexes for fast queries (safe - ignores errors)

-- 1. Messages indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_messages_recipient ON public.messages(recipient_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 2. User files indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_user_files_created_at ON public.user_files(created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_user_files_user_created ON public.user_files(user_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 3. Check-ins indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_checkins_created_at ON public.checkins(created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_checkins_client_date ON public.checkins(client_id, checkin_date DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_checkins_coach_date ON public.checkins(coach_id, checkin_date DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 4. Progress metrics indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_client_metrics_user_date ON public.client_metrics(user_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 5. Nutrition plans indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_nutrition_plans_user_created ON public.nutrition_plans(user_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 6. Workout plans indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_workout_plans_user_created ON public.workout_plans(user_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 7. Coach notes indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_coach_notes_client_created ON public.coach_notes(client_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_coach_notes_coach_created ON public.coach_notes(coach_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 8. Calendar events indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_calendar_events_user_start ON public.calendar_events(user_id, start_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 9. AI usage indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_ai_usage_user_month ON public.ai_usage(user_id, month, year);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_ai_usage_created_at ON public.ai_usage(created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 10. File tags and comments indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_file_tags_file_created ON public.file_tags(file_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_file_comments_file_created ON public.file_comments(file_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_file_comments_author ON public.file_comments(author_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 11. Progress photos indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_progress_photos_user_created ON public.progress_photos(user_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 12. Coach note versions indexes
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_coach_note_versions_note_created ON public.coach_note_versions(note_id, created_at DESC);
EXCEPTION WHEN OTHERS THEN NULL; END $$;
