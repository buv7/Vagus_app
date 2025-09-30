-- =====================================================
-- NUTRITION PLATFORM 2.0 - FOUNDATION MIGRATION
-- Migration 1 of 2: Create new tables and add columns
-- Compatible with existing Vagus schema
-- =====================================================

BEGIN;

-- =====================================================
-- PART 1: ADD COLUMNS TO EXISTING TABLES
-- =====================================================

-- Extend nutrition_plans with v2.0 metadata
ALTER TABLE nutrition_plans
  ADD COLUMN IF NOT EXISTS format_version TEXT DEFAULT '2.0',
  ADD COLUMN IF NOT EXISTS migrated_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_template BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS template_category TEXT,
  ADD COLUMN IF NOT EXISTS shared_with UUID[],
  ADD COLUMN IF NOT EXISTS version_history JSONB DEFAULT '[]';

-- Extend nutrition_meals with tracking fields
ALTER TABLE nutrition_meals
  ADD COLUMN IF NOT EXISTS meal_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS check_in_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS is_eaten BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS eaten_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS meal_comments TEXT,
  ADD COLUMN IF NOT EXISTS attachments JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS prep_instructions TEXT,
  ADD COLUMN IF NOT EXISTS storage_instructions TEXT,
  ADD COLUMN IF NOT EXISTS reheating_instructions TEXT;

-- Extend food_items with sustainability and verification
ALTER TABLE food_items
  ADD COLUMN IF NOT EXISTS barcode TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT,
  ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS verified_by UUID,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS sustainability_rating TEXT CHECK (sustainability_rating IN ('A', 'B', 'C', 'D', 'F')),
  ADD COLUMN IF NOT EXISTS carbon_footprint_kg DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS water_usage_liters DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS land_use_m2 DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS ethical_labels TEXT[],
  ADD COLUMN IF NOT EXISTS allergens TEXT[],
  ADD COLUMN IF NOT EXISTS is_seasonal BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS seasonal_months INTEGER[];

-- =====================================================
-- PART 2: CREATE NEW TABLES FOR ADVANCED FEATURES
-- =====================================================

-- 1. HOUSEHOLDS (Shared nutrition planning)
CREATE TABLE IF NOT EXISTS households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  members UUID[] DEFAULT '{}',
  shared_plans UUID[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. ACTIVE MACRO CYCLES (Periodization)
CREATE TABLE IF NOT EXISTS active_macro_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  phases JSONB NOT NULL, -- Array of phase configs
  current_phase_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. DIET PHASE PROGRAMS (Pre-built phase templates)
CREATE TABLE IF NOT EXISTS diet_phase_programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  duration_weeks INTEGER NOT NULL,
  macro_config JSONB NOT NULL, -- { protein_g, carbs_g, fat_g }
  refeed_schedule JSONB, -- { frequency, macro_adjustment }
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. REFEED SCHEDULES (Metabolic management)
CREATE TABLE IF NOT EXISTS refeed_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  frequency TEXT NOT NULL, -- 'weekly', 'biweekly'
  refeed_day TEXT NOT NULL, -- 'saturday', 'sunday'
  carb_increase_percent INTEGER NOT NULL DEFAULT 50,
  next_refeed_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. ALLERGY PROFILES (Medical tracking)
CREATE TABLE IF NOT EXISTS allergy_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  allergies TEXT[] DEFAULT '{}',
  intolerances TEXT[] DEFAULT '{}',
  medical_conditions TEXT[] DEFAULT '{}',
  dietary_restrictions TEXT[] DEFAULT '{}',
  auto_filter_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. RESTAURANT MEAL ESTIMATIONS (Dining out)
CREATE TABLE IF NOT EXISTS restaurant_meal_estimations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  restaurant_name TEXT NOT NULL,
  meal_description TEXT NOT NULL,
  estimated_macros JSONB NOT NULL, -- { kcal, protein_g, carbs_g, fat_g }
  confidence_level TEXT CHECK (confidence_level IN ('low', 'medium', 'high')),
  photo_url TEXT,
  actual_macros JSONB, -- User can update after the fact
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. DINING TIPS (AI suggestions)
CREATE TABLE IF NOT EXISTS dining_tips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  restaurant_type TEXT NOT NULL,
  tips JSONB NOT NULL, -- Array of tip strings
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. SOCIAL EVENTS (Calendar integration)
CREATE TABLE IF NOT EXISTS social_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_name TEXT NOT NULL,
  event_date TIMESTAMP WITH TIME ZONE NOT NULL,
  meal_strategy TEXT, -- 'save_calories', 'refeed', 'estimate'
  budget_kcal INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. GEOFENCE REMINDERS (Location-based)
CREATE TABLE IF NOT EXISTS geofence_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  location_name TEXT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  radius_meters INTEGER DEFAULT 100,
  reminder_type TEXT NOT NULL, -- 'meal_prep', 'grocery', 'restaurant'
  message TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. ACHIEVEMENTS (Gamification)
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_type TEXT NOT NULL, -- 'streak', 'macro_hit', 'meal_prep'
  title TEXT NOT NULL,
  description TEXT,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

-- 11. CHALLENGES (Community engagement)
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  challenge_type TEXT NOT NULL, -- 'streak', 'macro_accuracy', 'meal_prep'
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reward_type TEXT, -- 'badge', 'points', 'discount'
  reward_value JSONB,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. CHALLENGE PARTICIPANTS
CREATE TABLE IF NOT EXISTS challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  progress JSONB DEFAULT '{}',
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(challenge_id, user_id)
);

