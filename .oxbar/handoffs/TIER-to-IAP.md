# Handoff from TIER to IAP-APPLE and IAP-GOOGLE

**Date:** 2026-04-28
**PR:** [TIER v2] Subscription tier model + enforcement (agent/tier-v2)

---

## What's now available

### 1. `subscriptions` table (Supabase)

Location: `supabase/migrations/20260428120000_tier_subscriptions.sql`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → auth.users, UNIQUE |
| `tier` | `subscription_tier` enum | `free` / `pro` / `ultimate` |
| `status` | `subscription_status` enum | `active` / `trial` / `past_due` / `canceled` |
| `current_period_end` | timestamptz | NULL = no expiry (admin_grant) |
| `store` | `subscription_store` enum | `apple` / `google` / `admin_grant` |
| `receipt_data` | bytea | Encrypted via `vault_encrypt_text()` |

**RLS:** Users can `SELECT` their own row. INSERT/UPDATE/DELETE is **service-role only** — your webhook Edge Functions must use the service-role key.

### 2. `get_user_tier(p_user_id uuid)` RPC

Returns `'free'` / `'pro'` / `'ultimate'` based on the active subscription.
Returns `'free'` when status is canceled/past_due or the period has expired.

```dart
// Used by TierService.dart — do not call from IAP code
final tier = await supabase.rpc('get_user_tier', params: {'p_user_id': userId});
```

### 3. `TierService` (Dart)

`lib/services/subscription/tier_service.dart`

- `TierService.instance.currentTier()` → `Future<Tier>`
- `TierService.instance.invalidateCache()` — **call this immediately after your webhook updates the subscription row**, so the next `currentTier()` call fetches fresh data.

### 4. Tier product IDs to implement

| Tier | Price | Product ID (proposed) |
|---|---|---|
| Pro | \$9.99/mo | `com.vagus.pro_monthly` |
| Ultimate | \$19.99/mo | `com.vagus.ultimate_monthly` |

There is no a-la-carte "+1 client" IAP product. See `.oxbar/decisions.md` (2026-04-28 12:00 UTC) for rationale.

---

## How to implement the purchase flow

### Apple (IAP-APPLE)

1. User taps "Upgrade to Pro" on `UpgradePromptSheet` → navigates to `UpgradeScreen`.
2. IAP-APPLE purchases the StoreKit 2 product `com.vagus.pro_monthly`.
3. On purchase success, IAP-APPLE's server-side Edge Function:
   - Verifies receipt with Apple's `/verifyReceipt` (or App Store Server API).
   - UPSERTs into `subscriptions`:
     ```sql
     INSERT INTO public.subscriptions (user_id, tier, status, current_period_end, store, receipt_data)
     VALUES ($1, 'pro', 'active', $expiry, 'apple', vault_encrypt_text($raw_receipt))
     ON CONFLICT (user_id) DO UPDATE SET
       tier = EXCLUDED.tier,
       status = EXCLUDED.status,
       current_period_end = EXCLUDED.current_period_end,
       store = EXCLUDED.store,
       receipt_data = EXCLUDED.receipt_data;
     ```
   - Uses the **service-role key** (bypasses RLS).
4. Return success to the client.
5. Client calls `TierService.instance.invalidateCache()` then refreshes the UI.

### Google (IAP-GOOGLE)

Same flow, but:
- Product ID: `com.vagus.pro_monthly` on Play Console.
- Store field: `'google'`.
- Verify via Google Play Developer API (`purchases.subscriptions.get`).
- `receipt_data` = `vault_encrypt_text(purchaseToken)`.
- UPSERT same table, same columns.

### Subscription lifecycle (both stores)

| Event | Action on `subscriptions` |
|---|---|
| Initial purchase | INSERT / UPSERT with `status='active'` |
| Renewal | UPDATE `current_period_end`, keep `status='active'` |
| Grace period | UPDATE `status='past_due'` |
| Expiry / cancel | UPDATE `status='canceled'` |
| Resubscribe | UPDATE `status='active'`, new `current_period_end` |

`get_user_tier` automatically downgrades to `free` when status ≠ active/trial or period expired — no extra logic needed.

---

## Caveats

- **Never** store the raw receipt/token as plaintext. Always wrap with `vault_encrypt_text()`.
- **Always** use the service-role key for writes; the RLS policy blocks authenticated-role inserts.
- Call `TierService.instance.invalidateCache()` on the Flutter client after any successful purchase so the 5-minute cache doesn't serve a stale tier.
- The `trial` status is reserved for future use (TRIAL agent). IAP-APPLE and IAP-GOOGLE should not write `'trial'` — use `'active'` for paid subscriptions.
- Admin grants (superadmin panel, test accounts) use `store='admin_grant'` and `current_period_end=NULL` (never expires). Coordinate with ADMIN-BUTTONS for the panel UI.
