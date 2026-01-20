# VAGUS APP - COMPREHENSIVE CODEBASE AUDIT & ROADMAP

**Date:** 2025-01-XX  
**Auditor:** Cursor AI (Non-Destructive Mode)  
**Status:** READ-ONLY AUDIT COMPLETE

---

## 📋 EXECUTIVE SUMMARY

This audit provides a complete feature map, codebase snapshot, and safe execution plan for the VAGUS fitness coaching platform. The codebase is **Flutter-based** with **Supabase backend**, using **Provider** for state management, and follows a **service-oriented architecture**.

**Key Findings:**
- ✅ **127+ database tables** already exist
- ✅ **Major features implemented** across 11 sprints
- ✅ **Feature flag system** in place for safe rollouts
- ✅ **Admin panels** extensively built (24+ screens)
- ✅ **AI infrastructure** ready (OpenRouter integration)
- 🟡 **Some features partial** (calendar booking UI, billing flows)
- ❌ **PDF not found** - using sprint plan as feature source

---

## 📊 PDF FEATURE MAP (CONSOLIDATED)

*Note: PDF not found in repository. Using `.cursor/plans/vagus-sprint-plan-289421e1.plan.md` as feature source.*

### 1. WORKOUT SUPERCOMPUTER

| Feature | Status | Description | Dependencies | File Ownership |
|---------|--------|-------------|--------------|----------------|
| **AI Workout Generation** | ✅ Implemented | Generate personalized workout plans via AI | `workout_ai.dart`, `ai_client.dart` | `lib/services/ai/workout_ai.dart` |
| **Revolutionary Plan Builder** | ✅ Implemented | Hierarchical plan creation (Plans→Weeks→Days→Exercises) | `workout_plans` table, `workout_service.dart` | `lib/screens/workout/revolutionary_plan_builder_screen.dart` |
| **Exercise Library** | ✅ Implemented | Comprehensive exercise database with media | `exercise_library` table | `lib/services/workout/exercise_library_service.dart` |
| **Progression Algorithms** | ✅ Implemented | Linear, DUP, Wave periodization | `progression_service.dart` | `lib/services/workout/progression_service.dart` |
| **Workout Analytics** | ✅ Implemented | Volume tracking, PR detection, muscle group distribution | `workout_analytics_service.dart` | `lib/services/workout/workout_analytics_service.dart` |
| **Session Tracking** | ✅ Implemented | Real-time workout logging with sets/reps/weight/RPE | `workout_sessions` table | `lib/screens/workout/client_workout_dashboard_screen.dart` |
| **Rest Timer** | ✅ Implemented | Built-in timer with customizable rest periods | Local state | `lib/widgets/workout/` |
| **Export Functionality** | ✅ Implemented | PDF and image export | `workout_export_service.dart` | `lib/services/workout/workout_export_service.dart` |
| **Exercise History** | ✅ Implemented | Performance tracking over time | `exercise_history` table | `lib/services/workout/exercise_history_service.dart` |
| **Cardio Logging** | ✅ Implemented | Cardiovascular exercise tracking | `workout_cardio` table | `lib/screens/workout/cardio_log_screen.dart` |

**Dependencies:**
- Database: `workout_plans`, `workout_weeks`, `workout_days`, `exercises`, `workout_sessions`, `exercise_logs`
- Services: `WorkoutService`, `WorkoutAI`, `ProgressionService`, `WorkoutAnalyticsService`
- Models: `lib/models/workout/`

---

### 2. NUTRITION DOMINATION

