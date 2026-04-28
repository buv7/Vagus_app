# IAP-APPLE status: PENDING — waiting on TIER

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/iap-apple
**Mission:** Apple StoreKit IAP — Free/Pro $9.99/Ultimate $19.99 + 30-day trial

## Current state

PENDING: `lib/models/subscription/tier.dart` does not exist. TIER agent has not been launched yet. IAP-APPLE's service layer, Edge Function, and tier-sync code all depend on TIER's `SubscriptionTier` enum and `TierService` interface. Cannot write those without knowing the model shape.

## Progress

- [x] `in_app_purchase: ^3.2.0` added to `pubspec.yaml`
- [x] Billing decision documented in `.oxbar/decisions.md` — no per-client à-la-carte IAP; bundled in tier upgrade
- [x] App Store Connect setup escalated to Alhassan in `.oxbar/escalations.md` (E-003)
- [ ] App Store Connect: subscription group "Coach Tiers" + two products (blocked on Alhassan)
- [ ] `lib/services/iap/apple_iap_service.dart` (blocked on TIER)
- [ ] `supabase/functions/validate-apple-receipt/` Edge Function (blocked on TIER schema)
- [ ] Tier sync with `TierService` (blocked on TIER)
- [ ] Restore purchases UI in settings (blocked on TIER)
- [ ] Sandbox test with TestFlight account (blocked on Alhassan + TIER)

## Files touched

- `pubspec.yaml` — added `in_app_purchase: ^3.2.0`
- `.oxbar/decisions.md` — per-client billing decision
- `.oxbar/escalations.md` — E-003 App Store Connect setup

## Questions for OXBAR

None — blocker is structural (TIER not launched).

## Blockers

1. **TIER not launched** — need `lib/models/subscription/tier.dart` with `SubscriptionTier` enum and `TierService` before writing any IAP→tier sync code.
2. **App Store Connect** — Alhassan must create subscription group and products (E-003 in escalations.md).

## Next step

When TIER delivers `lib/models/subscription/tier.dart`, IAP-APPLE can immediately proceed with:
1. Full `lib/services/iap/apple_iap_service.dart`
2. `supabase/functions/validate-apple-receipt/` Edge Function
3. Tier sync wiring
4. Settings restore UI
