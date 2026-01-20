# Knowledge Base Seed - Mapping Documentation

**Date:** 2025-12-21  
**Status:** ✅ Migrations Created  
**Purpose:** Document the mapping from `exercises_library` to `exercise_knowledge` and intensifier seed data

---

## TASK A: Schema Confirmation

### `exercises_library` Table Structure
Based on migration `20251002000000_remove_mock_data_infrastructure.sql`:

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `name` | TEXT NOT NULL UNIQUE | Exercise name (English) |
| `name_ar` | TEXT | Arabic translation |
| `name_ku` | TEXT | Kurdish translation |
| `description` | TEXT | Exercise description |
| `muscle_group` | TEXT NOT NULL | Single muscle group (e.g., 'chest', 'back') |
| `secondary_muscles` | TEXT[] | Array of secondary muscle groups |
| `equipment_needed` | TEXT[] | Array of equipment required |
| `difficulty` | TEXT | CHECK constraint: 'beginner', 'intermediate', 'advanced' |
| `video_url` | TEXT | Video URL |
| `image_url` | TEXT | Image URL |
| `thumbnail_url` | TEXT | Thumbnail URL |
| `is_compound` | BOOLEAN | Compound vs isolation |
| `tags` | TEXT[] | Additional tags |
| `created_at` | TIMESTAMPTZ | Timestamp |
| `updated_at` | TIMESTAMPTZ | Timestamp |
| `created_by` | UUID | Creator user ID |

### `exercise_knowledge` Table Structure
Based on migration `20251221021539_workout_knowledge_base.sql`:

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `name` | TEXT NOT NULL | Exercise name |
| `aliases` | TEXT[] | Alternative names |
| `short_desc` | TEXT | Short description |
| `how_to` | TEXT | How-to instructions |
| `primary_muscles` | TEXT[] | Array of primary muscles |
| `secondary_muscles` | TEXT[] | Array of secondary muscles |
| `equipment` | TEXT[] | Array of equipment |
| `difficulty` | TEXT | Free text (no CHECK constraint) |
| `media` | JSONB | `{image_url, video_url, thumbnail_url}` |
| `source` | TEXT | Source identifier |
| `language` | TEXT DEFAULT 'en' | Language code |
| `status` | TEXT DEFAULT 'approved' | Status (approved/pending/rejected/draft) |
| `created_by` | UUID | Creator user ID |
| `created_at` | TIMESTAMPTZ | Timestamp |
| `updated_at` | TIMESTAMPTZ | Timestamp |

---

## TASK B: Mapping Plan

### `exercises_library` → `exercise_knowledge` Mapping

| Source Field | Target Field | Transformation Logic |
|--------------|-------------|---------------------|
| `name` | `name` | Direct copy |
| `description` | `short_desc` | Use if not null, otherwise generate from `muscle_group` |
| `muscle_group` | `primary_muscles` | Convert single value to array: `ARRAY[muscle_group]` |
| `secondary_muscles` | `secondary_muscles` | Direct copy (already array) |
| `equipment_needed` | `equipment` | Direct copy (already array) |
| `difficulty` | `difficulty` | Direct copy (remove CHECK constraint, keep as free text) |
| `{image_url, video_url, thumbnail_url}` | `media` | Build JSONB: `jsonb_build_object('image_url', ..., 'video_url', ..., 'thumbnail_url', ...)` |
| N/A | `source` | Set to `'imported_from_exercises_library'` |
| N/A | `language` | Set to `'en'` |
| N/A | `status` | Set to `'approved'` |
| N/A | `created_by` | Set to `NULL` (system import) |

### Generated `short_desc` Logic

If `description` is NULL or empty, generate:
```
'A [compound ]exercise targeting {muscle_group}[ and {first 1-2 secondary_muscles}].'
```

Example:
- Input: `muscle_group='chest'`, `is_compound=true`, `secondary_muscles=['triceps', 'shoulders']`
- Output: `'A compound exercise targeting chest and triceps, shoulders.'`

---

## TASK C: Unique Indexes

### Index 1: `exercise_knowledge`
```sql
CREATE UNIQUE INDEX idx_exercise_knowledge_unique_name_language
  ON public.exercise_knowledge (LOWER(name), language);
```

**Purpose:** Enable `ON CONFLICT (LOWER(name), language)` for idempotent upserts.

### Index 2: `intensifier_knowledge`
```sql
CREATE UNIQUE INDEX idx_intensifier_knowledge_unique_name_language
  ON public.intensifier_knowledge (LOWER(name), language);
```

**Purpose:** Enable `ON CONFLICT (LOWER(name), language)` for idempotent upserts.

---

## TASK D: Intensifier Seed Data

### Intensifiers Seeded (30 total)

