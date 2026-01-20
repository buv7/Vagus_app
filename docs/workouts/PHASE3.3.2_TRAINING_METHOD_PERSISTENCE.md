# PHASE 3.3.2: Persist TrainingMethod Safely - Complete

**Date:** 2025-12-21  
**Status:** ✅ Implementation Complete  
**Phase:** 3.3.2 of 5 (DB + Dart Minimal)

---

## SUMMARY

Added persistence for TrainingMethod to the Exercise model, allowing unlimited custom training method values to be stored in the database and round-tripped correctly.

---

## CHANGES MADE

### 1. Database Migration (`supabase/migrations/20251221021143_add_training_method_to_exercises.sql`)

**Added:**
- `training_method TEXT` column to `public.exercises` table
- No CHECK constraint (unlimited strings allowed)
- Idempotent migration (safe to run multiple times)
- Column is nullable (backward compatible - existing exercises have NULL)

### 2. Exercise Model (`lib/models/workout/exercise.dart`)

**Added:**
- `trainingMethod` field (nullable `TrainingMethod?`)
- `_trainingMethodRaw` private field to store raw string when enum is unknown
- Updated constructor to accept `trainingMethod` and `trainingMethodRaw` parameters
- Updated `fromMap()` factory to:
  - Parse `training_method` from database
  - Use `TrainingMethod.fromString()` to map known values
  - Store raw string in `_trainingMethodRaw` if enum is `unknown`
- Updated `toMap()` method to:
  - Write `training_method` only if `trainingMethod` is set
  - Prioritize `_trainingMethodRaw` if present (preserves custom values)
  - Fall back to `trainingMethod.value` if no raw string
- Updated `copyWith()` method to preserve `trainingMethod` and `trainingMethodRaw`
- Added `trainingMethodRawForDisplay` getter to expose raw string for UI display

**Import Added:**
- `import 'enhanced_exercise.dart' show TrainingMethod;` (to use TrainingMethod enum)

### 3. AdvancedExerciseEditorDialog (`lib/widgets/workout/advanced_exercise_editor_dialog.dart`)

**Updated:**
- `initState()` to load existing `trainingMethod` from Exercise:
  - If `trainingMethod` is `TrainingMethod.unknown`, extract raw string via `trainingMethodRawForDisplay` getter
  - Set `_customTrainingMethod` if value is custom
  - Set `_trainingMethod` enum appropriately
- `_save()` method to:
  - Save `trainingMethod` enum if custom value is null
  - Save `trainingMethodRaw` (custom string) if `_customTrainingMethod` is set
  - Pass both to Exercise constructor

---

## HOW TRAINING METHOD IS STORED

### Database:
- **Column:** `exercises.training_method` (TEXT, nullable)
- **Format:** Raw string (e.g., "straightSets", "myo_reps", "blood_flow_restriction")
- **Null handling:** NULL is allowed (existing exercises have NULL)

### Dart Model:
- **Field:** `trainingMethod` (nullable `TrainingMethod?`)
- **Raw preservation:** `_trainingMethodRaw` (private String?)
- **Logic:**
  - If DB value matches known enum → `trainingMethod` = enum, `_trainingMethodRaw` = null
  - If DB value is unknown → `trainingMethod` = `TrainingMethod.unknown`, `_trainingMethodRaw` = raw string
  - If DB value is NULL → `trainingMethod` = null, `_trainingMethodRaw` = null

### Round-Trip Behavior:
1. **Known enum value:** "straightSets" → `TrainingMethod.straightSets` → saves as "straightSets" ✅
2. **Unknown value:** "myo_reps" → `TrainingMethod.unknown` + `_trainingMethodRaw = "myo_reps"` → saves as "myo_reps" ✅
3. **NULL value:** NULL → `trainingMethod = null` → saves as NULL (omitted from toMap) ✅

---

## BACKWARD COMPATIBILITY

### ✅ Guaranteed:
- **Existing exercises:** All existing Exercise records have `training_method = NULL`
- **Model behavior:** NULL training_method maps to `trainingMethod = null` (no crash)
- **Save behavior:** NULL trainingMethod is omitted from `toMap()` (doesn't write NULL)
- **API stability:** No breaking changes to Exercise constructor or public methods
- **UI behavior:** Existing UI continues to work (trainingMethod is optional)

### ✅ New Capability:
- Users can now save custom training methods from AdvancedExerciseEditorDialog
- Custom values are preserved when saving/loading
- Unknown values from database are displayed correctly in UI

---

## TESTING VERIFICATION

### Old Exercises (NULL training_method):
1. Load exercise with NULL training_method → `trainingMethod = null` ✅
2. Save exercise with NULL trainingMethod → `toMap()` omits field ✅
3. No errors or crashes ✅

### New Exercises (Known enum):
1. Select "Straight Sets" in UI → `trainingMethod = TrainingMethod.straightSets` ✅
2. Save → `toMap()` writes "straightSets" ✅
3. Load → Parses back to `TrainingMethod.straightSets` ✅

### Custom Values:
1. Enter custom value "myo_reps" in UI → `_customTrainingMethod = "myo_reps"` ✅
2. Save → `toMap()` writes "myo_reps" (via `trainingMethodRaw`) ✅
3. Load → Parses to `TrainingMethod.unknown` + `_trainingMethodRaw = "myo_reps"` ✅
4. UI displays "Custom: myo_reps" chip ✅

---

## FILES MODIFIED

1. **`supabase/migrations/20251221021143_add_training_method_to_exercises.sql`**
   - New migration to add `training_method` column

2. **`lib/models/workout/exercise.dart`**
   - Added trainingMethod field with raw preservation
   - Updated constructor, fromMap, toMap, copyWith
   - Added getter for raw value display

3. **`lib/widgets/workout/advanced_exercise_editor_dialog.dart`**
   - Updated save/load logic to persist trainingMethod

---

## NOTES

- TrainingMethod enum is imported from `enhanced_exercise.dart` (shared enum)
- Raw preservation pattern matches `groupType` implementation (consistent approach)
- Migration is idempotent (safe to run multiple times)
- No CHECK constraints added (unlimited values allowed)
- Column is nullable (backward compatible with existing data)

---

**END OF PHASE 3.3.2 DOCUMENTATION**
