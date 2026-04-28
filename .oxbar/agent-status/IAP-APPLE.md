# IAP-APPLE status: READY-FOR-REVIEW

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/iap-apple
**PR:** #35 — [IAP-APPLE] Apple StoreKit integration — Free/Pro/Ultimate subscriptions

## Current state

Implementation complete. PR open. Sandbox validation blocked on Alhassan completing E-003 (App Store Connect product creation) and setting `APPLE_SHARED_SECRET` in Supabase.

## Progress

- [x] `in_app_purchase: ^3.2.0` + `in_app_purchase_storekit: ^0.4.4` added to `pubspec.yaml`
- [x] Billing decision documented — no per-client à-la-carte IAP (`.oxbar/decisions.md`)
- [x] App Store Connect setup escalated to Alhassan (`.oxbar/escalations.md` E-003)
- [x] `lib/models/subscription/tier.dart` — SubscriptionTier enum, SubscriptionState model
- [x] `lib/services/iap/apple_iap_service.dart` — full StoreKit IAP service
- [x] `lib/services/iap/tier_service.dart` — real-time tier sync from Supabase
- [x] `supabase/functions/validate-apple-receipt/index.ts` — server-side receipt validation
- [x] `supabase/migrations/20260428000100_apple_iap_subscriptions.sql` — additive schema
- [x] Restore Purchases UI in settings (iOS-only Subscription card)
- [x] `lib/main.dart` — init wired, TierService in Provider tree
- [x] Resolved merge conflicts with SHIELD (Sentry) and TRIAL (schema alignment)
- [x] `flutter analyze`: 0 errors
- [x] PR #35 opened
- [ ] Sandbox test — **blocked on E-003 + APPLE_SHARED_SECRET**

## Files touched

- `pubspec.yaml` + `pubspec.lock`
- `lib/models/subscription/tier.dart` (new)
- `lib/services/iap/apple_iap_service.dart` (new)
- `lib/services/iap/tier_service.dart` (new)
- `supabase/functions/validate-apple-receipt/index.ts` (new)
- `supabase/migrations/20260428000100_apple_iap_subscriptions.sql` (new)
- `lib/main.dart` (IAP init + provider)
- `lib/screens/settings/user_settings_screen.dart` (Subscription card)
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `linux/flutter/generated_plugin_registrant.*`
- `windows/flutter/generated_plugin_registrant.*`
- `.oxbar/decisions.md` (per-client billing decision)
- `.oxbar/escalations.md` (E-003 App Store Connect)

## Blockers for final sign-off

1. **E-003** — Alhassan creates App Store Connect subscription group + products + 30-day intro offer
2. **`APPLE_SHARED_SECRET`** — set in Supabase Dashboard → Edge Functions → Secrets
3. **Sandbox tester account** — credentials needed for TestFlight sandbox validation

## Architecture notes

- **Server is authority**: receipt data goes client → Edge Function → Apple → Supabase. The Flutter app reads `subscriptions` table only after server writes. No client-side grant possible.
- **Schema-compatible with TRIAL**: uses `plan_code`/`period_end` (TRIAL's columns). Migration `000100` runs after TRIAL's `000000_trial_flow`.
- **Realtime sync**: `TierService` attaches a Supabase realtime listener; tier updates propagate within < 5s of server write.
- **Platform guard**: IAP init and Subscription settings card are iOS/macOS-only.
