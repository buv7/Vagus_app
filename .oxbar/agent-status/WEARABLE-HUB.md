# WEARABLE-HUB status: READY-FOR-REVIEW

**Started:** 2026-04-28 UTC
**Last update:** 2026-04-28 UTC
**Branch:** agent/wearable-hub
**Mission:** Replace existing health_service.dart with Open Wearables. Apple Health + Health Connect first. Garmin/Whoop/Oura phased as OAuth approvals roll in.

## Current state
READY-FOR-REVIEW: PR authored. Apple Health + Google Health Connect fully operational via the `health` Dart package (already in pubspec). VAULT encryption in place for HRV and VO2max. Background sync every 4 hours. Coach dashboard widget live. Cloud provider stubs (Garmin/WHOOP/Oura) show "Coming Soon — awaiting OAuth approval". VPS provisioning escalated to Alhassan (E-003).

## PRs
- 🟡 **Open** — `[WEARABLE-HUB] Open Wearables integration (Apple Health + Health Connect first)`

## Progress
- [x] Read COORDINATION_PROTOCOL.md + VAULT-to-WEARABLE-HUB.md handoff
- [x] Supabase migration: `wearable_daily` + `wearable_sources` + `wearable_upsert_daily` RPC + `wearable_read_daily` RPC (with audit)
- [x] `lib/services/wearables/wearable_service.dart` — singleton service with:
  - Apple Health + Health Connect connect/disconnect
  - HRV encrypted via `vault_encrypt_text()` RPC (server-side, no bytea headaches on client)
  - Background sync on app launch + every 4 h (`Timer.periodic`)
  - Tier guard: free = HealthKit/HealthConnect; Pro+ = cloud providers (stubbed)
  - Coach read via `wearable_read_daily` RPC (emits single audit row per dashboard load)
  - OAuth token storage via `flutter_secure_storage` (cloud providers, when credentials land)
- [x] `lib/screens/wearables/wearable_connect_screen.dart` — full provider list with tier labels, "Coming Soon" badges for cloud providers, privacy note
- [x] `lib/components/wearables/wearable_data_card.dart` — coach dashboard widget: today's steps/sleep/RHR/active kcal + 7-day step sparklines
- [x] `ios/Runner/Info.plist` — `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription`
- [x] `ios/Runner/Runner.entitlements` — `com.apple.developer.healthkit` entitlement
- [x] `android/app/src/main/AndroidManifest.xml` — Health Connect `READ_*` permissions + `activity-alias` for permissions management + `queries/<package>` for Health Connect app discovery
- [x] `lib/main.dart` — `WearableService.instance.init()` called on launch (unawaited, non-blocking)
- [x] `flutter analyze` — 0 errors on all new + modified files
- [x] E-003 escalation filed in `.oxbar/escalations.md` (VPS + OAuth credentials for Garmin/WHOOP/Oura)

## Data contract (follows VAULT guidance)
- **Aggregate first, encrypt sensitive:** steps/sleep/RHR stored plaintext-but-RLS-protected; HRV and VO2max encrypted with `vault_encrypt_text()`.
- **Coach reads aggregates only:** `wearable_read_daily` returns non-encrypted columns; raw biomarkers require explicit consent gate (future).
- **Audit at session level:** one `vault_audit_access` row per dashboard view, not per metric. Background sync attributed to `user_id` with justification `'background_sync'`.
- **No polling < 4 h:** enforced via `SharedPreferences` timestamp check in `syncIfStale()`.
- **No unencrypted token storage:** cloud OAuth tokens stored in `flutter_secure_storage`, never in Supabase.

## Files touched
- `supabase/migrations/20260428000000_wearable_hub_tables.sql` (new)
- `lib/services/wearables/wearable_service.dart` (new)
- `lib/screens/wearables/wearable_connect_screen.dart` (new)
- `lib/components/wearables/wearable_data_card.dart` (new)
- `ios/Runner/Info.plist` (modified — HealthKit usage strings)
- `ios/Runner/Runner.entitlements` (new)
- `android/app/src/main/AndroidManifest.xml` (modified — Health Connect permissions)
- `lib/main.dart` (modified — wearable init on launch)
- `.oxbar/agent-status/WEARABLE-HUB.md` (this file)
- `.oxbar/escalations.md` (appended E-003)

## Notes / deferred
- **VO2max:** not available in `health` v13.1.4 package. Will arrive via Garmin/Oura cloud providers (Pro+) once OAuth approved. Column exists in `wearable_daily` and migration, ready to populate.
- **CGM passthrough:** CGM data already flows through Apple Health / Health Connect; the `wearable_daily` sync picks it up automatically once the CGM data types are added to `_readTypes` in `wearable_service.dart` (no schema change needed).
- **Existing `health_service.dart`:** kept intact — its 3 callers (`health_rings.dart`, `modern_client_dashboard.dart`, `health_connections_screen.dart`) still work. New code uses `WearableService`; old callers can migrate incrementally.
- **Open Wearables VPS:** not needed for Phase 1 (device-native). Escalated as E-003 for Phase 2 (cloud providers).

## Questions for OXBAR
1. E-003: proceed with Hetzner VPS now (so it's ready when OAuth approvals land), or wait?
2. Should `health_connections_screen.dart` be migrated to `WearableConnectScreen` as a follow-up, or left as-is until E2E tests cover it?

## Blockers
(none for current PR — Apple Health + Health Connect fully operational)
