# Nutrition Platform Rebuild - Phased Rollout Strategy

**Version:** 2.0
**Last Updated:** 2025-09-30
**Owner:** Development Team

---

## Executive Summary

This document outlines the complete 12-week phased rollout strategy for the Vagus App nutrition platform rebuild. The strategy ensures zero-downtime migration, maintains data integrity, and delivers features incrementally to minimize risk while maximizing value delivery.

**Key Metrics:**
- **Timeline:** 12 weeks (3 months)
- **Phases:** 4 major phases
- **Features Delivered:** 60+ major features
- **Services Created:** 25+ new services
- **Lines of Code:** 15,000+ lines
- **Zero Downtime:** Parallel running with feature flags
- **Risk Mitigation:** Gradual rollout with A/B testing

---

## Table of Contents

1. [Phase 1: Foundation (Weeks 1-3)](#phase-1-foundation)
2. [Phase 2: Essential Features (Weeks 4-6)](#phase-2-essential-features)
3. [Phase 3: Advanced Features (Weeks 7-9)](#phase-3-advanced-features)
4. [Phase 4: Delight & Innovation (Weeks 10-12)](#phase-4-delight-innovation)
5. [Migration Strategy](#migration-strategy)
6. [Database Migration Scripts](#database-migration-scripts)
7. [Testing Strategy](#testing-strategy)
8. [Rollback Plan](#rollback-plan)
9. [Success Metrics](#success-metrics)

---

## Phase 1: Foundation (Weeks 1-3)

**Goal:** Establish rock-solid infrastructure and fix all critical issues.

### Week 1: Data Layer & Architecture

#### Critical Fixes
- [ ] **Replace all `.single()` with `.maybeSingle()`** across entire codebase
  - Files affected: ~50 database query locations
  - Search pattern: `\.single\(\)`
  - Replace with proper null handling
  - Add try-catch blocks with PostgrestException handling

- [ ] **Implement SafeDatabaseService**
  - File: `lib/services/nutrition/safe_database_service.dart` ✅ (Already created)
  - Replace direct Supabase calls with safe wrappers
  - Add comprehensive error handling
  - Implement optimistic updates with rollback

- [ ] **Fix Network Image Loading**
  - Create: `lib/widgets/common/safe_network_image.dart`
  - Handle null URLs gracefully
  - Add loading skeletons
  - Implement error states with retry
  - Cache images locally

#### Architecture Setup
- [ ] **Create Unified NutritionHubScreen**
  - File: `lib/screens/nutrition/nutrition_hub_screen.dart`
  - Implement role detection (coach vs client)
  - Single entry point for all nutrition features
  - Dynamic UI based on user role

- [ ] **State Management Setup**
  - Choose: Provider or Riverpod (recommend Provider for simplicity)
  - Create: `lib/providers/nutrition_provider.dart`
  - Implement: `NutritionStateManager`
  - Set up: Global app state for nutrition

- [ ] **Base Models with All Fields**
  - Update: `lib/models/nutrition/nutrition_plan.dart`
  - Add fields: `format_version`, `migrated_at`, `metadata`
  - Update: `lib/models/nutrition/meal.dart`
  - Add fields: `meal_photo_url`, `check_in_at`, `is_eaten`, `eaten_at`

#### Database Migrations
```sql
-- Run migration: 001_add_new_fields.sql
ALTER TABLE nutrition_plans ADD COLUMN IF NOT EXISTS format_version TEXT DEFAULT '2.0';
ALTER TABLE nutrition_plans ADD COLUMN IF NOT EXISTS migrated_at TIMESTAMP;
ALTER TABLE nutrition_plans ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

ALTER TABLE meals ADD COLUMN IF NOT EXISTS meal_photo_url TEXT;
ALTER TABLE meals ADD COLUMN IF NOT EXISTS check_in_at TIMESTAMP;
ALTER TABLE meals ADD COLUMN IF NOT EXISTS is_eaten BOOLEAN DEFAULT FALSE;
ALTER TABLE meals ADD COLUMN IF NOT EXISTS eaten_at TIMESTAMP;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);
CREATE INDEX IF NOT EXISTS idx_meals_user_id ON meals(user_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_client_id ON nutrition_plans(client_id);
```

**Week 1 Deliverables:**
- ✅ Zero database errors
- ✅ All images load properly
- ✅ Clean architecture established
- ✅ Database migrations completed

---

### Week 2: Core Viewer (Client Mode)

#### UI Components
- [ ] **Meal Timeline Cards**
  - Create: `lib/widgets/nutrition/meal_timeline_card.dart`
  - Features: Photo display, macro summary, time display
  - Animations: Smooth entrance, tap to expand
  - States: Loading, error, empty

- [ ] **Macro Visualization**
  - Create: `lib/widgets/nutrition/macro_progress_ring.dart`
  - Circular progress rings for Protein/Carbs/Fat/Calories
  - Animated fills on mount
  - Color coding: Green (on track), Yellow (close), Red (over)

- [ ] **Meal Detail Modal**
  - Create: `lib/widgets/nutrition/meal_detail_modal.dart`
  - Tabs: Overview, Foods, Macros, Notes, History
  - Full-screen modal with smooth transitions
  - Edit mode for client adjustments

- [ ] **Daily Insights Panel**
  - Create: `lib/widgets/nutrition/daily_insights_panel.dart`
  - Display: Macro summary, water intake, calories remaining
  - Smart tips: AI-generated suggestions
  - Progress toward goals

- [ ] **Meal Check-ins**
  - Feature: Swipe to mark meal as eaten
  - Haptic feedback on check
  - Timestamp capture
  - Update progress rings in real-time

#### Error States & Loading
- [ ] **Loading Skeletons**
  - Create: `lib/widgets/common/shimmer_loading.dart`
  - Skeleton for: Meal cards, progress rings, lists
  - Smooth pulse animation

- [ ] **Error States**
  - Create: `lib/widgets/common/error_state.dart`
  - User-friendly error messages
  - Retry buttons
  - Contact support option

**Week 2 Deliverables:**
- ✅ Beautiful client viewing experience
- ✅ Zero crashes in core flows
- ✅ All states handled (loading, error, empty, success)
- ✅ Smooth animations throughout

---

### Week 3: Core Builder (Coach Mode)

#### Editing Features
- [ ] **Inline Meal Editing**
  - Create: `lib/widgets/nutrition/inline_meal_editor.dart`
  - Drag-and-drop reordering
  - Quick add/remove foods
  - Live macro calculations
  - Undo/redo support

- [ ] **Advanced Food Picker**
  - File: `lib/screens/nutrition/widgets/shared/food_picker_2_0.dart` ✅ (Already created)
  - 5 tabs: Search, Scan, Recent, Favorites, Custom
  - Multi-select mode
  - Bulk actions
  - Smart search with debouncing

- [ ] **Custom Food Creator**
  - Create: `lib/screens/nutrition/custom_food_editor.dart`
  - Form: Name, macros, serving size, photo
  - Barcode integration
  - Save to favorites

- [ ] **Live Macro Calculations**
  - Service: Real-time macro aggregation
  - Display: Total macros update as foods added/removed
  - Validation: Warn if macros don't match targets
  - Auto-save: Save draft every 30 seconds

- [ ] **Save/Publish Functionality**
  - Dual buttons: "Save Draft" and "Publish to Client"
  - Confirmation modal before publish
  - Notifications: Client notified on publish
  - Version tracking: Save revision history

#### Empty States
- [ ] **Helpful CTAs**
  - Empty plan: "Start by adding your first meal"
  - Empty meal: "Add foods from the picker below"
  - Empty day: "Generate with AI" button

**Week 3 Deliverables:**
- ✅ Complete coach editing experience
- ✅ All CRUD operations working
- ✅ Zero data loss
- ✅ Intuitive UX with helpful guidance

---

### Phase 1 Testing & QA

#### Test Checklist
- [ ] All database operations use `.maybeSingle()`
- [ ] All images load or show error states
- [ ] Role detection works correctly
- [ ] Meals display correctly for clients
- [ ] Coaches can create and edit plans
- [ ] Macro calculations are accurate
- [ ] No crashes in any core flow
- [ ] All loading states show properly
- [ ] All error states handled gracefully
- [ ] Offline mode basics work

#### Performance Targets
- [ ] Time to first content: < 500ms
- [ ] Meal card render: < 100ms
- [ ] Food picker search: < 300ms debounce
- [ ] Plan save: < 1s
- [ ] Memory usage: < 100MB baseline

---

## Phase 2: Essential Features (Weeks 4-6)

**Goal:** Achieve feature parity with old system and add essential new features.

### Week 4: Meal Management

#### AI Meal Generation
- [ ] **Full Day Generation**
  - Service: `lib/services/ai/nutrition_ai.dart` (enhance existing)
  - Input: Target macros, dietary preferences, restrictions
  - Output: Complete day with breakfast, lunch, dinner, snacks
  - Review: Allow coach to review and adjust before publishing

- [ ] **Recipe Browser**
  - Create: `lib/screens/nutrition/recipe_library_screen.dart` ✅ (Already exists)
  - Features: Search, filter by cuisine/meal type
  - Integration: Add recipe directly to meal plan
  - Import: From URL or manual entry

- [ ] **Barcode Scanner**
  - Create: `lib/screens/nutrition/barcode_scan_screen.dart` ✅ (Already exists)
  - Use: `mobile_scanner` package
  - Lookup: Food database by barcode
  - Fallback: Manual entry if not found

- [ ] **Meal Photo Upload**
  - Feature: Camera or gallery picker
  - Upload: To Supabase Storage
  - Compression: Optimize before upload
  - Display: In meal cards with zoom

- [ ] **Comments System**
  - Create: `lib/widgets/nutrition/meal_comments.dart`
  - Thread: Coach ↔ Client conversations
  - Real-time: Using Supabase realtime
  - Notifications: Push when new comment

- [ ] **Attachments**
  - Support: PDF, images, documents
  - Upload: To Supabase Storage
  - Display: Preview thumbnails
  - Download: Option to save locally

**Week 4 Deliverables:**
- ✅ AI can generate complete meal plans
- ✅ Barcode scanner works reliably
- ✅ Photos and attachments working
- ✅ Coach-client communication flowing

---

### Week 5: Supplements & Grocery

#### Supplement Manager
- [ ] **CRUD Operations**
  - Create: `lib/screens/supplements/supplement_editor_sheet.dart` ✅ (Already exists)
  - List: All supplements with dosage
  - Edit: Modify dosage, timing, notes
  - Delete: With confirmation

- [ ] **Tracking & Reminders**
  - Feature: Daily check-off list
  - Reminders: Push notifications at scheduled times
  - History: Log of taken supplements
  - Adherence: Track compliance rate

#### Grocery Lists
- [ ] **Auto-Generated Lists**
  - Service: `lib/services/nutrition/grocery_service.dart` ✅ (Already exists)
  - Input: Meal plan for the week
  - Output: Categorized shopping list
  - Smart: Combine quantities, remove duplicates

- [ ] **Pantry Integration**
  - Service: `lib/services/nutrition/pantry_service.dart` ✅ (Already exists)
  - Feature: Mark items as "already have"
  - Auto-exclude: From shopping list
  - Inventory: Track pantry stock

- [ ] **Export Options**
  - PDF: Printable shopping list
  - Share: Via text/email
  - Deep links: Instacart, Amazon Fresh integration

**Week 5 Deliverables:**
- ✅ Complete supplement management
- ✅ Smart grocery lists working
- ✅ Export and share functionality
- ✅ Pantry integration complete

---

### Week 6: Polish & Performance

#### Animations & Transitions
- [ ] **Smooth Animations**
  - Hero transitions: Between screens
  - Fade in/out: For cards and modals
  - Slide up: For bottom sheets
  - Scale: For buttons and interactions

#### Caching & Offline
- [ ] **Multi-Layer Caching**
  - Service: `lib/services/cache/cache_service.dart` ✅ (Already exists)
  - Memory cache: Session data
  - Persistent cache: 24h TTL
  - Offline cache: Critical data, never expires

- [ ] **Offline Support**
  - Service: `lib/services/offline/offline_operation_queue.dart` ✅ (Already exists)
  - Queue: Operations while offline
  - Sync: Auto-sync when connection restored
  - Conflicts: Merge strategy for conflicts

#### Image Optimization
- [ ] **Compression**
  - Use: `flutter_image_compress`
  - Quality: 85%
  - Resize: Max 1920x1080
  - Format: WebP when possible

#### Performance
- [ ] **Profiling**
  - Tool: Flutter DevTools
  - Metrics: Frame times, memory, network
  - Fixes: Optimize bottlenecks
  - Target: 60fps in all screens

#### Accessibility
- [ ] **WCAG AA Compliance**
  - Service: `lib/services/accessibility/accessibility_service.dart` ✅ (Already exists)
  - Semantic labels: For all widgets
  - Screen readers: VoiceOver/TalkBack support
  - Contrast: All text passes AA standards
  - Touch targets: Minimum 48x48

#### RTL Language Support
- [ ] **Internationalization**
  - Service: `lib/services/nutrition/locale_helper.dart` ✅ (Already exists)
  - Languages: EN, AR, KU
  - RTL: Automatic layout flip
  - Translations: All 78+ keys translated

**Week 6 Deliverables:**
- ✅ Buttery smooth 60fps animations
- ✅ Works perfectly offline
- ✅ Images optimized and fast
- ✅ Accessibility compliant
- ✅ RTL languages working

---

### Phase 2 Testing & QA

#### Feature Parity Checklist
- [ ] All old system features working in new system
- [ ] AI generation matches or exceeds old quality
- [ ] Barcode scanner recognition rate > 90%
- [ ] Photos upload and display correctly
- [ ] Comments delivered in real-time
- [ ] Supplements tracked accurately
- [ ] Grocery lists accurate and complete
- [ ] Offline mode works reliably
- [ ] Accessibility score > 95%

---

## Phase 3: Advanced Features (Weeks 7-9)

**Goal:** Deliver competitive advantages that differentiate from other apps.

### Week 7: Intelligence & Insights

#### Analytics
- [ ] **Macro Trend Analytics**
  - Service: `lib/services/nutrition/analytics_engine_service.dart` ✅ (Already created)
  - Features: 7-day and 30-day rolling averages
  - Visualization: Line charts with trends
  - Insights: AI-generated observations

- [ ] **Progress Tracking Dashboard**
  - Create: `lib/screens/nutrition/progress_dashboard_screen.dart`
  - Metrics: Weight, body fat, measurements
  - Charts: Progress over time
  - Milestones: Celebrate achievements

- [ ] **Weekly Nutrition Reports**
  - Service: Auto-generate every Monday
  - Content: Compliance, macro adherence, insights
  - Delivery: Push notification + email
  - PDF: Downloadable report

- [ ] **AI Suggestions**
  - Feature: Smart alerts based on patterns
  - Examples: "You tend to skip breakfast on Mondays"
  - Recommendations: Personalized tips
  - Timing: Non-intrusive delivery

- [ ] **Correlation Engine (Basic)**
  - Service: Analyze relationships between metrics
  - Examples: Protein intake vs. weight change
  - Visualization: Scatter plots
  - Insights: Statistical significance

**Week 7 Deliverables:**
- ✅ Comprehensive analytics dashboard
- ✅ Weekly reports generating automatically
- ✅ AI insights relevant and helpful
- ✅ Correlation engine finding patterns

---

### Week 8: Advanced Planning

#### Advanced Services
- [ ] **Meal Prep Mode**
  - Service: `lib/services/nutrition/meal_prep_service.dart` ✅ (Already created)
  - Features: Batch cooking analysis, prep schedules
  - Optimization: Parallel task suggestions
  - Storage: Recommendations and durations

- [ ] **Macro Cycling**
  - Service: `lib/services/nutrition/macro_cycling_service.dart` ✅ (Already created)
  - Templates: 5-2 carb cycle, training-based, zig-zag
  - Custom: Create own cycles
  - Calendar: Visual display of cycle

- [ ] **Restaurant Database**
  - Service: `lib/services/nutrition/restaurant_service.dart` ✅ (Already created)
  - Database: Chain restaurants with verified nutrition
  - Estimation: AI macro estimation from photos
  - Tips: Coach dining guidance

- [ ] **Allergy Scanner**
  - Service: `lib/services/nutrition/allergy_medical_service.dart` ✅ (Already created)
  - Scanning: Check foods against user allergies
  - Alerts: Red warnings for severe allergies
  - Alternatives: Suggest safe substitutes

- [ ] **Medical Condition Support**
  - Service: Same as allergy scanner
  - Conditions: Diabetes, kidney disease, heart disease, PCOS, IBS, celiac
  - Guidelines: Dietary recommendations per condition
  - Monitoring: Track compliance

**Week 8 Deliverables:**
- ✅ Meal prep planning working
- ✅ Macro cycling functional
- ✅ Restaurant database integrated
- ✅ Medical support comprehensive

---

### Week 9: Integrations

#### External Integrations
- [ ] **Wearable Sync**
  - Service: `lib/services/nutrition/integration_ecosystem_service.dart` ✅ (Already created)
  - Platforms: Apple Health, Google Fit, Fitbit, Garmin, Whoop, Oura
  - Data: Import activity, sleep, heart rate
  - Bidirectional: Export nutrition to wearables

- [ ] **Calendar Integration**
  - Service: Same as integration service
  - Platforms: Google Calendar, Apple Calendar, Outlook
  - Export: Meal times and reminders
  - Sync: Two-way synchronization

- [ ] **Grocery Delivery**
  - Service: Same as integration service
  - Platforms: Instacart, Amazon Fresh, Walmart+
  - Deep links: One-tap ordering
  - Lists: Export shopping list directly

- [ ] **Meal Kit Services**
  - Service: Same as integration service
  - Platforms: HelloFresh, Blue Apron, Factor
  - Integration: Import meal kit recipes
  - Tracking: Track deliveries

- [ ] **Export to Other Platforms**
  - Formats: CSV, JSON, PDF
  - Platforms: MyFitnessPal, Cronometer, Lose It
  - API: RESTful export endpoints

**Week 9 Deliverables:**
- ✅ Apple Health/Google Fit working
- ✅ Calendar sync operational
- ✅ Grocery delivery integrated
- ✅ Export functionality complete

---

### Phase 3 Testing & QA

#### Power User Features Checklist
- [ ] Analytics provide valuable insights
- [ ] Meal prep saves users time
- [ ] Macro cycling templates work correctly
- [ ] Restaurant database has 100+ chains
- [ ] Allergy scanner catches all allergens
- [ ] Wearable sync reliable (>99% success)
- [ ] Calendar events created correctly
- [ ] Grocery delivery links work
- [ ] Export formats valid and complete

---

## Phase 4: Delight & Innovation (Weeks 10-12)

**Goal:** Deliver mind-blowing features that create viral moments.

### Week 10: Gamification

#### Gamification System
- [ ] **Achievement System**
  - Service: `lib/services/nutrition/gamification_service.dart` ✅ (Already created)
  - Badges: 17+ predefined achievements
  - Categories: Streaks, nutrition, preparation, tracking, goals
  - Unlocking: Automatic detection and awarding

- [ ] **Challenges & Leaderboards**
  - Service: Same as gamification service
  - Types: No sugar, eat the rainbow, hydration, protein goals
  - Duration: 7, 14, 30 days
  - Leaderboards: Cohort and global rankings

- [ ] **Streaks & Habits**
  - Service: Same as gamification service
  - Tracking: Daily logging streaks
  - Protection: Streak freeze for missed days
  - Milestones: 7, 30, 100, 365 days

- [ ] **Social Sharing**
  - Feature: Shareable achievement cards
  - Platforms: Instagram, Facebook, Twitter
  - Design: Beautiful gradient cards with stats
  - Privacy: User controls what to share

- [ ] **Badges & Rewards**
  - Custom: Coaches can award badges
  - Display: Profile badge showcase
  - Notifications: Celebrate new achievements
  - Motivation: Gamified progress

**Week 10 Deliverables:**
- ✅ Achievement system live
- ✅ Challenges engaging users
- ✅ Streaks tracking working
- ✅ Social sharing viral

---

### Week 11: Collaboration

#### Collaboration Features
- [ ] **Family Meal Planning**
  - Service: `lib/services/nutrition/collaboration_service.dart` ✅ (Already created)
  - Household: Multi-member meal planning
  - Preferences: Track each member's dietary needs
  - Shared: Single grocery list for household

- [ ] **Real-time Co-editing**
  - Service: Same as collaboration service
  - Technology: Supabase Realtime
  - Presence: See who's editing
  - Cursors: Show collaborator positions
  - Conflicts: Merge strategy for edits

- [ ] **Group Coaching**
  - Service: Same as collaboration service
  - Cohorts: Coach multiple clients together
  - Shared: Group challenges and resources
  - Analytics: Cohort performance metrics

- [ ] **Version History**
  - Service: Same as collaboration service
  - Tracking: Every save creates version
  - Display: Timeline of changes
  - Rollback: Restore previous versions

- [ ] **Advanced Commenting**
  - Service: Same as collaboration service
  - Threads: Nested conversations
  - Context: Comments on specific meals/foods
  - Mentions: @mention collaborators
  - Resolve: Mark threads as resolved

**Week 11 Deliverables:**
- ✅ Family planning working
- ✅ Real-time co-editing smooth
- ✅ Group coaching functional
- ✅ Version history tracking all changes

---

### Week 12: Future-Forward

#### Cutting-Edge Features
- [ ] **Voice Interface**
  - Service: `lib/services/nutrition/voice_interface_service.dart` ✅ (Already created)
  - Recognition: Speech-to-text meal logging
  - Commands: "Show me high protein breakfast"
  - TTS: Voice responses
  - Hands-free: Cooking mode

- [ ] **AI Nutrition Coach Chat**
  - Service: Same as voice interface service
  - Conversational: Natural language Q&A
  - Context: Aware of user's plan and goals
  - Recommendations: Personalized advice
  - History: Persistent chat history

- [ ] **Sustainability Metrics**
  - Service: `lib/services/nutrition/sustainability_service.dart` ✅ (Already created)
  - Carbon: Track CO2 footprint per meal
  - Water: Usage in liters
  - Impact: Sustainability rating
  - Alternatives: Eco-friendly suggestions

- [ ] **Predictive Modeling**
  - Service: `lib/services/nutrition/analytics_engine_service.dart` (enhance)
  - Goals: Predict achievement dates
  - Trends: Forecast future progress
  - Recommendations: Adjust plan for faster results
  - Confidence: Show prediction accuracy

- [ ] **Beta Features Flag System**
  - Service: `lib/services/feature_flags_service.dart` ✅ (Already exists)
  - Flags: Enable/disable features remotely
  - A/B Testing: Test variations
  - Rollout: Gradual feature releases
  - Rollback: Instant disable if issues

**Week 12 Deliverables:**
- ✅ Voice interface intuitive
- ✅ AI coach helpful
- ✅ Sustainability tracking working
- ✅ Predictions accurate
- ✅ Feature flags operational

---

### Phase 4 Testing & QA

#### Innovation Checklist
- [ ] Gamification drives engagement
- [ ] Collaboration smooth and bug-free
- [ ] Voice recognition >90% accurate
- [ ] AI chat responses relevant
- [ ] Sustainability data accurate
- [ ] Predictions within 10% margin
- [ ] Feature flags work instantly
- [ ] Overall experience feels magical

---

## Migration Strategy

### A. Parallel Running (Week 3-4)

#### Setup
```dart
// Feature flag configuration
class FeatureFlags {
  static const NUTRITION_V2_ENABLED = 'nutrition_v2_enabled';

  static bool useNutritionV2(String userId) {
    // Check if user is in beta group
    return betaUsers.contains(userId);
  }
}
```

#### Routing
```dart
// Navigation logic
Widget getNutritionScreen(BuildContext context) {
  final userId = context.read<AuthProvider>().userId;

  if (FeatureFlags.useNutritionV2(userId)) {
    return NutritionHubScreen(); // New system
  } else {
    return ModernNutritionPlanViewer(); // Old system
  }
}
```

#### Beta Testing
- **Week 3:** Internal team testing (10 users)
- **Week 4:** Select beta users (50 users)
- **Metrics:** Error rate, performance, satisfaction
- **Feedback:** Rapid iteration based on feedback

---

### B. Gradual Rollout (Week 5-6)

#### Week 5: 10% Rollout
```dart
static bool useNutritionV2(String userId) {
  // 10% of users
  final hash = userId.hashCode % 100;
  return hash < 10;
}
```

**Monitoring:**
- Error rate: Target < 0.1%
- Performance: Time to first content < 500ms
- Engagement: Session duration
- Satisfaction: In-app survey (NPS)

#### Week 6: 50% Rollout
```dart
static bool useNutritionV2(String userId) {
  // 50% of users
  final hash = userId.hashCode % 100;
  return hash < 50;
}
```

**A/B Testing:**
- Compare new vs old system metrics
- Engagement: Daily active usage
- Retention: 7-day and 30-day
- Conversion: Free to paid upgrades

---

### C. Full Migration (Week 7)

#### 100% Rollout
```dart
static bool useNutritionV2(String userId) {
  return true; // Everyone on new system
}
```

#### Communication
- **In-app banner:** "Welcome to the new nutrition experience!"
- **Email:** Feature highlights and tutorial
- **Push notification:** "Check out what's new"
- **Video tutorial:** 2-minute walkthrough

#### Support
- **Help center:** Updated articles
- **In-app chat:** Support team ready
- **FAQ:** Common questions answered
- **Feedback:** Easy reporting mechanism

---

### D. Data Migration

#### Schema Updates
```sql
-- Migration: 001_add_nutrition_v2_fields.sql
-- Run this BEFORE launching new system

BEGIN;

-- Nutrition Plans
ALTER TABLE nutrition_plans
  ADD COLUMN IF NOT EXISTS format_version TEXT DEFAULT '2.0',
  ADD COLUMN IF NOT EXISTS migrated_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;

-- Meals
ALTER TABLE meals
  ADD COLUMN IF NOT EXISTS meal_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS check_in_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS is_eaten BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS eaten_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS meal_comments JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS attachments JSONB DEFAULT '[]';

-- Food Items
ALTER TABLE food_items
  ADD COLUMN IF NOT EXISTS barcode TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT,
  ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS sustainability_rating TEXT,
  ADD COLUMN IF NOT EXISTS carbon_footprint DECIMAL,
  ADD COLUMN IF NOT EXISTS ethical_labels TEXT[];

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);
CREATE INDEX IF NOT EXISTS idx_meals_user_id ON meals(user_id);
CREATE INDEX IF NOT EXISTS idx_meals_is_eaten ON meals(is_eaten);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_client_id ON nutrition_plans(client_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_coach_id ON nutrition_plans(coach_id);
CREATE INDEX IF NOT EXISTS idx_food_items_barcode ON food_items(barcode);

COMMIT;
```

#### Data Preservation
```sql
-- Archive old data before migration
-- Migration: 002_archive_old_data.sql

BEGIN;

-- Create archive tables
CREATE TABLE IF NOT EXISTS nutrition_plans_archive AS
SELECT * FROM nutrition_plans
WHERE format_version IS NULL OR format_version = '1.0';

CREATE TABLE IF NOT EXISTS meals_archive AS
SELECT * FROM meals
WHERE id IN (
  SELECT m.id FROM meals m
  JOIN nutrition_plans np ON m.plan_id = np.id
  WHERE np.format_version IS NULL OR np.format_version = '1.0'
);

-- Mark archived plans
UPDATE nutrition_plans
SET is_archived = TRUE,
    format_version = '1.0'
WHERE format_version IS NULL;

COMMIT;
```

#### Migration Script
```sql
-- Migration: 003_migrate_to_v2.sql
-- Migrate existing plans to new format

BEGIN;

-- Update all plans to v2.0
UPDATE nutrition_plans
SET format_version = '2.0',
    migrated_at = NOW()
WHERE format_version IS NULL OR format_version = '1.0';

-- Set default metadata
UPDATE nutrition_plans
SET metadata = jsonb_build_object(
  'migrated_from', 'v1.0',
  'migration_date', NOW(),
  'original_id', id
)
WHERE metadata = '{}';

COMMIT;
```

#### Rollback Script
```sql
-- EMERGENCY: Rollback to old system
-- Migration: 999_rollback_to_v1.sql

BEGIN;

-- Restore from archive
TRUNCATE nutrition_plans;
INSERT INTO nutrition_plans SELECT * FROM nutrition_plans_archive;

TRUNCATE meals;
INSERT INTO meals SELECT * FROM meals_archive;

-- Update version
UPDATE nutrition_plans SET format_version = '1.0';

COMMIT;
```

---

## Testing Strategy

### Unit Tests
**Target Coverage:** 88%

```bash
# Run all unit tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Test Files Created:**
- ✅ `test/services/nutrition/role_manager_test.dart`
- ✅ `test/services/accessibility/accessibility_service_test.dart`
- ✅ `test/services/nutrition/locale_helper_test.dart`
- [ ] `test/services/nutrition/meal_prep_service_test.dart`
- [ ] `test/services/nutrition/gamification_service_test.dart`
- [ ] `test/services/nutrition/analytics_engine_service_test.dart`

---

### Widget Tests
**Target:** 50+ widget tests

```bash
# Run widget tests
flutter test test/widgets/
```

**Test Files Created:**
- ✅ `test/widgets/nutrition/macro_progress_bar_test.dart`
- [ ] `test/widgets/nutrition/meal_timeline_card_test.dart`
- [ ] `test/widgets/nutrition/food_picker_test.dart`

---

### Integration Tests
**Target:** 10+ user flow tests

```bash
# Run integration tests
flutter test integration_test/
```

**Test Files Created:**
- ✅ `test/integration/nutrition_flow_test.dart` (template)
- [ ] `integration_test/coach_create_plan_test.dart`
- [ ] `integration_test/client_view_plan_test.dart`
- [ ] `integration_test/meal_logging_test.dart`

---

### Manual QA
**Checklist:** ✅ `test/manual_qa_checklist.md` (200+ items)

**Categories:**
1. Core Functionality (50 items)
2. Nutrition Features (60 items)
3. Role-Based UX (20 items)
4. Technical Excellence (30 items)
5. UI/UX Polish (20 items)
6. Internationalization (15 items)
7. Accessibility (20 items)
8. Platform-Specific (30 items)
9. Edge Cases (20 items)
10. Regression Tests (10 items)

---

## Rollback Plan

### Immediate Rollback (< 1 hour)

#### Scenario: Critical bug found after 100% rollout

**Step 1: Disable New System**
```dart
// Update feature flag via Supabase
await supabase
  .from('feature_flags')
  .update({'enabled': false})
  .eq('flag_name', 'nutrition_v2_enabled');
```

**Step 2: Force App Refresh**
```dart
// Send push notification to all users
OneSignal.shared.sendNotification({
  'contents': {'en': 'Important update available'},
  'data': {'force_refresh': true}
});
```

**Step 3: Rollback Database**
```bash
# If data corrupted, restore from archive
psql -U postgres -d vagus_db < rollback_to_v1.sql
```

**Step 4: Monitor**
- Error rates return to normal
- Users successfully using old system
- No data loss reported

---

### Partial Rollback (< 4 hours)

#### Scenario: Feature causing issues for subset of users

**Step 1: Identify Affected Users**
```sql
SELECT user_id
FROM error_logs
WHERE error_message LIKE '%nutrition%'
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id;
```

**Step 2: Disable for Affected Users**
```dart
// Add users to rollback list
await supabase
  .from('user_feature_flags')
  .insert(affectedUsers.map((userId) => {
    'user_id': userId,
    'flag_name': 'nutrition_v2_enabled',
    'enabled': false,
  }));
```

**Step 3: Communicate**
- Email affected users
- Acknowledge issue
- Provide timeline for fix

---

## Success Metrics

### Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Error Rate | < 0.1% | Sentry error tracking |
| API Response Time | < 500ms | Supabase metrics |
| App Crash Rate | < 0.01% | Firebase Crashlytics |
| Page Load Time | < 2s | Analytics |
| Memory Usage | < 150MB | DevTools profiler |
| Cache Hit Rate | > 80% | Custom analytics |
| Offline Success | > 95% | Sync logs |

### Business Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Daily Active Users | +20% | Analytics |
| Session Duration | +30% | Analytics |
| Feature Adoption | > 60% | Feature usage logs |
| Client Satisfaction | NPS > 50 | In-app survey |
| Coach Productivity | +40% | Time tracking |
| Meal Plan Compliance | +25% | Check-in rate |
| Retention (7-day) | > 75% | Cohort analysis |
| Retention (30-day) | > 50% | Cohort analysis |

### User Experience Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to First Plan | < 5 min | User flow analytics |
| Food Search Speed | < 1s | Performance logs |
| Meal Logging Time | < 30s | User flow analytics |
| Error Recovery Rate | > 90% | Error tracking |
| Accessibility Score | > 95% | Automated testing |
| User Delight Score | > 4.5/5 | App store reviews |

---

## Communication Plan

### Internal Team

**Weekly Sync:**
- Every Monday 9am
- Review progress vs plan
- Identify blockers
- Adjust timeline if needed

**Daily Standups:**
- 15 minutes
- What shipped yesterday
- What shipping today
- Any blockers

**Slack Channel:**
- #nutrition-rebuild
- Real-time updates
- Quick questions
- Celebrate wins

---

### External Users

**Beta Program:**
- Week 3: Invite email
- Weekly: Progress updates
- Survey: Feedback requests
- Thank you: Beta badge reward

**General Users:**
- Week 5: "Coming soon" teaser
- Week 6: Feature announcements
- Week 7: "Now live" celebration
- Week 8: Tutorial videos

**Support Team:**
- Week 2: Training sessions
- Documentation: Updated help articles
- FAQ: Common questions prepared
- Escalation: Process for critical issues

---

## Risk Mitigation

### High-Risk Items

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Data Loss | Low | Critical | Archive before migration, frequent backups |
| Performance Issues | Medium | High | Load testing, gradual rollout, caching |
| User Confusion | High | Medium | In-app tutorials, help center, support ready |
| API Failures | Low | High | Offline mode, retry logic, fallbacks |
| Integration Breaks | Medium | Medium | Mock testing, partner communication |
| Team Bandwidth | High | Medium | Clear priorities, buffer time, overtime if needed |

---

## Contingency Plans

### Plan B: Extended Timeline
If critical issues arise, extend timeline by 2 weeks:
- Phase 1: +1 week
- Phase 2: +1 week
- Phase 3: As planned
- Phase 4: As planned

### Plan C: Reduced Scope
If timeline cannot extend, cut Phase 4 features:
- Move to post-launch roadmap
- Focus on core stability
- Launch Phase 1-3 only

### Plan D: Parallel Systems
If migration too risky:
- Run both systems indefinitely
- Let users choose
- Sunset old system in 6 months

---

## Post-Launch (Week 13+)

### Week 13-14: Stabilization
- Fix all critical bugs
- Optimize performance bottlenecks
- Polish UI/UX based on feedback
- Update documentation

### Week 15-16: Deprecation
- Mark old screens as deprecated
- Add migration prompts
- Prepare code removal

### Week 17-18: Cleanup
- Remove old code
- Archive legacy tests
- Update team documentation
- Celebrate success! 🎉

---

## Appendix

### Resources
- ✅ **API Documentation:** `API_DOCUMENTATION.md`
- ✅ **Migration Guide:** `MIGRATION_GUIDE.md`
- ✅ **Implementation Report:** `IMPLEMENTATION_REPORT.md`
- ✅ **Testing Guide:** `test/README.md`
- ✅ **Manual QA Checklist:** `test/manual_qa_checklist.md`

### Team Contacts
- **Project Lead:** TBD
- **Tech Lead:** TBD
- **Backend Lead:** TBD
- **QA Lead:** TBD
- **Product Manager:** TBD

### Tools
- **Project Management:** Jira / Linear
- **Communication:** Slack
- **Code Review:** GitHub
- **CI/CD:** GitHub Actions
- **Monitoring:** Sentry, Firebase
- **Analytics:** Mixpanel, Amplitude

---

**Document Version:** 1.0
**Next Review:** Week 4 (checkpoint)
**Status:** Ready for Execution ✅

---

## 🚀 LET'S BUILD SOMETHING AMAZING! 🚀