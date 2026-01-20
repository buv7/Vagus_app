# PHASE 3.3: Remaining Hard-Coded Limits Audit

**Date:** 2025-01-20  
**Status:** Audit Complete

---

## TASK 1: REMAINING HARD-CODED LIMITS

| File | Component | What is Hard-Coded | Replacement Plan | Priority |
|------|-----------|-------------------|------------------|----------|
| `lib/widgets/workout/cardio_editor_dialog.dart` | CardioType selector (line 371) | `CardioType.values.map()` | Use DB-driven strings via service (if available) or safe defaults | 🟡 MEDIUM |
| `lib/widgets/workout/advanced_exercise_editor_dialog.dart` | TrainingMethod selector (line 391) | `TrainingMethod.values.map()` | Use DB-driven strings via service (if available) or safe defaults | 🟡 MEDIUM |
| `lib/widgets/workout/session_mode_selector.dart` | TransformationMode selector (line 34) | `TransformationMode.values.map()` | Not workout metadata - skip | ⚪ LOW |
| `lib/widgets/workout/set_type_sheet.dart` | SetType selector (line 175) | `SetType.values.map()` | Not workout metadata - skip | ⚪ LOW |

### Difficulty Selectors
**Result:** No explicit difficulty selectors found in workout UI components.
- `advanced_exercise_editor_dialog.dart` does NOT have a difficulty selector
- Difficulty is handled at model level (DifficultyLevel enum with raw preservation already implemented)

### Goal Selectors  
**Result:** No workout plan goal selector found in Flutter UI yet.
- `revolutionary_plan_builder_screen.dart` does NOT have a goal selector
- Goal field exists in DB but UI for selecting it is not implemented yet

---

## RECOMMENDATIONS

### Priority 1: CardioType Selector
- **File:** `lib/widgets/workout/cardio_editor_dialog.dart`
- **Change:** Replace `CardioType.values.map()` with DB-driven strings
- **Challenge:** CardioType enum doesn't map directly to a database table
- **Solution:** Keep enum for type safety but load available types from DB if a cardio_types table exists, otherwise use enum values as fallback

### Priority 2: TrainingMethod Selector  
- **File:** `lib/widgets/workout/advanced_exercise_editor_dialog.dart`
- **Change:** Replace `TrainingMethod.values.map()` with DB-driven strings
- **Challenge:** TrainingMethod enum doesn't map directly to a database table
- **Solution:** Keep enum for type safety but could load from exercise_groups.type or use enum values as fallback

### Priority 3: Difficulty (N/A)
- No difficulty selector UI found - difficulty is handled at model level with raw preservation already implemented

### Priority 4: Goal (N/A)
- No goal selector UI found - goal selection UI doesn't exist yet in Flutter codebase

---

## IMPLEMENTATION PLAN

Since there are no difficulty/goal selectors found, and the enum.values usages are for enums that don't have direct DB tables, we'll:

1. **Patch CardioType selector** - Make it use string-based selection with enum fallback
2. **Patch TrainingMethod selector** - Make it use string-based selection with enum fallback  
3. **Note:** Difficulty and Goal selectors don't exist yet, so nothing to patch

---

**END OF AUDIT**
