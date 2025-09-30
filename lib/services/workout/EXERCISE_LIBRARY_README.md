# Exercise Library System

Comprehensive exercise management infrastructure with 200+ exercises, multilingual support (EN/AR/KU), and AI integration.

## Overview

The Exercise Library System provides:
- **200+ Common Exercises** across all categories
- **Multilingual Support** (English, Arabic, Kurdish)
- **Advanced Search** with multiple filters
- **Custom Exercise Creation** for coaches
- **Exercise Alternatives** with similarity scoring
- **Media Management** (videos, images, thumbnails)
- **Favorites System** for quick access
- **AI Integration** for smart suggestions

---

## Database Schema

### Tables Created (in migration 0004)

#### 1. `exercise_library`
Main exercise database with public and coach-created exercises.

**Columns**:
- `id` - UUID primary key
- `name`, `name_ar`, `name_ku` - Exercise names (multilingual)
- `category` - Type: compound, isolation, cardio, stretching, plyometric, olympic
- `primary_muscle_groups` - Array of primary muscles worked
- `secondary_muscle_groups` - Array of secondary muscles
- `equipment_needed` - Array of required equipment
- `difficulty_level` - beginner, intermediate, advanced, expert
- `instructions`, `instructions_ar`, `instructions_ku` - Exercise instructions
- `video_url`, `thumbnail_url` - Media URLs
- `created_by` - User ID (NULL for public exercises)
- `is_public` - Boolean for public/private
- `usage_count` - Analytics counter
- `search_vector` - Full-text search (auto-generated)

**Indexes**:
- GIN index on `search_vector` for fast full-text search
- GIN index on `primary_muscle_groups` for array queries
- GIN index on `equipment_needed`
- B-tree indexes on category, difficulty, public status

#### 2. `exercise_tags`
Flexible tagging system for categorization.

**Columns**:
- `exercise_id` - References exercise_library
- `tag` - Tag string (e.g., "powerlifting", "beginner_friendly")

#### 3. `exercise_media`
Multiple media files per exercise (different angles).

**Columns**:
- `exercise_id` - References exercise_library
- `media_type` - video, image, gif
- `url` - Media URL
- `angle` - front, side, top, close-up
- `description` - Optional description
- `order_index` - Display order

#### 4. `exercise_favorites`
User favorites for quick access.

**Columns**:
- `user_id` - References auth.users
- `exercise_id` - References exercise_library

#### 5. `exercise_alternatives`
Exercise substitutions with similarity scoring.

**Columns**:
- `exercise_id` - Original exercise
- `alternative_id` - Alternative exercise
- `reason` - equipment, difficulty, injury, preference
- `similarity_score` - 0.0 to 1.0

---

## Database Functions

### `search_exercises()`
Advanced search with multiple filters.

**Parameters**:
- `search_query` - Full-text search term
- `muscle_groups_filter` - Array of muscle groups
- `equipment_filter` - Array of equipment
- `difficulty_filter` - Difficulty level
- `category_filter` - Exercise category
- `include_custom` - Include user's custom exercises
- `user_id` - Current user ID

**Returns**: Table of exercises with `is_favorite` boolean

**Example**:
```sql
SELECT * FROM search_exercises(
  search_query := 'bench press',
  muscle_groups_filter := ARRAY['chest'],
  equipment_filter := ARRAY['barbell'],
  difficulty_filter := 'intermediate',
  user_id := 'user-uuid'
);
```

### `get_exercise_alternatives()`
Get alternative exercises with similarity scoring.

**Parameters**:
- `p_exercise_id` - Exercise ID
- `p_reason` - Optional filter by reason

**Returns**: Table of alternative exercises with similarity scores

---

## Service Layer (ExerciseLibraryService)

### Search and Retrieval

```dart
// Search exercises
final exercises = await service.searchExercises(
  query: 'bench press',
  muscleGroups: ['chest'],
  equipment: ['barbell', 'dumbbell'],
  difficulty: 'intermediate',
  category: 'compound',
);

// Get exercise details
final exercise = await service.getExerciseDetails(exerciseId);

// Get popular exercises
final popular = await service.fetchPopularExercises(
  muscleGroup: 'chest',
  limit: 20,
);

// Get alternatives
final alternatives = await service.suggestAlternatives(
  exerciseId,
  reason: 'equipment',
);
```

