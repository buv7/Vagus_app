# Workout Plan Builder Refactor - Modular Architecture

## Overview
The CoachPlanBuilderScreen has been refactored into a modular, production-quality implementation following the NutritionPlanBuilder patterns.

## Main File
- **`coach_plan_builder_screen_refactored.dart`** - Core screen with state management, navigation, and orchestration

## Required Widget Modules

### 1. `widgets/exercise_builder_widget.dart`
**Purpose**: Main exercise list builder with drag-and-drop, editing, and management

**Key Features**:
- Reorderable list view for exercises
- Add/edit/delete exercise functionality
- Exercise card with all details (sets, reps, rest, tempo, RIR, %1RM)
- Cardio session builder
- Exercise group indicators (supersets, circuits)
- Quick actions (duplicate, suggest alternatives, view history)

**Key Methods**:
```dart
class ExerciseBuilderWidget extends StatefulWidget {
  final WorkoutDay day;
  final String? clientId;
  final VoidCallback onChanged;
  final Function(Exercise) onExerciseAdded;
  final Function(int) onExerciseRemoved;
  final Function(int, int) onExerciseReordered;
  final Function(CardioSession) onCardioAdded;
}
```

### 2. `widgets/client_selector_widget.dart`
**Purpose**: Enhanced client selection with search, filter, and client info preview

**Key Features**:
- Searchable dropdown
- Client info cards showing:
  - Recent workout history
  - Current goals
  - Training preferences
- Filter by client status/tags
- Quick access to client profile

**Key Methods**:
```dart
class ClientSelectorWidget extends StatefulWidget {
  final List<Map<String, dynamic>> clients;
  final String? selectedClientId;
  final bool loading;
  final Function(String) onClientSelected;
}
```

### 3. `widgets/superset_builder_dialog.dart`
**Purpose**: Visual interface for creating exercise groups (supersets, circuits, etc.)

**Key Features**:
- Exercise selection checkboxes
- Group type selector (superset, circuit, giant set, drop set, rest-pause)
- Color picker for group badge
- Visual preview of grouped exercises
- Group-level rest period setting
- Support for 2-10 exercises per group

**Key Methods**:
```dart
class SupersetBuilderDialog extends StatefulWidget {
  final List<Exercise> availableExercises;
  final Function(List<Exercise>, ExerciseGroupType, String groupId) onGroupCreated;
}
```

### 4. `widgets/ai_workout_generator_dialog.dart`
**Purpose**: AI-powered workout generation with preference controls

**Key Features**:
- Generation mode selector:
  - Full week plan
  - Single day
  - Current week progression
  - Deload week
- Preference controls:
  - Target muscle groups (visual selector)
  - Available equipment (multi-select)
  - Session duration slider
  - Intensity level (beginner/intermediate/advanced)
  - Training goal (strength/hypertrophy/endurance)
- AI usage indicator
- Generation progress indicator
- Preview and edit before applying

**Key Methods**:
```dart
class AIWorkoutGeneratorDialog extends StatefulWidget {
  final String? clientId;
  final Function(WorkoutPlan) onPlanGenerated;
}
```

### 5. `widgets/exercise_history_panel.dart`
**Purpose**: Display client's previous performance for exercises in current workout

**Key Features**:
- Exercise-specific history charts:
  - Volume progression
  - Weight progression
  - 1RM estimates over time
- Recent session details:
  - Sets/reps completed
  - Weight used
  - Form ratings
  - Client notes
- Progressive overload suggestions
- PR (Personal Record) indicators
- Export history to CSV

**Key Methods**:
```dart
class ExerciseHistoryPanel extends StatefulWidget {
  final String? clientId;
  final WorkoutDay? currentDay;
}
```

### 6. `widgets/validation_helper.dart`
**Purpose**: Comprehensive validation and safety checks for workout plans

**Key Features**:
- Validate plan structure:
  - Non-empty weeks/days
  - Exercise data completeness
  - Valid rep/set ranges
- Safety checks:
  - Muscle group balance (push/pull ratio)
  - Rest day recommendations
  - Excessive volume warnings
  - Missing warm-up/cooldown alerts
- Exercise name validation with suggestions
- Return detailed validation report with errors/warnings

**Key Classes**:
```dart
class ValidationHelper {
  static ValidationResult validatePlan(WorkoutPlan plan);
  static List<String> validateExercise(Exercise exercise);
  static BalanceWarnings checkMuscleBalance(WorkoutPlan plan);
  static List<int> suggestRestDays(WorkoutPlan plan);
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String summary;
}
```

### 7. `widgets/exercise_editor_dialog.dart`
**Purpose**: Detailed exercise editing form

**Key Features**:
- All exercise parameters:
  - Name (with autocomplete from exercise database)
  - Sets, reps, rest
  - Weight, %1RM, RIR
  - Tempo notation (4-digit format)
  - Notes with rich text
- Demo video preview/selector
- Equipment tag selector
- Target muscle group selector
- Auto-fill suggestions from AI
- Exercise alternative suggestions

### 8. `widgets/cardio_editor_dialog.dart`
**Purpose**: Machine-specific cardio session builder

