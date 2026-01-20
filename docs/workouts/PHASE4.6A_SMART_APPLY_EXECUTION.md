# Phase 4.6A: Smart Apply Intensifier Rules During Workout Execution

**Date**: 2025-01-22  
**Status**: ✅ Complete (All Scopes Supported)

---

## Overview

Implemented smart auto-configuration of intensifier rules during workout execution. When an exercise has `intensifier_rules` stored in `Exercise.notes` JSON, the app automatically configures sets with the appropriate set type and parameters based on `intensifier_apply_scope`.

**Supported Scopes**:
- `"off"`: No auto-configuration (informational only)
- `"last_set"`: Apply rules to last set only ✅
- `"all_sets"`: Apply rules to all sets ✅

---

## Files Modified

### 1. `lib/widgets/workout/exercise_detail_sheet.dart`

**Changes**:
- Added state variables:
  - `LocalSetLog? _autoConfigExtras` - Auto-configured extras
  - `String? _autoConfigIntensifierName` - Name for UI hint
  - `String? _intensifierApplyScope` - Apply scope ('off' | 'last_set' | 'all_sets')
  - `Map<String, dynamic>? _intensifierRules` - Raw rules for per-set application
- Added methods:
  - `_parseIntensifierRules()` - Parses `intensifier_rules` and `intensifier_apply_scope` from `Exercise.notes` JSON
  - `_generateAutoConfigExtras()` - Generates `LocalSetLog` from rules
  - `_getAutoConfigForSet(int setIndex, int totalSets)` - Returns auto-config for specific set based on scope
- Updated set rendering:
  - Calls `_getAutoConfigForSet()` for each set to determine if auto-config applies
  - Passes `autoConfigExtras` to `SetRowControls` when applicable
  - Displays UI hint chip: "⚡ Intensifier applied: [Name]" (shown on affected sets)

### 2. `lib/widgets/workout/set_row_controls.dart`

**Changes**:
- Added parameter:
  - `LocalSetLog? initialExtras` - Auto-configured extras (optional)
- Updated `initState()`:
  - Initializes `_setExtras` from `initialExtras` if provided (non-destructive)
- Updated `_openSetTypeSheet()`:
  - Uses `_setExtras ?? widget.initialExtras` to pre-populate set type sheet

---

## Supported Rules → Field Mapping

| Intensifier Rule | Rule Key(s) | Mapped To | Notes |
|-----------------|-------------|-----------|-------|
| **Rest-Pause** | `rest_pause` | `SetType.restPause`<br>`rpRestSec`<br>`rpBursts` | `rest_seconds` → `rpRestSec`<br>`mini_sets` + `reps_per_mini_set` → `rpBursts` (estimated pattern) |
| **Cluster Sets** | `cluster_set`, `cluster` | `SetType.cluster`<br>`clusterRestSec`<br>`clusterSize`<br>`clusterTotalReps` | `rest_between_clusters` / `rest_seconds` → `clusterRestSec`<br>`reps_per_cluster` → `clusterSize`<br>`clusters` × `reps_per_cluster` → `clusterTotalReps` |
| **Drop Sets** | `drop_set`, `drop` | `SetType.drop`<br>`dropPercents` | `drops` → number of drops<br>`weight_reduction_percent` / `reduction_percent` → `dropPercents` list |
| **Myo-Reps** | `myo_reps`, `myo-reps` | `SetType.restPause`<br>`rpRestSec`<br>`rpBursts` | Uses rest-pause flow with shorter rest<br>`activation_reps` + `mini_set_reps` → `rpBursts`<br>`rest_seconds` → `rpRestSec` |
| **Tempo** | (ignored) | Already handled by `Exercise.tempo` field | Not auto-filled from rules |
| **Target RIR** | (ignored) | Already handled by `Exercise.rir` field | Not auto-filled from rules |

---

## Rule Parsing Logic

### JSON Structure Expected:
```json
{
  "intensifier_rules": {
    "rest_pause": {
      "rest_seconds": 15,
      "mini_sets": 3,
      "reps_per_mini_set": 2
    }
  },
  "intensifier_apply_scope": "last_set",
  "intensifier": "Rest-Pause"
}
```

### Parsing Flow:
1. **Parse Notes**: Attempts to parse `Exercise.notes` as JSON
2. **Check Apply Scope**: 
   - `"off"` → No auto-configuration
   - `"last_set"` → Apply to last set only
   - `"all_sets"` → Apply to all sets
   - Missing/invalid → Defaults to `"last_set"` (backward compatible)
3. **Generate Extras**: Creates `LocalSetLog` with appropriate `SetType` and parameters
4. **Per-Set Application**: `_getAutoConfigForSet()` determines if auto-config applies to specific set
5. **Safe Fallbacks**: Uses default values if rule fields are missing:
   - Rest-Pause: `rest_seconds = 20`, `mini_sets = 3`, `reps_per_mini_set = 2`
   - Cluster: `rest_seconds = 15`, `reps_per_cluster = 3`, `clusters = 4`
   - Drop: `drops = 1`, `reduction_percent = 25.0`
   - Myo-Reps: `rest_seconds = 7`, `activation_reps = 20`, `mini_set_reps = 4`, `target_mini_sets = 4`

---

## Safety Behavior

### Non-Destructive:
- ✅ **Never overwrites user-set values**: If user manually selects a set type, auto-config is ignored
- ✅ **Only applies to last set**: Other sets are unaffected
- ✅ **Safe parsing**: If notes is plain text or invalid JSON, auto-config is skipped (no crash)
- ✅ **Missing fields**: Uses safe defaults if rule fields are missing