| Feature | Status | Description | Dependencies | File Ownership |
|---------|--------|-------------|--------------|----------------|
| **AI Meal Generation** | ✅ Implemented | AI-powered meal plan generation | `nutrition_ai.dart`, `ai_client.dart` | `lib/services/ai/nutrition_ai.dart` |
| **Nutrition Plan Builder v2** | ✅ Implemented | Modern plan creation with recipes | `nutrition_plans` table | `lib/screens/nutrition/nutrition_plan_builder_screen.dart` |
| **Recipe System** | ✅ Implemented | Custom recipe database with steps | `nutrition_recipes` table | `lib/services/nutrition/recipe_service.dart` |
| **Grocery Lists** | ✅ Implemented | Auto-generated shopping lists | `nutrition_grocery_lists` table | `lib/services/nutrition/grocery_service.dart` |
| **Barcode Scanner** | ✅ Implemented | Quick food item addition | `mobile_scanner` package | `lib/screens/nutrition/barcode_scan_screen.dart` |
| **Macro Tracking** | ✅ Implemented | Protein, carbs, fat, calorie monitoring | `nutrition_items` table | `lib/widgets/nutrition/macro_rings.dart` |
| **Meal Prep Planning** | 🟡 Partial | Meal prep system (data model exists) | `meal_prep_plans` table | `lib/services/nutrition/meal_prep_service.dart` |
| **Pantry Management** | ✅ Implemented | Food inventory tracking | `nutrition_pantry_items` table | `lib/services/nutrition/pantry_service.dart` |
| **Hydration Tracking** | ✅ Implemented | Water intake monitoring | `nutrition_hydration_logs` table | `lib/services/nutrition/hydration_service.dart` |
| **Cost Analysis** | ✅ Implemented | Meal cost calculations | `nutrition_cost_summary` view | `lib/services/nutrition/cost_service.dart` |
| **Sustainability Tracking** | 🟡 Partial | Carbon footprint (data model exists) | `daily_sustainability_summaries` table | `lib/services/nutrition/sustainability_service.dart` (archived) |
| **Gamification** | 🟡 Partial | Streaks, achievements (partial) | `user_streaks`, `achievements` tables | `lib/services/streaks/` |
| **Restaurant Mode** | 🟡 Partial | Advanced restaurant tracking (archived service) | `dining_tips` table | `lib/archive/disabled/restaurant_service.dart.disabled` |
| **Macro Cycling** | 🟡 Partial | Diet phase programs (data exists) | `diet_phase_programs` table | `lib/services/nutrition/` |
| **Allergy & Medical** | ✅ Implemented | Comprehensive allergy tracking | `client_allergies`, `nutrition_allergies` tables | `lib/services/nutrition/allergy_service.dart` |

**Dependencies:**
- Database: `nutrition_plans`, `nutrition_meals`, `nutrition_items`, `nutrition_recipes`, `nutrition_grocery_lists`
- Services: `NutritionService`, `NutritionAI`, `RecipeService`, `GroceryService`
- Models: `lib/models/nutrition/`

---

### 3. MESSAGING + COACH NOTES SECOND BRAIN

| Feature | Status | Description | Dependencies | File Ownership |
|---------|--------|-------------|--------------|----------------|
| **Real-time Messaging** | ✅ Implemented | Instant messaging between coach/client | `messages` table, Supabase Realtime | `lib/screens/messaging/modern_messenger_screen.dart` |
| **Message Threading** | ✅ Implemented | Organized conversation handling | `parent_id` column | `lib/services/messages_service.dart` |
| **AI Smart Replies** | ✅ Implemented | Contextual reply suggestions | `messaging_ai.dart` | `lib/services/ai/messaging_ai.dart` |
| **Read Receipts** | ✅ Implemented | Message read tracking | `message_reads` table | `lib/services/messages_service.dart` |
| **Message Pinning** | ✅ Implemented | Pin important messages | `is_pinned` column | `lib/services/messages_service.dart` |
| **Message Search** | ✅ Implemented | Full-text + embedding search | `message_embeddings` table | `lib/services/messages_service.dart` |
| **Translation Support** | ✅ Implemented | Multi-language message translation | `messaging_ai.dart` | `lib/widgets/messaging/translation_toggle.dart` |
| **Typing Indicators** | ✅ Implemented | Real-time typing status | `message_typing` table | `lib/widgets/messaging/typing_indicator.dart` |
| **File Attachments** | ✅ Implemented | Attach files to messages | `message_attachments` table | `lib/widgets/messaging/attachment_preview.dart` |
| **Coach Notes System** | ✅ Implemented | Rich text notes with versioning | `coach_notes` table | `lib/screens/notes/coach_notes_screen.dart` |
| **Voice Transcription** | ✅ Implemented | Voice-to-text for notes | `transcription_ai.dart` | `lib/services/ai/transcription_ai.dart` |
| **Note Versioning** | ✅ Implemented | Complete version history | `coach_note_versions` table | `lib/screens/notes/note_version_viewer.dart` |
| **Duplicate Detection** | ✅ Implemented | Find similar notes via embeddings | `note_embeddings` table | `lib/services/ai/embedding_helper.dart` |
| **Note Attachments** | ✅ Implemented | Attach files to notes | `coach_note_attachments` table | `lib/components/notes/attach_file_to_note.dart` |

**Dependencies:**
- Database: `messages`, `message_threads`, `message_embeddings`, `coach_notes`, `note_embeddings`
- Services: `MessagesService`, `MessagingAI`, `EmbeddingHelper`, `CoachNotesService`
- Models: `lib/models/` (message, note models)

---

### 4. CALENDAR + SCHEDULING

