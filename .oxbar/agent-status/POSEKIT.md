# POSEKIT status: READY-FOR-REVIEW

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/posekit
**PR:** [POSEKIT] Minimal pose detection (3 exercises, on-device)

## Current state
All tasks complete. PR open against main. Awaiting OXBAR review.

## Progress
- [x] pubspec.yaml: added `camera`, `google_mlkit_pose_detection`, `google_mlkit_commons`
- [x] iOS Info.plist: fixed duplicate NSCameraUsageDescription, added pose detection mention
- [x] Android: CAMERA permission already present
- [x] `lib/services/subscription/tier_service.dart` — Pro+ gate stub (TIER not merged; uses entitlements_v like PlanAccessManager)
- [x] `lib/services/pose/pose_engine.dart` — camera + MLKit pose stream, NV21/BGRA8888 conversion, video recording support
- [x] `lib/services/pose/classifiers/exercise_classifier.dart` — base class, ExerciseType, FormQuality, RepPhase, ClassificationResult
- [x] `lib/services/pose/classifiers/squat_classifier.dart` — knee angle depth + back angle
- [x] `lib/services/pose/classifiers/pushup_classifier.dart` — elbow angle + body alignment
- [x] `lib/services/pose/classifiers/deadlift_classifier.dart` — hip hinge + bar path proxy
- [x] `lib/screens/workout/form_check_screen.dart` — full-screen camera, landmark overlay, rep counter, form badge (green/yellow/red), exercise picker, save-clip opt-in (default OFF)
- [x] `lib/screens/workout/coach_form_clips_screen.dart` — coach view with pin/play, 30-day expiry shown, signed URL for video

## Files touched
- pubspec.yaml
- ios/Runner/Info.plist
- lib/services/subscription/tier_service.dart (new)
- lib/services/pose/pose_engine.dart (new)
- lib/services/pose/classifiers/exercise_classifier.dart (new)
- lib/services/pose/classifiers/squat_classifier.dart (new)
- lib/services/pose/classifiers/pushup_classifier.dart (new)
- lib/services/pose/classifiers/deadlift_classifier.dart (new)
- lib/screens/workout/form_check_screen.dart (new)
- lib/screens/workout/coach_form_clips_screen.dart (new)

## Notes for OXBAR / reviewer
- TIER not merged: `TierService` stub checks `entitlements_v.plan_code` same as `PlanAccessManager`. Swap for real TIER API when merged.
- `pose-clips` Supabase Storage bucket must be created (private) with RLS: user reads own clips, coach reads client clips. A pg_cron job should enforce 30-day TTL (expires_at column present).
- All pose processing is on-device; no frames leave the device.
- Save clip is opt-in per session (default OFF). Without opting in, no media is written or uploaded.
- iOS minimum deployment target should be iOS 15.5+ for `google_mlkit_pose_detection`.
- Coordinate mapping in `_PosePainter` uses simple x/y scale (stretches to fill). A letterbox-aware version is a nice-to-have for v2.

## Blockers
(none — TIER dependency stubbed)

## Questions for OXBAR
- Should the coach clips screen be wired into existing coach client management screens? If so, which one?
- Confirm `pose-clips` bucket name and RLS policy wording before merge.