-- Note: user_streaks already exists, skip creating it

-- 13. MEAL PREP PLANS
CREATE TABLE IF NOT EXISTS meal_prep_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  prep_date DATE NOT NULL,
  recipes UUID[], -- References to nutrition_recipes
  batch_multipliers INTEGER[] DEFAULT '{}',
  storage_plan JSONB DEFAULT '{}',
  estimated_prep_time_minutes INTEGER,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. FOOD WASTE LOGS (Sustainability)
CREATE TABLE IF NOT EXISTS food_waste_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  food_item_id UUID REFERENCES food_items(id) ON DELETE SET NULL,
  food_name TEXT NOT NULL,
  quantity_grams DECIMAL(10,2) NOT NULL,
  reason TEXT, -- 'spoiled', 'expired', 'overcooked'
  estimated_cost_usd DECIMAL(10,2),
  logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 15. INTEGRATION CONFIGS (Wearables & Apps)
CREATE TABLE IF NOT EXISTS integration_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  integration_type TEXT NOT NULL, -- 'myfitnesspal', 'cronometer', 'fitbit'
  credentials_encrypted TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  last_sync_at TIMESTAMP WITH TIME ZONE,
  sync_frequency TEXT DEFAULT 'hourly', -- 'realtime', 'hourly', 'daily'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, integration_type)
);

-- 16. SYNC RESULTS (Integration history)
CREATE TABLE IF NOT EXISTS sync_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_id UUID NOT NULL REFERENCES integration_configs(id) ON DELETE CASCADE,
  sync_started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sync_ended_at TIMESTAMP WITH TIME ZONE,
  status TEXT CHECK (status IN ('success', 'partial', 'failed')),
  records_synced INTEGER DEFAULT 0,
  errors JSONB DEFAULT '[]',
  summary TEXT
);

-- 17. VOICE COMMANDS (Voice interface)
CREATE TABLE IF NOT EXISTS voice_commands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transcript TEXT NOT NULL,
  intent TEXT NOT NULL, -- 'log_meal', 'check_macros', 'ask_question'
  entities JSONB DEFAULT '{}',
  action_taken TEXT,
  confidence_score DECIMAL(3,2),
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 18. CHAT MESSAGES (AI assistant)
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  context JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 19. VOICE REMINDERS (Proactive notifications)
CREATE TABLE IF NOT EXISTS voice_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL, -- 'meal', 'hydration', 'supplement'
  message TEXT NOT NULL,
  scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
  delivered BOOLEAN DEFAULT FALSE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 20. COLLABORATION SESSIONS (Real-time editing)
CREATE TABLE IF NOT EXISTS collaboration_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES nutrition_plans(id) ON DELETE CASCADE,
  host_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  active_users UUID[] DEFAULT '{}',
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE
);

