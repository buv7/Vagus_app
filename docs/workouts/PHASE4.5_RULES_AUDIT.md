# Phase 4.5: Intensifier Rule Fields Audit

**Date**: 2025-01-22  
**Purpose**: Audit existing exercise editor for intensifier "rule fields" before implementing Phase 4.5 "Smart Apply" feature

---

## Executive Summary

**Status**: ❌ **We do NOT have intensifier rule fields in the exercise editor**

The editor currently supports:
- ✅ **Tempo** (string field, e.g., "3-1-2-0")
- ✅ **RIR** (Reps in Reserve, 0-5 integer)
- ✅ **Training Method** (enum selection: restPause, clusterSet, dropSet, myoReps, etc.)

**Missing**: Specific rule configuration fields for:
- Rest-Pause (rest seconds, mini-sets, reps per mini-set)
- Cluster Sets (reps per cluster, clusters, rest between)
- Drop Sets (weight reduction %, number of drops)
- Myo-Reps (activation reps, rest seconds, mini-set reps)
- Partials (range of motion %, position)
- Isometrics (hold seconds, position: top/mid/bottom)
- RPE targets (currently only RIR exists)

---

## TASK A: Code Search Results

### Existing Fields Found

#### ✅ Tempo
- **Model**: `Exercise.tempo` (String?), `EnhancedExercise.tempo` (String?)
- **UI**: `lib/widgets/workout/advanced_exercise_editor_dialog.dart:38, 79, 205, 404-407`
- **DB**: `exercises.tempo` (TEXT column)
- **Status**: Fully implemented and persisted

#### ✅ RIR (Reps in Reserve)
- **Model**: `Exercise.rir` (int?), `EnhancedExercise.rir` (int?)
- **UI**: `lib/widgets/workout/advanced_exercise_editor_dialog.dart:42, 80, 206, 430-433`
- **DB**: `exercises.rir` (implied, via Exercise.toMap())
- **Status**: Fully implemented and persisted

#### ✅ RPE (Rate of Perceived Exertion)
- **Model**: `EnhancedExercise.rpe` (double?), `ExerciseHistoryEntry.rpeRating` (int?)
- **UI**: ❌ **NOT in AdvancedExerciseEditorDialog** (only in completion widget)
- **DB**: `workout_sessions.target_rpe_min/max` (DECIMAL), but NOT in `exercises` table
- **Status**: Model exists but NOT in editor UI

#### ⚠️ Rest-Pause
- **Model**: `EnhancedExercise.restPause` (bool), `EnhancedExercise.restPauseConfig` (RestPauseConfig)
  - Config fields: `activationReps`, `restSeconds`, `miniSets`, `repsPerMiniSet`
- **UI**: ❌ **NOT in AdvancedExerciseEditorDialog**
- **DB**: ❌ **NOT in exercises table** (only in EnhancedExercise model, not persisted)
- **Status**: Model exists but NOT in editor UI or DB schema

#### ⚠️ Cluster Sets
- **Model**: `EnhancedExercise.clusterSets` (bool), `EnhancedExercise.clusterSetConfig` (ClusterSetConfig)
  - Config fields: `repsPerCluster`, `clusters`, `restBetweenClusters`
- **UI**: ❌ **NOT in AdvancedExerciseEditorDialog**
- **DB**: ❌ **NOT in exercises table**
- **Status**: Model exists but NOT in editor UI or DB schema

#### ⚠️ Drop Sets
- **Model**: `EnhancedExercise.dropSets` (List<DropSet>?)
  - DropSet fields: `setNumber`, `weightReduction`, `reps`
- **UI**: ❌ **NOT in AdvancedExerciseEditorDialog**
- **DB**: ❌ **NOT in exercises table**
- **Status**: Model exists but NOT in editor UI or DB schema

#### ⚠️ Partials
- **Model**: `EnhancedExercise.partialReps` (PartialRepsConfig?)
  - Config fields: `rangeOfMotion` (String), `reps` (int)
- **UI**: ❌ **NOT in AdvancedExerciseEditorDialog**
- **DB**: ❌ **NOT in exercises table**
- **Status**: Model exists but NOT in editor UI or DB schema

