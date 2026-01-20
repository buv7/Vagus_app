# Exercise Seed Import Guide

**Date:** 2025-12-21  
**Status:** ✅ Implementation Complete  
**Feature:** Admin Import Button for Exercise Knowledge Seed

---

## Overview

Admin-only import functionality to seed `exercise_knowledge` table from a local JSON file containing 2000 exercises.

**Key Features:**
- ✅ 2000 exercises in JSON format
- ✅ Admin-only import button
- ✅ Idempotent upsert (safe to run multiple times)
- ✅ Progress indication
- ✅ Only fills missing fields (preserves existing data)

---

## Files Created/Modified

### 1. `assets/seeds/exercise_knowledge_seed_en.json`
**Purpose:** Seed data file with 2000 exercises

**Format:**
```json
[
  {
    "name": "Barbell Bench Press",
    "aliases": ["Bench Press", "BB Bench"],
    "short_desc": "Barbell pressing exercise targeting the chest.",
    "how_to": "Maintain proper form, control the weight through full range of motion...",
    "cues": ["Keep core engaged", "Control the weight", "Full range of motion"],
    "common_mistakes": ["Arching back excessively", "Flaring elbows", "Bouncing weight"],
    "primary_muscles": ["chest"],
    "secondary_muscles": ["triceps", "front_delts"],
    "equipment": ["barbell", "bench"],
    "movement_pattern": "push",
    "difficulty": "intermediate",
    "contraindications": [],
    "media": {},
    "source": "seed_pack_v1",
    "language": "en",
    "status": "approved"
  }
]
```

**Content Coverage:**
- All major muscle groups: chest, back, legs, shoulders, arms, core
- Equipment variations: barbell, dumbbells, cables, machine, bodyweight, bands
- Movement patterns: push, pull, squat, hinge, core, rotation
- Difficulty levels: beginner, intermediate, advanced

---

### 2. `pubspec.yaml`
**Modified:** Added asset path
```yaml
assets:
  - assets/seeds/exercise_knowledge_seed_en.json
```

---

### 3. `lib/services/workout/workout_knowledge_service.dart`
**Added Method:** `upsertExerciseKnowledgeBatch()`

**Functionality:**
- Processes exercises in batches of 50
- For each exercise:
  - Checks if exists (by name + language, case-insensitive)
  - If exists: Updates only empty/null fields
  - If new: Inserts
- Returns count of imported/updated exercises
- Handles errors gracefully

**Idempotency:**
- Uses unique index `(LOWER(name), language)` for conflict detection
- Only updates empty fields, never overwrites existing content
- Safe to run multiple times

---

### 4. `lib/screens/admin/workout_knowledge_admin_screen.dart`
**Added:**
- Import button (admin-only, next to search bar)
- `_importSeedExercises()` method
- Progress dialogs
- Error handling

**UI Flow:**
1. Admin clicks import button (file_download icon)
2. Confirmation dialog appears
3. Loading dialog shows "Loading seed file..."
4. Progress dialog shows "Importing Exercises..."
5. Success snackbar: "✅ Successfully imported X exercises"
6. Exercises list refreshes automatically

---

## Test Steps

### Prerequisites
1. User must be logged in as admin
2. `exercise_knowledge` table must exist (from base migration)
3. Unique index must exist (from seed migrations)

### Test 1: Basic Import
1. Navigate to Admin → Workout Knowledge Base
2. Go to "Exercises" tab
3. Verify import button (📥) appears next to search bar (admin only)
4. Click import button
5. Confirm in dialog
6. Wait for import to complete
7. Verify success message shows "✅ Successfully imported 2000 exercises"
8. Verify exercises appear in list
9. Search for "Bench Press" - should find exercises

### Test 2: Idempotency (Run Twice)
1. Run import once (from Test 1)
2. Wait for completion
3. Run import again (click button, confirm)
4. Verify no errors occur
5. Verify success message (may show same count or slightly less if some already existed)
6. Verify no duplicate exercises created
7. Check existing exercises weren't overwritten (e.g., if you manually edited one)

### Test 3: Partial Field Update
1. Manually create/edit an exercise with empty `short_desc`
2. Run import
3. Verify the exercise now has `short_desc` filled
4. Verify other manually-added fields weren't overwritten

### Test 4: Non-Admin Access
1. Log in as coach (non-admin)
2. Navigate to Workout Knowledge Base
3. Verify import button does NOT appear
4. (If button appears due to bug) Click it - should show "Admin access required"

### Test 5: Error Handling
1. Temporarily rename/delete JSON file
2. Try to import
3. Verify error message appears
4. Restore file and verify import works

### Test 6: Search After Import
1. After import, test search functionality:
   - Search "chest" - should find chest exercises
   - Search "barbell" - should find barbell exercises
   - Search "push" - should find push pattern exercises
2. Verify filters work (muscle groups, equipment)

---

## Verification SQL

```sql
-- Count imported exercises
SELECT COUNT(*) FROM exercise_knowledge 
WHERE source = 'seed_pack_v1' AND language = 'en';

-- Check for duplicates (should be 0)
SELECT LOWER(name), language, COUNT(*) 
FROM exercise_knowledge 
GROUP BY LOWER(name), language 
HAVING COUNT(*) > 1;

-- Sample exercises
SELECT name, primary_muscles, equipment, movement_pattern 
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1' 
LIMIT 10;

-- Exercises by muscle group
SELECT unnest(primary_muscles) AS muscle, COUNT(*) 
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1' 
GROUP BY muscle 
ORDER BY count DESC;

-- Exercises by equipment
SELECT unnest(equipment) AS eq, COUNT(*) 
FROM exercise_knowledge 
WHERE source = 'seed_pack_v1' 
GROUP BY eq 
ORDER BY count DESC;
```

---

## Troubleshooting

### Import button doesn't appear
- Check user is admin: `SELECT role FROM profiles WHERE id = auth.uid();`
- Check `_isAdmin` is true in screen state
- Verify button is in exercises tab (not intensifiers tab)

### Import fails with "file not found"
- Verify `pubspec.yaml` has asset path: `assets/seeds/exercise_knowledge_seed_en.json`
- Run `flutter pub get`
- Verify file exists at correct path
- Check file permissions

### Import shows 0 exercises
- Check JSON file is valid JSON
- Check JSON structure matches expected format
- Check service method logs for errors
- Verify database connection

### Duplicates created
- Check unique index exists: `\d exercise_knowledge` in psql
- Verify index name: `idx_exercise_knowledge_unique_name_language`
- Re-run migration if index missing

### Existing exercises overwritten
- This should NOT happen (only empty fields updated)
- Check service method logic
- Verify `updateData` only contains fields that were empty

---

## Performance Notes

- **Batch size:** 50 exercises per batch (configurable in service)
- **Expected time:** ~30-60 seconds for 2000 exercises (depends on network/DB)
- **Memory:** JSON file is ~2-3MB, loaded entirely into memory
- **Database:** Uses individual upserts (could be optimized with bulk upsert if Supabase supports it)

---

## Future Enhancements

1. **Progress bar:** Real-time progress updates in dialog
2. **Bulk upsert:** Use Supabase bulk operations if available
3. **Arabic/Kurdish seeds:** Add `exercise_knowledge_seed_ar.json`, `exercise_knowledge_seed_ku.json`
4. **Selective import:** Allow admin to choose which categories to import
5. **Import history:** Track when imports were run

---

**END OF GUIDE**
