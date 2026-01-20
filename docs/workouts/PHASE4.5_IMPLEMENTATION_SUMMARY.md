# Phase 4.5: Intensifier Rules Preview - Implementation Summary

**Date**: 2025-01-22  
**Status**: ✅ Complete (Preview Mode Only)

---

## Overview

Implemented Phase 4.5 preview mode for intensifier rules. When an intensifier is selected from the knowledge base, the editor now:
1. Loads full intensifier details (including `intensity_rules` JSONB)
2. Displays a preview card in the Methods tab
3. Stores rules in `Exercise.notes` JSON (non-breaking)

**No behavior changes**: Rules are previewed and stored, but NOT automatically applied to sets.

---

## Files Modified

### 1. `lib/widgets/workout/advanced_exercise_editor_dialog.dart`

**Changes**:
- Added state variables:
  - `Map<String, dynamic>? _selectedIntensifierDetails`
  - `bool _loadingIntensifierDetails = false`
- Added methods:
  - `_loadIntensifierDetails()` - Loads intensifier by ID
  - `_loadIntensifierDetailsByName()` - Fallback: loads by name (best effort)
  - `_buildIntensifierRulesPreview()` - Renders preview card
  - `_buildIntensityRulesView()` - Pretty renders rules JSON
  - `_getFatigueColor()` - Helper for fatigue cost colors
- Updated `_buildNotesString()`:
  - Adds `intensifier_rules` (from `intensity_rules` JSONB)
  - Adds `intensifier_apply_scope` (default: `'last_set'`)
  - Preserves all existing keys
- Updated `_parseNotesForKnowledge()`:
  - Loads intensifier details if `intensifier_rules` exists in notes
- Updated intensifier selection handlers:
  - Loads details when intensifier is selected (from picker or recommended)
  - Clears details when intensifier is cleared
- Added preview card in Methods tab:
  - Shows name + fatigue cost chip
  - Shows "best_for" chips (if available)
  - Pretty renders `intensity_rules` JSON (grouped by top-level key)

### 2. `lib/services/workout/workout_knowledge_service.dart`

**No changes required** - Existing `getIntensifier(String id)` method already returns all fields including `intensity_rules`.

---

## Notes JSON Structure

### Before Phase 4.5:
```json
{
  "knowledge_exercise_id": "...",
  "knowledge_short_desc": "...",
  "intensifier": "Rest-Pause",
  "intensifier_id": "...",
  "user_notes": "..."
}
```

### After Phase 4.5 (when intensifier selected):
```json
{
  "knowledge_exercise_id": "...",
  "knowledge_short_desc": "...",
  "intensifier": "Rest-Pause",
  "intensifier_id": "...",
  "user_notes": "...",
  "intensifier_rules": {
    "rest_pause": {
      "rest_seconds": 15,
      "mini_sets": 3,
      "target_rir": 0,
      "reps_per_mini_set": 2
    }
  },
  "intensifier_apply_scope": "last_set"
}
```

**Key Preservation**: All existing keys are preserved. If notes is plain text, it's converted to `user_notes` and preserved.

---

## Preview Card Location

**Tab**: Methods (3rd tab in `AdvancedExerciseEditorDialog`)  
**Position**: After "Intensifier Picker" section, before the info banner

**Preview Card Shows**:
1. **Header**: Intensifier name + fatigue cost chip (high/medium/low)
2. **Best For**: Chips showing use cases (if `best_for` field exists)
3. **Rules Section**: Pretty-rendered `intensity_rules` JSON:
   - Grouped by top-level key (e.g., `rest_pause`, `drop_set`, `tempo`)
   - Each key shows formatted name (e.g., "Rest Pause")
   - Nested key-value pairs displayed in readable format

**Example Preview**:
```
┌─────────────────────────────────────┐
│ ⚡ Intensifier Rules: Rest-Pause [HIGH] │
│ Best for: Strength, Hypertrophy    │
│                                     │
│ Rules:                              │
│ ┌─────────────────────────────────┐ │
│ │ Rest Pause                      │ │
│ │ Rest Seconds    15              │ │
│ │ Mini Sets       3               │ │
│ │ Target Rir      0               │ │
│ │ Reps Per Mini Set 2             │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## Data Flow

1. **User selects intensifier** (from Recommended or Search modal)
   - `_selectedIntensifier` and `_selectedIntensifierId` are set
   - `_loadIntensifierDetails()` is called

2. **Load intensifier details**:
   - Calls `WorkoutKnowledgeService.instance.getIntensifier(id)`
   - Fetches: `id`, `name`, `fatigue_cost`, `best_for`, `intensity_rules`
   - Stores in `_selectedIntensifierDetails`

3. **Display preview**:
   - `_buildIntensifierRulesPreview()` renders card
   - Shows loading spinner while fetching
   - Shows "No rules available" if rules missing

4. **Save exercise**:
   - `_buildNotesString()` includes:
     - All existing keys (preserved)
     - `intensifier_rules` (from `intensity_rules` JSONB)
     - `intensifier_apply_scope` (default: `'last_set'`)

5. **Load existing exercise**:
   - `_parseNotesForKnowledge()` parses notes JSON
   - If `intensifier_rules` exists and `intensifier_id` present:
     - Calls `_loadIntensifierDetails()` to show preview

---

## Backward Compatibility

✅ **Fully backward compatible**:
- Existing exercises with plain text notes: Converted to JSON with `user_notes` key
- Existing exercises with JSON notes: All keys preserved, new keys added
- Exercises without intensifiers: No changes to notes structure
- No database migrations required
- No breaking changes to Exercise model

---

## Limitations (By Design)

1. **Preview Only**: Rules are displayed but NOT automatically applied to sets
2. **No UI Fields**: No editable fields for rule configuration (Phase 4.6)
3. **No Auto-Apply**: "Apply to last set" / "Apply to all sets" not implemented (Phase 4.6)
4. **Name Fallback**: If `intensifier_id` is missing, attempts name-based lookup (best effort, may fail)

---

## Testing Checklist

- [x] Select intensifier from Recommended list → Preview appears
- [x] Select intensifier from Search modal → Preview appears
- [x] Clear intensifier → Preview disappears
- [x] Save exercise → Notes JSON includes `intensifier_rules` and `intensifier_apply_scope`
- [x] Load existing exercise with intensifier → Preview appears
- [x] Load exercise with plain text notes → Converted to JSON, preserved as `user_notes`
- [x] Load exercise with existing JSON notes → All keys preserved, new keys added
- [x] Intensifier without rules → Shows "No rules available"
- [x] Intensifier with complex rules → Pretty renders nested structure

---

## Next Steps (Phase 4.6)

1. Add UI fields for rule configuration (rest-pause config, cluster config, etc.)
2. Implement "Apply to last set" / "Apply to all sets" logic
3. Auto-populate set-level fields based on rules
4. Consider database migration for `intensifier_rules` JSONB column (optional)

---

**End of Implementation Summary**
