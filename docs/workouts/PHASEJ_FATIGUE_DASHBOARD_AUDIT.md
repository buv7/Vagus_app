# Phase J: Fatigue Dashboard Audit

**Date**: 2025-01-22  
**Status**: ✅ Audit Complete

---

## Overview

This audit documents the existing Phase 4.8 fatigue engine implementation to enable building athlete-level fatigue dashboards (Phase J).

---

## Existing Fatigue Engine (Phase 4.8)

### Location
- **Engine**: `lib/services/workout/fatigue_engine.dart`
- **Models**: `lib/models/workout/fatigue_score.dart`
- **Integration**: `lib/widgets/workout/exercise_detail_sheet.dart`

### Architecture

**FatigueEngine** is a pure Dart class with:
- NO UI logic
- NO BuildContext dependencies
- NO database calls
- Deterministic fatigue calculation

### Fatigue Model

**FatigueScore** has three independent channels:
- `local` (double): Target muscle exhaustion
- `systemic` (double): CNS / cardiovascular stress  
- `connective` (double): Joints / tendons / passive tissue

### Calculation Formula

**Base Set Cost**: `reps × rirMultiplier × weightMultiplier`

**RIR Scaling** (cubic):
- RIR 0 → Multiplier = 1.0 (max fatigue)
- RIR 5 → Multiplier = 0.1 (minimal fatigue)
- Formula: `(6 - RIR) / 6` raised to power 3

**Weight Scaling**:
- Normalized to ~100kg baseline
- Formula: `1.0 + (weight / 100.0) × 0.3`

**Base Multipliers**:
- Local: 1.0×
- Systemic: 0.5×
- Connective: 0.3×

### Intensifier Multipliers

| Intensifier | Local | Systemic | Connective |
|-------------|-------|----------|------------|
| Rest-Pause | 1.8× | 1.5× | 0.8× |
| Myo-Reps | 2.5× | 1.2× | 0.5× |
| Drop Sets | 1.6× | 1.0× | 1.4× |
| Cluster Sets | 1.2× | 1.3× | 0.9× |
| Tempo | 1.1× | 0.9× | 1.3× |
| Isometrics | 0.8× | 0.7× | 1.8× |
| Partials | 1.2× | 0.8× | 1.2× |

### Failure & Density Penalties

**Failure Penalty**:
- Local: 2.0× base cost
- Systemic: 3.0× base cost
- Connective: 1.5× base cost

**Density Penalty** (insufficient rest):
- Only affects systemic fatigue
- Formula: `baseSystemic × 1.5 × (restDeficit / expectedRest)`

---

## Data Sources

### Current Storage (Phase 4.8)

**SharedPreferences** (session-only):
- Per-Set: `fatigue_set::{exKey}::{clientId}` (array of FatigueScore JSON)
- Session Aggregate: `fatigue_session::{clientId}` (single FatigueScore JSON)

**NOT persisted to database** - only in-memory during workout session.

### Database Tables Available

1. **workout_sessions**
   - `id`, `user_id`, `day_id`
   - `started_at`, `completed_at`
   - `total_volume`, `total_sets`, `average_rpe`
   - `notes`, `energy_level`

2. **exercise_logs**
   - `id`, `session_id`, `exercise_id`
   - `set_number`, `reps`, `weight`
   - `rpe`, `tempo`, `rest_seconds`
   - `notes`, `form_rating`, `completed_at`

3. **LocalSetLog** (from SharedPreferences)
   - Used by fatigue engine as input
   - Contains: `date`, `weight`, `reps`, `rir`, `unit`
   - Advanced: `setType`, `dropWeights`, `rpBursts`, `clusterSize`, etc.

### Missing Data for Dashboard

