-- =====================================================
-- NUTRITION PLATFORM 2.0 - FOUNDATION MIGRATION
-- =====================================================
-- This migration adds all necessary fields for the new nutrition platform
-- Run this BEFORE launching the new system
-- Migration: 001_nutrition_v2_foundation.sql
-- =====================================================

BEGIN;

-- =====================================================
-- NUTRITION PLANS TABLE UPDATES
-- =====================================================

-- Add new fields for v2.0
ALTER TABLE nutrition_plans
  ADD COLUMN IF NOT EXISTS format_version TEXT DEFAULT '2.0',
  ADD COLUMN IF NOT EXISTS migrated_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_template BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS template_category TEXT,
  ADD COLUMN IF NOT EXISTS shared_with JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS version_history JSONB DEFAULT '[]';

-- =====================================================
-- MEALS TABLE UPDATES
-- =====================================================

-- Add new fields for meal tracking and collaboration
ALTER TABLE meals
  ADD COLUMN IF NOT EXISTS meal_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS check_in_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS is_eaten BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS eaten_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS meal_comments JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS attachments JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS prep_instructions TEXT,
  ADD COLUMN IF NOT EXISTS storage_instructions TEXT,
  ADD COLUMN IF NOT EXISTS reheating_instructions TEXT;

-- =====================================================
-- FOOD ITEMS TABLE UPDATES
-- =====================================================

-- Add new fields for enhanced food data
ALTER TABLE food_items
  ADD COLUMN IF NOT EXISTS barcode TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT,
  ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS verified_by TEXT,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS sustainability_rating TEXT,
  ADD COLUMN IF NOT EXISTS carbon_footprint_kg DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS water_usage_liters DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS land_use_m2 DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS ethical_labels TEXT[],
  ADD COLUMN IF NOT EXISTS allergens TEXT[],
  ADD COLUMN IF NOT EXISTS is_seasonal BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS seasonal_months TEXT[];

-- =====================================================
-- CREATE NEW TABLES FOR ADVANCED FEATURES
-- =====================================================

-- Households for family meal planning
CREATE TABLE IF NOT EXISTS households (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  members JSONB DEFAULT '[]',
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Active macro cycles
CREATE TABLE IF NOT EXISTS active_macro_cycles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  template_id TEXT NOT NULL,
  template_name TEXT NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP,
  current_week INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  day_targets JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Diet phase programs
CREATE TABLE IF NOT EXISTS diet_phase_programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phases JSONB NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP,
  current_phase_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Refeed schedules
CREATE TABLE IF NOT EXISTS refeed_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  frequency_days INTEGER NOT NULL,
  calorie_multiplier DECIMAL(3,2) DEFAULT 1.2,
  duration_hours INTEGER DEFAULT 24,
  next_scheduled_date TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Allergy profiles
CREATE TABLE IF NOT EXISTS allergy_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  allergens JSONB DEFAULT '[]',
  conditions JSONB DEFAULT '[]',
  custom_restrictions TEXT[],
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  epi_pen_location TEXT,
  notify_coach BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Restaurant meal estimations
CREATE TABLE IF NOT EXISTS restaurant_meal_estimations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  photo_url TEXT,
  description TEXT,
  estimated_calories DECIMAL(10,2),
  estimated_protein DECIMAL(10,2),
  estimated_carbs DECIMAL(10,2),
  estimated_fat DECIMAL(10,2),
  confidence_score DECIMAL(3,2),
  detected_items TEXT[],
  restaurant_name TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Dining tips from coaches
CREATE TABLE IF NOT EXISTS dining_tips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  restaurant_id TEXT,
  cuisine TEXT,
  tip TEXT NOT NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Social events
CREATE TABLE IF NOT EXISTS social_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  event_date TIMESTAMP NOT NULL,
  restaurant_id TEXT,
  restaurant_name TEXT,
  location TEXT,
  adjust_macros BOOLEAN DEFAULT TRUE,
  macro_adjustment_percent DECIMAL(5,2),
  meal_swap_from TEXT,
  meal_swap_to TEXT,
  notes TEXT,
  reminder_enabled BOOLEAN DEFAULT TRUE,
  reminder_minutes_before INTEGER DEFAULT 60,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Geofence reminders
CREATE TABLE IF NOT EXISTS geofence_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  restaurant_id TEXT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  radius_meters DECIMAL(8,2) DEFAULT 200,
  message TEXT NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Achievements
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  category TEXT,
  points INTEGER DEFAULT 0,
  unlocked_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- Challenges
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL,
  duration_days INTEGER NOT NULL,
  target_value DECIMAL(10,2) NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  reward_description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Challenge participants
CREATE TABLE IF NOT EXISTS challenge_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  current_progress DECIMAL(10,2) DEFAULT 0,
  joined_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  UNIQUE(challenge_id, user_id)
);