| Feature | Status | Description | Dependencies | File Ownership |
|---------|--------|-------------|--------------|----------------|
| **Calendar Views** | ✅ Implemented | Month/Week/Day views | `calendar_events` table | `lib/screens/calendar/calendar_screen.dart` |
| **Event CRUD** | ✅ Implemented | Create, read, update, delete events | `event_service.dart` | `lib/services/calendar/event_service.dart` |
| **Recurring Events** | ✅ Implemented | RRULE-based recurrence | `rrule` column | `lib/services/calendar/recurring_event_handler.dart` |
| **Booking System** | 🟡 Partial | Client requests → coach approval | `booking_requests` table | `lib/services/calendar/booking_conflict_service.dart` |
| **Reminders** | ✅ Implemented | Local notifications (15/30/60 min) | `reminder_manager.dart` | `lib/services/calendar/reminder_manager.dart` |
| **Event Tags** | ✅ Implemented | Categorize events | `tags` column | `lib/services/calendar/smart_event_tagger.dart` |
| **File Attachments** | ✅ Implemented | Attach files to events | `attachments` column | `lib/components/calendar/attached_file_preview.dart` |
| **AI Event Tagging** | ✅ Implemented | Auto-suggest event tags | `calendar_ai.dart` | `lib/services/ai/calendar_ai.dart` |
| **Conflict Detection** | ✅ Implemented | Booking conflict detection (edge function) | Edge function | `supabase/functions/booking_conflict/` |
| **Availability Service** | ✅ Implemented | Coach availability management | `availability_service.dart` | `lib/services/calendar/availability_service.dart` |

**Dependencies:**
- Database: `calendar_events`, `booking_requests`, `calendar_attendees`
- Services: `CalendarService`, `EventService`, `ReminderManager`, `CalendarAI`
- Models: `lib/models/` (calendar models)

---

### 5. CLIENT DOPAMINE & RETENTION

| Feature | Status | Description | Dependencies | File Ownership |
|---------|--------|-------------|--------------|----------------|
| **Progress Tracking** | ✅ Implemented | Progress photos, metrics, check-ins | `progress_entries`, `progress_photos` tables | `lib/screens/progress/` |
| **Compliance Scoring** | ✅ Implemented | Weekly compliance metrics | `compliance_score` column | `lib/components/progress/compliance_stats_card.dart` |
| **Streak System** | ✅ Implemented | Daily streak tracking | `user_streaks`, `streak_days` tables | `lib/services/streaks/streak_service.dart` |
| **Progress Charts** | ✅ Implemented | 7/30-day moving averages | `progress_entries` table | `lib/screens/progress/progress_chart.dart` |
| **Check-in Calendar** | ✅ Implemented | Visual check-in calendar | `checkins` table | `lib/screens/progress/client_check_in_calendar.dart` |
| **Coach Feedback Loop** | ✅ Implemented | Coach comments on progress | `checkins` table | `lib/components/progress/coach_feedback_box.dart` |
| **Achievements** | ✅ Implemented | Achievement system | `achievements` table | `lib/services/streaks/achievement_service.dart` |
| **Announcements** | ✅ Implemented | Platform announcements | `announcements` table | `lib/services/announcements_service.dart` |
| **Rank System** | ✅ Implemented | User ranking/VP system | `user_ranks` table | `lib/screens/rank/rank_screen.dart` |
| **Referral System** | ✅ Implemented | Referral codes and rewards | `referral_codes`, `referrals` tables | `lib/services/growth/referrals_service.dart` |

**Dependencies:**
- Database: `progress_entries`, `checkins`, `user_streaks`, `achievements`, `referrals`
- Services: `ProgressService`, `StreakService`, `ReferralsService`
- Models: `lib/models/progress/`, `lib/models/growth/`

---

### 6. ADMIN GOD-MODE

| Feature | Status | Description | Dependencies | File Ownership |
|---------|--------|-------------|--------------|----------------|
| **Admin Hub** | ✅ Implemented | Central command center | Admin role check | `lib/screens/admin/admin_hub_screen.dart` |
| **User Management** | ✅ Implemented | User CRUD, role management | `profiles` table | `lib/screens/admin/user_manager_panel.dart` |
| **Coach Approval** | ✅ Implemented | Approve/deny coach applications | `coach_applications` table | `lib/screens/admin/coach_approval_panel.dart` |
| **AI Configuration** | ✅ Implemented | Model toggles, quotas | `ai_usage` table | `lib/screens/admin/admin_ai_config_panel.dart` |
| **Billing Viewer** | ✅ Implemented | View billing summaries | `invoices`, `subscriptions` tables | `lib/screens/admin/admin_billing_viewer.dart` |
| **File Moderation** | ✅ Implemented | Review flagged files | `user_files` table | `lib/screens/admin/admin_file_moderator_panel.dart` |
| **Message Review** | ✅ Implemented | Review flagged messages | `messages` table | `lib/screens/admin/admin_message_review_panel.dart` |
| **Support Inbox** | ✅ Implemented | Support ticket management | `support_requests` table | `lib/screens/admin/support_inbox_screen.dart` |
| **Ticket Queue** | ✅ Implemented | Ticket routing and assignment | `support_requests` table | `lib/screens/admin/admin_ticket_queue_screen.dart` |
| **Analytics Dashboard** | ✅ Implemented | System analytics | Various tables | `lib/screens/admin/admin_analytics_screen.dart` |
| **Audit Logs** | ✅ Implemented | System audit trail | `audit_logs`, `admin_audit_log` tables | `lib/screens/admin/audit_log_screen.dart` |
| **Global Settings** | ✅ Implemented | Platform-wide settings | `admin_settings` table | `lib/screens/admin/global_settings_panel.dart` |
| **Incident Console** | ✅ Implemented | System incident tracking | `incidents` table | `lib/screens/admin/admin_incidents_screen.dart` |
| **Knowledge Base** | ✅ Implemented | Help articles management | `admin_knowledge_service.dart` | `lib/services/admin/admin_knowledge_service.dart` |
| **Live Session Monitoring** | ✅ Implemented | Observe user sessions | `sessions` table | `lib/screens/admin/admin_live_session_screen.dart` |
| **Session Co-Pilot** | ✅ Implemented | Real-time session assistance | `admin_session_service.dart` | `lib/screens/admin/admin_session_copilot_screen.dart` |

