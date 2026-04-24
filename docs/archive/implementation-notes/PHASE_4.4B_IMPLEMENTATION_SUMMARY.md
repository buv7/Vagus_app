# Phase 4.4B: Auto-Generate Exercise-Intensifier Links

## Implementation Complete ✅

### Summary
This migration automatically generates `exercise_intensifier_links` for the top 300-500 exercises using heuristic rules based on movement patterns, equipment, and exercise characteristics.

---

## Migration File

**File:** `supabase/migrations/20250122000000_auto_generate_exercise_intensifier_links.sql`

---

## Features

### 1. **Idempotency** ✅
- Uses `ON CONFLICT (exercise_id, intensifier_id) DO NOTHING`
- Unique constraint already exists on table (from original schema)
- Safe to run multiple times without creating duplicates

### 2. **Top Exercise Selection**
- Selects up to 500 exercises
- Prioritizes:
  1. Exercises with `source='seed_pack_v1'` (highest priority)
  2. Then by `created_at DESC` (most recent)
- Only includes approved EN content:
  - `status='approved'`
  - `language='en'`

### 3. **Intensifier Matching**
- Matches intensifiers by name patterns (ILIKE):
  - Rest-Pause, Drop Set, Paused Reps, Tempo
  - Lengthened Partials, 1.5 Reps, Myo-Reps
  - Slow Eccentric, Cluster Sets, Back-off Sets
  - Wave Loading, Partials, Iso-holds
  - Density, EMOM, Isometrics
- Only approved EN intensifiers

### 4. **Heuristic Rules**

#### Exercise Classification:
- **Isolation/Machine:** Equipment contains 'machine'/'cable'/'smith' OR name contains 'curl'/'extension'/'raise'/'fly'
- **Compound/Free-weight:** Name contains 'squat'/'deadlift'/'bench'/'row'/'press'/'pull-up'/'chin-up'/'lunge'

#### Movement Pattern Mapping:
- **Push compounds:** Rest-Pause, Drop Set, Paused Reps, Tempo, Lengthened Partials, 1.5 Reps
- **Pull/back:** Myo-Reps, Drop Set, Rest-Pause, Lengthened Partials, Slow Eccentric, Paused Reps
- **Squat/hinge:** Paused Reps, Tempo, Cluster Sets, Back-off Sets, Wave Loading
- **Machines/isolation:** Myo-Reps, Drop Set, Rest-Pause, Partials, Iso-holds
- **Carry/locomotion:** Density, EMOM, Tempo
- **Rotation/core:** Tempo, Paused Reps, Iso-holds, Isometrics

#### Fatigue Limiting:
- **Compound/Free-weight:** Max 2 high-fatigue intensifiers
- **Machine/Isolation:** Max 4 high-fatigue intensifiers
- **Other types:** No limit

### 5. **Link Generation**
- Generates 5-8 intensifiers per exercise
- Prioritizes:
  1. Pattern-specific matches (push_compound_default, pull_default, etc.)
  2. Fatigue cost (low/medium first for compounds)
- Notes field contains heuristic reason:
  - `push_compound_default`
  - `pull_default`
  - `squat_hinge_default`
  - `machine_isolation_default`
  - `carry_locomotion_default`
  - `rotation_core_default`
  - `general_default`

---

## SQL Structure

### CTEs Used:
1. **`intensifier_lookup`:** Maps intensifier names to types and fatigue costs
2. **`top_exercises`:** Selects top 500 exercises with classification
3. **`generated_links`:** Generates candidate links based on heuristics
4. **`ranked_links`:** Ranks links by priority and tracks high-fatigue count
5. **`final_links`:** Applies fatigue limits and selects top 8 per exercise

### Insert Statement:
```sql
INSERT INTO public.exercise_intensifier_links (
  exercise_id,
  intensifier_id,
  notes
)
SELECT ... FROM final_links
ON CONFLICT (exercise_id, intensifier_id) DO NOTHING;
```

---

## Verification

The migration includes verification queries:

1. **Total links count**
2. **Total exercises with links**
3. **Average links per exercise**
4. **Sample 20 links** showing:
   - Exercise name
   - Intensifier name
   - Notes (heuristic reason)
   - Fatigue cost
   - Exercise type

---

## Safety Features

✅ **No deletes** - Only inserts new links  
✅ **No updates** - Existing links are preserved  
✅ **No schema changes** - Uses existing table structure  
✅ **Idempotent** - Safe to run multiple times  
✅ **Error handling** - Graceful failure if data missing  

---

## Expected Results

- **Total links:** ~1,500-4,000 (depending on exercise count)
- **Exercises with links:** 300-500
- **Average links per exercise:** 5-8
- **Link distribution:**
  - Push compounds: 6-8 links
  - Pull exercises: 5-7 links
  - Squat/hinge: 5-6 links
  - Machines/isolation: 5-8 links

---

## Testing

After running the migration:

1. **Check total count:**
   ```sql
   SELECT COUNT(*) FROM exercise_intensifier_links;
   ```

2. **Check per-exercise average:**
   ```sql
   SELECT 
     COUNT(DISTINCT exercise_id) as exercises,
     COUNT(*) as total_links,
     ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT exercise_id), 2) as avg_links
   FROM exercise_intensifier_links;
   ```

3. **Verify fatigue limiting:**
   ```sql
   -- Should show max 2 high-fatigue for compounds
   SELECT 
     exercise_id,
     COUNT(*) FILTER (WHERE fatigue_cost = 'high') as high_fatigue_count
   FROM exercise_intensifier_links eil
   JOIN intensifier_knowledge ik ON eil.intensifier_id = ik.id
   JOIN exercise_knowledge ek ON eil.exercise_id = ek.id
   WHERE ek.name LIKE '%squat%' OR ek.name LIKE '%bench%'
   GROUP BY exercise_id
   HAVING COUNT(*) FILTER (WHERE fatigue_cost = 'high') > 2;
   -- Should return 0 rows
   ```

4. **Sample links:**
   ```sql
   SELECT 
     ek.name,
     ik.name,
     eil.notes,
     ik.fatigue_cost
   FROM exercise_intensifier_links eil
   JOIN exercise_knowledge ek ON eil.exercise_id = ek.id
   JOIN intensifier_knowledge ik ON eil.intensifier_id = ik.id
   ORDER BY eil.created_at DESC
   LIMIT 20;
   ```

---

## Notes

- Migration is **pure SQL** - no application code changes
- Uses **heuristic matching** - may not be 100% accurate but provides good defaults
- **Idempotent** - can be re-run to add links for new exercises
- **Performance** - Should complete in < 30 seconds for 500 exercises
- **Future improvements:** Can be enhanced with ML-based matching or user feedback

---

## Files Created

1. **supabase/migrations/20250122000000_auto_generate_exercise_intensifier_links.sql**
   - Full migration with heuristics, ranking, and verification

2. **PHASE_4.4B_IMPLEMENTATION_SUMMARY.md** (this file)
   - Documentation
