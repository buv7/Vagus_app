# TIER status: READY-FOR-REVIEW

**Started:** 2026-04-28 12:00 UTC
**Last update:** 2026-04-28 13:30 UTC
**Branch:** agent/tier-v2
**Mission:** Subscription tier model + enforcement (Free/Pro/Ultimate)

## Current state
READY-FOR-REVIEW: PR open. All 31 unit tests pass. `flutter analyze` clean (no
errors, no warnings — only pre-existing `prefer_const_constructors` info hints
shared by the whole codebase). VAULT migration compliant (RLS enabled, no secrets,
receipt_data encrypted via vault_encrypt_text). IAP handoff written.

## Progress
- [x] `lib/models/subscription/tier.dart` — Tier enum, TierLimits, TierCheckResult
- [x] `lib/services/subscription/tier_service.dart` — server-authoritative resolver + all check* methods
- [x] `lib/widgets/subscription/upgrade_prompt_sheet.dart` — reusable upsell bottom sheet
- [x] `supabase/migrations/20260428120000_tier_subscriptions.sql` — subscriptions table + get_user_tier RPC + RLS
- [x] Enforcement: Add Client gate in `modern_client_management_screen.dart`
- [x] Enforcement: AI insights gate in `workout_ai.dart` (suggestProgression, deloadAdvice, weakPointAnalysis)
- [x] Enforcement stubs in TierService for LABKIT (checkLabwork), POSEKIT (checkPoseDetection), WEARABLE-HUB (checkAdvancedWearables)
- [x] `test/subscription/tier_test.dart` — 20 tests
- [x] `test/subscription/tier_limits_enforcement_test.dart` — 11 tests
- [x] `.oxbar/decisions.md` — per-extra-client billing rationale documented
- [x] `.oxbar/handoffs/TIER-to-IAP.md` — full interface contract for IAP-APPLE + IAP-GOOGLE
- [x] This status file updated to READY-FOR-REVIEW

## Files touched
- `lib/models/subscription/tier.dart` (new)
- `lib/services/subscription/tier_service.dart` (new)
- `lib/widgets/subscription/upgrade_prompt_sheet.dart` (new)
- `supabase/migrations/20260428120000_tier_subscriptions.sql` (new)
- `lib/screens/coach/modern_client_management_screen.dart` (modified — tier gate on _onAddClient)
- `lib/services/ai/workout_ai.dart` (modified — tier gate on all AI methods)
- `test/subscription/tier_test.dart` (new)
- `test/subscription/tier_limits_enforcement_test.dart` (new)
- `.oxbar/decisions.md` (appended)
- `.oxbar/handoffs/TIER-to-IAP.md` (new)
- `.oxbar/agent-status/TIER.md` (this file)

## Enforcement points completed
| Feature | Gate method | Where enforced |
|---|---|---|
| Add Client | `checkCanAddClient(count)` | `modern_client_management_screen.dart:_onAddClient` |
| AI insights | `checkAiInsights()` | `workout_ai.dart` (suggestProgression, deloadAdvice, weakPointAnalysis) |
| Lab work | `checkLabwork()` | TierService (LABKIT agent must wire) |
| Pose detection | `checkPoseDetection()` | TierService (POSEKIT agent must wire) |
| Advanced wearables | `checkAdvancedWearables()` | TierService (WEARABLE-HUB agent must wire) |
| Marketplace watermark | `requiresMarketplaceWatermark()` | TierService (WATERMARK agent must wire) |

## Questions for OXBAR
- Should the staging migration be applied before merging? Migration depends on
  20260427211500_vault_audit_table.sql (pgcrypto + vault_encrypt_text) which is
  already in the repo. Ready for staging dry-run at OXBAR's discretion.

## Blockers
(none)

## Next step
OXBAR merges once CI green. IAP-APPLE + IAP-GOOGLE should read TIER-to-IAP.md handoff.
LABKIT, POSEKIT, WEARABLE-HUB: call TierService.instance.check* before their upload/connect flows.
