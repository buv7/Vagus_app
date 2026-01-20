---
name: Vagus App - Complete Sprint Plan
overview: ""
todos:
  - id: b850c184-bdb6-42b0-99d7-cdb17ebe4f85
    content: "Sprint 0: Stabilization & Scaffolding - Set up feature flags, logging, error handling, and verify dependencies"
    status: pending
  - id: 51ab9882-4805-4ba2-80f8-be701fff7faf
    content: "Sprint 1: Auth System Completion - Password reset, email verification, biometrics, device management, become coach flow"
    status: pending
  - id: 43164ec4-4029-4fd2-b220-efb8fc61741b
    content: "Sprint 2: AI Core Integration - Implement OpenRouter client, model registry, caching, rate limiting, and feature-specific AI services"
    status: pending
  - id: 64205546-ecdb-4dd0-bab5-bdbee727e6ca
    content: "Sprint 3: Files & Media 1.0 - File previews, tagging, comments, versioning, and attachment features"
    status: pending
  - id: 1f43fb84-df51-4d89-a1e5-7bc76f99c6cd
    content: "Sprint 4: Coach Notes Voice + Versioning - Voice transcription, version history viewer, duplicate detection"
    status: pending
  - id: 7fa0f127-555a-4bdb-8111-1562a6f6df2a
    content: "Sprint 5: Client Dashboard Compliance & Analytics - Progress tracking, charts, compliance metrics, check-in calendar"
    status: pending
  - id: 6a2f9d5a-fb78-44b6-ba90-716cc877cfb2
    content: "Sprint 6: Messaging Power Features - Threads, smart replies, read receipts, pinning, search, translations"
    status: pending
  - id: bde66e97-a476-4692-bba5-089ad9ed2444
    content: "Sprint 7: Calendar & Booking - Full calendar system with recurring events, booking flow, AI tagging"
    status: pending
  - id: ca9250a9-abc2-4edc-a10a-62fe69569cb2
    content: "Sprint 8: Admin Panels Expansion - Complete admin toolset for user management, moderation, analytics"
    status: pending
  - id: dcd95e94-473d-484d-bbef-b9b312c4bbc2
    content: "Sprint 9: Monetization & Plan Gating - Billing screens, subscription management, plan access control"
    status: pending
  - id: e9400e2d-9106-4c5f-9503-8c50b615fa24
    content: "Sprint 10: Settings, Themes, i18n - User settings screen, theme toggle, language selector, data export"
    status: pending
  - id: 8cc3137e-52da-4ce0-ad15-022a6ff934fa
    content: "Sprint 11: QA, Tests, Performance & Launch - Unit tests, performance optimization, monitoring, production readiness"
    status: pending
---

# Vagus App - Complete Sprint Plan

## Overview

This plan implements 11 sprints to take Vagus from RC (0.9.0) to production-ready GA, adding critical features while respecting all existing working code and architecture.

## Global Guardrails (ALL SPRINTS)

- ✅ NEVER delete or change working logic unless explicitly requested
- ✅ ALWAYS check if target file exists; request latest version before patching
- ✅ Preserve Supabase URL & anon key exactly as provided
- ✅ Match existing UI/UX patterns (monochrome + glassmorphic)
- ✅ Maintain folder structure: `lib/screens/`, `lib/services/`, `lib/components/`
- ✅ Feature flags for risky features (`lib/services/config/feature_flags.dart`)
- ✅ Keep role/permission model and AI quotas intact
- ✅ All SQL migrations must be idempotent (IF NOT EXISTS)

---

## Sprint 0: Stabilization & Scaffolding

**Goal:** Set up safe, incremental delivery foundation

**Key Deliverables:**

1. Create `lib/services/config/feature_flags.dart` with module toggles
2. Create `lib/services/core/logger.dart` (centralized logging)
3. Create `lib/services/core/result.dart` (Result<T,E> error handling)
4. Create `tooling/check_exists.dart` (file verification helper)
5. Pin & verify package versions: `photo_view`, `pdfx`, `video_player`, `just_audio`

**Acceptance:**

- App builds & runs unchanged
- All feature flags compile and default to OFF
- No regressions in existing functionality

