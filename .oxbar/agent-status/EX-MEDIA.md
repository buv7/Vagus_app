# EX-MEDIA status: RUNNING

**Started:** 2026-04-27 22:00 UTC
**Last update:** 2026-04-27 22:00 UTC
**Branch:** agent/ex-media
**Mission:** Exercise video upload + URL handler + in-app player integration (REEL); image management for 350 yuhonas exercises.

## Current state
RUNNING: Dependencies EX-FORGE and MASON are both PENDING. Proceeding with reasonable assumptions:
- exercises table FK written as soft reference (DO block); EX-FORGE migration must run before this one in prod.
- media_url_resolver stub written at lib/services/media/media_url_resolver.dart — MASON replaces with real CDN impl.
- REEL integration uses a well-defined interface; REEL agent fills in the player implementation.

## Progress
- [x] Read COORDINATION_PROTOCOL.md
- [x] Checked dep statuses (EX-FORGE: PENDING, MASON: PENDING, REEL: PENDING)
- [x] Status file updated to RUNNING
- [ ] Migration: exercise_videos table
- [ ] Model: ExerciseVideo
- [ ] Service: ExerciseVideoService
- [ ] MASON stub: media_url_resolver.dart
- [ ] Uploader screen: exercise_video_uploader.dart
- [ ] REEL integration widget: reel_player_widget.dart
- [ ] Unit test
- [ ] flutter analyze clean
- [ ] Open PR

## Files touched
- .oxbar/agent-status/EX-MEDIA.md
- supabase/migrations/20260427220000_ex_media_exercise_videos.sql
- lib/models/workout/exercise_video.dart
- lib/services/exercise/exercise_video_service.dart
- lib/services/media/media_url_resolver.dart
- lib/screens/coach/exercise_video_uploader.dart
- lib/widgets/reel/reel_player_widget.dart
- test/exercise_video_service_test.dart

## Questions for OXBAR
- EX-FORGE is PENDING: exercise_videos.exercise_id FK needs the exercises table. I've written the FK in a DO block that checks if the table exists before adding. If EX-FORGE runs after this migration, OXBAR should apply a follow-up FK migration or reorder. Recommend: EX-FORGE runs first.
- MASON is PENDING: media_url_resolver stub is at lib/services/media/media_url_resolver.dart. When MASON ships, MASON replaces this file. I've left a MASON_HANDOFF comment at the top.
- REEL is PENDING: my reel_player_widget.dart defines the interface. When REEL ships, they should extend or replace this file (see HANDOFF note at top of file).

## Blockers
(none — proceeding with stubs as documented above)

## Next step
Write migration SQL.