**Dependencies:**
- Database: `profiles`, `admin_audit_log`, `support_requests`, `ai_usage`, `admin_settings`
- Services: `AdminService`, `AdminSupportService`, `AdminAnalyticsService`
- Models: `lib/models/admin/`

---

### 7. EMBEDDINGS / KNOWLEDGE BRAIN

| Feature | Status | Description | Dependencies | File Ownership |
|---------|--------|-------------|--------------|----------------|
| **Note Embeddings** | ✅ Implemented | Semantic search for notes | `note_embeddings` table (pgvector) | `lib/services/ai/embedding_helper.dart` |
| **Message Embeddings** | ✅ Implemented | Semantic search for messages | `message_embeddings` table | `lib/services/ai/embedding_helper.dart` |
| **Workout Embeddings** | ✅ Implemented | Semantic search for workouts | `workout_embeddings` table | `lib/services/ai/embedding_helper.dart` |
| **Similarity Search** | ✅ Implemented | Cosine similarity via pgvector | PostgreSQL functions | `supabase/migrations/0004_ai_core_embeddings.sql` |
| **Embedding Service** | ✅ Implemented | Text-to-embedding conversion | `ai_client.dart`, OpenRouter | `lib/services/ai/embedding_helper.dart` |
| **Knowledge Base** | ✅ Implemented | Admin knowledge management | `admin_knowledge_service.dart` | `lib/services/admin/admin_knowledge_service.dart` |

**Dependencies:**
- Database: `note_embeddings`, `message_embeddings`, `workout_embeddings` (pgvector extension)
- Services: `EmbeddingHelper`, `AIClient`
- Infrastructure: PostgreSQL pgvector extension

---

### 8. VIRAL / SHARE LOOPS

| Feature | Status | Description | Dependencies | File Ownership |
|---------|--------|-------------|--------------|----------------|
| **Referral Codes** | ✅ Implemented | User referral code generation | `referral_codes` table | `lib/services/growth/referrals_service.dart` |
| **Referral Tracking** | ✅ Implemented | Track referrals and milestones | `referrals` table | `lib/services/growth/referrals_service.dart` |
| **Affiliate Links** | ✅ Implemented | Coach affiliate link system | `affiliate_links` table | `lib/services/growth/referrals_service.dart` |
| **Share Cards** | ✅ Implemented | Shareable workout/nutrition cards | `share_card_service.dart` | `lib/services/share/share_card_service.dart` |
| **QR Code Sharing** | ✅ Implemented | Coach QR code for sharing | `coach_qr_tokens` table | `lib/widgets/coaches/coach_share_qr_sheet.dart` |
| **Deep Links** | ✅ Implemented | App deep linking support | `deep_link_service.dart` | `lib/services/deep_link_service.dart` |
| **Social Sharing** | ✅ Implemented | Share to social platforms | `share_plus` package | `lib/screens/share/share_preview_screen.dart` |
| **Invite System** | ✅ Implemented | Invite friends flow | `referrals` table | `lib/widgets/growth/invite_card.dart` |

**Dependencies:**
- Database: `referral_codes`, `referrals`, `affiliate_links`, `coach_qr_tokens`
- Services: `ReferralsService`, `ShareCardService`, `DeepLinkService`
- Models: `lib/models/growth/referrals_models.dart`

---

## 🏗️ REPO AUDIT SNAPSHOT

### A) CURRENT ARCHITECTURE

**App Framework:**
- **Flutter SDK:** ^3.8.1
- **Dart:** Latest stable
- **Platform:** Cross-platform (iOS/Android/Web/Desktop)
- **Version:** 0.9.0+90