-- Streaks
CREATE TABLE IF NOT EXISTS user_streaks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_logged_date DATE,
  streak_protected_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Meal prep plans
CREATE TABLE IF NOT EXISTS meal_prep_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nutrition_plan_id UUID REFERENCES nutrition_plans(id) ON DELETE CASCADE,
  prep_schedule JSONB NOT NULL,
  batch_opportunities JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Food waste logs
CREATE TABLE IF NOT EXISTS food_waste_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  food_name TEXT NOT NULL,
  quantity_grams DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL,
  estimated_cost DECIMAL(10,2),
  carbon_wasted DECIMAL(10,2),
  notes TEXT,
  wasted_at TIMESTAMP DEFAULT NOW()
);

-- Integration configurations
CREATE TABLE IF NOT EXISTS integration_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  status TEXT DEFAULT 'connected',
  sync_direction TEXT DEFAULT 'import',
  credentials JSONB DEFAULT '{}',
  last_synced_at TIMESTAMP,
  auto_sync BOOLEAN DEFAULT TRUE,
  sync_interval_minutes INTEGER DEFAULT 60,
  connected_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, provider)
);

-- Sync results
CREATE TABLE IF NOT EXISTS sync_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  integration_id UUID NOT NULL REFERENCES integration_configs(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  success BOOLEAN NOT NULL,
  items_synced INTEGER DEFAULT 0,
  synced_at TIMESTAMP DEFAULT NOW(),
  error TEXT,
  items_breakdown JSONB DEFAULT '{}'
);

-- Voice commands
CREATE TABLE IF NOT EXISTS voice_commands (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transcript TEXT NOT NULL,
  type TEXT NOT NULL,
  parsed_data JSONB DEFAULT '{}',
  was_successful BOOLEAN DEFAULT FALSE,
  response TEXT,
  timestamp TIMESTAMP DEFAULT NOW()
);

-- Chat messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  role TEXT NOT NULL,
  metadata JSONB,
  timestamp TIMESTAMP DEFAULT NOW()
);

-- Voice reminders
CREATE TABLE IF NOT EXISTS voice_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  scheduled_time TIMESTAMP NOT NULL,
  repeat BOOLEAN DEFAULT FALSE,
  repeat_frequency TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  use_voice BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Collaboration sessions
CREATE TABLE IF NOT EXISTS collaboration_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  resource_id UUID NOT NULL,
  resource_type TEXT NOT NULL,
  active_collaborators JSONB DEFAULT '[]',
  started_at TIMESTAMP DEFAULT NOW(),
  ended_at TIMESTAMP
);

-- Version history
CREATE TABLE IF NOT EXISTS version_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  resource_id UUID NOT NULL,
  resource_type TEXT NOT NULL,
  version_number INTEGER NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  snapshot JSONB NOT NULL,
  change_description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Comment threads
CREATE TABLE IF NOT EXISTS comment_threads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  resource_id UUID NOT NULL,
  resource_type TEXT NOT NULL,
  context_path TEXT,
  comments JSONB DEFAULT '[]',
  is_resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Cohorts
CREATE TABLE IF NOT EXISTS cohorts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  members JSONB DEFAULT '[]',
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Shared resources
CREATE TABLE IF NOT EXISTS shared_resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  resource_id UUID NOT NULL,
  resource_type TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  share_type TEXT DEFAULT 'private',
  shared_with JSONB DEFAULT '[]',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Daily sustainability summaries
CREATE TABLE IF NOT EXISTS daily_sustainability_summaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_carbon_footprint_kg DECIMAL(10,2),
  total_water_usage_liters DECIMAL(10,2),
  overall_rating TEXT,
  meals_logged INTEGER DEFAULT 0,
  sustainable_meals INTEGER DEFAULT 0,
  achievements TEXT[],
  breakdown_by_category JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Ethical food items