#### ⚠️ Isometrics
- **Model**: `EnhancedExercise.isometricHoldSeconds` (int?), `EnhancedExercise.isometricPosition` (IsometricPosition?)
- **UI**: ❌ **NOT in AdvancedExerciseEditorDialog**
- **DB**: ❌ **NOT in exercises table**
- **Status**: Model exists but NOT in editor UI or DB schema

#### ⚠️ Myo-Reps
- **Model**: `TrainingMethod.myoReps` (enum value only, no config)
- **UI**: ✅ Training method selector exists, but no config fields
- **DB**: `exercises.training_method` (TEXT, stores enum name)
- **Status**: Method selection exists, but NO config fields

### Key Finding: Exercise vs EnhancedExercise Split

**Critical Discovery**: The `AdvancedExerciseEditorDialog` saves to the **`Exercise`** model (not `EnhancedExercise`):

```dart
// lib/widgets/workout/advanced_exercise_editor_dialog.dart:196-213
final exercise = Exercise(
  // ... basic fields ...
  tempo: _tempoController.text.trim().isEmpty ? null : _tempoController.text.trim(),
  rir: _rir,
  percent1RM: _percent1RM,
  notes: _buildNotesString().isEmpty ? null : _buildNotesString(),
  // ... NO restPause, clusterSets, dropSets, partialReps, isometric fields ...
);
```

The `EnhancedExercise` model has all the advanced fields, but:
1. The editor doesn't use it
2. The fields aren't persisted to the database
3. They're only used in-memory for display/logging

---

## TASK B: Data Model Audit

### Exercise Model (`lib/models/workout/exercise.dart`)

**Fields for intensifier rules**:
- ✅ `tempo` (String?) - "3-1-2-0" format
- ✅ `rir` (int?) - 0-5
- ❌ No rest-pause config
- ❌ No cluster config
- ❌ No drop-set config
- ❌ No partials config
- ❌ No isometric config
- ❌ No RPE field

**Notes JSON structure** (current):
```json
{
  "knowledge_exercise_id": "...",
  "knowledge_short_desc": "...",
  "intensifier": "...",
  "intensifier_id": "...",
  "user_notes": "..."
}
```

### EnhancedExercise Model (`lib/models/workout/enhanced_exercise.dart`)

**Fields for intensifier rules**:
- ✅ `tempo` (String?)
- ✅ `rir` (int?)
- ✅ `rpe` (double?)
- ✅ `restPause` (bool) + `restPauseConfig` (RestPauseConfig)
- ✅ `clusterSets` (bool) + `clusterSetConfig` (ClusterSetConfig)
- ✅ `dropSets` (List<DropSet>?)
- ✅ `partialReps` (PartialRepsConfig?)
- ✅ `isometricHoldSeconds` (int?) + `isometricPosition` (IsometricPosition?)

**Problem**: These fields are NOT persisted to database. `EnhancedExercise.toMap()` includes them, but the exercises table doesn't have columns for them.

---

## TASK C: Database Schema Audit

### Exercises Table Schema

**Source**: `supabase/migrations/migrate_workout_v1_to_v2.sql:115-149`

**Columns relevant to intensifier rules**:
```sql
tempo TEXT,                    -- ✅ Exists (e.g., "3-0-1-0")
target_rpe_min DECIMAL(3,1),  -- ⚠️ Exists but NOT used by Exercise model
target_rpe_max DECIMAL(3,1),  -- ⚠️ Exists but NOT used by Exercise model
rest_seconds INTEGER,         -- ✅ Exists (general rest, not intensifier-specific)
notes TEXT,                   -- ✅ Exists (stores JSON with knowledge data)
```

**Missing columns**:
- ❌ `rest_pause_config` (JSONB)
- ❌ `cluster_set_config` (JSONB)
- ❌ `drop_set_config` (JSONB)
- ❌ `myo_reps_config` (JSONB)
- ❌ `partial_reps_config` (JSONB)
- ❌ `isometric_config` (JSONB)
- ❌ `rir` (INTEGER) - **Note**: Not found in schema, but Exercise model expects it
- ❌ `intensifier_rules` (JSONB)

### Intensifier Knowledge Table

**Source**: `supabase/migrations/20251221021539_workout_knowledge_base.sql`

