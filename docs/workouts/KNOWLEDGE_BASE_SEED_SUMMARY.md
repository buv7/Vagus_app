# Knowledge Base Seed - Complete Summary

**Date:** 2025-12-21  
**Status:** ✅ All Migrations Created  
**Phase:** 4 - Knowledge Base Population

---

## Overview

This seed operation populates the Phase 4 knowledge base tables (`exercise_knowledge` and `intensifier_knowledge`) with data from `exercises_library` and comprehensive intensifier definitions.

**Goal:** Make 500-2000+ exercises and 30+ intensifiers immediately searchable in `WorkoutKnowledgeAdminScreen`.

---

## Migration Files (Run in Order)

### 1. `20251221122033_knowledge_seed_unique_indexes.sql`
**Purpose:** Enable idempotent upserts

**Creates:**
- `idx_exercise_knowledge_unique_name_language` - UNIQUE (LOWER(name), language)
- `idx_intensifier_knowledge_unique_name_language` - UNIQUE (LOWER(name), language)

**Safety:** ✅ Additive only, uses `IF NOT EXISTS` checks

---

### 2. `20251221122034_seed_exercise_knowledge_from_library.sql`
**Purpose:** Import exercises from `exercises_library` into `exercise_knowledge`

**Mapping:**
- `name` → `name`
- `muscle_group` → `primary_muscles` (as array)
- `secondary_muscles` → `secondary_muscles`
- `equipment_needed` → `equipment`
- `description` → `short_desc` (or generated)
- `{image_url, video_url, thumbnail_url}` → `media` (JSONB)
- Sets `source='imported_from_exercises_library'`, `status='approved'`, `language='en'`

**Idempotency:** ✅ Uses `ON CONFLICT (LOWER(name), language) DO UPDATE` - only fills missing fields

**Expected:** 500-2000+ exercises (depends on `exercises_library` size)

---

### 3. `20251221122035_seed_intensifier_knowledge.sql`
**Purpose:** Seed 30+ training intensifiers with full descriptions

**Intensifiers Included:**
- Rest-Pause, Myo-Reps, Drop Sets (single/double/mechanical)
- Cluster Sets, EMOM, Density Blocks
- 1.5 Reps, Lengthened Partials, Paused Reps
- Slow Eccentrics, Tempo Sets
- Isometrics (yielding/overcoming), Iso-Hold at Stretch
- Pre-Exhaust, Post-Exhaust
- Superset, Antagonist Superset, Triset, Giant Set, Circuit
- BFR, Partial Reps (top/bottom), Cheat Reps, Forced Reps, Negatives
- Wave Loading, Back-Off Sets

**Each Includes:**
- `short_desc` (1-2 lines)
- `how_to` (2-6 lines practical instructions)
- `fatigue_cost` (low/medium/high/very_high)
- `best_for` (array: strength, hypertrophy, etc.)
- `intensity_rules` (JSONB with method-specific parameters)
- `examples` (array of practical examples)

**Idempotency:** ✅ Uses `ON CONFLICT (LOWER(name), language) DO UPDATE` - only fills missing fields

**Expected:** 30+ intensifiers

---

### 4. `20251221122036_seed_exercise_intensifier_links.sql`
**Purpose:** Create starter links between common exercises and intensifiers

**Link Patterns:**
- Bench Press → Rest-Pause, Drop Set, Paused Reps, Tempo Sets
- Squat → Paused Reps, Tempo Sets, Cluster Sets, Slow Eccentrics
- Lat Pulldown → Myo-Reps, Drop Set, Rest-Pause
- Deadlift → Paused Reps, Tempo Sets, Cluster Sets
- Shoulder Press → Rest-Pause, Drop Set, Paused Reps
- Rows → Rest-Pause, Myo-Reps, Tempo Sets
- Bicep Curls → Drop Set, Myo-Reps, Rest-Pause, Cheat Reps
- Tricep Extensions → Drop Set, Myo-Reps, Rest-Pause
- Leg Press → Rest-Pause, Drop Set, Cluster Sets
- Leg Extension → Myo-Reps, Drop Set, Pre-Exhaust

**Idempotency:** ✅ Uses `ON CONFLICT (exercise_id, intensifier_id) DO NOTHING`

**Expected:** 20-50 links (depends on exercise name matches)

---

### 5. `20251221122037_verify_knowledge_seed.sql`
**Purpose:** Verification queries

**Checks:**
- Counts for `exercise_knowledge` and `intensifier_knowledge`
- Sample rows (10 each)
- Duplicate detection (should be 0)
- Media and JSON rules presence

---

## Quick Verification SQL

```sql
-- Count exercises
SELECT COUNT(*) FROM exercise_knowledge WHERE source = 'imported_from_exercises_library';

-- Count intensifiers
SELECT COUNT(*) FROM intensifier_knowledge WHERE status = 'approved' AND language = 'en';

-- Count links
SELECT COUNT(*) FROM exercise_intensifier_links;

-- Sample exercises
SELECT name, primary_muscles, equipment FROM exercise_knowledge WHERE status = 'approved' LIMIT 10;

-- Sample intensifiers
SELECT name, fatigue_cost, best_for FROM intensifier_knowledge WHERE status = 'approved' LIMIT 10;
```

---

## Safety Guarantees

✅ **No destructive operations**  
✅ **No modifications to `exercises_library`**  
✅ **No modifications to workout plan tables**  
✅ **No RLS policy changes**  
✅ **Idempotent** (safe to run multiple times)  
✅ **Additive only** (only adds unique indexes, no deletions)

---

## Expected Results

After running all migrations:

| Table | Expected Count | Status |
|-------|---------------|--------|
| `exercise_knowledge` | 500-2000+ | `approved`, `language='en'` |
| `intensifier_knowledge` | 30+ | `approved`, `language='en'` |
| `exercise_intensifier_links` | 20-50 | All links valid |

---

## Running the Migrations

### Via Supabase CLI:
```bash
supabase migration up
```

### Via SQL Editor:
Run each migration file in order (1-4), then run verification (5).

---

## Troubleshooting

### If exercises don't import:
1. Check `exercises_library` has data: `SELECT COUNT(*) FROM exercises_library;`
2. Check for name conflicts: Run verification SQL
3. Check RLS policies allow INSERT (should be fine for system imports with `created_by=NULL`)

### If intensifiers don't appear:
1. Check unique index exists: `\d intensifier_knowledge` in psql
2. Check for name conflicts (case-insensitive)
3. Verify migration ran without errors

### If links are missing:
1. Check exercise names match (case-insensitive): `SELECT name FROM exercise_knowledge WHERE LOWER(name) LIKE '%bench%';`
2. Check intensifier names match: `SELECT name FROM intensifier_knowledge WHERE LOWER(name) LIKE '%rest%';`
3. Links only created if both exercise and intensifier exist

---

## Next Steps

After seeding:
1. ✅ Verify data in `WorkoutKnowledgeAdminScreen`
2. ✅ Test search functionality
3. ✅ Test exercise-intensifier linking UI (if implemented)
4. ✅ Consider adding more exercises from external sources
5. ✅ Consider adding more intensifiers as needed

---

**END OF SUMMARY**