**State Management:**
- **Primary:** Provider (^6.0.5)
- **Pattern:** Service-oriented with singleton services
- **Local State:** `setState()` for UI state
- **Cross-widget:** `ChangeNotifier` (e.g., `OfflineSyncManager`, `RestTimerController`)
- **Reactive:** ValueNotifier and Stream-based subscriptions

**Navigation:**
- **Approach:** MaterialApp with named routes + TabBarView
- **Main Entry:** `lib/main.dart` → `AnimatedSplashScreen` → `AuthGate` → `MainNav`
- **Navigation File:** `lib/screens/nav/main_nav.dart`
- **Role-based:** Separate tabs for client/coach/admin
- **Deep Links:** `lib/services/deep_link_service.dart`

**Folder Structure:**
```
lib/
├── screens/          # UI Screens (Feature-driven)
│   ├── admin/       # 35 admin screens
│   ├── auth/        # 12 auth screens
│   ├── calendar/    # 5 calendar screens
│   ├── coach/       # 18 coach screens
│   ├── messaging/   # 9 messaging screens
│   ├── nutrition/   # 41 nutrition screens
│   ├── workout/     # Workout screens
│   └── ...
├── services/         # Business Logic Layer
│   ├── ai/          # 12 AI services
│   ├── admin/       # 10 admin services
│   ├── calendar/    # 9 calendar services
│   ├── coach/       # 14 coach services
│   ├── messaging/   # 3 messaging services
│   ├── nutrition/   # 29 nutrition services
│   ├── workout/     # Workout services
│   └── ...
├── models/           # Data Models & Entities
├── widgets/          # Reusable UI Components
├── components/       # Feature-specific Components
├── theme/            # Design System & Theming
└── utils/            # Utility Functions
```

**Supabase Usage:**
- **Auth:** `Supabase.instance.client.auth` (email/password, biometrics)
- **Database:** PostgreSQL with Row Level Security (RLS)
- **Storage:** File uploads to Supabase Storage buckets
- **Realtime:** Real-time subscriptions for messages, calendar
- **Edge Functions:** Serverless backend logic
- **Configuration:** `lib/config/env_config.dart` (loads from `.env`)

**Key Feature Screens:**
- **Auth:** `premium_login_screen.dart`, `auth_gate.dart`
- **Workout:** `revolutionary_plan_builder_screen.dart`, `client_workout_dashboard_screen.dart`
- **Nutrition:** `nutrition_hub_screen.dart`, `nutrition_plan_viewer.dart`
- **Messaging:** `modern_messenger_screen.dart`, `coach_threads_screen.dart`
- **Calendar:** `calendar_screen.dart`, `modern_calendar_viewer.dart`
- **Admin:** `admin_hub_screen.dart`, `admin_screen.dart`

---

### B) FEATURE EXISTENCE MATRIX

