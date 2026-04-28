# Handoff: IAP-GOOGLE → IAP-APPLE

**Date:** 2026-04-28
**From:** IAP-GOOGLE (branch `agent/iap-google`, PR #21)
**To:** IAP-APPLE

---

## What IAP-GOOGLE built that you depend on

### 1. Shared abstract interface

`lib/services/iap/iap_interface.dart` — implement `IapService` and produce
`SubscriptionState` objects. The interface is intentionally minimal so both
stores can conform without leaking store-specific types to callers.

```dart
// Implement this:
abstract class IapService {
  Future<void> init();
  Future<List<ProductDetails>> fetchProducts(List<String> productIds);
  Future<void> purchase(ProductDetails product);
  Stream<SubscriptionState> get subscriptionStream;
  Future<SubscriptionState> currentState();
  Future<void> restorePurchases();
  Future<void> dispose();
}
```

### 2. Platform provider with your hook already wired in

`lib/services/iap/iap_provider.dart` has a `_NoOpIapService` placeholder for
iOS/macOS.  Replace it by:

1. Creating `lib/services/iap/apple_iap_service.dart` implementing `IapService`
2. In `iap_provider.dart`, change the `else` branch to:
   ```dart
   } else {
     service = AppleIapService(supabase);
   }
   ```

### 3. Product IDs (shared constants)

```dart
// lib/services/iap/iap_interface.dart
const kVagusProMonthly      = 'vagus_pro_monthly';
const kVagusUltimateMonthly = 'vagus_ultimate_monthly';
```

These are the same product IDs configured in App Store Connect. Use them
when calling `fetchProducts()`.

### 4. Subscriptions table schema

Migration `supabase/migrations/20260428000000_iap_google_columns.sql` added:

| Column | Type | Notes |
|---|---|---|
| `store` | `text` | `'apple'` or `'google'` — you write `'apple'` |
| `purchase_token` | `text` | Google-specific; leave NULL for Apple rows |
| `google_order_id` | `text` | Google-specific; leave NULL for Apple rows |

Existing columns you'll use:

| Column | Type | Notes |
|---|---|---|
| `user_id` | `uuid` | FK to `auth.users` |
| `plan_code` | `text` | `vagus_pro_monthly` or `vagus_ultimate_monthly` |
| `status` | `text` | `trialing` \| `active` \| `past_due` \| `canceled` \| `expired` |
| `period_start` | `timestamptz` | |
| `period_end` | `timestamptz` | |
| `cancel_at_period_end` | `boolean` | |
| `external_subscription_id` | `text` | Use for Apple original transaction ID |

### 5. Billing plans (already seeded)

`vagus_pro_monthly` (999¢) and `vagus_ultimate_monthly` (1999¢) are in
`public.billing_plans`. App Store Connect prices should match.

---

## What IAP-APPLE needs to build

### Required
- `lib/services/iap/apple_iap_service.dart` — `AppleIapService implements IapService`
  - Uses `in_app_purchase` (already in `pubspec.yaml`) + StoreKit
  - On `PurchaseStatus.purchased / restored`: call `validate-apple-receipt` edge function (you build this)
  - Reads current state from `subscriptions` where `store = 'apple'`
- `supabase/functions/validate-apple-receipt/index.ts` — calls Apple App Store Server API
  - Pattern mirrors `validate-google-receipt/index.ts` — verify JWT, validate server-side, upsert
  - Secret to set: `APPLE_SHARED_SECRET` (for App Store receipt validation) or use the newer JWT-based API

### Edge function security contract (must match Google's)
1. Verify `Authorization: Bearer <jwt>` — reject `401` if missing/invalid
2. Assert `body.userId == JWT subject` — reject `403` if mismatch
3. Validate receipt with Apple before writing any subscription row
4. Never grant features based on client-supplied data alone

### Wiring in `iap_provider.dart`

Add `import 'apple_iap_service.dart';` and replace `_NoOpIapService()` with
`AppleIapService(supabase)` in the iOS/macOS branch.

---

## VAULT compliance reminders

- No Apple shared secret or private key in code — use `Deno.env.get("APPLE_SHARED_SECRET")`
- Any new table needs `ENABLE ROW LEVEL SECURITY` + a policy in the same migration
- `in_app_purchase_storekit` (if you add it directly) is BSD-3-Clause — permissive, fine

---

## Contacts

- OXBAR: coordinates launch timing
- IAP-GOOGLE: owns `iap_interface.dart` and `iap_provider.dart` — coordinate before changing the interface
- TIER: owns pricing / `billing_plans` table — check before changing plan codes or amounts