---

## Sprint 1: Auth System Completion

**Goal:** Close critical auth gaps with production-ready flows

**Key Deliverables:**

### 1. Password Reset Flow

- Create `lib/screens/auth/password_reset_screen.dart`
- Wire `Supabase.instance.client.auth.resetPasswordForEmail()`
- Add route + link from Login screen

### 2. Email Verification UX

- Create `lib/screens/auth/verify_email_pending_screen.dart`
- Navigate here post-signup until `user.emailConfirmedAt != null`

### 3. Biometrics Toggle

- Create `lib/screens/auth/enable_biometrics_dialog.dart`
- Use `local_auth` package
- Store preference in `secure_storage` per user

### 4. Session Manager + Devices

- Create `lib/screens/auth/device_list_screen.dart`
- Create `lib/screens/auth/session_manager.dart`
- Add SQL table: `user_devices` with RLS
- Update login/logout to upsert device info

### 5. Become Coach + Admin Approval

- Create `lib/screens/coach/become_coach_screen.dart`
- Create `lib/screens/admin/coach_approval_panel.dart`
- Wire coach request → admin approval → role update

**Acceptance:**

- Password reset works end-to-end
- Email verification gate functional
- Biometrics optional with stored preference
- Device list shows all devices; revoke forces re-login
- Admin can approve/deny coach applications

---

## Sprint 2: AI Core Integration (OpenRouter)

**Goal:** Replace simulated AI with real OpenRouter services

**Key Deliverables:**

### Core AI Services

1. `lib/services/ai/ai_client.dart` - OpenRouter HTTP client
2. `lib/services/ai/model_registry.dart` - Task→model mapping
3. `lib/services/ai/ai_cache.dart` - LRU in-memory + optional Supabase KV
4. `lib/services/ai/rate_limiter.dart` - Per-user token limits
5. `lib/services/ai/transcription_ai.dart` - Whisper alternative
6. `lib/services/ai/embedding_helper.dart` - Text embeddings

### Feature-Specific AI

7. `lib/services/ai/notes_ai.dart` - Note intelligence
8. `lib/services/ai/workout_ai.dart` - Workout generation
9. `lib/services/ai/calendar_ai.dart` - Calendar intelligence
10. `lib/services/ai/messaging_ai.dart` - Message features

### Integration

- Wire existing Nutrition AI to `ai_client` behind `FeatureFlags.aiNutrition`
- Connect Notes Smart Panel to `notes_ai`

**Acceptance:**

- Nutrition AI (meal generation) calls real API when flag ON
- Notes Smart Panel (summarize/improve/tags/duplicate detection) functional
- Rate limiting + usage tracked via existing `ai_usage_service.dart`
- All AI calls fail gracefully when flag OFF

---

## Sprint 3: Files & Media 1.0

**Goal:** Elevate file UX with previews, tagging, feedback, versioning

**Key Deliverables:**

### UI Components

1. `lib/components/files/inline_file_picker.dart`
2. `lib/components/files/file_previewer.dart` - All formats (image/video/audio/PDF)
3. `lib/screens/files/upload_photos_screen.dart`
4. `lib/screens/files/coach_file_feedback_screen.dart`
5. `lib/components/files/attach_to_note_button.dart`
6. `lib/components/files/attach_to_workout_button.dart`

### Database

- Add tables: `file_tags`, `file_comments`, `file_versions`
- Add `is_pinned` column to `user_files`
- Implement RLS policies

**Acceptance:**

- Inline preview works for images, videos, audio, PDFs
- Tags and comments save & display
- Version history visible
- "Attach to Note/Workout" buttons functional
- Pinning works

---

## Sprint 4: Coach Notes - Voice + Versioning

**Goal:** Ship real transcription and complete version history

**Key Deliverables:**

1. Wire `voice_recorder.dart` → `transcription_ai.dart`
2. Create `lib/components/notes/attach_file_to_note.dart`
3. Create `lib/screens/notes/note_version_viewer.dart`
4. Add SQL trigger for automatic versioning on content update
5. Implement duplicate detection via embeddings (cosine similarity)

**Acceptance:**

