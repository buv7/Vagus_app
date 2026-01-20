# Phase 4.7: Full Intensifier Rule Engine - Implementation Summary

**Date**: 2025-01-22  
**Status**: ✅ Complete

---

## Overview

Implemented a **pure Dart rule engine** that interprets intensifier rules and applies them deterministically during workout execution. The engine is stateful, tracks execution across sets, and persists metadata while maintaining full backward compatibility.

---

## Architecture

### Core Components

1. **IntensifierRuleEngine** (`lib/services/workout/intensifier_rule_engine.dart`)
   - Pure Dart class (NO UI logic)
   - Deterministic output
   - Interprets rules and generates directives

2. **IntensifierSetDirective** (`lib/models/workout/intensifier_models.dart`)
   - Output from engine
   - Contains: `setType`, `fields`, `lockStructure`, `ruleName`, `metadata`

3. **SetExecutionState** (`lib/models/workout/intensifier_models.dart`)
   - Tracks state across sets
   - Persists execution metadata
   - Handles user override tracking

4. **Integration** (`lib/widgets/workout/exercise_detail_sheet.dart`)
   - Initializes engine from `Exercise.notes`
   - Gets directives per set
   - Updates execution state
   - Persists metadata

---

## Files Created/Modified

### Created:
1. `lib/models/workout/intensifier_models.dart` - Models for directives and state
2. `lib/services/workout/intensifier_rule_engine.dart` - Pure rule engine

### Modified:
1. `lib/widgets/workout/exercise_detail_sheet.dart` - Engine integration

---

## Engine Design

### Rule Interpretation Priority

1. **Rest-Pause** (highest priority)
2. **Cluster Sets**
3. **Drop Sets**
4. **Myo-Reps**

