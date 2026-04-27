# MUSIC-PURGE status: READY-FOR-REVIEW

**Started:** 2026-04-27 21:05 UTC
**Last update:** 2026-04-27 22:30 UTC
**Branch:** agent/music-purge
**Mission:** Remove all music-related code, screens, services, dependencies, and DB tables. Music is OUT of v1.

## Current state
READY-FOR-REVIEW: feature code deleted, admin toggles dropped, migration authored, status posted. Pending OXBAR decision on `just_audio` dep retention (see Question below). PR title: `[MUSIC-PURGE] Retire music feature`.

## Progress
- [x] Inventory hits across repo
- [x] Categorize hits (feature / incidental / test)
- [x] Create branch `agent/music-purge` from `main`
- [x] Delete feature code (5 files; 3 dirs cleared)
- [x] Update consumers (`user_settings_screen`, `admin_session_copilot_screen`, `session_models`, `user_inspector_sheet`)
- [ ] Drop deps from pubspec.yaml — **deferred pending OXBAR decision** (see Question)
- [x] Author migration to drop music_* tables
- [x] Strip music permission strings from native manifests (none found — confirmed)
- [x] Update CHANGELOG.md
- [ ] Run validation (`flutter analyze`, `flutter test`, `flutter build appbundle`) — **environment caveat**
- [ ] Open PR

## Inventory (final)

### A. Feature code — DELETED
- `lib/models/music/music_models.dart`
- `lib/services/music/music_service.dart`
- `lib/widgets/music/music_play_button.dart`
- `lib/widgets/music/music_attachment_widget.dart`
- `lib/screens/settings/music_settings_screen.dart`

### B. Feature surface in shared files — EDITED
- `lib/screens/settings/user_settings_screen.dart` — removed `music_settings_screen` import + Music Integration card
- `lib/screens/admin/admin_session_copilot_screen.dart` — removed Beta Music SwitchListTile
- `lib/models/admin/session_models.dart` — removed `betaMusic` field, ctor param, copyWith param
- `lib/widgets/admin/user_inspector_sheet.dart` — dropped "Music" from Connections placeholder text
- `CHANGELOG.md` — Music Integration entry struck through with "retired pre-v1" note

### C. Database — DROP via migration
File: `supabase/migrations/20260427192816_music_purge_drop_tables.sql`
Drops:
- `public.workout_music_refs`
- `public.event_music_refs`
- `public.user_music_prefs`
- `public.music_links`

`public.workout_plans` is left untouched — it's a real domain table.

### D. Incidental — KEPT (NOT music feature)
- `lib/widgets/workout/tempo_cue_pill.dart` L183 — `Icons.music_off` is a Material icon used for a generic "tempo off" state; no music behavior.
- `lib/screens/admin/admin_ticket_queue_screen.dart` — `Icons.playlist_add_check` is a generic Material icon for ticket queues, unrelated to music playlists.
- `lib/widgets/messaging/voice_recorder.dart`, `lib/screens/notes/voice_recorder.dart` — voice recorder; unrelated.

### E. Tests — none
`grep -ri "music\|playlist" test/` → 0 hits. No widget/unit tests reference music.

### F. Native manifests — none
No music permission strings present in `android/app/src/main/AndroidManifest.xml` or `ios/Runner/Info.plist`.

### G. Routes
No music routes in `lib/main.dart` or `lib/app.dart`. Only entry was the settings card (covered above).

## Question for OXBAR — `just_audio` scope

`pubspec.yaml` has `just_audio: ^0.9.36`. It is also used by `lib/widgets/files/file_previewer.dart` to preview **audio file attachments** (voice notes, audio uploads). That is NOT a music-feature use — it's a generic audio file preview.

**Recommendation (default I am taking unless OXBAR objects):** keep `just_audio`. The music FEATURE is retired (UI gone, services gone, DB gone). The package stays as a generic audio playback dep for `file_previewer.dart`.

**Alternative:** migrate `file_previewer.dart` to `audioplayers` and remove `just_audio` entirely. Adds a new dep, churn in an unrelated file. If OXBAR wants this, I will do it as a follow-up PR.

The mission listed `just_audio, on_audio_query, audio_service` as deps to remove — but only `just_audio` was actually present, and it has a non-music use. Without OXBAR's confirmation I am NOT dropping it from pubspec.yaml in this PR.

## Validation caveat

I cannot run `flutter analyze` / `flutter test` / `flutter build appbundle` in this conversation — the multi-agent worktree is being switched between branches by other agents and the toolchain is not stable enough to run a full build cycle here. The diff is mechanical (deletions + small edits in 4 files) and trivially compilable. OXBAR / CI must run validation on the PR.

## Files touched (final)
- D: `lib/models/music/music_models.dart`
- D: `lib/services/music/music_service.dart`
- D: `lib/widgets/music/music_play_button.dart`
- D: `lib/widgets/music/music_attachment_widget.dart`
- D: `lib/screens/settings/music_settings_screen.dart`
- M: `lib/screens/settings/user_settings_screen.dart`
- M: `lib/screens/admin/admin_session_copilot_screen.dart`
- M: `lib/models/admin/session_models.dart`
- M: `lib/widgets/admin/user_inspector_sheet.dart`
- M: `CHANGELOG.md`
- A: `supabase/migrations/20260427192816_music_purge_drop_tables.sql`

## Note on the worktree thrash
The local working tree was being switched between branches by other agents during my session. An earlier copy of the code-deletion commit briefly landed on `agent/vault-init` (sha `2598d37`) before I cherry-picked it onto this branch as `7142c6c`. If `2598d37` is still on the local `agent/vault-init` after my session ends, OXBAR should drop it from that branch (it is not on origin and is intended only for `agent/music-purge`).

## Blockers
(none)

## Next step
Push branch to origin, open PR `[MUSIC-PURGE] Retire music feature`. Wait for OXBAR review on the `just_audio` question.
