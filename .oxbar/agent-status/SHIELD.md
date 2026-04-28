# SHIELD status: READY-FOR-REVIEW

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/shield-init-v2
**Mission:** "Broken but functional, never crashed." — crash-proofing, Sentry, error boundaries.

## Current state
All tasks complete. PR opened. Awaiting review.

## Progress
- [x] Add `sentry_flutter` + `connectivity_plus` to pubspec.yaml
- [x] Initialize Sentry in `lib/main.dart` (DSN via `String.fromEnvironment('SENTRY_DSN')`)
- [x] Wrap `runApp` in `runZonedGuarded`
- [x] `FlutterError.onError` + `PlatformDispatcher.instance.onError` route to Sentry + ShieldStore
- [x] Create `lib/core/error/error_boundary.dart` — `installGlobalErrorBoundary()` replaces `ErrorWidget.builder` in release/profile; `ErrorBoundary` widget for scoped fallback state
- [x] Create `lib/core/error/shield_store.dart` — in-memory store for error/sync diagnostics
- [x] Create `lib/core/network/retry_policy.dart` — `withRetry<T>()` with 3-attempt exponential back-off + full jitter; non-transient errors immediately rethrown to Sentry
- [x] Create `lib/screens/diagnostics_screen.dart` — hidden diagnostics (5-tap "Settings" title → reveal). Shows pending sync queue, last sync time, last error, network status, build version
- [x] Add `WidgetsBindingObserver` to `_VagusMainAppState` with lifecycle breadcrumbs to Sentry
- [x] `test/core/retry_policy_test.dart` — 4 unit tests for retry behavior

## Files touched
- `pubspec.yaml`
- `lib/main.dart`
- `lib/core/error/error_boundary.dart` (new)
- `lib/core/error/shield_store.dart` (new)
- `lib/core/network/retry_policy.dart` (new)
- `lib/screens/diagnostics_screen.dart` (new)
- `lib/screens/settings/user_settings_screen.dart` (5-tap trigger added)
- `test/core/retry_policy_test.dart` (new)

## Design decisions
- `ErrorWidget.builder` is the correct Flutter analog to React's `componentDidCatch` — no red screen in release
- `ErrorBoundary` widget for explicit scoped fallback (async errors, initState failures)
- `runZonedGuarded` is nested inside `SentryFlutter.init`'s `appRunner` — standard Sentry pattern
- VAULT-compatible: `String.fromEnvironment` for DSN (no secrets in code), both new deps are permissive (BSD/MIT/Apache)
- Diagnostics screen is completely hidden (5-tap) — no visible entry point in prod UI

## Questions for OXBAR
None.

## Blockers
None.

## Next step
Merge when CI green.