### CRUD Operations

```dart
// Create custom exercise
final exerciseId = await service.createCustomExercise(
  ExerciseLibraryItem(
    name: 'My Custom Exercise',
    nameAr: 'تمريني المخصص',
    nameKu: 'ڕاهێنانی تایبەتی من',
    category: 'compound',
    primaryMuscleGroups: ['chest', 'shoulders'],
    equipmentNeeded: ['dumbbell'],
    difficulty Level: 'intermediate',
    instructions: 'Detailed instructions...',
  ),
);

// Update exercise
await service.updateExercise(exercise);

// Delete exercise
await service.deleteExercise(exerciseId);
```

### Media Management

```dart
// Upload video
final videoUrl = await service.uploadExerciseVideo(
  exerciseId,
  '/path/to/video.mp4',
);

// Upload thumbnail
final thumbnailUrl = await service.uploadExerciseThumbnail(
  exerciseId,
  '/path/to/image.jpg',
);

// Add additional media (different angles)
await service.addExerciseMedia(
  exerciseId: exerciseId,
  mediaType: 'video',
  url: videoUrl,
  angle: 'side',
  description: 'Side view demonstration',
);

// Get all media
final mediaList = await service.getExerciseMedia(exerciseId);
```

### Favorites

```dart
// Toggle favorite
await service.toggleFavorite(exerciseId);

// Get favorites
final favorites = await service.getFavorites();

// Check if favorited
final isFav = await service.isFavorite(exerciseId);
```

### Alternatives

```dart
// Add alternative
await service.addAlternative(
  exerciseId: benchPressId,
  alternativeId: dumbbellPressId,
  reason: 'equipment',
  similarityScore: 0.95,
);

// Remove alternative
await service.removeAlternative(
  exerciseId: exerciseId,
  alternativeId: alternativeId,
);
```

---

## Seed Data

### Exercise Categories Included

**200+ exercises across all categories**:

1. **Compound Movements** (50+ exercises)
   - Chest: Bench press variations, dips
   - Back: Deadlifts, rows, pull-ups
   - Legs: Squats, lunges, leg press
   - Shoulders: Overhead press variations

2. **Isolation Exercises** (80+ exercises)
   - Chest: Flys, pec deck
   - Back: Face pulls, pullovers
   - Shoulders: Raises (lateral, front, rear)
   - Biceps: Curls (barbell, dumbbell, hammer, preacher)
   - Triceps: Pushdowns, extensions, dips
   - Legs: Extensions, curls
   - Calves: Raises (standing, seated)
   - Core: Crunches, planks, leg raises

3. **Olympic Lifts** (5 exercises)
   - Clean and Jerk, Snatch, Clean, Power Clean, Hang Clean

4. **Cardio** (10+ exercises)
   - Running, Cycling, Rowing, Jump Rope, Burpees, etc.

5. **Stretching & Mobility** (10+ exercises)
   - Quad stretch, Hamstring stretch, Yoga poses, etc.

6. **Functional/CrossFit** (15+ exercises)
   - Kettlebell swings, Turkish get-ups, Farmer walks, Thrusters, etc.

### Multilingual Support

All exercises include:
- **English** (`name`, `instructions`)
- **Arabic** (`name_ar`, `instructions_ar`)
- **Kurdish** (`name_ku`, `instructions_ku`)

Example:
```
EN: Barbell Bench Press
AR: ضغط البار
KU: بەرز کردنەوەی بار
```

### Exercise Alternatives

Pre-configured alternatives for common substitutions:
- Barbell Bench Press → Dumbbell Bench Press (equipment, 0.95)
- Barbell Bench Press → Push-up (equipment, 0.75)
- Barbell Squat → Leg Press (difficulty, 0.80)
- Deadlift → Romanian Deadlift (difficulty, 0.90)
- Pull-up → Lat Pulldown (difficulty, 0.85)

### Exercise Tags

