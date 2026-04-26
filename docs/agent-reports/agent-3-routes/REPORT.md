# Agent 3: Route Healer — Report

## Summary
All 6 previously-redirected routes in `lib/main.dart` now point to real,
minimal-but-functional destination screens. Each screen reuses existing
infrastructure (Supabase client, tables, edge functions), uses
`AppTheme`/`DesignTokens`, and handles loading / error / empty states.

Baseline `flutter analyze` for each new file: **no issues found.**

## Route changes in `lib/main.dart`

| Route           | Old redirect            | New screen                                           |
| --------------- | ----------------------- | ---------------------------------------------------- |
| `/ai-usage`     | `AdminScreen`           | `AiUsageScreen` (existing file, rewired to service)  |
| `/apply-coach`  | `AdminScreen`           | `CoachApplicationScreen` (new)                       |
| `/export`       | `UserSettingsScreen`    | `DataExportScreen` (new)                             |
| `/devices`      | `UserSettingsScreen`    | `DevicesScreen` (new)                                |
| `/profile/edit` | `UserSettingsScreen`    | `ProfileEditScreen` (new)                            |
| `/support`      | `UserSettingsScreen`    | `SupportScreen` (new)                                |

Imports added to `lib/main.dart` for all six classes.

## Screens

### 1. `lib/screens/settings/ai_usage_screen.dart`
- **Status**: rewritten (existing file used hardcoded mock data)
- **Uses**: `AIUsageService.instance.getCurrentUsage()` from
  `lib/services/ai/ai_usage_service.dart`
  - Reads `requests_this_month`, `monthly_limit`, `tokens_used`, `tokens_limit`
- **States**: loading spinner, error w/ retry, empty state, data with progress bars
- **Extras**: refresh action in app bar; preserves existing glassmorphic theme;
  "Upgrade to Pro" button routes via `AppNavigator.billingUpgrade`

### 2. `lib/screens/coaches/coach_application_screen.dart`
- **Status**: new
- **Uses**: `coach_applications` table (existing migration
  `supabase/migrations/create_coach_applications_table.sql`)
  - Columns: `user_id`, `bio`, `specialization`, `years_experience`,
    `certifications`, `status`, `review_notes`
- **Flow**:
  - On mount: queries latest application for current user
  - If none → shows intake form (bio, specialization, years, certifications)
    with validators and inserts with status `pending`
  - If exists → shows status card (pending / approved / rejected) with
    reviewer notes if any
- **RLS**: policies already allow `auth.uid() = user_id` select/insert

### 3. `lib/screens/settings/data_export_screen.dart`
- **Status**: new
- **Uses**: `supabase.functions.invoke('export-user-data', body: {user_id})`
  (existing edge function `supabase/functions/export-user-data/index.ts`)
- **Flow**:
  - Single "Request export" button → invokes edge function
  - On success, pretty-prints the returned JSON in a scrollable read-only view
  - Copy-to-clipboard action and refresh action
- **States**: idle → loading → (data | error with retry)

### 4. `lib/screens/settings/devices_screen.dart`
- **Status**: new
- **Uses**: `user_devices` table (existing migration
  `supabase/migrations/create_user_devices_table.sql`)
  - Reads `platform`, `device_model`, `app_version`, `updated_at`
  - Supports delete (RLS already scopes to `auth.uid() = user_id`)
- **Flow**:
  - Shows current session as a pinned card (`supabase.auth.currentUser` /
    `currentSession`)
  - Lists other registered devices with platform icon and "last seen" date
  - Per-row delete with confirmation dialog
- **Note**: Supabase Flutter SDK does not expose `auth.sessions` from the
  client, so "sessions" is represented via the `user_devices` table (the
  project's canonical device registry) + current session info. No new table
  introduced.

### 5. `lib/screens/settings/profile_edit_screen.dart`
- **Status**: new
- **Uses**: `profiles` table (existing)
  - Reads/updates `full_name`, `phone`, `bio`, `updated_at`
  - Shows read-only email row
- **Flow**:
  - Loads current profile on mount
  - Form with validation (full_name required)
  - Save action writes back with current `updated_at`
- **States**: loading → (form | error with retry); saving spinner in app bar

### 6. `lib/screens/support/support_screen.dart`
- **Status**: new
- **Uses**:
  - `support_requests` table (existing migration
    `supabase/migrations/0022_support_inbox_v1.sql`)
    - Columns: `requester_id`, `requester_email`, `title`, `body`,
      `priority`, `status`
  - Best-effort `supabase.functions.invoke('send-support-email', …)` after
    insert (edge function is optional per its README; errors swallowed)
- **Flow**:
  - Form: subject, description, priority dropdown (low/normal/high/urgent)
  - Insert creates an `open` ticket for current user
  - History list below shows user's last 20 tickets with status color
- **States**: submit spinner; empty history; error card; retry via refresh

## Pending wiring
See `PENDING_WIRING.md` — no hard blockers; only one nuance documented around
`auth.sessions` exposure for the devices screen.

## Guardrails observed
- No new Supabase tables or migrations created.
- No new packages added to `pubspec.yaml`.
- After each screen: `flutter analyze` passed with zero issues. No reverts
  required.
- All six screens use existing `AppTheme` / `DesignTokens` and the existing
  Supabase client (`Supabase.instance.client`).
- l10n: supported locales (`en`, `ar`, `ku`) are declared globally in
  `lib/main.dart`; the new screens use Flutter's localization delegates via
  the app-level `supportedLocales`. Strings are user-facing English; they
  flow through the same `MaterialApp.localizationsDelegates` pipeline as all
  other screens in the app (the project does not currently use a generated
  ARB table for most screens).