**Key Features**:
- Machine type selector (treadmill, bike, rower, elliptical, stairmaster)
- Machine-specific settings forms:
  - Treadmill: speed, incline, duration
  - Bike: resistance, RPM, duration
  - Rower: resistance, stroke rate, distance
  - Elliptical: resistance, incline, duration
  - Stairmaster: level, duration
- Heart rate zone calculator
- Interval builder (HIIT/Tabata)
- Cardio duration estimator

### 9. `widgets/muscle_group_selector.dart`
**Purpose**: Visual muscle group selector for AI generation and filtering

**Key Features**:
- Interactive body diagram
- Muscle group checklist:
  - Chest, Back, Shoulders
  - Biceps, Triceps, Forearms
  - Quads, Hamstrings, Glutes, Calves
  - Core/Abs
- Quick select presets:
  - Upper/Lower split
  - Push/Pull/Legs
  - Full body
- Visual highlighting of selected groups

### 10. `widgets/exercise_search_dialog.dart`
**Purpose**: Advanced exercise search and filtering

**Key Features**:
- Search by name
- Filter by:
  - Muscle groups
  - Equipment required
  - Difficulty level
  - Exercise type (compound/isolation)
- Sort by:
  - Alphabetical
  - Popularity
  - Recently used
- Quick add to workout
- Bulk add multiple exercises

## State Management Pattern

All widgets follow these principles:

1. **Immutable data** - Use `copyWith()` for updates
2. **Single responsibility** - Each widget has one clear purpose
3. **Callback pattern** - Parent manages state, children emit events
4. **Loading states** - Show progress for async operations
5. **Error handling** - Graceful degradation with user-friendly messages

## Integration with Services

### WorkoutService
- All database operations go through WorkoutService
- No direct Supabase calls in UI code
- Proper error handling and loading states

### WorkoutAI
- All AI features use WorkoutAI service methods
- Token usage tracked via AIUsageService
- Results cached to minimize API calls

### AIUsageService
- Track usage for all AI operations
- Display usage meter in UI
- Prevent operations when quota exceeded

## Validation Flow

```
User initiates save
    ↓
Form validation (required fields)
    ↓
ValidationHelper.validatePlan()
    ↓
Show warnings dialog if issues found
    ↓
User can fix issues or save anyway
    ↓
WorkoutService.createPlan() or updatePlan()
    ↓
Success/error feedback to user
```

## AI Integration Flow

```
User clicks "Generate with AI"
    ↓
AIWorkoutGeneratorDialog opens
    ↓
User selects preferences
    ↓
Check AI quota via AIUsageService
    ↓
Call appropriate WorkoutAI method
    ↓
Show generation progress
    ↓
Preview generated content
    ↓
User accepts or modifies
    ↓
Apply to current plan
    ↓
Mark as changed, enable save
```

## File Structure

```
lib/screens/workout/
├── coach_plan_builder_screen_refactored.dart  (main screen)
├── REFACTOR_README.md                          (this file)
└── widgets/
    ├── exercise_builder_widget.dart
    ├── client_selector_widget.dart
    ├── superset_builder_dialog.dart
    ├── ai_workout_generator_dialog.dart
    ├── exercise_history_panel.dart
    ├── validation_helper.dart
    ├── exercise_editor_dialog.dart
    ├── cardio_editor_dialog.dart
    ├── muscle_group_selector.dart
    └── exercise_search_dialog.dart
```

## Implementation Priority

**Phase 1 (Critical)**:
1. validation_helper.dart
2. client_selector_widget.dart
3. exercise_builder_widget.dart

**Phase 2 (Core Features)**:
4. exercise_editor_dialog.dart
5. ai_workout_generator_dialog.dart
6. exercise_search_dialog.dart

**Phase 3 (Advanced Features)**:
7. superset_builder_dialog.dart
8. exercise_history_panel.dart
9. cardio_editor_dialog.dart
10. muscle_group_selector.dart

## Testing Checklist

- [ ] Create plan from scratch
- [ ] Edit existing plan
- [ ] Add/remove weeks and days
- [ ] Add/edit/delete exercises
- [ ] Reorder exercises via drag-and-drop
- [ ] Create supersets and circuits
- [ ] Generate with AI (full week, single day)
- [ ] Validate plan (empty, unbalanced, excessive)
- [ ] Auto-save functionality
- [ ] Save as template
- [ ] Export to PDF
- [ ] View exercise history
- [ ] Search and filter exercises
- [ ] Add cardio sessions
- [ ] Client selection with search
- [ ] Unsaved changes warning
- [ ] Keyboard shortcuts (Ctrl+S, Ctrl+N, Ctrl+W)

## Notes

- All widgets are designed to be reusable
- Follow Material Design 3 guidelines
- Support responsive layouts (mobile, tablet, desktop)
- Implement proper loading and error states
- Add analytics tracking for user actions
- Consider accessibility (screen readers, keyboard navigation)
- Optimize for performance (lazy loading, pagination)
- Add comprehensive error messages
- Implement undo/redo functionality (future enhancement)

## Migration Path

1. Test `coach_plan_builder_screen_refactored.dart` alongside existing implementation
2. Implement Phase 1 widgets
3. Integration test with WorkoutService
4. Implement Phase 2 widgets
5. Full feature parity test
6. Implement Phase 3 widgets
7. Performance optimization
8. Replace old `coach_plan_builder_screen.dart`
9. Remove deprecated code
10. Update documentation