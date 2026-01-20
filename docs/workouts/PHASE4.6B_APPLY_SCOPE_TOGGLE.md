# Phase 4.6B: Intensifier Apply Scope Toggle

**Date**: 2025-01-22  
**Status**: ✅ Complete

---

## Overview

Added UI control in `AdvancedExerciseEditorDialog` (Methods tab) to toggle intensifier apply scope. Users can now choose where intensifier rules are applied during workout execution:
- **Off**: Do not auto-apply rules
- **Last Set** (default): Apply rules to last set only
- **All Sets**: Apply rules to all sets (future-ready)

---

## Implementation

### Files Modified
- `lib/widgets/workout/advanced_exercise_editor_dialog.dart`

### Changes
1. **State Variable**: `String _intensifierApplyScope = 'last_set'`
2. **Load from Notes**: Parses `intensifier_apply_scope` from `Exercise.notes` JSON
3. **UI Control**: SegmentedButton in Methods tab (shown when intensifier selected or rules exist)
4. **Save to Notes**: Stores apply scope in `notes['intensifier_apply_scope']`
5. **Clear Behavior**: When intensifier is cleared, also clears rules and apply scope

---

## Notes JSON Key

**Key**: `intensifier_apply_scope`  
**Type**: String  
**Values**: `"off"` | `"last_set"` | `"all_sets"`  
**Default**: `"last_set"` (if missing or invalid)

### Example Notes JSON:
```json
{
  "knowledge_exercise_id": "...",
  "knowledge_short_desc": "...",
  "intensifier": "Rest-Pause",
  "intensifier_id": "...",
  "user_notes": "...",
  "intensifier_rules": {
    "rest_pause": { ... }
  },
  "intensifier_apply_scope": "last_set"
}
```

---

## Default Behavior

- **Missing Key**: Defaults to `"last_set"` (backward compatible)
- **Invalid Value**: Defaults to `"last_set"` (safe fallback)
- **Plain Text Notes**: Defaults to `"last_set"` (when converting to JSON)

---

## Clear Behavior

When user clears the intensifier (removes selection):
- ✅ `intensifier` key removed from notes JSON
- ✅ `intensifier_id` key removed from notes JSON
- ✅ `intensifier_rules` key removed from notes JSON
- ✅ `intensifier_apply_scope` key removed from notes JSON
- ✅ `_intensifierApplyScope` state reset to `'last_set'`
- ✅ All other keys preserved (knowledge_exercise_id, user_notes, etc.)

**Rationale**: Prevents stale automation when intensifier is removed. User must re-select intensifier to re-enable auto-config.

---

## UI Location

**Tab**: Methods (3rd tab)  
**Position**: After "Intensifier Rules Preview" card, before info banner

**Control**: SegmentedButton with 3 options:
- **Off**: Do not auto-apply rules
- **Last Set**: Apply rules to last set only (default)
- **All Sets**: Apply rules to all sets

**Helper Text**: "Controls where intensifier rules apply during workout logging."

**Visibility**: Only shown when:
- `_selectedIntensifier != null` OR
- `_selectedIntensifierDetails != null` (rules exist even if intensifier name missing)

---

## Backward Compatibility

✅ **Fully backward compatible**:
- Exercises without `intensifier_apply_scope`: Defaults to `"last_set"` (Phase 4.6A behavior)
- Exercises with plain text notes: Converted to JSON, apply scope defaults to `"last_set"`
- Existing workout sessions: Unaffected
- No database migrations required
- No breaking changes

---

## Integration with Phase 4.6A

Phase 4.6A (workout execution) reads `intensifier_apply_scope`:
- `"last_set"`: Auto-configures last set only ✅ (implemented)
- `"all_sets"`: Auto-configures all sets ⏭️ (future)
- `"off"`: No auto-configuration ✅ (implemented)

---

## Testing Checklist

- [x] Load exercise with `intensifier_apply_scope = "last_set"` → Control shows "Last Set"
- [x] Load exercise with `intensifier_apply_scope = "all_sets"` → Control shows "All Sets"
- [x] Load exercise with `intensifier_apply_scope = "off"` → Control shows "Off"
- [x] Load exercise without apply scope → Control shows "Last Set" (default)
- [x] Change scope to "Off" → Saved as `"off"` in notes JSON
- [x] Change scope to "All Sets" → Saved as `"all_sets"` in notes JSON
- [x] Clear intensifier → Apply scope removed from notes JSON
- [x] Control hidden when no intensifier selected and no rules exist
- [x] Control visible when intensifier selected
- [x] Control visible when rules exist (even if intensifier name missing)
- [x] All existing notes JSON keys preserved

---

**End of Implementation Summary**
