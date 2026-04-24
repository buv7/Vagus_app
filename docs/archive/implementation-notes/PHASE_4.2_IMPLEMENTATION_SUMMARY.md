# Phase 4.2: Auto Intensifier Suggestions + Store knowledge_exercise_id

## Implementation Complete ✅

### Summary
This implementation adds automatic intensifier recommendations when selecting exercises from the Knowledge base, and ensures `knowledge_exercise_id` is properly stored and preserved throughout the exercise lifecycle.

---

## Changes Made

### 1. **exercise_picker_dialog.dart** ✅
**Status:** Already correctly implemented - no changes needed

**Functionality:**
- When selecting an exercise from Knowledge mode, stores both:
  - `knowledge_exercise_id` (UUID from `exercise_knowledge.id`)
  - `knowledge_short_desc`
- Stores data in `Exercise.notes` as JSON:
  ```json
  {
    "knowledge_exercise_id": "<uuid>",
    "knowledge_short_desc": "..."
  }
  ```

### 2. **advanced_exercise_editor_dialog.dart** ✅
**Changes:**
- ✅ Fixed `_buildNotesString()` to preserve `knowledge_exercise_id` when saving
- ✅ Implemented `_loadRecommendedIntensifiers()` method
- ✅ Added `_generateHeuristicIntensifiers()` for rule-based suggestions
- ✅ Added `_buildRecommendedIntensifiersSection()` UI component
- ✅ Added `_applyIntensifier()` method for applying suggestions

**New Features:**

#### Recommended Intensifiers Section
- **Location:** Methods tab, above the manual intensifier picker
- **Display Logic:**
  - Only shows if `knowledge_exercise_id` exists in exercise notes
  - Loads recommendations when editor opens (if `knowledge_exercise_id` present)

#### Recommendation Priority:
1. **Database Links (Highest Priority):**
   - If `exercise_intensifier_links` has rows for this `knowledge_exercise_id`:
     - Fetches linked intensifiers via `getLinkedIntensifiersForExercise()`
     - Shows top 8 linked intensifiers

2. **Heuristic Suggestions (Fallback):**
   - If no database links exist, generates suggestions based on:
     - Movement pattern (push/pull/squat/hinge/carry/rotation/locomotion)
     - Equipment (machine vs free weights)
     - Difficulty level
   - Filters high-fatigue intensifiers for free-weight compounds (max 1-2)

#### Heuristic Rules:
- **Push compounds:** Rest-Pause, Drop Set, Paused Reps, Tempo, Lengthened Partials, 1.5 Reps
- **Pull/back:** Myo-Reps, Drop Set, Rest-Pause, Lengthened Partials, Slow Eccentric
- **Squat/hinge:** Paused Reps, Tempo, Cluster Sets, Back-off Sets, Wave Loading
- **Machines/isolation:** Myo-Reps, Drop Set, Rest-Pause, Partials, Iso-holds at stretch

#### UI Features:
- Each recommendation card shows:
  - Intensifier name
  - Short description (1-2 lines)
  - Fatigue cost chip (High/Medium/Low with color coding)
  - "Apply" button (changes to "Applied" when selected)
- Cards are color-coded when selected
- Limits to top 5-8 suggestions

### 3. **workout_knowledge_service.dart** ✅
**Status:** Already has required methods - no changes needed

**Existing Methods:**
- ✅ `getExerciseKnowledgeById(String id, {String language='en'})` - Fetches exercise knowledge
- ✅ `getLinkedIntensifiersForExercise(String exerciseId, {String language='en'})` - Fetches linked intensifiers

---

## Data Storage Format

### Exercise.notes JSON Structure
```json
{
  "knowledge_exercise_id": "<uuid-from-exercise_knowledge.id>",
  "knowledge_short_desc": "Exercise description from knowledge base",
  "intensifier": "Rest-Pause",
  "intensifier_id": "<uuid-from-intensifier_knowledge.id>",
  "user_notes": "User's custom notes here"
}
```

### Backward Compatibility
- ✅ If `Exercise.notes` is plain text, it's preserved as `user_notes` when converting to JSON
- ✅ If JSON exists, all existing keys are preserved
- ✅ Plain text notes continue to work as before

---

## How It Works

### Exercise Selection Flow
1. User opens exercise picker (Knowledge mode default)
2. User searches and selects exercise from `exercise_knowledge`
3. System stores `knowledge_exercise_id` + `knowledge_short_desc` in notes JSON
4. Exercise is added to workout plan

### Exercise Editing Flow
1. User opens exercise editor
2. System parses `Exercise.notes` JSON:
   - Extracts `knowledge_exercise_id`
   - Extracts `knowledge_short_desc` (shows in collapsible info section)
   - Extracts `intensifier` and `intensifier_id` (if set)
   - Extracts `user_notes` (populates notes field)
3. If `knowledge_exercise_id` exists:
   - Loads recommended intensifiers (database links first, then heuristics)
   - Displays "Recommended Intensifiers" section in Methods tab
4. User can:
   - Click "Apply" on any recommendation (sets `intensifier` + `intensifier_id`)
   - Or manually select intensifier via picker
   - Edit user notes separately
5. On save, all knowledge data is preserved in notes JSON

---

## Testing Checklist

- [ ] Select exercise from Knowledge mode → verify `knowledge_exercise_id` stored
- [ ] Open exercise editor → verify recommendations load (if `knowledge_exercise_id` exists)
- [ ] Apply intensifier suggestion → verify `intensifier` and `intensifier_id` set
- [ ] Save exercise → verify all knowledge data preserved in notes JSON
- [ ] Edit exercise with plain text notes → verify converted to JSON with `user_notes`
- [ ] Edit exercise with existing JSON → verify all keys preserved
- [ ] Test with exercise that has database links → verify linked intensifiers shown first
- [ ] Test with exercise without links → verify heuristic suggestions shown
- [ ] Test different movement patterns → verify appropriate suggestions

---

## Files Modified

1. `lib/widgets/workout/advanced_exercise_editor_dialog.dart`
   - Added `_loadRecommendedIntensifiers()` method
   - Added `_generateHeuristicIntensifiers()` method
   - Added `_buildRecommendedIntensifiersSection()` UI component
   - Added `_applyIntensifier()` method
   - Fixed `_buildNotesString()` to preserve `knowledge_exercise_id`
   - Added `foundation` import for `debugPrint`

2. `lib/widgets/workout/exercise_picker_dialog.dart`
   - ✅ No changes needed (already correct)

3. `lib/services/workout/workout_knowledge_service.dart`
   - ✅ No changes needed (methods already exist)

---

## Notes

- **No database schema changes** - uses existing tables
- **No breaking changes** - fully backward compatible
- **Minimal refactoring** - only patched existing integration files
- **Safe implementation** - all new logic isolated in dialog file
- **Graceful error handling** - returns empty list on errors, doesn't crash

---

## Next Steps (Optional Future Enhancements)

1. Add caching for intensifier recommendations
2. Add user preference learning (which intensifiers user applies most)
3. Add intensifier effectiveness tracking
4. Add more sophisticated heuristics based on user history
5. Add intensifier combinations (e.g., "Rest-Pause + Drop Set")
