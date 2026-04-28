# CALLBACK status: READY-FOR-REVIEW

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/callback-webrtc
**Mission:** Re-enable WebRTC calling with free TURN/STUN

## Current state
READY-FOR-REVIEW: All tasks complete, no analyzer errors.

## Progress
- [x] Uncomment flutter_webrtc in pubspec.yaml — bumped to ^0.12.0 (resolved: 0.12.12+hotfix.1)
- [x] iOS Podfile created — platform :ios, '13.0', ENABLE_BITCODE=NO (the compat fix)
- [x] ICE config — stun.l.google.com, stun.cloudflare.com, relay.expressturn.com:3478
- [x] EXPRESSTURN_USER / EXPRESSTURN_PASS added to env_config.dart + .env.example
- [x] WebRTC service — lib/services/calling/webrtc_service.dart
  - PeerConnection, offer/answer/ICE exchange
  - mute, video toggle, switch camera (Helper.switchCamera)
  - getStats() for PostHog
- [x] Supabase Realtime signaling — lib/services/calling/call_signaling_service.dart
  - Channel: call:{session_id}
  - Events: offer, answer, ice_candidate, ready, hangup
- [x] Call screen — lib/screens/calling/simple_call_screen.dart
  - RTCVideoView for local (PIP) and remote (full-screen)
  - Caller: waits for ready → sends offer
  - Callee: sends ready → receives offer → answers
  - ICE exchange wired end-to-end
- [x] Call controls — lib/widgets/calling/call_controls.dart — onSwitchCamera wired
- [x] End-call analytics stub — lib/services/calling/call_analytics_service.dart
  - call_started, call_ended (duration), call_quality (stats)
- [x] SIGNAL push stub — lib/services/calling/incoming_call_stub.dart
  - No-op until SIGNAL merges; contract documented inline

## Files touched
- pubspec.yaml
- ios/Podfile (created)
- .env.example
- lib/config/env_config.dart
- lib/services/calling/webrtc_service.dart (created)
- lib/services/calling/call_signaling_service.dart (created)
- lib/services/calling/call_analytics_service.dart (created)
- lib/services/calling/incoming_call_stub.dart (created)
- lib/screens/calling/simple_call_screen.dart
- lib/widgets/calling/call_controls.dart

## SIGNAL dependency
SIGNAL status is PENDING. Until SIGNAL merges:
- Incoming push notification is a no-op (IncomingCallStub)
- Both parties must be in the app and navigate to the same session
- Caller → Call Management screen → join session
- Callee → Call Management screen → Active tab → join session

## Validation notes
- flutter pub get: ✅ flutter_webrtc 0.12.12+hotfix.1 resolved
- flutter analyze (new files): ✅ no issues
- Full project analyze: ✅ no errors (pre-existing info lints only)
- Two-device E2E test: ⚠️ requires physical devices on different networks

## Questions for OXBAR
None.

## Blockers
None — SIGNAL dependency gracefully stubbed.

## Next step
PR open for review. Awaiting SIGNAL merge for push integration.
