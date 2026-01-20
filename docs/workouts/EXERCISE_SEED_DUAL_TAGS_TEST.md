# Exercise Seed Import - Dual Tags Test Guide

**Date:** 2025-12-21  
**Status:** ✅ Implementation Complete  
**Feature:** 2000 Exercises with Dual Tags (English + Anatomical)

---

## Overview

Seed file contains 2000 exercises with **dual tag system**:
- **English tags:** `chest`, `back`, `triceps`, `biceps`, etc.
- **Anatomical tags:** `pectoralis_major`, `latissimus_dorsi`, `triceps_brachii`, etc.

Both tag types are included in the same arrays (`primary_muscles` and `secondary_muscles`).

---

## Dual Tag Examples

### Example 1: Barbell Bench Press
```json
{
  "primary_muscles": ["chest", "pectoralis_major", "pectoralis_minor"],
  "secondary_muscles": ["triceps", "front_delts", "triceps_brachii", "anterior_deltoid"]
}
```

### Example 2: Barbell Row
```json
{
  "primary_muscles": ["back", "latissimus_dorsi", "rhomboids", "middle_trapezius"],
  "secondary_muscles": ["biceps", "biceps_brachii", "brachialis"]
}
```

### Example 3: Barbell Squat
```json
{
  "primary_muscles": ["legs", "quads", "quadriceps", "rectus_femoris", "vastus_lateralis"],
  "secondary_muscles": ["glutes", "gluteus_maximus", "hamstrings"]
}
```

---

## Test Steps

### 1. Verify JSON File Structure
```bash
# Check file exists and has 2000 exercises
node -e "const data = require('./assets/seeds/exercise_knowledge_seed_en.json'); console.log('Count:', data.length); console.log('Sample:', JSON.stringify(data[0], null, 2));"
```

**Expected:**
- Count: 2000
- Sample exercise should have both English and anatomical tags in `primary_muscles` and `secondary_muscles`

### 2. Verify Asset Registration
- Check `pubspec.yaml` includes: `assets/seeds/exercise_knowledge_seed_en.json`
- Run `flutter pub get`

### 3. Test Import (Admin)
1. Log in as admin
2. Navigate to: Admin → Workout Knowledge Base
3. Go to "Exercises" tab
4. Verify import button shows tooltip: "Import Seed (EN) — 2000"
5. Click import button
6. Confirm in dialog (should mention "dual tags: English + anatomical")
7. Wait for import (10 batches of 200 = ~30-60 seconds)
8. Verify success message: "✅ Successfully imported 2000 exercises"
9. Verify exercises appear in list

### 4. Verify Dual Tags in Database
```sql
-- Check exercises have both English and anatomical tags
SELECT 
  name,
  primary_muscles,
  secondary_muscles
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1' 
  AND (
    primary_muscles && ARRAY['chest', 'pectoralis_major']::text[]
    OR primary_muscles && ARRAY['back', 'latissimus_dorsi']::text[]
  )
LIMIT 5;

-- Count exercises with anatomical tags
SELECT COUNT(*) 
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1'
  AND (
    primary_muscles && ARRAY['pectoralis_major', 'latissimus_dorsi', 'triceps_brachii', 'biceps_brachii', 'quadriceps', 'gluteus_maximus']::text[]
    OR secondary_muscles && ARRAY['pectoralis_major', 'latissimus_dorsi', 'triceps_brachii', 'biceps_brachii', 'quadriceps', 'gluteus_maximus']::text[]
  );
-- Expected: Should find many exercises with anatomical tags

-- Sample: Exercises with both English and anatomical tags
SELECT 
  name,
  primary_muscles,
  array_length(primary_muscles, 1) as primary_count
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1'
  AND array_length(primary_muscles, 1) >= 2  -- Should have at least English + anatomical
LIMIT 10;
```

### 5. Test Search with Anatomical Tags
1. After import, test search in admin screen:
   - Search "pectoralis" - should find chest exercises
   - Search "latissimus" - should find back exercises
   - Search "triceps_brachii" - should find tricep exercises
   - Search "quadriceps" - should find leg exercises
2. Verify filters work with both tag types

### 6. Test Idempotency
1. Run import once
2. Run import again immediately
3. Verify no errors
4. Verify no duplicates
5. Verify existing exercises weren't overwritten
6. Check that dual tags are preserved

---

## Verification Queries

```sql
-- Total imported
SELECT COUNT(*) FROM exercise_knowledge 
WHERE source = 'seed_pack_v1' AND language = 'en';
-- Expected: 2000

-- Exercises with dual tags (English + anatomical)
SELECT COUNT(*) 
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1'
  AND array_length(primary_muscles, 1) >= 2;
-- Expected: Most or all exercises should have 2+ tags

-- Tag distribution
SELECT 
  unnest(primary_muscles) AS tag,
  COUNT(*) AS count
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1'
GROUP BY tag
ORDER BY count DESC
LIMIT 20;
-- Should see both English tags (chest, back, etc.) and anatomical tags (pectoralis_major, etc.)

-- Check for exercises with only English tags (should be minimal)
SELECT COUNT(*) 
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1'
  AND NOT (
    primary_muscles && ARRAY[
      'pectoralis_major', 'latissimus_dorsi', 'triceps_brachii', 
      'biceps_brachii', 'quadriceps', 'hamstrings', 'gluteus_maximus',
      'gastrocnemius', 'deltoid', 'rectus_abdominis'
    ]::text[]
  );
-- Expected: Very few or zero (most should have anatomical tags)
```

---

## Expected Tag Coverage

**English Tags:**
- chest, back, lats, triceps, biceps, quads, hamstrings, glutes, calves, delts, core, shoulders, arms, legs

**Anatomical Tags:**
- pectoralis_major, pectoralis_minor
- latissimus_dorsi, rhomboids, middle_trapezius, lower_trapezius
- triceps_brachii, biceps_brachii, brachialis
- quadriceps, rectus_femoris, vastus_lateralis, vastus_medialis
- hamstrings, biceps_femoris, semitendinosus, semimembranosus
- gluteus_maximus, gluteus_medius, gluteus_minimus
- gastrocnemius, soleus
- anterior_deltoid, medial_deltoid, posterior_deltoid, deltoid
- rectus_abdominis, transverse_abdominis, obliques, erector_spinae

---

## Troubleshooting

### If exercises don't have anatomical tags:
1. Check generator script: `tooling/generate_exercise_seed.js`
2. Verify `addAnatomicalTags()` function is called
3. Regenerate JSON: `node tooling/generate_exercise_seed.js`
4. Re-import

### If search doesn't find anatomical tags:
1. Verify tags are in database (run verification SQL)
2. Check search uses array overlap: `primary_muscles && ARRAY['tag']`
3. Verify GIN index exists on `primary_muscles` column

---

**END OF TEST GUIDE**