| Category | Feature | Status | File Path(s) | Notes |
|----------|---------|--------|--------------|-------|
| **Workout** | AI Generation | ✅ | `lib/services/ai/workout_ai.dart` | OpenRouter integration ready |
| **Workout** | Plan Builder | ✅ | `lib/screens/workout/revolutionary_plan_builder_screen.dart` | Full hierarchical system |
| **Workout** | Analytics | ✅ | `lib/services/workout/workout_analytics_service.dart` | Volume, PR, muscle groups |
| **Workout** | Progression | ✅ | `lib/services/workout/progression_service.dart` | 5 periodization models |
| **Nutrition** | AI Generation | ✅ | `lib/services/ai/nutrition_ai.dart` | Meal plan generation |
| **Nutrition** | Recipe System | ✅ | `lib/services/nutrition/recipe_service.dart` | Full CRUD |
| **Nutrition** | Grocery Lists | ✅ | `lib/services/nutrition/grocery_service.dart` | Auto-generation |
| **Nutrition** | Meal Prep | 🟡 | `lib/services/nutrition/meal_prep_service.dart` | Data model exists, UI partial |
| **Nutrition** | Gamification | 🟡 | `lib/services/streaks/` | Streaks exist, full gamification partial |
| **Messaging** | Threads | ✅ | `lib/services/messages_service.dart` | `parent_id` support |
| **Messaging** | Smart Replies | ✅ | `lib/services/ai/messaging_ai.dart` | AI-powered |
| **Messaging** | Search | ✅ | `lib/services/messages_service.dart` | Text + embeddings |
| **Messaging** | Translation | ✅ | `lib/widgets/messaging/translation_toggle.dart` | Multi-language |
| **Notes** | Voice Transcription | ✅ | `lib/services/ai/transcription_ai.dart` | Whisper alternative |
| **Notes** | Versioning | ✅ | `lib/screens/notes/note_version_viewer.dart` | Complete history |
| **Notes** | Duplicate Detection | ✅ | `lib/services/ai/embedding_helper.dart` | Embedding-based |
| **Calendar** | Views | ✅ | `lib/screens/calendar/calendar_screen.dart` | Month/Week/Day |
| **Calendar** | Recurring Events | ✅ | `lib/services/calendar/recurring_event_handler.dart` | RRULE support |
| **Calendar** | Booking | 🟡 | `lib/services/calendar/booking_conflict_service.dart` | Backend ready, UI partial |
| **Calendar** | Reminders | ✅ | `lib/services/calendar/reminder_manager.dart` | Local notifications |
| **Calendar** | AI Tagging | ✅ | `lib/services/ai/calendar_ai.dart` | Auto-suggest tags |
| **Progress** | Tracking | ✅ | `lib/screens/progress/` | Photos, metrics, check-ins |
| **Progress** | Compliance | ✅ | `lib/components/progress/compliance_stats_card.dart` | Weekly scoring |
| **Progress** | Charts | ✅ | `lib/screens/progress/progress_chart.dart` | 7/30-day MA |
| **Admin** | User Management | ✅ | `lib/screens/admin/user_manager_panel.dart` | Full CRUD |
| **Admin** | Coach Approval | ✅ | `lib/screens/admin/coach_approval_panel.dart` | Approval workflow |
| **Admin** | AI Config | ✅ | `lib/screens/admin/admin_ai_config_panel.dart` | Model toggles |
| **Admin** | Support Inbox | ✅ | `lib/screens/admin/support_inbox_screen.dart` | Ticket management |
| **Admin** | Analytics | ✅ | `lib/screens/admin/admin_analytics_screen.dart` | System metrics |
| **Embeddings** | Note Embeddings | ✅ | `lib/services/ai/embedding_helper.dart` | pgvector |
| **Embeddings** | Message Embeddings | ✅ | `lib/services/ai/embedding_helper.dart` | Semantic search |
| **Embeddings** | Workout Embeddings | ✅ | `lib/services/ai/embedding_helper.dart` | Similarity search |
| **Sharing** | Referrals | ✅ | `lib/services/growth/referrals_service.dart` | Codes, tracking |
| **Sharing** | QR Codes | ✅ | `lib/widgets/coaches/coach_share_qr_sheet.dart` | Coach sharing |
| **Sharing** | Deep Links | ✅ | `lib/services/deep_link_service.dart` | App linking |
| **Billing** | Plan Gating | ✅ | `lib/services/billing/plan_access_manager.dart` | Access control |
| **Billing** | Subscriptions | 🟡 | `lib/screens/billing/billing_settings.dart` | UI exists, payment partial |
| **Billing** | Invoices | ✅ | `lib/screens/billing/invoice_history_viewer.dart` | View history |

---

### C) DATA MODEL INVENTORY

**Workout Plans:**
- **Tables:** `workout_plans`, `workout_weeks`, `workout_days`, `exercises`, `exercise_groups`, `workout_sessions`, `exercise_logs`
- **Models:** `lib/models/workout/workout_plan.dart`, `lib/models/workout/exercise.dart`
- **Services:** `lib/services/workout/workout_service.dart`

**Nutrition Plans:**
- **Tables:** `nutrition_plans`, `nutrition_meals`, `nutrition_items`, `nutrition_recipes`, `nutrition_grocery_lists`
- **Models:** `lib/models/nutrition/nutrition_plan.dart`, `lib/models/nutrition/meal.dart`
- **Services:** `lib/services/nutrition/nutrition_service.dart`

**Notes:**
- **Tables:** `coach_notes`, `coach_note_versions`, `coach_note_attachments`, `note_embeddings`
- **Models:** `lib/models/` (note models)
- **Services:** `lib/services/coach_notes_service.dart`

**Messages:**
- **Tables:** `messages`, `message_threads`, `message_embeddings`, `message_reads`, `message_pins`, `message_attachments`
- **Models:** `lib/models/` (message models)
- **Services:** `lib/services/messages_service.dart`

**Calendar Events:**
- **Tables:** `calendar_events`, `booking_requests`, `calendar_attendees`, `calendar_event_overrides`
- **Models:** `lib/models/` (calendar models)
- **Services:** `lib/services/calendar/event_service.dart`

**Uploads:**
- **Tables:** `user_files`, `file_tags`, `file_comments`, `file_versions`
- **Models:** `lib/models/` (file models)
- **Services:** `lib/services/files/` (if exists)

**Audit Logs / Roles:**
- **Tables:** `audit_logs`, `admin_audit_log`, `profiles` (role column), `user_devices`
- **Models:** `lib/models/admin/`
- **Services:** `lib/services/admin/admin_service.dart`

**Additional Key Tables:**
- `checkins`, `progress_entries`, `progress_photos`
- `user_streaks`, `achievements`
- `referral_codes`, `referrals`, `affiliate_links`
- `ai_usage`, `subscriptions`, `invoices`
- `support_requests`, `admin_settings`