### Error Handling:
- Invalid JSON → Auto-config skipped (silent)
- Missing `intensifier_rules` → Auto-config skipped
- Missing `intensifier_apply_scope` → Defaults to `'last_set'`
- Unknown rule type → Auto-config skipped (silent)
- Missing rule fields → Uses safe defaults

---

## UI Hint

**Location**: Above each set's `SetRowControls` widget (when auto-config is active)

**Display**:
```
┌──────────────────────────────────┐
│ ⚡ Intensifier applied: Rest-Pause │
└──────────────────────────────────┘
```

**Conditions**:
- Shown on sets where auto-config is active (based on `intensifier_apply_scope`)
- Only shown if `autoConfigExtras != null` and `autoConfigIntensifierName != null`
- Small blue chip with icon
- For `"last_set"`: Only shown on last set
- For `"all_sets"`: Shown on all sets
- For `"off"`: Never shown

---

## Example Scenarios

### Scenario 1: Rest-Pause Auto-Config
**Exercise Notes**:
```json
{
  "intensifier_rules": {
    "rest_pause": {
      "rest_seconds": 15,
      "mini_sets": 3,
      "reps_per_mini_set": 2
    }
  },
  "intensifier_apply_scope": "last_set",
  "intensifier": "Rest-Pause"
}
```

**Result**:
- Last set automatically configured as `SetType.restPause`
- `rpRestSec = 15`
- `rpBursts = [4, 2, 2]` (estimated: initial 2×2, then 2 per mini-set)
- UI hint: "Auto: Rest-Pause"

### Scenario 2: Cluster Sets Auto-Config
**Exercise Notes**:
```json
{
  "intensifier_rules": {
    "cluster_set": {
      "reps_per_cluster": 4,
      "clusters": 5,
      "rest_between_clusters": 20
    }
  },
  "intensifier_apply_scope": "last_set",
  "intensifier": "Cluster Sets"
}
```

**Result**:
- Last set automatically configured as `SetType.cluster`
- `clusterSize = 4`
- `clusterRestSec = 20`
- `clusterTotalReps = 20` (4 × 5)
- UI hint: "Auto: Cluster Sets"

### Scenario 3: Drop Set Auto-Config
**Exercise Notes**:
```json
{
  "intensifier_rules": {
    "drop_set": {
      "drops": 2,
      "weight_reduction_percent": 25
    }
  },
  "intensifier_apply_scope": "last_set",
  "intensifier": "Drop Set"
}
```

**Result**:
- Last set automatically configured as `SetType.drop`
- `dropPercents = [-25.0, -25.0]` (two drops of -25% each)
- UI hint: "Auto: Drop Set"

### Scenario 4: User Overrides Auto-Config
**Behavior**:
- User opens set type sheet for last set
- Auto-config pre-populates fields
- User changes set type to `SetType.normal`
- User's choice takes precedence (auto-config ignored)

---

## Backward Compatibility

✅ **Fully backward compatible**:
- Exercises without `intensifier_rules`: No auto-config (normal behavior)
- Exercises with plain text notes: Auto-config skipped (safe)
- Exercises with invalid JSON: Auto-config skipped (safe)
- Existing workout sessions: Unaffected
- No database migrations required
- No breaking changes to Exercise or LocalSetLog models

---

## Limitations

1. **Rest-Pause Bursts**: Initial burst reps are estimated (2× reps_per_mini_set) since we don't know target reps
2. **Myo-Reps Implementation**: Uses rest-pause flow structure (similar mechanics)
3. **No Validation**: Rule values are not validated (e.g., negative rest seconds would be accepted)
4. **User Override**: Once user manually sets a set type, auto-config is ignored (by design)
5. **Tempo/RIR**: Not auto-filled from rules (already in Exercise model, handled separately)

---

## Testing Checklist

### Scope: "last_set"
- [x] Exercise with `rest_pause` rules → Last set auto-configured
- [x] Exercise with `cluster_set` rules → Last set auto-configured
- [x] Exercise with `drop_set` rules → Last set auto-configured
- [x] Exercise with `myo_reps` rules → Last set auto-configured
- [x] UI hint appears on last set only
- [x] Other sets unaffected

### Scope: "all_sets"
- [x] Exercise with `rest_pause` rules → All sets auto-configured
- [x] Exercise with `cluster_set` rules → All sets auto-configured
- [x] UI hint appears on all sets
- [x] Each set gets same auto-config

### Scope: "off"
- [x] Exercise with rules but scope="off" → No auto-config
- [x] UI hint never appears
- [x] Sets behave normally

### General
- [x] Exercise without rules → No auto-config
- [x] Exercise with plain text notes → No auto-config (safe)
- [x] Exercise with invalid JSON → No auto-config (safe)
- [x] User manually changes set type → Auto-config ignored
- [x] Set type sheet pre-populated with auto-config values
- [x] Auto-config only fills empty fields (non-destructive)

---

## Next Steps (Phase 4.7 - Full Rule Engine)

1. Add validation for rule values (e.g., rest_seconds > 0)
2. Improve rest-pause burst estimation (use target reps if available)
3. Add support for more rule types (partials, isometrics, etc.)
4. Implement tempo auto-fill from rules (if not in Exercise.tempo)
5. Add RPE/RIR auto-fill from rules (if not in Exercise.rir)

---

**End of Implementation Summary**