The `intensifier_knowledge` table stores:
- `intensity_rules` (JSONB) - Contains rule parameters like:
  ```json
  {
    "rest_pause": {
      "rest_seconds": 15,
      "mini_sets": 3,
      "target_rir": 0,
      "reps_per_mini_set": 2
    }
  }
  ```

**Key Finding**: Intensifier rules exist in the **knowledge base** (as reference data), but are NOT stored on individual exercises. They're meant to be applied dynamically, not persisted per-exercise.

---

## TASK D: UI Flow Audit

### Edit Flow

1. **Entry Point**: `AdvancedExerciseEditorDialog` (`lib/widgets/workout/advanced_exercise_editor_dialog.dart`)
2. **Save Method**: `_save()` (line 188-217)
   - Creates `Exercise` object (not `EnhancedExercise`)
   - Saves: name, sets, reps, weight, rest, tempo, rir, percent1RM, notes, groupId, groupType, trainingMethod
   - **Does NOT save**: rest-pause config, cluster config, drop-set config, partials, isometrics
3. **Callback**: `widget.onSave(exercise)` - passes Exercise to parent
4. **Persistence**: Parent calls `WorkoutService` which saves to `exercises` table

### Set-Level Editing

**Location**: `lib/widgets/workout/exercise_detail_sheet.dart` (line 1446-1487)

When logging sets during workout:
- Uses `SetRowControls` widget
- Supports: `SetType.restPause`, `SetType.cluster`, `SetType.drop`
- Stores in `LocalSetLog` (local storage, not DB):
  - `rpBursts`, `rpRestSec` (rest-pause)
  - `clusterSize`, `clusterRestSec`, `clusterTotalReps` (cluster)
  - `dropWeights`, `dropPercents` (drop-set)

**Key Finding**: Set-level intensifier data exists for **logging** (workout execution), but NOT for **planning** (exercise editor).

---

## Mapping: Intensifier Rule Types → Existing Fields

| Intensifier Rule Type | Existing Field? | Location | Persisted? |
|----------------------|----------------|----------|------------|
| **Tempo** | ✅ Yes | `Exercise.tempo` | ✅ Yes (DB column) |
| **Eccentric/Concentric timing** | ✅ Yes (via tempo) | `Exercise.tempo` | ✅ Yes |
| **Rest-Pause** | ❌ No | Model only (`EnhancedExercise`) | ❌ No |
| **Myo-Reps** | ⚠️ Partial | `TrainingMethod.myoReps` (enum only) | ⚠️ Partial (method name only) |
| **Cluster Sets** | ❌ No | Model only (`EnhancedExercise`) | ❌ No |
| **Drop Sets** | ❌ No | Model only (`EnhancedExercise`) | ❌ No |
| **Partials** | ❌ No | Model only (`EnhancedExercise`) | ❌ No |
| **Lengthened Partials** | ❌ No | Model only (`EnhancedExercise`) | ❌ No |
| **Isometric Holds** | ❌ No | Model only (`EnhancedExercise`) | ❌ No |
| **RIR** | ✅ Yes | `Exercise.rir` | ✅ Yes (via model) |
| **RPE** | ⚠️ Partial | `EnhancedExercise.rpe` (not in editor) | ⚠️ Partial (DB has target_rpe_min/max but not used) |
| **Intensity Rules** | ⚠️ Reference only | `intensifier_knowledge.intensity_rules` (JSONB) | ⚠️ Reference data, not per-exercise |

---

## Storage Plan Proposal

### Option 1: Store in Exercise.notes JSON (Recommended for Phase 4.5)