- Voice recording → transcription → text insertion works
- Every note edit creates a version entry
- Version viewer shows complete history with diffs
- Duplicate detection surfaces similar notes

---

## Sprint 5: Client Dashboard - Compliance & Analytics

**Goal:** Complete progress workflow with rich analytics

**Key Deliverables:**

### UI Screens

1. `lib/screens/progress/ProgressEntryForm.dart`
2. `lib/screens/progress/ProgressGallery.dart`
3. `lib/screens/progress/ProgressChart.dart` - 7/30-day MA + deltas
4. `lib/components/progress/ComplianceStatsCard.dart`
5. `lib/components/progress/CoachFeedbackBox.dart`
6. `lib/components/progress/AttachToCheckin.dart`
7. `lib/screens/progress/ClientCheckInCalendar.dart`

### Database

- Add `compliance_score` to `checkins`
- Create `checkin_files` junction table
- Add AI hooks for burnout risk & trends (flag-gated)

**Acceptance:**

- Users can add/edit progress entries
- Gallery displays all progress photos
- Charts show 7/30-day moving averages with deltas
- Compliance card shows weekly score & streaks
- Check-in calendar renders with file attachments

---

## Sprint 6: Messaging Power Features

**Goal:** Advanced messaging parity (threads, search, translations)

**Key Deliverables:**

### UI Components

1. `lib/components/messaging/SmartReplyButtons.dart`
2. `lib/components/messaging/AttachmentPreview.dart`
3. `lib/components/messaging/ThreadView.dart`
4. `lib/components/messaging/TypingIndicator.dart`
5. `lib/components/messaging/MessageSearchBar.dart`
6. `lib/components/messaging/PinPanel.dart`
7. `lib/components/messaging/TranslationToggle.dart`

### Enhanced Service

- Update `messages_service.dart`:
- Presence + typing indicators
- Read receipts (`read_by` array)
- Message pinning
- Thread support (`parent_id`)
- Search (embedding-based when flag ON)

### Database

- Add columns: `parent_id`, `is_pinned`, `read_by`
- Add index on `parent_id`

**Acceptance:**

- Smart replies render and insert
- Threads expand inline or in separate view
- Read receipts show per message
- Message search works (text + optional embeddings)
- Pin/unpin functional
- Translation toggle (flag-gated)

---

## Sprint 7: Calendar & Booking

**Goal:** Full calendar system with AI tagging & booking flow

**Key Deliverables:**

### UI Screens

1. `lib/screens/calendar/CalendarScreen.dart` - Month/Week/Day views
2. `lib/screens/calendar/EventEditor.dart`
3. `lib/screens/calendar/BookingForm.dart`
4. `lib/components/calendar/AttachedFilePreview.dart`
5. `lib/components/calendar/CalendarFilterBar.dart`
6. `lib/screens/calendar/AISchedulerPanel.dart`

### Services

1. `lib/services/calendar/ReminderManager.dart`
2. `lib/services/calendar/RecurringEventHandler.dart`
3. `lib/services/calendar/SmartEventTagger.dart` - Uses `calendar_ai.dart`

### Database

- Add columns to `calendar_events`: `rrule`, `attachments`, `tags`
- Create `booking_requests` table (if not exists)
- Add conflict detection edge function

**Acceptance:**

- Month/Week/Day views with full CRUD
- Recurring events supported (basic RRULE)
- Booking flow: client requests → coach approves → event created
- Reminders fire on schedule
- AI suggests event tags when flag ON

---

## Sprint 8: Admin Panels Expansion

**Goal:** Complete admin toolset for platform management

**Key Deliverables:**

1. `lib/screens/admin/UserManagerPanel.dart`
2. `lib/screens/admin/CoachApprovalPanel.dart` (from Sprint 1)
3. `lib/screens/admin/AIConfigPanel.dart` - Model toggles, quotas
4. `lib/screens/admin/BillingViewer.dart`
5. `lib/screens/admin/FileModeratorPanel.dart`
6. `lib/screens/admin/PlanAuditScreen.dart`
7. `lib/screens/admin/MessageReviewPanel.dart`
8. `lib/screens/admin/RoleManager.dart`
9. `lib/screens/admin/GlobalSettingsPanel.dart`
10. `lib/components/common/ConfirmationDialogTwoStep.dart`