Pre-configured tags for filtering:
- `compound` - Major compound movements
- `big3` - Bench, Squat, Deadlift
- `powerlifting` - Powerlifting movements
- `olympic` - Olympic lifts
- `beginner_friendly` - Suitable for beginners
- `no_equipment` - Bodyweight exercises
- `core_stability` - Core engagement

---

## AI Integration

### WorkoutAI Service Integration

The exercise library integrates with `WorkoutAI` for intelligent suggestions:

```dart
// In WorkoutAI service
static Future<List<Exercise>> suggestExercisesFromLibrary({
  required List<String> muscleGroups,
  required List<String> availableEquipment,
  required String experienceLevel,
  String? excludeExerciseId,
}) async {
  final service = ExerciseLibraryService();

  // Map experience level to difficulty
  final difficulty = experienceLevel == 'beginner'
    ? 'beginner'
    : experienceLevel == 'advanced'
      ? 'advanced'
      : 'intermediate';

  // Search library
  final exercises = await service.searchExercises(
    muscleGroups: muscleGroups,
    equipment: availableEquipment,
    difficulty: difficulty,
  );

  // Convert to Exercise models
  return exercises.map((lib) => Exercise(
    name: lib.name,
    // ... map other fields
  )).toList();
}
```

### Auto-populate Exercise Details

When coach types exercise name, auto-fill from library:

```dart
Future<Exercise?> autofillExerciseDetails(String exerciseName) async {
  final service = ExerciseLibraryService();

  final results = await service.searchExercises(query: exerciseName);

  if (results.isEmpty) return null;

  final lib = results.first;
  return Exercise(
    name: lib.name,
    sets: _getSuggestedSets(lib.category),
    reps: _getSuggestedReps(lib.category),
    notes: lib.instructions,
    // ... other defaults
  );
}
```

### Smart Alternative Suggestions

When client requests substitution:

```dart
Future<List<Exercise>> suggestAlternatives({
  required String exerciseId,
  required String reason, // 'equipment', 'injury', 'difficulty'
}) async {
  final service = ExerciseLibraryService();

  final alternatives = await service.suggestAlternatives(
    exerciseId,
    reason: reason,
  );

  return alternatives.map((alt) => Exercise(
    name: alt.name,
    // ... map fields
  )).toList();
}
```

---

## Row Level Security (RLS)

All tables have RLS enabled with proper policies:

### exercise_library
- ✅ **Public exercises** viewable by all
- ✅ **Custom exercises** viewable only by creator
- ✅ **Insert** - Any authenticated user can create custom exercises
- ✅ **Update/Delete** - Only creator can modify their exercises

### exercise_tags
- ✅ Follows exercise visibility
- ✅ Creator can manage tags

### exercise_media
- ✅ Follows exercise visibility
- ✅ Creator can manage media

### exercise_favorites
- ✅ Users can only view/manage their own favorites

### exercise_alternatives
- ✅ Follows exercise visibility
- ✅ Creator can manage alternatives

---

## Usage Examples

### Example 1: Browse by Muscle Group

```dart
final service = ExerciseLibraryService();

final chestExercises = await service.searchExercises(
  muscleGroups: ['chest'],
);

// Display in UI
for (final exercise in chestExercises) {
  print('${exercise.name} (${exercise.difficulty Level})');
  print('Equipment: ${exercise.equipmentNeeded.join(", ")}');
}
```

### Example 2: Create Custom Exercise

```dart
final newExercise = ExerciseLibraryItem(
  name: 'Cable Chest Press',
  nameAr: 'ضغط صدر بالكابل',
  nameKu: 'پرێسی سنگ بە کەیبڵ',
  category: 'compound',
  primaryMuscleGroups: ['chest'],
  secondaryMuscleGroups: ['shoulders', 'triceps'],
  equipmentNeeded: ['cable'],
  difficultyLevel: 'intermediate',
  instructions: 'Stand between cable stacks, press handles forward...',
  tags: ['chest', 'push', 'cable'],
);

final exerciseId = await service.createCustomExercise(newExercise);

// Upload demo video
await service.uploadExerciseVideo(exerciseId, videoPath);
```

### Example 3: Search with Multiple Filters