---

## 🛡️ SAFE EXECUTION PLAN (STAGES)

### STAGE 0: FOUNDATION VERIFICATION

**Goal:** Verify existing infrastructure before any changes

**Tasks:**
1. ✅ Verify feature flags system exists (`lib/services/config/feature_flags.dart`)
2. ✅ Verify logger exists (`lib/services/core/logger.dart`)
3. ✅ Verify result type exists (`lib/services/core/result.dart`)
4. ✅ Verify all database migrations are idempotent
5. ✅ Document current feature flag states

**New Files:** None (verification only)

**Existing Files to Review:**
- `lib/services/config/feature_flags.dart`
- `lib/services/core/logger.dart`
- `lib/services/core/result.dart`
- `supabase/migrations/*.sql`

**Risk Notes:**
- Low risk - read-only verification
- No code changes

**Test Checklist:**
- [ ] All feature flags compile
- [ ] Logger works in debug mode
- [ ] Result type can be imported
- [ ] No breaking migrations

---

### STAGE 1: ENHANCEMENTS (ADDITIVE ONLY)

**Goal:** Add missing features without breaking existing functionality

**Features Included:**
1. **Calendar Booking UI** (if missing)
   - Create: `lib/screens/calendar/booking_form.dart`
   - Enhance: `lib/screens/calendar/event_editor.dart`
   - Insertion: After existing calendar screens

2. **Billing Payment Flow** (if partial)
   - Enhance: `lib/screens/billing/billing_settings.dart`
   - Create: `lib/services/billing/payment_service.dart` (if needed)
   - Insertion: After existing billing screens

3. **Meal Prep UI** (if partial)
   - Enhance: `lib/screens/nutrition/meal_prep_screen.dart` (if exists)
   - Create: `lib/screens/nutrition/meal_prep_planner_screen.dart` (if missing)
   - Insertion: After nutrition plan builder

**New Files to Create:**
- `lib/screens/calendar/booking_form.dart` (if missing)
- `lib/services/billing/payment_service.dart` (if missing)
- `lib/screens/nutrition/meal_prep_planner_screen.dart` (if missing)

**Existing Files to Patch:**
- `lib/screens/calendar/calendar_screen.dart`
  - Insertion marker: `// ✅ VAGUS ADD: booking-flow START`
  - Add booking button/link
  - Insertion marker: `// ✅ VAGUS ADD: booking-flow END`

- `lib/screens/billing/billing_settings.dart`
  - Insertion marker: `// ✅ VAGUS ADD: payment-integration START`
  - Add payment method UI
  - Insertion marker: `// ✅ VAGUS ADD: payment-integration END`

**Risk Notes:**
- Low risk - new files only
- Medium risk - patching existing files (use markers)
- Mitigation: Feature flags for new features

**Test Checklist:**
- [ ] Booking form opens from calendar
- [ ] Payment flow works (or shows placeholder)
- [ ] Meal prep screen accessible
- [ ] No regressions in existing calendar/billing/nutrition

---

### STAGE 2: AI ENHANCEMENTS

**Goal:** Enhance AI features with additional capabilities

**Features Included:**
1. **Enhanced Workout AI**
   - Create: `lib/services/ai/workout_ai_enhanced.dart`
   - Add: Exercise recommendation engine
   - Insertion: New file, extend existing `workout_ai.dart`

2. **Enhanced Nutrition AI**
   - Enhance: `lib/services/ai/nutrition_ai.dart`
   - Add: Meal optimization suggestions
   - Insertion marker: `// ✅ VAGUS ADD: meal-optimization START`

3. **Calendar AI Scheduler**
   - Create: `lib/screens/calendar/ai_scheduler_panel.dart`
   - Insertion: New file, link from calendar screen

**New Files to Create:**
- `lib/services/ai/workout_ai_enhanced.dart`
- `lib/screens/calendar/ai_scheduler_panel.dart`

**Existing Files to Patch:**
- `lib/services/ai/nutrition_ai.dart`
  - Insertion marker: `// ✅ VAGUS ADD: meal-optimization START`
  - Add optimization method
  - Insertion marker: `// ✅ VAGUS ADD: meal-optimization END`

- `lib/screens/calendar/calendar_screen.dart`
  - Insertion marker: `// ✅ VAGUS ADD: ai-scheduler START`
  - Add AI scheduler button
  - Insertion marker: `// ✅ VAGUS ADD: ai-scheduler END`

**Risk Notes:**
- Medium risk - AI features behind flags
- Mitigation: Feature flags (`FeatureFlags.aiWorkout`, `FeatureFlags.aiNutrition`, `FeatureFlags.calendarAI`)

**Test Checklist:**
- [ ] AI features only work when flags enabled
- [ ] AI calls fail gracefully when quota exceeded
- [ ] No regressions in existing AI features
- [ ] Usage tracked in `ai_usage` table

