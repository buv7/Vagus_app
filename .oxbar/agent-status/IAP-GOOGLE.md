# IAP-GOOGLE status: READY-FOR-REVIEW

**Started:** 2026-04-28 00:00 UTC
**Last update:** 2026-04-28
**Branch:** agent/iap-google
**Mission:** Mirror IAP-APPLE for Google Play Billing — same tier pricing, same 30-day trial, shared abstract interface.

## Current state

READY-FOR-REVIEW: All code deliverables shipped on branch `agent/iap-google`. PR is open.

## Progress

- [x] Read COORDINATION_PROTOCOL (not present — proceeded from context)
- [x] Checked TIER + IAP-APPLE status — both PENDING; no handoff doc exists
- [x] Designed shared abstract interface (`IapService` / `SubscriptionState`) so IAP-APPLE can conform to same contract
- [x] `lib/services/iap/iap_interface.dart` — abstract interface + constants
- [x] `lib/services/iap/google_iap_service.dart` — Google Play Billing implementation
- [x] `supabase/functions/validate-google-receipt/index.ts` — receipt validation Edge Function
- [x] `supabase/migrations/20260428000000_iap_google_columns.sql` — additive columns + plan seeds
- [x] `pubspec.yaml` — added `in_app_purchase: ^3.2.0` and `in_app_purchase_android: ^0.3.5`
- [x] Status updated
- [ ] Play Console: create `vagus_pro_monthly` + `vagus_ultimate_monthly` subscription products (manual — escalated to Alhassan)
- [ ] Play Console: configure 30-day free trial on each base plan (manual — escalated)
- [ ] Supabase secret: `supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='...'` (VAULT manages)
- [ ] Internal testing track purchase verified end-to-end
- [ ] IAP-APPLE agent launched to conform to same `IapService` interface

## Files touched

- `lib/services/iap/iap_interface.dart` (new)
- `lib/services/iap/google_iap_service.dart` (new)
- `supabase/functions/validate-google-receipt/index.ts` (new)
- `supabase/migrations/20260428000000_iap_google_columns.sql` (new)
- `pubspec.yaml` (modified — 2 deps added)
- `.oxbar/agent-status/IAP-GOOGLE.md` (this file)

## Architecture decisions

### Interface-first: no TIER/IAP-APPLE handoff
TIER and IAP-APPLE were PENDING with no handoff doc. Proceeded by:
1. Defining a clean `IapService` abstract class and `SubscriptionState` model that IAP-APPLE can conform to
2. Using the existing `subscriptions` table (TIER's archive migration `0008_monetization.sql`)
3. Adding only additive columns (`store`, `purchase_token`, `google_order_id`) — no breaking changes

### Receipt validation is server-side only
The Flutter client sends `purchaseToken` to `validate-google-receipt` edge function. The function:
1. Verifies the caller's Supabase JWT
2. Asserts `body.userId == JWT subject` to prevent spoofing
3. Exchanges a service account JWT for a Google OAuth token
4. Calls `androidpublisher.subscriptions.get` to validate the token
5. Acknowledges unacknowledged purchases (prevents 3-day auto-refund)
6. Upserts into `subscriptions` with `store='google'`
The client never grants features based solely on a client-side receipt.

### Billing plans seeded at migration time
`vagus_pro_monthly` (999¢) and `vagus_ultimate_monthly` (1999¢) seeded as placeholders. Prices must match Play Console product configuration. TIER can UPDATE these rows when pricing is finalized.

### No Pub/Sub real-time notifications (TODO)
Server-side subscription lifecycle events (renewals, cancellations, billing issues) require a Google Cloud Pub/Sub webhook. This is a follow-up; current implementation covers purchase + restore flows only.

## Play Console setup (manual — needs Alhassan)

1. Go to Play Console → your app → Monetize → Subscriptions
2. Create subscription: Product ID `vagus_pro_monthly`, name "Vagus Pro"
   - Add base plan with 30-day free trial
   - Set price to match seeded value (or update migration seed)
3. Create subscription: Product ID `vagus_ultimate_monthly`, name "Vagus Ultimate"
   - Add base plan with 30-day free trial
4. Add a tester account to the internal testing track
5. Link a Google service account:
   - Google Play Console → Setup → API access → Link a Google Cloud project
   - Create service account, grant "Financial data viewer" role in Play Console
   - Download service account JSON
   - `supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='<json>'`

## Questions for OXBAR

1. **Play Console access** — Alhassan must create the subscription products manually. Can OXBAR prompt him with the steps above?
2. **Service account JSON** — VAULT should manage this as an encrypted env var. When Alhassan obtains the service account JSON, it goes to: `supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='<json>'`
3. **IAP-APPLE launch** — the `IapService` interface is ready; IAP-APPLE should implement it for Apple StoreKit. Should OXBAR launch IAP-APPLE now?
4. **Pricing alignment** — current seeds are 999¢ (Pro) and 1999¢ (Ultimate). TIER should confirm final pricing.
5. **Pub/Sub webhook** — real-time subscription lifecycle events need a second edge function + GCP Pub/Sub setup. Should this be a follow-up task for a new agent?

## Blockers

- **Play Console setup** — cannot create subscription products without Play Console access (human step)
- **Service account JSON** — needed for `validate-google-receipt` to call Google APIs
- **No TIER/IAP-APPLE handoff** — proceeded with reasonable interface; may need adjustment once TIER defines plan schema

## Next step

Alhassan creates Play Console subscription products + obtains service account JSON → VAULT sets the secret → internal test track purchase validates end-to-end.