**Minimal, non-breaking approach**:

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
      "reps_per_mini_set": 2
    }
  },
  "intensifier_apply_scope": "last_set"  // or "all_sets"
}
```

**Pros**:
- ✅ No migration required
- ✅ Backward compatible (existing exercises work)
- ✅ Flexible (can store any rule type)
- ✅ Already JSON structure in place

**Cons**:
- ⚠️ Not queryable (would need JSONB column for queries)
- ⚠️ No type safety (manual parsing)

### Option 2: Add JSONB Column (Future Enhancement)

```sql
ALTER TABLE exercises
ADD COLUMN intensifier_rules JSONB DEFAULT '{}';
```

**Pros**:
- ✅ Queryable (PostgreSQL JSONB operators)
- ✅ Indexable (GIN indexes)
- ✅ Type-safe structure

**Cons**:
- ❌ Requires migration
- ❌ More complex implementation

**Recommendation**: Use Option 1 for Phase 4.5 (audit-only, preview rules), then consider Option 2 for Phase 4.6 (full implementation).

---

## Go/No-Go Decision

### ✅ GO for Phase 4.5 (Preview Only)

**Rationale**:
1. We have tempo and RIR fields (basic rules)
2. Intensifier rules exist in knowledge base (`intensity_rules` JSONB)
3. Notes JSON structure already supports extensibility
4. Can preview rules without behavior changes
5. No breaking changes required

**Scope**:
- Display intensifier rules from knowledge base in editor
- Show rule parameters (rest seconds, mini-sets, etc.) as read-only preview
- Store selected intensifier + rules in `notes['intensifier_rules']` (optional)
- **Do NOT** modify exercise behavior yet (no auto-apply to sets)

### ❌ NO-GO for Full Implementation (Phase 4.6)

**Blockers**:
1. No UI fields for rule configuration (rest-pause config, cluster config, etc.)
2. No database columns for rule persistence
3. Editor saves to `Exercise` model (not `EnhancedExercise`)
4. Set-level editing happens in different widget (`exercise_detail_sheet`)

**Required for Phase 4.6**:
1. Add rule config UI fields to `AdvancedExerciseEditorDialog`
2. Extend `Exercise` model with rule fields (or migrate to `EnhancedExercise`)
3. Add database columns or use JSONB in notes
4. Implement "Apply to last set" / "Apply to all sets" logic

---

## Files Phase 4.5 Will Modify (Max 2-3)

### 1. `lib/widgets/workout/advanced_exercise_editor_dialog.dart`
- **Change**: Display intensifier rules preview from knowledge base
- **Location**: `_buildMethodsTab()` or new `_buildIntensifierRulesPreview()` method
- **Impact**: UI-only, read-only display

### 2. `lib/services/workout/workout_knowledge_service.dart` (if needed)
- **Change**: Helper method to extract `intensity_rules` from intensifier knowledge
- **Impact**: Service layer, no breaking changes

### 3. `lib/widgets/workout/advanced_exercise_editor_dialog.dart` (optional)
- **Change**: Store `intensifier_rules` in notes JSON when intensifier selected
- **Location**: `_buildNotesString()` method
- **Impact**: Data storage, backward compatible (optional field)

---

## Summary Table

| Component | Status | Notes |
|-----------|--------|-------|
| **Tempo field** | ✅ Complete | UI + Model + DB |
| **RIR field** | ✅ Complete | UI + Model + DB |
| **RPE field** | ⚠️ Partial | Model exists, not in editor |
| **Rest-Pause config** | ❌ Missing | Model only, not in editor/DB |
| **Cluster config** | ❌ Missing | Model only, not in editor/DB |
| **Drop-set config** | ❌ Missing | Model only, not in editor/DB |
| **Partials config** | ❌ Missing | Model only, not in editor/DB |
| **Isometric config** | ❌ Missing | Model only, not in editor/DB |
| **Myo-Reps config** | ❌ Missing | Enum only, no config fields |
| **Intensifier rules (knowledge)** | ✅ Exists | In `intensifier_knowledge.intensity_rules` (JSONB) |
| **Intensifier rules (per-exercise)** | ❌ Missing | Not stored on exercises |

---

## Next Steps for Phase 4.5

1. ✅ **Audit Complete** (this document)
2. ⏭️ **Preview Rules in UI** (read-only display from knowledge base)
3. ⏭️ **Store Rules in Notes** (optional, for future use)
4. ⏭️ **No Behavior Changes** (preview only, no auto-apply)

---

## Next Steps for Phase 4.6 (Full Implementation)

1. Add rule config UI fields to editor
2. Extend Exercise model or migrate to EnhancedExercise
3. Add database persistence (JSONB column or notes JSON)
4. Implement "Apply to last set" / "Apply to all sets" logic
5. Update set-level editing to respect rules

---

**End of Audit Report**