To compute historical fatigue snapshots, we need:
- ✅ Set execution data (reps, weight, RIR) - available in `exercise_logs`
- ⚠️ Intensifier metadata - stored in exercise `notes` as JSON
- ⚠️ Set type (drop, rest-pause, etc.) - may be in `exercise_logs.notes` or missing
- ⚠️ Failure flags - may be in `exercise_logs.notes` or missing
- ⚠️ Actual vs expected rest - may be in `exercise_logs.rest_seconds` but no expected rest stored

**Conclusion**: We can compute **approximate** fatigue from `exercise_logs` but may miss:
- Intensifier-specific multipliers (unless stored in notes)
- Failure penalties (unless logged)
- Density penalties (no expected rest stored)

---

## Coach-Client Relationships

### Table: `coach_clients`
- `id`, `coach_id`, `client_id`
- `status` ('active', 'inactive', 'pending')
- `started_at`, `ended_at`

### RLS Policies
- ✅ Coaches can view their clients' data
- ✅ Clients can view their own data
- ✅ Admins can view all data

**Pattern**: Used in `fatigue_logs` and `recovery_scores` tables already.

---

## Existing Fatigue-Related Tables

### `fatigue_logs` (Manual Logging)
- User-submitted fatigue scores (0-10 scale)
- NOT computed from workouts
- Separate from Phase 4.8 engine

### `recovery_scores` (Aggregated)
- Daily recovery scores (0-10 scale)
- Calculated from `fatigue_logs` or manual entry
- NOT computed from workout fatigue

**Note**: These are for **subjective** fatigue/recovery, not **computed** fatigue from workout execution.

---

## Integration Points

### Where Fatigue is Calculated

**Exercise Detail Sheet** (`exercise_detail_sheet.dart`):
- Line ~1514: On set log, calculates fatigue
- Uses `FatigueEngine.scoreSet()` with `SetExecutionData` and `IntensifierExecution`
- Accumulates per-exercise and per-session
- Persists to SharedPreferences (session-only)

### Input Data Flow

1. User logs set → `LocalSetLog` created
2. `SetExecutionData.fromLocalSetLog()` extracts execution data
3. `IntensifierExecution.fromState()` extracts intensifier rules from exercise notes
4. `FatigueEngine.scoreSet()` computes fatigue
5. Fatigue stored in SharedPreferences (not database)

---

## Gaps for Dashboard Implementation

### 1. Historical Fatigue Data
- ❌ No daily snapshots stored
- ❌ No muscle group breakdown stored
- ❌ No intensifier contribution breakdown stored

### 2. Database Persistence
- ❌ Fatigue scores not written to database
- ❌ Only session-level SharedPreferences storage
- ❌ No way to query historical fatigue

### 3. Aggregation Needs
- Need: Daily fatigue score (0-100 scale)
- Need: Per-muscle fatigue breakdown
- Need: Per-intensifier contribution
- Need: Volume load, hard sets count, near-failure sets count

---

## Implementation Strategy

### Option A: App-Side Compute (Recommended)
1. Query `exercise_logs` for date range
2. Reconstruct `SetExecutionData` from logs
3. Use existing `FatigueEngine` to compute fatigue
4. Aggregate per-day, per-muscle, per-intensifier
5. Store snapshots in `fatigue_snapshots` table

**Pros**: Uses existing engine logic exactly  
**Cons**: Requires fetching all exercise logs (can be heavy)

### Option B: SQL Compute (Fallback)
1. Implement fatigue formula in SQL
2. Query `exercise_logs` directly
3. Compute aggregates in database
4. Store snapshots

**Pros**: Faster, no data transfer  
**Cons**: Duplicates logic, harder to maintain

### Hybrid Approach (Chosen)
- **App computes** fatigue using existing engine
- **RPC function** only upserts computed values
- **SQL fallback** for basic aggregates (volume, set counts) if needed

---

## Next Steps

1. ✅ Create `fatigue_snapshots` table
2. ✅ Create RPC function for snapshot refresh
3. ✅ Create service layer to compute and store snapshots
4. ✅ Create dashboard UI (client + coach)
5. ✅ Wire into navigation

---

**End of Audit**