-- 21. VERSION HISTORY (Plan versioning)
CREATE TABLE IF NOT EXISTS version_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES nutrition_plans(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  snapshot JSONB NOT NULL,
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  change_description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 22. COMMENT THREADS (Meal discussion)
CREATE TABLE IF NOT EXISTS comment_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_id UUID NOT NULL REFERENCES nutrition_meals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  parent_comment_id UUID REFERENCES comment_threads(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 23. COHORTS (Group programs)
CREATE TABLE IF NOT EXISTS cohorts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  coach_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  member_ids UUID[] DEFAULT '{}',
  shared_plan_id UUID REFERENCES nutrition_plans(id) ON DELETE SET NULL,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 24. SHARED RESOURCES (Educational content)
CREATE TABLE IF NOT EXISTS shared_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cohort_id UUID REFERENCES cohorts(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  resource_type TEXT NOT NULL, -- 'article', 'video', 'recipe', 'guide'
  url TEXT,
  content TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 25. DAILY SUSTAINABILITY SUMMARIES
CREATE TABLE IF NOT EXISTS daily_sustainability_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_carbon_kg DECIMAL(10,2) DEFAULT 0,
  total_water_liters DECIMAL(10,2) DEFAULT 0,
  total_land_m2 DECIMAL(10,2) DEFAULT 0,
  sustainability_score DECIMAL(3,1), -- 0-10
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- 26. ETHICAL FOOD ITEMS (Verified sustainability data)
CREATE TABLE IF NOT EXISTS ethical_food_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  food_item_id UUID NOT NULL REFERENCES food_items(id) ON DELETE CASCADE,
  certifications TEXT[], -- 'organic', 'fair-trade', 'b-corp'
  source_region TEXT,
  supply_chain_transparency TEXT CHECK (supply_chain_transparency IN ('high', 'medium', 'low')),
  ethical_score DECIMAL(3,1), -- 0-10
  verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(food_item_id)
);

-- =====================================================
-- PART 3: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes on nutrition_meals
CREATE INDEX IF NOT EXISTS idx_nutrition_meals_day_id ON nutrition_meals(day_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_meals_is_eaten ON nutrition_meals(is_eaten);
CREATE INDEX IF NOT EXISTS idx_nutrition_meals_eaten_at ON nutrition_meals(eaten_at);

-- Indexes on nutrition_plans
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_client_id ON nutrition_plans(client_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_created_by ON nutrition_plans(created_by);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_format_version ON nutrition_plans(format_version);

-- Indexes on food_items
CREATE INDEX IF NOT EXISTS idx_food_items_barcode ON food_items(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_food_items_sustainability ON food_items(sustainability_rating) WHERE sustainability_rating IS NOT NULL;

-- Indexes on new tables
CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_earned_at ON achievements(earned_at DESC);

CREATE INDEX IF NOT EXISTS idx_active_macro_cycles_user_id ON active_macro_cycles(user_id);
CREATE INDEX IF NOT EXISTS idx_active_macro_cycles_dates ON active_macro_cycles(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_allergy_profiles_user_id ON allergy_profiles(user_id);

CREATE INDEX IF NOT EXISTS idx_meal_prep_plans_user_id ON meal_prep_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_prep_plans_date ON meal_prep_plans(prep_date);

CREATE INDEX IF NOT EXISTS idx_restaurant_estimations_user_id ON restaurant_meal_estimations(user_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_estimations_created ON restaurant_meal_estimations(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_voice_commands_user_id ON voice_commands(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_commands_recorded ON voice_commands(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_daily_sustainability_user_date ON daily_sustainability_summaries(user_id, date);

-- =====================================================
-- PART 4: ENABLE ROW LEVEL SECURITY
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

-- =====================================================
-- PART 5: CREATE RLS POLICIES
-- =====================================================

-- Households: Users can manage households they created or are members of
CREATE POLICY "Users can view their households" ON households
  FOR SELECT USING (created_by = auth.uid() OR auth.uid() = ANY(members));

CREATE POLICY "Users can create households" ON households
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update their households" ON households
  FOR UPDATE USING (created_by = auth.uid() OR auth.uid() = ANY(members));

-- Macro cycles: Users manage their own
CREATE POLICY "Users can manage their macro cycles" ON active_macro_cycles
  FOR ALL USING (user_id = auth.uid());

-- Allergy profiles: Users manage their own
CREATE POLICY "Users can manage their allergy profile" ON allergy_profiles
  FOR ALL USING (user_id = auth.uid());

-- Achievements: Users can view and create their own
CREATE POLICY "Users can view their achievements" ON achievements
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "System can create achievements" ON achievements
  FOR INSERT WITH CHECK (true);

-- Challenges: Public read, admin create
CREATE POLICY "Anyone can view active challenges" ON challenges
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage challenges" ON challenges
  FOR ALL USING (true); -- Add admin check here

-- Challenge participants: Users manage their participation
CREATE POLICY "Users can manage their challenge participation" ON challenge_participants
  FOR ALL USING (user_id = auth.uid());

-- Meal prep plans: Users manage their own
CREATE POLICY "Users can manage their meal prep plans" ON meal_prep_plans
  FOR ALL USING (user_id = auth.uid());

-- Restaurant estimations: Users manage their own
CREATE POLICY "Users can manage their restaurant logs" ON restaurant_meal_estimations
  FOR ALL USING (user_id = auth.uid());

-- Voice commands: Users manage their own
CREATE POLICY "Users can manage their voice commands" ON voice_commands
  FOR ALL USING (user_id = auth.uid());

-- Chat messages: Users manage their own
CREATE POLICY "Users can manage their chat messages" ON chat_messages
  FOR ALL USING (user_id = auth.uid());

-- Collaboration sessions: Participants can view/edit
CREATE POLICY "Users can view collaboration sessions they're in" ON collaboration_sessions
  FOR SELECT USING (host_user_id = auth.uid() OR auth.uid() = ANY(active_users));

-- Comment threads: Users can view comments on their meals
CREATE POLICY "Users can view comments on accessible meals" ON comment_threads
  FOR SELECT USING (true); -- Add proper meal ownership check

CREATE POLICY "Users can create comments" ON comment_threads
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Daily sustainability: Users manage their own
CREATE POLICY "Users can manage their sustainability data" ON daily_sustainability_summaries
  FOR ALL USING (user_id = auth.uid());

COMMIT;

-- =====================================================
-- MIGRATION 1 COMPLETE
-- =====================================================
-- Next: Run migration 2 (archive_and_migrate)
-- =====================================================