```dart
final exercises = await service.searchExercises(
  query: 'press',
  muscleGroups: ['chest', 'shoulders'],
  equipment: ['dumbbell'],
  difficulty: 'beginner',
  category: 'compound',
);

// Results: Dumbbell Bench Press, Dumbbell Shoulder Press, etc.
```

### Example 4: Get Alternatives for Injury

```dart
// Client has shoulder pain, can't do overhead press
final alternatives = await service.suggestAlternatives(
  overheadPressId,
  reason: 'injury',
);

// Results: Landmine Press, Arnold Press, etc.
```

---

## Running Migrations

### 1. Apply Migration

The exercise library tables are part of migration 0004:

```bash
# If using Supabase CLI
supabase db reset

# Or apply migration manually
psql -h your-host -U your-user -d your-db -f supabase/migrations/0004_workout_system_v2.sql
```

### 2. Load Seed Data

After migration, load the exercise library:

```bash
psql -h your-host -U your-user -d your-db -f supabase/seed/exercise_library_seed.sql
```

This will insert:
- 200+ exercises with multilingual names
- Exercise alternatives with similarity scores
- Exercise tags for categorization

---

## Next Steps

### UI Screen Implementation

Create `ExerciseLibraryScreen.dart` with:
1. **Browse Tab**
   - Muscle group grid selector
   - Exercise list with cards
   - Filter drawer (equipment, difficulty, category)

2. **Search Tab**
   - Search bar with debouncing
   - Filter chips
   - Results list

3. **Favorites Tab**
   - User's favorited exercises
   - Quick add to workout

4. **Custom Tab** (Coaches only)
   - Create custom exercise button
   - List of coach's custom exercises
   - Edit/delete actions

### Integration with Plan Builder

In `CoachPlanBuilderScreen`:
```dart
// Add exercise button
onPressed: () async {
  final selectedExercise = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExerciseLibraryScreen(
        selectionMode: true,
      ),
    ),
  );

  if (selectedExercise != null) {
    addExerciseToDay(selectedExercise);
  }
}
```

### Integration with Client Portal

In `WorkoutPlanViewerScreen`:
```dart
// Request substitution
onSubstitutionRequest: () async {
  final alternatives = await service.suggestAlternatives(
    exercise.id,
    reason: 'equipment',
  );

  showAlternativesDialog(alternatives);
}
```

---

## Testing Checklist

- [ ] Migration runs without errors
- [ ] Seed data loads successfully
- [ ] Search function returns correct results
- [ ] Full-text search works (try "bench press")
- [ ] Muscle group filter works
- [ ] Equipment filter works
- [ ] Difficulty filter works
- [ ] Category filter works
- [ ] Custom exercise creation works
- [ ] Custom exercise update/delete works
- [ ] Media upload works
- [ ] Favorites toggle works
- [ ] Alternatives query works
- [ ] RLS policies enforce security
- [ ] Multilingual names display correctly
- [ ] Usage count increments when exercise added to workout

---

## Performance Considerations

1. **Full-Text Search**: Uses GIN index on `search_vector` for fast searches
2. **Array Queries**: GIN indexes on muscle groups and equipment arrays
3. **Favorites**: Indexed on user_id for quick retrieval
4. **Usage Count**: Automatically incremented via trigger
5. **Media Storage**: Uses Supabase Storage with CDN

---

## Future Enhancements

1. **Exercise Database Expansion**
   - Add more exercises (target: 500+)
   - Add detailed instructions with step-by-step breakdown
   - Add common mistakes and form cues

2. **Video Library**
   - Partner with content creators
   - Multiple camera angles for each exercise
   - Slow-motion form videos

3. **AI Enhancements**
   - Computer vision for form analysis
   - Automatic exercise recognition from uploaded videos
   - Personalized exercise recommendations

4. **Community Features**
   - User-submitted exercises (moderation required)
   - Exercise ratings and reviews
   - Form tips from experienced users

5. **Integration Features**
   - Exercise equipment shopping links
   - Gym equipment availability checker
   - Exercise of the day notifications

---

## Support

For questions or issues:
1. Check this documentation
2. Review migration file: `supabase/migrations/0004_workout_system_v2.sql`
3. Review seed data: `supabase/seed/exercise_library_seed.sql`
4. Test service methods in `exercise_library_service.dart`