# PHASE 1: Database Unblocking - Remove Restrictive CHECK Constraints

**Date:** 2025-01-20  
**Status:** ✅ Migration Created  
**Phase:** 1 of 5 (Database Only)

---

## OVERVIEW

Phase 1 removes restrictive CHECK constraints from workout/exercise tables to enable unlimited expansion of:
- Exercise difficulty levels
- Exercise group types (supersets, circuits, etc.)
- Workout plan goals

This is a **safe, backward-compatible** migration that only removes validation restrictions. No data is modified.

---

## CONSTRAINTS REMOVED

### 1. `exercises_library.difficulty`

**Constraint:** `CHECK (difficulty IN ('beginner', 'intermediate', 'advanced'))`

**Why Remove:**  
- Blocks adding new difficulty levels ('expert', 'elite', 'novice', 'professional', etc.)
- Limits future expansion of difficulty classification

**Impact:**  
- ✅ Can now insert any difficulty string
- ✅ Existing data remains valid (all current values still work)
- ✅ No breaking changes to existing queries

### 2. `exercise_groups.type`

**Constraint:** `CHECK (type IN ('superset', 'triset', 'giant_set', 'circuit', 'drop_set'))`

**Why Remove:**  
- Missing intensifier types already present in code (rest_pause, myo_reps, cluster_set)
- Blocks adding new grouping methods ('blood_flow_restriction', 'mechanical_dropset', etc.)

**Impact:**  
- ✅ Can now insert any group type string
- ✅ Existing data remains valid
- ✅ Unblocks Phase 4 intensifier expansion

### 3. `workout_plans.goal`

**Constraint:** `CHECK (goal IN ('strength', 'hypertrophy', 'endurance', 'powerlifting', 'general_fitness', 'weight_loss'))`

**Why Remove:**  
- Blocks adding new plan goals ('mobility', 'rehabilitation', 'sport_specific', 'cardio_fitness', etc.)
- Limits workout plan categorization

**Impact:**  
- ✅ Can now insert any goal string
- ✅ Existing data remains valid (field is nullable)
- ✅ Enables more flexible plan classification

---

## VERIFICATION SCRIPT

Before running the migration, verify constraint names:

```bash
# Run verification script
psql "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" \
  -f supabase/scripts/verify_constraint_names.sql
```

**Expected Output:**
- Lists exact constraint names for the 3 target constraints
- Shows constraint definitions
- Confirms which constraints exist

**Script Location:** `supabase/scripts/verify_constraint_names.sql`

---

## MIGRATION FILE

**File:** `supabase/migrations/20250120120000_phase1_remove_restrictive_workout_checks.sql`

**Features:**
- ✅ Uses DO blocks to find constraints by pattern matching
- ✅ Safe to run multiple times (idempotent)
- ✅ Uses `DROP CONSTRAINT IF EXISTS` for safety
- ✅ Provides NOTICE messages for logging
- ✅ Includes verification step at the end
- ✅ Wrapped in BEGIN/COMMIT transaction

---

## HOW TO APPLY MIGRATION

### Option 1: Supabase CLI (Recommended)

```bash
# Navigate to project root
cd /path/to/vagus_app

# Apply migration
supabase migration up

# Or apply specific migration
supabase migration up --target 20250120120000_phase1_remove_restrictive_workout_checks
```

### Option 2: Direct psql Connection

```bash
# Using connection string
psql "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" \
  -f supabase/migrations/20250120120000_phase1_remove_restrictive_workout_checks.sql
```

### Option 3: Supabase Dashboard

1. Go to Supabase Dashboard → SQL Editor
2. Copy migration file contents
3. Run in SQL Editor
4. Verify output messages

---

## VERIFICATION AFTER MIGRATION

After running the migration, verify constraints were removed:

```sql
-- Check exercises_library.difficulty constraint (should return 0 rows)
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.exercises_library'::regclass
  AND contype = 'c'
  AND pg_get_constraintdef(oid) LIKE '%difficulty%IN%';

-- Check exercise_groups.type constraint (should return 0 rows)
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.exercise_groups'::regclass
  AND contype = 'c'
  AND pg_get_constraintdef(oid) LIKE '%type%IN%';

-- Check workout_plans.goal constraint (should return 0 rows)
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.workout_plans'::regclass
  AND contype = 'c'
  AND pg_get_constraintdef(oid) LIKE '%goal%IN%';
```

---

## ROLLBACK PROCEDURE

If you need to restore the constraints (not recommended, but possible):

```sql
-- Restore exercises_library.difficulty constraint
ALTER TABLE public.exercises_library
  ADD CONSTRAINT exercises_library_difficulty_check
  CHECK (difficulty IN ('beginner', 'intermediate', 'advanced'));

-- Restore exercise_groups.type constraint
ALTER TABLE public.exercise_groups
  ADD CONSTRAINT exercise_groups_type_check
  CHECK (type IN ('superset', 'triset', 'giant_set', 'circuit', 'drop_set'));

-- Restore workout_plans.goal constraint
ALTER TABLE public.workout_plans
  ADD CONSTRAINT workout_plans_goal_check
  CHECK (goal IN ('strength', 'hypertrophy', 'endurance', 'powerlifting', 'general_fitness', 'weight_loss'));
```

**⚠️ Warning:**  
- Rollback may fail if data exists outside the constraint
- Check data first: `SELECT DISTINCT difficulty FROM exercises_library;`
- Clean up invalid data before re-adding constraints

---

## SAFETY GUARANTEES

### ✅ What This Migration Does:
- Removes CHECK constraint validation only
- Preserves all existing data
- Allows new values to be inserted
- No breaking changes to existing queries

### ✅ What This Migration Does NOT Do:
- ❌ Does NOT modify column types
- ❌ Does NOT delete data
- ❌ Does NOT change table structure
- ❌ Does NOT affect indexes
- ❌ Does NOT modify RLS policies
- ❌ Does NOT touch Flutter/Dart code

---

## NEXT STEPS

After Phase 1 is complete, proceed to:

1. **Phase 2:** Update Dart enum parsing to handle unknown values gracefully
2. **Phase 3:** Make UI components dynamic (replace hard-coded lists with DB queries)
3. **Phase 4:** Extend intensifier system (add JSONB storage for unlimited intensifiers)
4. **Phase 5:** Build knowledge base layer (exercise_knowledge and intensifier_knowledge tables)

---

## RELATED DOCUMENTATION

- **Full Audit Report:** `WORKOUT_KNOWLEDGE_SYSTEM_MCP_VERIFIED_AUDIT.md`
- **Quick Summary:** `WORKOUT_KNOWLEDGE_SYSTEM_QUICK_SUMMARY.md`
- **Original Audit:** `WORKOUT_INTENSIFIER_KNOWLEDGE_SYSTEM_AUDIT.md`

---

## TROUBLESHOOTING

### Migration Fails with "constraint does not exist"
- ✅ This is expected if constraints were already removed
- ✅ Check NOTICE messages - migration is idempotent
- ✅ Verify with verification script

### Migration Finds Multiple Constraints
- Check the DO block logic - it uses LIMIT 1
- Review constraint definitions to ensure correct pattern matching
- Run verification script to see all constraints

### Need to Verify Data After Migration
```sql
-- Check existing values (should all still be valid)
SELECT DISTINCT difficulty FROM exercises_library ORDER BY difficulty;
SELECT DISTINCT type FROM exercise_groups ORDER BY type;
SELECT DISTINCT goal FROM workout_plans WHERE goal IS NOT NULL ORDER BY goal;
```

---

**END OF PHASE 1 DOCUMENTATION**
