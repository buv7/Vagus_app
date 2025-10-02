# Archived Files - VAGUS App

This directory contains unused, disconnected, or legacy files from the VAGUS Flutter application. **Nothing is deleted** - all files are preserved here for future reference or potential restoration.

## Archive Date
Files archived on: 2025-10-02

## Why Files Are Archived

The VAGUS app has undergone multiple development iterations, resulting in:
- Legacy shim files that redirect to newer implementations
- Test/debug files not connected to production
- Stubbed services for disabled features (OneSignal)
- Fully functional but disconnected features
- Documentation for disabled/removed features

Rather than deleting these files and losing git history, they're preserved here.

---

## Archive Categories

### 1. `/archived/shims/` - Legacy Compatibility Exports
Shim files that were created as temporary exports. The actual implementations now exist elsewhere.

#### Files Archived:
- **attach_file_to_note.dart** (originally: `lib/components/notes/attach_file_to_note.dart`)
  - **Why Archived**: Legacy shim file
  - **Real Implementation**: File attachment functionality is now in `lib/screens/notes/note_editor_screen.dart`
  - **Lines of Code**: ~50
  - **Last Known Usage**: None - was only a re-export

- **voice_recorder.dart** (originally: `lib/components/notes/voice_recorder.dart`)
  - **Why Archived**: Legacy shim file
  - **Real Implementation**: Voice recording functionality is in `lib/screens/notes/note_editor_screen.dart`
  - **Lines of Code**: ~100
  - **Last Known Usage**: None - was only a re-export

---

### 2. `/archived/tests/` - Test and Debug Files
Test files, test helpers, and debug widgets not connected to production.

#### Files Archived:
- **notification_test.dart** (originally: `lib/services/notifications/notification_test.dart`)
  - **Why Archived**: Debug/test file, not part of production code
  - **Purpose**: Manual testing of notification functionality
  - **Lines of Code**: ~150
  - **Last Known Usage**: Development testing only

- **notification_test_helper.dart** (originally: `lib/services/notifications/notification_test_helper.dart`)
  - **Why Archived**: Helper for notification_test.dart
  - **Purpose**: Provides test utilities for notification testing
  - **Lines of Code**: ~80
  - **Last Known Usage**: Used by notification_test.dart only

- **ai_usage_test_widget.dart** (originally: `lib/widgets/ai/ai_usage_test_widget.dart`)
  - **Why Archived**: Test widget for AI usage tracking
  - **Purpose**: Debug interface for testing AI usage metrics
  - **Lines of Code**: ~200
  - **Last Known Usage**: Never imported in main app

- **widget_test.dart** (originally: `test/widget_test.dart`)
  - **Why Archived**: Unused Flutter default test file
  - **Purpose**: Default Flutter test template
  - **Lines of Code**: ~30
  - **Last Known Usage**: Never executed

---

### 3. `/archived/stubs/` - Stubbed Services
Service implementations for disabled features.

#### Files Archived:
- **onesignal_service.dart** (originally: `lib/services/notifications/onesignal_service.dart`)
  - **Why Archived**: OneSignal push notifications completely disabled in VAGUS app
  - **Status**: Fully stubbed - all methods return empty/null
  - **Lines of Code**: ~250
  - **Real Implementation**: None - feature disabled
  - **Note**: `notification_helper.dart` is still active and used for local notifications
  - **Related Docs**: See `/archived/documentation/ONESIGNAL_FIXES_SUMMARY.md`

---

### 4. `/archived/disconnected/` - Disconnected Features
Fully functional features that are not connected to the UI or navigation flow.

#### Files Archived:
- **notification_badge.dart** (originally: `lib/widgets/notifications/notification_badge.dart`)
  - **Why Archived**: Zero usage - never imported anywhere
  - **Status**: Fully functional widget
  - **Lines of Code**: 217
  - **Purpose**: Displays notification count badge
  - **Restoration Notes**: To restore, import in desired screen and add to widget tree

- **note_version_viewer.dart** (originally: `lib/screens/notes/note_version_viewer.dart`)
  - **Why Archived**: Built but no navigation routes to this screen
  - **Status**: Fully functional screen
  - **Lines of Code**: ~400
  - **Purpose**: View note version history
  - **Planned**: Will reconnect in Phase 2 of note system refactor
  - **Restoration Notes**: Add route in `lib/routes/app_routes.dart` and navigation call

- **AccountSwitchScreen.dart** (Status: File not found during archival)
  - **Why Listed**: Mentioned in requirements but file doesn't exist
  - **Status**: Possibly already deleted or renamed
  - **Action**: No action taken - file not found

---

### 5. `/archived/documentation/` - Documentation for Disabled Features
Documentation and summaries for features that have been disabled or removed.

#### Files Archived:
- **ONESIGNAL_FIXES_SUMMARY.md** (originally: `ONESIGNAL_FIXES_SUMMARY.md` in root)
  - **Why Archived**: Documents OneSignal integration that was later disabled
  - **Purpose**: Historical record of OneSignal implementation attempt
  - **Related Code**: See `/archived/stubs/onesignal_service.dart`
  - **Status**: Reference only - OneSignal not used in VAGUS

- **onesignal_setup.md** (Status: File not found during archival)
  - **Why Listed**: Mentioned in requirements but file doesn't exist
  - **Status**: Possibly never created or already deleted
  - **Action**: No action taken - file not found

---

## How to Restore Archived Files

If you need to restore any archived file:

### Option 1: Git History (Recommended)
```bash
# View history of an archived file
git log --follow archived/shims/attach_file_to_note.dart

# Restore to original location
git mv archived/shims/attach_file_to_note.dart lib/components/notes/attach_file_to_note.dart
```

### Option 2: Copy and Modify
```bash
# Copy file back to desired location
cp archived/disconnected/note_version_viewer.dart lib/screens/notes/note_version_viewer.dart

# Update imports as needed
# Add to navigation routes if it's a screen
```

### Option 3: Reference Only
Some archived files (especially shims) should NOT be restored. Use them as reference only.

---

## Import Errors and Fixes

### Known Import Issues After Archival:

**No active imports detected** - All archived files were either:
- Never imported (disconnected features)
- Only imported by other archived files (test helpers)
- Stubbed services with no real usage

### Verification Commands:
```bash
# Check for broken imports
flutter analyze

# Rebuild dependencies
flutter pub get

# Run app to verify
flutter run
```

---

## Statistics

### Total Files Archived: 9
- Shims: 2 files (~150 LOC)
- Tests: 4 files (~460 LOC)
- Stubs: 1 file (~250 LOC)
- Disconnected: 2 files (~617 LOC)
- Documentation: 1 file

### Total Lines Preserved: ~1,477 lines of code

---

## Related Documentation

- Main codebase: `/lib/`
- Active services: `/lib/services/`
- Active screens: `/lib/screens/`
- Edge functions: `/supabase/functions/` (NOT archived - still in use)
- Database migrations: `/supabase/migrations/` (NOT archived - still in use)

---

## Notes

- **DO NOT** delete archived files without team discussion
- All files retain full git history via `git mv`
- Some files (like note_version_viewer.dart) are planned for Phase 2 reconnection
- Shim files should generally NOT be restored - use real implementations instead
- Test files can be restored if needed for debugging

---

## Archive Manifest

Last updated: 2025-10-02
Git commit: (To be added after commit)

For questions about archived files, review git history:
```bash
git log --follow archived/{category}/{filename}
```