**Acceptance:**

- Admin can approve coaches
- Admin can view flagged files
- Admin can adjust AI quotas
- Admin can view billing summaries
- Admin can manage user roles
- Admin can toggle global settings
- All actions require two-step confirmation

---

## Sprint 9: Monetization & Plan Gating

**Goal:** Enable revenue streams and access control

**Key Deliverables:**

### UI Screens

1. `lib/screens/billing/UpgradeScreen.dart`
2. `lib/screens/billing/BillingSettings.dart`
3. `lib/screens/billing/InvoiceHistoryViewer.dart`
4. `lib/components/billing/FreeTrialCountdownCard.dart`
5. `lib/components/billing/CouponInput.dart`

### Service

1. `lib/services/billing/PlanAccessManager.dart` - Entitlements single source
2. `lib/screens/admin/AdminManualActivatePanel.dart`

### Database (Provider-Agnostic)

- Create tables: `subscriptions`, `invoices`, `coupons`
- Gate high-cost AI calls behind `PlanAccessManager`

**Acceptance:**

- Upgrade screen shows plans and current entitlement
- Admin can manually grant/revoke access
- Invoice history displays
- Coupon entry adjusts pricing (mocked checkout)
- AI features respect plan limits

---

## Sprint 10: Settings, Themes, i18n

**Goal:** Complete settings system with themes and localization

**Key Deliverables:**

### UI Screens

1. `lib/screens/settings/UserSettingsScreen.dart`
2. `lib/components/settings/ThemeToggle.dart` - light/dark/auto
3. `lib/components/settings/LanguageSelector.dart` - EN/AR/KU
4. `lib/components/settings/ReminderDefaults.dart`
5. `lib/components/settings/ExportMyDataButton.dart`
6. `lib/components/settings/AccountDeletionDialog.dart`
7. `lib/screens/admin/AdminSettingsPanel.dart`

### Database

- Create `user_settings` table with theme, language, quiet hours

**Acceptance:**

- Users can change theme (light/dark/auto)
- Users can change language (EN/AR/KU with RTL)
- Users can set reminder defaults
- Export data button triggers existing exporter
- Account deletion requires confirmation
- Admin has global settings panel

---

## Sprint 11: QA, Tests, Performance & Launch

**Goal:** Production readiness - stabilize for GA launch

**Key Deliverables:**

### Testing

1. Unit tests for new services (AI client, PlanAccessManager, Calendar)
2. Widget tests for new screens (happy paths)
3. Integration tests for critical flows

### Performance

1. Profile slow queries
2. Add missing indexes:

- `messages.parent_id`
- `user_files.created_at`
- `checkins.created_at`
- Others as needed

### Monitoring

1. Crashlytics events for new flows
2. Analytics events for feature usage
3. Performance monitoring dashboards

### Launch Prep

1. Feature flag review - enable only passing features
2. Documentation updates
3. Migration scripts verification
4. Rollback procedures documented

**Acceptance:**

- CI builds green
- Test coverage +10% for new code
- No critical crashes in staging
- All P0/P1 bugs resolved
- Performance benchmarks met
- Feature flags properly configured
- Documentation complete

---

## Execution Guidelines for Cursor

1. **Before ANY file edit:** Request latest version from user
2. **New files:** Mirror folder conventions and import style from nearby files
3. **SQL changes:** Always use `IF NOT EXISTS` / `ALTER ADD COLUMN IF NOT EXISTS`
4. **Risky features:** Behind FeatureFlags until verified
5. **Testing:** Add tests for every new service/component
6. **UI consistency:** Follow existing design tokens and patterns
7. **Backwards compatibility:** Never break existing APIs
8. **Security:** Maintain RLS policies on all tables

---

## Success Metrics

- ✅ Zero regressions in existing features
- ✅ All new features behind flags
- ✅ Test coverage maintained/improved
- ✅ Performance metrics stable or improved
- ✅ Clean CI/CD pipeline
- ✅ Production deployment successful
- ✅ User feedback positive