CREATE TABLE IF NOT EXISTS ethical_food_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  food_item_id UUID REFERENCES food_items(id) ON DELETE CASCADE,
  food_name TEXT NOT NULL,
  labels TEXT[],
  origin TEXT,
  producer TEXT,
  is_local_seasonal BOOLEAN DEFAULT FALSE,
  certification_info TEXT,
  fair_trade_precentage DECIMAL(5,2),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(food_item_id)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Meals indexes
CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);
CREATE INDEX IF NOT EXISTS idx_meals_user_id ON meals(user_id);
CREATE INDEX IF NOT EXISTS idx_meals_is_eaten ON meals(is_eaten);
CREATE INDEX IF NOT EXISTS idx_meals_plan_id ON meals(plan_id);

-- Nutrition plans indexes
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_client_id ON nutrition_plans(client_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_coach_id ON nutrition_plans(coach_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_format_version ON nutrition_plans(format_version);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_is_archived ON nutrition_plans(is_archived);

-- Food items indexes
CREATE INDEX IF NOT EXISTS idx_food_items_barcode ON food_items(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_food_items_verified ON food_items(verified);

-- Achievements indexes
CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_category ON achievements(category);

-- Challenges indexes
CREATE INDEX IF NOT EXISTS idx_challenges_is_active ON challenges(is_active);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_user_id ON challenge_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_challenge_id ON challenge_participants(challenge_id);

-- Streaks indexes
CREATE INDEX IF NOT EXISTS idx_user_streaks_user_id ON user_streaks(user_id);

-- Integration configs indexes
CREATE INDEX IF NOT EXISTS idx_integration_configs_user_id ON integration_configs(user_id);
CREATE INDEX IF NOT EXISTS idx_integration_configs_provider ON integration_configs(provider);

-- Voice commands indexes
CREATE INDEX IF NOT EXISTS idx_voice_commands_user_id ON voice_commands(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_commands_timestamp ON voice_commands(timestamp);

-- Chat messages indexes
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp ON chat_messages(timestamp);

-- Collaboration sessions indexes
CREATE INDEX IF NOT EXISTS idx_collaboration_sessions_resource ON collaboration_sessions(resource_id, resource_type);

-- Version history indexes
CREATE INDEX IF NOT EXISTS idx_version_history_resource ON version_history(resource_id, resource_type);
CREATE INDEX IF NOT EXISTS idx_version_history_version ON version_history(resource_id, version_number);

-- Comment threads indexes
CREATE INDEX IF NOT EXISTS idx_comment_threads_resource ON comment_threads(resource_id, resource_type);

-- Sustainability indexes
CREATE INDEX IF NOT EXISTS idx_sustainability_user_date ON daily_sustainability_summaries(user_id, date);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all new tables
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_macro_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_phase_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE refeed_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE allergy_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_meal_estimations ENABLE ROW LEVEL SECURITY;
ALTER TABLE dining_tips ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE geofence_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_prep_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_waste_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaboration_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE version_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_sustainability_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE ethical_food_items ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (users can only access their own data)
-- Note: You may need to customize these based on your specific requirements

CREATE POLICY "Users can view their own households" ON households
  FOR SELECT USING (owner_id = auth.uid() OR auth.uid() IN (
    SELECT (value->>'user_id')::uuid FROM jsonb_array_elements(members)
  ));

CREATE POLICY "Users can manage their own macro cycles" ON active_macro_cycles
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own diet phases" ON diet_phase_programs
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own refeed schedules" ON refeed_schedules
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own allergy profiles" ON allergy_profiles
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can view their own achievements" ON achievements
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view their own streaks" ON user_streaks
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own meal prep plans" ON meal_prep_plans
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own food waste logs" ON food_waste_logs
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own integrations" ON integration_configs
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can view their own voice commands" ON voice_commands
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view their own chat messages" ON chat_messages
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own voice reminders" ON voice_reminders
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can view their own sustainability data" ON daily_sustainability_summaries
  FOR ALL USING (user_id = auth.uid());

-- Challenges are public (everyone can view)
CREATE POLICY "Anyone can view active challenges" ON challenges
  FOR SELECT USING (is_active = true);

CREATE POLICY "Users can join challenges" ON challenge_participants
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view their challenge participation" ON challenge_participants
  FOR SELECT USING (user_id = auth.uid());

COMMIT;