1. **Rest-Pause** - High fatigue, strength/hypertrophy
2. **Myo-Reps** - High fatigue, hypertrophy/pump
3. **Drop Set** - Very high fatigue, hypertrophy
4. **Double Drop Set** - Very high fatigue, hypertrophy
5. **Mechanical Advantage Drop Set** - High fatigue, hypertrophy
6. **Cluster Sets** - Medium fatigue, strength/power
7. **EMOM** - Medium fatigue, conditioning
8. **Density Block** - Medium fatigue, conditioning
9. **1.5 Reps** - High fatigue, hypertrophy
10. **Lengthened Partials** - Medium fatigue, hypertrophy
11. **Paused Reps** - Medium fatigue, strength
12. **Slow Eccentrics** - High fatigue, hypertrophy
13. **Tempo Sets** - Medium fatigue, hypertrophy
14. **Yielding Isometric** - Medium fatigue, strength
15. **Overcoming Isometric** - Low fatigue, strength/power
16. **Iso-Hold at Stretch** - Medium fatigue, hypertrophy
17. **Pre-Exhaust** - High fatigue, hypertrophy
18. **Post-Exhaust** - High fatigue, hypertrophy
19. **Superset** - Medium fatigue, hypertrophy
20. **Antagonist Superset** - Low fatigue, hypertrophy
21. **Triset** - High fatigue, hypertrophy
22. **Giant Set** - Very high fatigue, hypertrophy
23. **Circuit** - Medium fatigue, conditioning
24. **Blood Flow Restriction (BFR)** - Low fatigue, hypertrophy
25. **Partial Reps (Top)** - Low fatigue, strength
26. **Partial Reps (Bottom)** - Medium fatigue, hypertrophy
27. **Cheat Reps (Controlled)** - Medium fatigue, hypertrophy
28. **Forced Reps** - High fatigue, hypertrophy
29. **Negatives** - High fatigue, strength
30. **Wave Loading** - Medium fatigue, strength
31. **Back-Off Sets** - Medium fatigue, strength

### Intensifier JSON Rules Structure

Each intensifier includes `intensity_rules` JSONB with method-specific parameters:

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

---

## TASK E: Exercise-Intensifier Links

### Link Patterns

| Exercise Pattern | Intensifiers |
|-----------------|--------------|
| Bench Press variants | Rest-Pause, Drop Set, Paused Reps, Tempo Sets |
| Squat variants | Paused Reps, Tempo Sets, Cluster Sets, Slow Eccentrics |
| Lat Pulldown variants | Myo-Reps, Drop Set, Rest-Pause |
| Deadlift variants | Paused Reps, Tempo Sets, Cluster Sets |
| Shoulder Press variants | Rest-Pause, Drop Set, Paused Reps |
| Row variants | Rest-Pause, Myo-Reps, Tempo Sets |
| Bicep Curl variants | Drop Set, Myo-Reps, Rest-Pause, Cheat Reps |
| Tricep Extension variants | Drop Set, Myo-Reps, Rest-Pause |
| Leg Press variants | Rest-Pause, Drop Set, Cluster Sets |
| Leg Extension variants | Myo-Reps, Drop Set, Pre-Exhaust |

**Total Links:** ~20-50 (depends on exercise matches in knowledge base)

---

## Idempotency Strategy

### Exercise Knowledge
- Uses `ON CONFLICT (LOWER(name), language) DO UPDATE`
- Only updates NULL/empty fields
- Preserves existing rich content (`short_desc`, `how_to`, `media`)

### Intensifier Knowledge
- Uses `ON CONFLICT (LOWER(name), language) DO UPDATE`
- Only updates NULL/empty fields
- Preserves existing content

### Exercise-Intensifier Links
- Uses `ON CONFLICT (exercise_id, intensifier_id) DO NOTHING`
- Safe to run multiple times

---

## Migration Files Created

1. **`20251221122033_knowledge_seed_unique_indexes.sql`**
   - Creates unique indexes for idempotent upserts

2. **`20251221122034_seed_exercise_knowledge_from_library.sql`**
   - Imports exercises from `exercises_library`
   - Idempotent with ON CONFLICT

3. **`20251221122035_seed_intensifier_knowledge.sql`**
   - Seeds 30+ intensifiers with full descriptions
   - Idempotent with ON CONFLICT

4. **`20251221122036_seed_exercise_intensifier_links.sql`**
   - Creates starter links between exercises and intensifiers
   - Idempotent with ON CONFLICT

5. **`20251221122037_verify_knowledge_seed.sql`**
   - Verification queries for counts and samples

---

## Expected Results

After running all migrations:

- **Exercise Knowledge:** 500-2000+ exercises (depends on `exercises_library` size)
- **Intensifier Knowledge:** 30+ intensifiers
- **Exercise-Intensifier Links:** 20-50 links
- **All entries:** `status='approved'`, `language='en'`, `source='imported_from_exercises_library'` (for exercises)

---

## Safety Guarantees

✅ **No destructive operations**  
✅ **No modifications to existing tables** (`exercises_library`, workout plan tables)  
✅ **No RLS changes**  
✅ **Idempotent** (safe to run multiple times)  
✅ **Additive only** (only adds unique indexes, no deletions)

---

**END OF MAPPING DOCUMENTATION**