First matching rule wins. Rules do NOT stack (except tempo/isometrics/partials which modify behavior but don't change SetType).

### Supported Rule Types

| Rule Type | SetType | Fields | State Tracking |
|-----------|---------|--------|----------------|
| **Rest-Pause** | `SetType.restPause` | `rpRestSec`, `rpBursts` | `completedBursts`, `currentBurstIndex` |
| **Cluster Sets** | `SetType.cluster` | `clusterSize`, `clusterRestSec`, `clusterTotalReps` | `completedClusters`, `currentClusterIndex` |
| **Drop Sets** | `SetType.drop` | `dropPercents` | `dropsUsed`, `dropWeightsUsed` |
| **Myo-Reps** | `SetType.restPause` | `rpRestSec`, `rpBursts` | `activationSetCompleted`, `completedMiniSets` |
| **Tempo** | (no SetType change) | (enforced via Exercise.tempo) | N/A |
| **Isometrics** | (no SetType change) | `hold_seconds` | N/A |
| **Partials** | (no SetType change) | `rom_percent` | N/A |

### Apply Scope Enforcement

- `"off"` → Engine returns `null` (no directive)
- `"last_set"` → Directive only for `setIndex == totalSets - 1`
- `"all_sets"` → Directive for every set
- Missing/invalid → Defaults to `"last_set"`

---

## Stateful Execution

### Execution State Tracking

**Per Exercise**:
- `completedBursts` - Total bursts completed (rest-pause)
- `completedClusters` - Total clusters completed
- `activationSetCompleted` - Myo-reps activation done
- `completedMiniSets` - Myo-reps mini-sets done
- `dropsUsed` - Number of drops executed
- `dropWeightsUsed` - List of drop weights
- `runtime` - Per-set metadata
- `userOverrides` - Map of set indices user has overridden

**State Lifecycle**:
- Initialized when exercise loads
- Updated when sets are logged
- Reset when exercise is reset/cleared
- Persisted to SharedPreferences (session-only)

---

## User Override Handling

### Non-Negotiable Rules

1. **User edits ALWAYS win**
2. **Override Detection**:
   - When user changes set type via `SetTypeSheet`
   - Marked in `_executionState.userOverrides[setIndex] = true`
3. **Engine Disengagement**:
   - `getDirectiveForSet()` checks `userOverridden` flag
   - Returns `null` if user has overridden that set
4. **No Re-engagement**:
   - Once overridden, engine stays disengaged for that set

---

## Execution Metadata Persistence

### Storage Location

**SharedPreferences** (session-only, not in plan):
- Key: `intensifier_execution::{exKey}::{clientId}`
- Value: JSON string of execution metadata

### Metadata Structure

```json
{
  "completed_bursts": 4,
  "completed_clusters": 3,
  "activation_set_completed": true,
  "completed_mini_sets": 2,
  "drops_used": 2,
  "drop_weights_used": [80.0, 60.0],
  "runtime": {
    "set_0": {
      "set_type": "restPause",
      "reps": 8,
      "weight": 100.0,
      "logged_at": "2025-01-22T10:30:00Z"
    }
  }
}
```

### Persistence Flow

1. **On Set Log**: `_updateExecutionState()` updates state
2. **After Log**: `_persistExecutionMetadata()` saves to SharedPreferences
3. **On Load**: `_loadExecutionMetadata()` restores state (if exists)
4. **On Reset**: State cleared, metadata deleted

---

## Integration Points

### Exercise Detail Sheet

**Initialization** (line ~142):
```dart
_parseIntensifierRules(); // Initialize engine
_loadExecutionMetadata(exKey, clientId); // Restore state
```

**Per-Set Rendering** (line ~1453):
```dart
final directive = _getDirectiveForSet(index, setsPlanned);
final autoConfigExtras = _directiveToLocalSetLog(directive);
```

**Set Logging** (line ~1497):
```dart
_updateExecutionState(index, extras); // Update state
_persistExecutionMetadata(exKey, clientId); // Persist
```

**User Override** (line ~1593):
```dart
_executionState.markUserOverride(index); // Mark override
```

---

## Safety Guarantees

### ✅ Non-Destructive

- **Never overwrites user values**: Engine only provides directives when fields are empty
- **User overrides respected**: Once overridden, engine disengages
- **Safe parsing**: All JSON parsing wrapped in try-catch
- **Safe defaults**: Missing rule fields use sensible defaults

### ✅ Backward Compatible

- Exercises without rules: Engine is `null`, no behavior change
- Plain text notes: Engine not initialized, no crash
- Invalid JSON: Engine not initialized, no crash
- Missing scope: Defaults to `"last_set"`

### ✅ Performance

- **Single initialization**: Engine created once per exercise load
- **O(1) per-set lookup**: `getDirectiveForSet()` is fast
- **No DB queries**: All data from `Exercise.notes` (already loaded)
- **Lazy persistence**: Metadata only persisted when sets logged

---

## Test Scenarios

### ✅ Rest-Pause Execution
- Multiple bursts tracked correctly
- State persists across sets
- User override disengages engine

### ✅ Myo-Reps Execution
- Activation set detected (15+ reps)
- Mini-sets follow activation
- State tracks phase correctly

### ✅ Cluster Sets Execution
- Clusters tracked per set
- Rest enforcement works
- Total reps calculated correctly

### ✅ User Override
- Manual set type change → Engine disengages
- Override persists for that set
- Other sets unaffected

### ✅ Scope Enforcement
- `"last_set"` → Only last set gets directive
- `"all_sets"` → All sets get directive
- `"off"` → No directives

### ✅ State Persistence
- Metadata saved after each set
- Metadata loaded on exercise load
- State resets on exercise reset

---

## Known Limitations

1. **Myo-Reps Detection**: Activation set detection uses heuristics (15+ reps), may not be perfect
2. **Rest-Pause Burst Estimation**: Initial burst reps estimated (2× reps_per_mini_set)
3. **No Rule Stacking**: Only first matching rule applies (by design)
4. **Tempo/Isometrics/Partials**: Not fully enforced yet (detected but not blocking)
5. **State Persistence**: Session-only (cleared on app restart)

---

## Next Steps (Future Phases)

1. **Phase 4.8**: Fatigue Accumulation Engine
2. **Phase 4.9**: Auto-Deload Detection
3. **Phase 5.0**: AI Progression Coach (uses rule engine output)

---

## Engine Architecture Summary

```
Exercise.notes JSON
    ↓
IntensifierRuleEngine (pure Dart)
    ↓
IntensifierSetDirective (per set)
    ↓
LocalSetLog (execution)
    ↓
SetExecutionState (updated)
    ↓
SharedPreferences (persisted)
```

**Key Principle**: Engine is **stateless** (deterministic), but execution is **stateful** (tracks progress).

---

**End of Implementation Summary**
