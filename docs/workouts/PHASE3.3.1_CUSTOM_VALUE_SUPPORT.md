# PHASE 3.3.1: Custom Value Support for enum.values Selectors - Complete

**Date:** 2025-01-20  
**Status:** ✅ Implementation Complete  
**Phase:** 3.3.1 of 5 (UI Only, Minimal)

---

## SUMMARY

Added custom value support to CardioType and TrainingMethod selectors, allowing users to enter unlimited custom values beyond enum options.

---

## CHANGES MADE

### 1. CardioEditorDialog (`lib/widgets/workout/cardio_editor_dialog.dart`)

**Added:**
- `_customCardioType` state variable to store custom string value
- `_showCustomCardioTypeDialog()` method to allow user to enter custom value
- Updated `_buildCardioTypeSection()` to:
  - Show all known enum values (excluding `unknown`)
  - Show custom value chip if `_customCardioType` exists (e.g., "Custom: myo_cardio")
  - Show "Custom..." chip to add new custom value
- Updated `initState()` to parse existing custom values from `settings['cardio_type']`
- Updated `_save()` to store custom string in `settings['cardio_type']`

**Import Added:**
- `import '../../models/workout/enhanced_exercise.dart';` (to use CardioType enum with `unknown` support)

**Removed:**
- Duplicate `CardioType` enum definition at end of file (now uses enum from enhanced_exercise.dart)
- `_parseCardioType()` method (replaced with `CardioType.fromString()`)

### 2. AdvancedExerciseEditorDialog (`lib/widgets/workout/advanced_exercise_editor_dialog.dart`)

**Added:**
- `_customTrainingMethod` state variable to store custom string value
- `_showCustomTrainingMethodDialog()` method to allow user to enter custom value
- Updated `_buildMethodsTab()` TrainingMethod selector to:
  - Show all known enum values (excluding `unknown`)
  - Show custom value chip if `_customTrainingMethod` exists (e.g., "Custom: myo_reps")
  - Show "Custom..." chip to add new custom value

**Note:** TrainingMethod is not currently saved in the `Exercise` model, so custom values are UI-only. To persist them, add `trainingMethod` field to Exercise model or use EnhancedExercise model.

---

## HOW CUSTOM VALUES ARE STORED

### CardioType:
- **Storage:** Saved as raw string in `CardioSession.settings['cardio_type']`
- **Example:** `{'cardio_type': 'myo_cardio', ...}`
- **Round-trip:** ✅ Custom values are preserved when loading/saving

### TrainingMethod:
- **Storage:** Currently UI-only (stored in `_customTrainingMethod` state variable)
- **Note:** Exercise model doesn't have `trainingMethod` field, so custom values are not persisted
- **Future:** To persist, add `trainingMethod` field to Exercise model or migrate to EnhancedExercise

---

## HOW UNKNOWN EXISTING VALUES ARE DISPLAYED

### CardioType:
1. On load, `initState()` reads `settings['cardio_type']` from existing CardioSession
2. Uses `CardioType.fromString()` to parse the value
3. If enum is `unknown`, stores the raw string in `_customCardioType`
4. Selector shows "Custom: <raw_value>" chip, which is selected
5. User can tap the custom chip to edit the value

### TrainingMethod:
- Currently no persistence, so unknown values only appear if manually entered in the current session
- When custom value is set, selector shows "Custom: <value>" chip

---

## USER FLOW

### Adding Custom Value:
1. User taps "Custom..." chip in selector
2. Dialog opens with TextField
3. User enters custom value (e.g., "myo_cardio")
4. Value is validated (non-empty, trimmed, lowercased)
5. Custom value is stored and displayed as "Custom: myo_cardio" chip
6. Custom value is saved when dialog is saved

### Editing Custom Value:
1. User taps existing "Custom: <value>" chip
2. Dialog opens pre-filled with current custom value
3. User edits and saves
4. Updated value is displayed

### Selecting Known Enum Value:
1. User taps any known enum chip (e.g., "HIIT")
2. Custom value is cleared
3. Known enum value is selected

---

## FILES MODIFIED

1. **`lib/widgets/workout/cardio_editor_dialog.dart`**
   - Added custom value support for CardioType selector
   - Added custom dialog for entering custom values
   - Updated save/load logic to preserve custom strings

2. **`lib/widgets/workout/advanced_exercise_editor_dialog.dart`**
   - Added custom value support for TrainingMethod selector
   - Added custom dialog for entering custom values
   - Note: Values are UI-only (not persisted in Exercise model)

---

## BACKWARD COMPATIBILITY

### ✅ Guaranteed:
- Existing enum values still work exactly as before
- Existing CardioSession records with known enum values continue to work
- No breaking changes to public API
- Custom values are optional - users can still use enum values

### ✅ New Capability:
- Users can now enter unlimited custom values
- Custom values are preserved when saving/loading
- Unknown values from database are displayed and editable

---

## NOTES

- Custom values are normalized to lowercase for consistency
- Custom values are trimmed (whitespace removed)
- Validation ensures non-empty values
- CardioType custom values are persisted in CardioSession.settings
- TrainingMethod custom values are currently UI-only (Exercise model doesn't store trainingMethod)

---

**END OF PHASE 3.3.1 DOCUMENTATION**
