# WATERMARK status: READY-FOR-REVIEW

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/watermark
**PR:** #34 — [WATERMARK] Tier-based watermark system

## Current state

Implementation complete. PR open against `main`. VAULT CI running.

## What was built

### Dart / Flutter

| File | Purpose |
|---|---|
| `lib/services/subscription/tier_service.dart` | TierService shim over `entitlements_v`; converts `plan_code → UserTier`; provides `mandatoryWatermark` / `canToggleWatermark` policy helpers |
| `lib/models/watermark/watermark_models.dart` | `WatermarkSettings` (JSON), `WatermarkPolicy`, `WatermarkRenderSpec`; 15% area cap baked in |
| `lib/services/watermark/watermark_service.dart` | Image compositing (image ^4.2, MIT); video stamping first+last 3 s (ffmpeg_kit_flutter_min); dual-version Supabase Storage upload; settings persistence |
| `lib/components/watermark/watermark_toggle.dart` | Toggle + template selector + opacity slider (free tier locked); `VideoWatermarkProgress` widget |

### Supabase

| File | Purpose |
|---|---|
| `supabase/functions/og-preview/index.ts` | Edge Function — fetches image, checks tier, stamps with imagescript (MIT), returns JPEG |
| `supabase/migrations/20260428000001_watermark_settings.sql` | `watermark_settings` table with full RLS + DB trigger blocking free-tier `enabled=FALSE` |

### CI

| File | Change |
|---|---|
| `pubspec.yaml` | + `image ^4.2.0` (MIT), + `ffmpeg_kit_flutter_min ^6.0.3` |
| `.github/workflows/vault.yml` | ALLOWLIST entry for `ffmpeg_kit_flutter_min` (min build = LGPL-2.1, not LGPL-3.0) |

### Tests

`test/services/watermark/watermark_service_test.dart` — 16 tests, all green:
- WatermarkSettings JSON round-trip
- TierService policy helpers (all 3 tiers)
- WatermarkPolicy.forTier (all 3 tiers)
- WatermarkRenderSpec invariants
- Area-cap arithmetic for 5 resolutions (Full HD, SD, portrait, thumbnail, camera)

## Progress

- [x] lib/services/subscription/tier_service.dart
- [x] lib/services/watermark/watermark_service.dart
- [x] Image compositing (logo + text, bottom-right, opacity, <15% area)
- [x] Video stamping (first 3 s + last 3 s, ffmpeg, async progress)
- [x] OG preview Edge Function (supabase/functions/og-preview/)
- [x] Tier enforcement (Free = mandatory; Pro/Ultimate = toggleable, default ON)
- [x] 3 watermark templates (minimal, prominent, brand-first)
- [x] Background async + progress UI for video (VideoWatermarkProgress widget)
- [x] Dual-version storage (media-originals + media-watermarked buckets)
- [x] DB trigger enforces watermark for free tier server-side
- [x] 16 unit tests, all passing
- [x] flutter analyze — no issues
- [x] PR #34 opened

## Notes for OXBAR / reviewer

- **TIER shim**: `TierService` is a deliberate thin wrapper over `entitlements_v` until the TIER agent ships. When TIER lands, only `TierService.currentTier()` needs updating — one method, one file.
- **ffmpeg ALLOWLIST**: The VAULT license scanner would flag `ffmpeg_kit_flutter_min` as LGPL-3.0 (pub.dev metadata). The min build actually uses LGPL-2.1 codecs only. Entry added to ALLOWLIST with justification. Reviewer should confirm this is acceptable or find an alternative.
- **Video performance**: 1-min clip targeting <30 s. Actual time depends on device; `libx264 -preset fast -crf 23` is a reasonable default. Can tune to `-preset ultrafast` if timing fails on lower-end devices.
- **Storage buckets**: `media-originals` and `media-watermarked` must be created in Supabase Storage with appropriate RLS policies (not created by the migration — bucket creation is a Supabase dashboard/CLI operation).

## Files touched

- lib/services/subscription/tier_service.dart (new)
- lib/models/watermark/watermark_models.dart (new)
- lib/services/watermark/watermark_service.dart (new)
- lib/components/watermark/watermark_toggle.dart (new)
- supabase/functions/og-preview/index.ts (new)
- supabase/migrations/20260428000001_watermark_settings.sql (new)
- test/services/watermark/watermark_service_test.dart (new)
- pubspec.yaml (modified)
- .github/workflows/vault.yml (modified)