---

### STAGE 3: GAMIFICATION ENHANCEMENTS

**Goal:** Complete gamification system

**Features Included:**
1. **Achievement System UI**
   - Enhance: `lib/screens/streaks/streaks_screen.dart`
   - Create: `lib/widgets/gamification/achievement_badge.dart`
   - Insertion: New widgets, enhance existing screen

2. **Leaderboard** (if missing)
   - Create: `lib/screens/rank/leaderboard_screen.dart`
   - Insertion: New file, link from rank screen

3. **Challenge System** (if partial)
   - Enhance: `lib/services/streaks/challenge_service.dart` (if exists)
   - Create: `lib/screens/challenges/challenges_screen.dart` (if missing)
   - Insertion: New file

**New Files to Create:**
- `lib/widgets/gamification/achievement_badge.dart`
- `lib/screens/rank/leaderboard_screen.dart` (if missing)
- `lib/screens/challenges/challenges_screen.dart` (if missing)

**Existing Files to Patch:**
- `lib/screens/streaks/streaks_screen.dart`
  - Insertion marker: `// ✅ VAGUS ADD: achievement-display START`
  - Add achievement badges
  - Insertion marker: `// ✅ VAGUS ADD: achievement-display END`

**Risk Notes:**
- Low risk - additive features
- Mitigation: Feature flags (`FeatureFlags.gamification`)

**Test Checklist:**
- [ ] Achievements display correctly
- [ ] Leaderboard loads (if created)
- [ ] Challenges work (if created)
- [ ] No regressions in streak system

---

### STAGE 4: ADMIN ENHANCEMENTS

**Goal:** Add any missing admin tools

**Features Included:**
1. **Enhanced Analytics**
   - Enhance: `lib/screens/admin/admin_analytics_screen.dart`
   - Add: Custom date range filters
   - Insertion marker: `// ✅ VAGUS ADD: analytics-filters START`

2. **Bulk Actions**
   - Create: `lib/widgets/admin/bulk_action_toolbar.dart`
   - Insertion: New widget, use in user manager

3. **Export Enhancements**
   - Enhance: `lib/services/admin/admin_service.dart`
   - Add: CSV export for analytics
   - Insertion marker: `// ✅ VAGUS ADD: csv-export START`

**New Files to Create:**
- `lib/widgets/admin/bulk_action_toolbar.dart`

**Existing Files to Patch:**
- `lib/screens/admin/admin_analytics_screen.dart`
  - Insertion marker: `// ✅ VAGUS ADD: analytics-filters START`
  - Add date range picker
  - Insertion marker: `// ✅ VAGUS ADD: analytics-filters END`

- `lib/services/admin/admin_service.dart`
  - Insertion marker: `// ✅ VAGUS ADD: csv-export START`
  - Add export method
  - Insertion marker: `// ✅ VAGUS ADD: csv-export END`

**Risk Notes:**
- Low risk - admin-only features
- Mitigation: Role-based access control

**Test Checklist:**
- [ ] Analytics filters work
- [ ] Bulk actions functional
- [ ] CSV export generates correctly
- [ ] Admin-only access enforced

---

## ❓ QUESTIONS YOU STILL NEED ANSWERED

1. **PDF Location:** Where is the PDF document mentioned in the task? I couldn't find it in the repository. Should I use a different source?

2. **Priority Features:** Which features from the sprint plan should be prioritized? Are there specific user requests or pain points?

3. **Payment Integration:** What payment provider should be integrated for billing? (Stripe, PayPal, etc.)

4. **AI Model Preferences:** Are there specific AI models preferred for different tasks, or should I use the existing `ModelRegistry` defaults?

5. **Testing Requirements:** Are there specific test coverage requirements for new features?

6. **Performance Targets:** Are there specific performance benchmarks (load times, query speeds) that must be met?

7. **Rollout Strategy:** Should new features be enabled immediately or follow a phased rollout via feature flags?

8. **Database Migrations:** Should I create new migration files, or are there existing migration patterns to follow?

9. **UI/UX Consistency:** Are there specific design tokens or component libraries to follow beyond the existing `design_tokens.dart`?

10. **Integration Points:** Are there external services (analytics, crash reporting) that need to be integrated with new features?

---

## 📝 NOTES

- **No code has been generated** - this is a read-only audit
- **All existing code preserved** - no deletions or modifications
- **Feature flags system** is ready for safe rollouts
- **Database schema** is comprehensive (127+ tables)
- **Service architecture** is well-organized and extensible
- **Admin tools** are extensive (24+ screens)

**Next Steps:**
1. Review this audit report
2. Answer questions above (if any)
3. Provide PDF location (if available)
4. Specify which stage to execute first
5. Say "GO STAGE X" to begin implementation

---

**END OF AUDIT REPORT**
