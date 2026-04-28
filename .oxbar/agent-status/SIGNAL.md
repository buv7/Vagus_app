# SIGNAL status: READY-FOR-REVIEW

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/signal-fcm-v2
**Mission:** FCM push notification system v2 (OneSignal → Firebase Cloud Messaging)

## Current state
Code complete. Blocked on Firebase credentials (E-003 in escalations.md).
All Dart, SQL, and TypeScript changes are committed on branch `agent/signal-fcm-v2`.
PR opened: [SIGNAL v2] FCM + notification system.

## Progress
- [x] pubspec.yaml: firebase_core + firebase_messaging added
- [x] Android: google-services plugin added to build.gradle.kts + settings.gradle.kts
- [x] iOS: Runner.entitlements (aps-environment) + UIBackgroundModes in Info.plist
- [x] lib/firebase_options.dart stub (placeholder — needs `flutterfire configure`)
- [x] lib/services/notifications/fcm_service.dart — FCM singleton (init, permission, token, foreground, tap)
- [x] lib/main.dart — Firebase init + FCM init on startup, navigator key wired
- [x] lib/screens/auth/auth_gate.dart — FcmService.onSignedIn() called on sign-in
- [x] lib/widgets/notifications/in_app_notification_banner.dart — foreground in-app banner
- [x] lib/screens/settings/notification_preferences_screen.dart — full FCM category UI
- [x] supabase/migrations/20260428000001_user_devices_fcm.sql — fcm_token column + templates + preferences
- [x] supabase/functions/send-push/index.ts — FCM v1 Edge Function (locale-aware templates)
- [x] test/notifications/fcm_service_test.dart — unit tests (categories, defaults, stream)
- [x] .gitignore — Firebase config files excluded
- [x] .env.example — FCM setup documented
- [x] E-003 filed in .oxbar/escalations.md (Firebase + APNs human action needed)

## Files touched
- pubspec.yaml
- .gitignore
- .env.example
- android/app/build.gradle.kts
- android/settings.gradle.kts
- ios/Runner/Runner.entitlements (NEW)
- ios/Runner/Info.plist
- lib/firebase_options.dart (NEW — gitignored stub)
- lib/main.dart
- lib/screens/auth/auth_gate.dart
- lib/services/notifications/fcm_service.dart (NEW)
- lib/widgets/notifications/in_app_notification_banner.dart (NEW)
- lib/screens/settings/notification_preferences_screen.dart (REWRITTEN)
- supabase/migrations/20260428000001_user_devices_fcm.sql (NEW)
- supabase/functions/send-push/index.ts (NEW)
- test/notifications/fcm_service_test.dart (NEW)
- .oxbar/escalations.md (E-003 added)

## Questions for OXBAR
- HARBOR (notification templates) is PENDING — SIGNAL has seeded EN/AR/KU base templates
  in the migration. HARBOR should upsert additional templates when it launches.
- Should `lib/firebase_options.dart` be added to CI secrets instead of being
  fully gitignored? Currently each dev generates it locally with `flutterfire configure`.

## Blockers
- E-003: Firebase credentials + APNs key needed from Alhassan (human action)
- iOS push will not work until Xcode push capability is enabled in the Xcode project file

## Validation status
- [x] flutter analyze: passes (zero errors)
- [x] test/notifications/ tests: pass
- [ ] iOS APNs entitlement verified in Xcode (blocked on E-003)
- [ ] End-to-end test push within 10s (blocked on E-003 — Firebase not yet configured)
- [ ] VAULT CI: expected to pass (RLS on new tables, Apache 2.0 Firebase licenses, no secrets committed)

## Next step
Alhassan to resolve E-003, then run end-to-end validation.
