# Workout Widgets Library

Comprehensive, reusable widget library for workout features following DesignTokens and supporting RTL (AR/KU).

## Implemented Widgets

### 1. WorkoutSummaryCard.dart ✅
**Purpose**: Weekly summary with volume, duration, and muscle distribution

**Features**:
- Weekly volume, tonnage, duration metrics
- Muscle group distribution pie chart (fl_chart)
- Rest day indicators (7-day week view)
- Progress vs previous week with % change
- Long press to share via SharePicker

**Usage**:
```dart
WorkoutSummaryCard(
  summary: weekSummary,
  previousWeekSummary: lastWeekSummary,
  isCompact: false,
)
```

**Dependencies**: `fl_chart: ^0.69.0`

---

### 2. ExerciseCard.dart ✅
**Purpose**: Exercise display with all details and quick actions

**Features**:
- Exercise name with expandable details
- Set/rep/rest/weight/tempo/RIR display
- Group badge (superset, circuit, etc.) with color coding
- Quick actions (edit, delete, history, demo video)
- Weight progression indicator vs last session
- Comment section for exercise notes
- Drag handle for reordering

**Usage**:
```dart
ExerciseCard(
  exercise: exercise,
  showGroupBadge: true,
  isDraggable: true,
  onEdit: () => editExercise(),
  onDelete: () => deleteExercise(),
  onViewHistory: () => showHistory(),
  onPlayDemo: () => playDemoVideo(),
  previousWeight: '80 kg',
  comment: exercise.notes,
  onCommentChanged: (text) => updateNotes(text),
)
```

---

### 3. SupersetGroupWidget.dart ✅
**Purpose**: Visual grouping of exercises in supersets/circuits

**Features**:
- Color-coded border based on group type
- Expandable/collapsible with animation
- Group type badge and icon
- Exercise list with numbering
- Reorderable exercises within group (ReorderableListView)
- Group-level rest period display
- Edit/disband group actions
- Remove exercises from group

**Usage**:
```dart
SupersetGroupWidget(
  exercises: groupedExercises,
  groupType: ExerciseGroupType.superset,
  groupId: 'group-1',
  groupRest: 120,
  isExpanded: true,
  onReorder: (oldIndex, newIndex) => reorderExercises(),
  onRemoveFromGroup: (exercise) => removeExercise(),
  onEditGroup: () => editGroupSettings(),
  onDisbandGroup: () => disbandGroup(),
)
```

**Group Types**:
- `superset` - Blue
- `circuit` - Purple
- `giantSet` - Orange
- `dropSet` - Red
- `restPause` - Teal

---

### 4. CardioSessionCard.dart ✅
**Purpose**: Cardio session display with machine-specific settings

**Features**:
- Machine type icon and color coding
- Machine-specific settings display:
  - Treadmill: speed, incline, duration
  - Bike: resistance, RPM, duration
  - Rower: resistance, stroke rate, distance
  - Elliptical: resistance, incline, duration
  - Stairmaster: level, duration
- Duration display
- Quick timer access button
- Edit/delete actions
- Notes display

**Usage**:
```dart
CardioSessionCard(
  session: cardioSession,
  onEdit: () => editSession(),
  onDelete: () => deleteSession(),
  onStartTimer: () => startCardioTimer(),
)
```

---

### 5. WeekProgressBar.dart ✅
**Purpose**: Week-by-week progress visualization

**Features**:
- Horizontal scrollable week indicators
- Completed weeks (green checkmark)
- Current week highlight (blue border + shadow)
- Deload week markers (orange badge)
- Volume increase/decrease indicators
- Tap to jump to week

**Usage**:
```dart
WeekProgressBar(
  totalWeeks: 12,
  currentWeek: 3,
  completedWeeks: [1, 2],
  deloadWeeks: [4, 8, 12],
  weekVolumeChanges: {1: 0, 2: 5.2, 3: 3.1},
  onWeekTap: (week) => goToWeek(week),
)
```

---

## Widgets to Implement

### 6. ExerciseHistoryChart.dart 📝
**Purpose**: Performance visualization over time

**Required Features**:
- Line chart for weight progression
- Volume over time (sets × reps × weight)
- PR (Personal Record) markers
- Trend analysis (improving/stable/declining)
- Multiple chart types (weight, volume, 1RM, reps)
- Date-based x-axis
- Tap data points for details

**Reference**: `progress_chart_widget.dart` in `lib/screens/workout/widgets/`

**Dependencies**: `fl_chart: ^0.69.0`

---

### 7. MuscleGroupSelector.dart 📝
**Purpose**: Interactive body diagram for muscle group selection

**Required Features**:
- Visual body diagram (front/back views)
- Clickable muscle groups
- Selected groups highlighted
- Muscle group checkboxes as alternative
- Balance indicator (push/pull ratio)
- Quick select presets:
  - Upper/Lower split
  - Push/Pull/Legs
  - Full body

**Implementation Approach**:
```dart
class MuscleGroupSelector extends StatefulWidget {
  final List<MuscleGroup> selectedGroups;
  final Function(List<MuscleGroup>) onSelectionChanged;
  final bool showBalanceIndicator;

  // Use CustomPaint for body diagram
  // Or use SVG with flutter_svg package
}
```

---

### 8. WorkoutTimerWidget.dart 📝
**Purpose**: Countdown timer with interval support

**Required Features**:
- Countdown timer display
- Interval support (work/rest phases)
- Audio cues at milestones
- Pause/resume/skip controls
- Background timer support
- Notification integration

**Reference**: `rest_timer_widget.dart` in `lib/screens/workout/widgets/`

**Dependencies**:
- `audioplayers: ^5.0.0` for audio cues
- `flutter_local_notifications` for background notifications

---

### 9. ExerciseSearchWidget.dart 📝
**Purpose**: Advanced exercise search and filtering

**Required Features**:
- Search bar with debouncing
- Equipment filter chips (barbell, dumbbell, machine, bodyweight)
- Muscle group filter (multi-select)
- Exercise type filter (compound/isolation)
- Recent exercises section
- Favorites section
- Sort options (alphabetical, popularity, recently used)
- Quick add button

**Implementation**:
```dart
class ExerciseSearchWidget extends StatefulWidget {
  final Function(Exercise) onExerciseSelected;
  final List<String> availableEquipment;
  final List<MuscleGroup> muscleGroupFilter;

  // Use SearchDelegate or custom search UI
  // Connect to exercise database/API
}
```

---

### 10. AIWorkoutGeneratorDialog.dart 📝
**Purpose**: AI-powered workout generation interface

**Required Features**:
- Goals selection (strength/hypertrophy/endurance)
- Days per week slider (3-6 days)
- Equipment availability multi-select
- Experience level radio buttons (beginner/intermediate/advanced)
- Injury/limitation text input
- Generate button with loading state
- Preview generated workout
- Accept/regenerate options

**Integration**:
- Connect to `WorkoutAI` service
- Track AI usage via `AIUsageService`
- Show token usage meter
- Handle errors gracefully

**Reference**: `ai_workout_generator_dialog.dart` in `lib/screens/workout/widgets/`

---

## Helper Widgets

### 11. WorkoutAttachmentViewer.dart 📝
**Purpose**: View workout attachments (images, videos, PDFs)

**Required Features**:
- Image viewer with zoom
- Video player (inline or fullscreen)
- PDF viewer
- Download button
- Share button

**Dependencies**:
- `video_player: ^2.8.0`
- `photo_view: ^0.14.0`
- `syncfusion_flutter_pdfviewer` or `flutter_pdfview`

**Reference**: `file_attach_to_meal.dart` in `lib/widgets/nutrition/`

---

### 12. ClientWorkoutCommentBox.dart 📝
**Purpose**: Comment box for client feedback

**Required Features**:
- Text input with character limit
- Auto-save functionality
- Read-only mode for coach view
- Visual distinction (client comment vs coach notes)
- Save indicator

**Implementation**: Copy pattern from `ClientNutritionCommentBox`

---

### 13. WorkoutVersionHistoryViewer.dart 📝
**Purpose**: View and restore previous workout plan versions

**Required Features**:
- List of versions with timestamps
- Side-by-side diff view
- Restore version button
- Version notes/changelog

**Implementation**:
```dart
class WorkoutVersionHistoryViewer extends StatelessWidget {
  final List<WorkoutPlanVersion> versions;
  final Function(String versionId) onRestore;

  // Show version list
  // Tap to expand and show changes
  // Restore button with confirmation
}
```

---

### 14. ExerciseDemoPlayer.dart 📝
**Purpose**: Video player wrapper for exercise demos

**Required Features**:
- Inline video player
- Play/pause controls
- Seek bar
- Fullscreen toggle
- Loop option
- Speed controls (0.5x, 1x, 1.5x)

**Dependencies**: `video_player: ^2.8.0` or `chewie: ^1.7.0`

---

### 15. SetRepInputWidget.dart 📝
**Purpose**: Quick input interface for sets/reps/weight

**Required Features**:
- Numeric keyboard overlay
- Quick increment buttons (+5kg, +2.5kg, -2.5kg, -5kg)
- Set completion checkboxes
- Save button
- Clear button

**Implementation**:
```dart
class SetRepInputWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(int sets, String reps, double weight) onSave;

  // Show modal bottom sheet with number pickers
  // Or use inline text fields with +/- buttons
}
```

---

## Design Guidelines

### Colors and Theming
All widgets use `DesignTokens` for consistency:
- Primary: `DesignTokens.blue600`
- Success: `DesignTokens.accentGreen`
- Warning: `DesignTokens.warn`
- Danger: `DesignTokens.danger`
- Background: `DesignTokens.cardBackground`

### RTL Support
All widgets support RTL layout for AR/KU:
```dart
Directionality(
  textDirection: language == 'ar' || language == 'ku'
    ? TextDirection.rtl
    : TextDirection.ltr,
  child: widget,
)
```

### Internationalization
Use `LocaleHelper.t()` for all text:
```dart
Text(LocaleHelper.t('exercise', language))
```

### Responsive Design
- Use `LayoutBuilder` for adaptive layouts
- Minimum touch target: 44×44 (iOS guideline)
- Compact mode for small screens
- Desktop: show more details inline

### Loading States
Show loading indicators for async operations:
```dart
isLoading
  ? CircularProgressIndicator()
  : actualContent
```

### Error Handling
Display user-friendly error messages:
```dart
if (hasError)
  Text(
    LocaleHelper.t('error_loading_data', language),
    style: TextStyle(color: DesignTokens.danger),
  )
```

---

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  fl_chart: ^0.69.0                    # Charts
  video_player: ^2.8.0                 # Video playback
  photo_view: ^0.14.0                  # Image zoom
  audioplayers: ^5.0.0                 # Audio cues
  flutter_local_notifications: ^16.0.0 # Notifications
  shared_preferences: ^2.2.0           # Persistence
```

---

## File Structure

```
lib/widgets/workout/
├── README.md                           ✅ This file
├── workout_summary_card.dart           ✅ Implemented
├── exercise_card.dart                  ✅ Implemented
├── superset_group_widget.dart          ✅ Implemented
├── cardio_session_card.dart            ✅ Implemented
├── week_progress_bar.dart              ✅ Implemented
├── exercise_history_chart.dart         📝 TODO (reference: progress_chart_widget.dart)
├── muscle_group_selector.dart          📝 TODO
├── workout_timer_widget.dart           📝 TODO (reference: rest_timer_widget.dart)
├── exercise_search_widget.dart         📝 TODO
├── ai_workout_generator_dialog.dart    📝 TODO (reference: ai_workout_generator_dialog.dart in screens)
├── workout_attachment_viewer.dart      📝 TODO
├── client_workout_comment_box.dart     📝 TODO (copy pattern from nutrition)
├── workout_version_history_viewer.dart 📝 TODO
├── exercise_demo_player.dart           📝 TODO
└── set_rep_input_widget.dart           📝 TODO
```

---

## Testing Checklist

### Visual Testing
- [ ] All widgets render correctly on different screen sizes
- [ ] RTL layout works for AR/KU languages
- [ ] Dark mode support (if applicable)
- [ ] Color contrast meets accessibility guidelines

### Functional Testing
- [ ] Tap actions trigger callbacks
- [ ] Loading states display correctly
- [ ] Error states display user-friendly messages
- [ ] Animations run smoothly (60fps)
- [ ] Long press gestures work (share, reorder)

### Integration Testing
- [ ] Widgets integrate with WorkoutService
- [ ] LocaleHelper translations work
- [ ] SharePicker integration works
- [ ] Navigation flows work correctly

---

## Usage Examples

### Building a Workout Day View
```dart
Column(
  children: [
    WeekProgressBar(
      totalWeeks: plan.weeks.length,
      currentWeek: currentWeekIndex,
      completedWeeks: getCompletedWeeks(),
    ),
    WorkoutSummaryCard(
      summary: getCurrentWeekSummary(),
      previousWeekSummary: getPreviousWeekSummary(),
    ),
    ...day.exercises.map((exercise) {
      if (exercise.groupId != null) {
        // Show in SupersetGroupWidget
        return SupersetGroupWidget(...);
      } else {
        return ExerciseCard(exercise: exercise);
      }
    }),
    ...day.cardioSessions.map((session) {
      return CardioSessionCard(session: session);
    }),
  ],
)
```

### Exercise Selection Flow
```dart
// Show search widget
showModalBottomSheet(
  context: context,
  builder: (context) => ExerciseSearchWidget(
    onExerciseSelected: (exercise) {
      Navigator.pop(context);
      addExerciseToDay(exercise);
    },
  ),
);
```

---

## Next Steps

1. **Complete Remaining Widgets**: Implement the 10 widgets marked with 📝
2. **Add Tests**: Create unit and widget tests for all components
3. **Optimize Performance**: Profile and optimize heavy widgets (charts, video players)
4. **Accessibility**: Add semantic labels and screen reader support
5. **Documentation**: Add inline documentation and examples
6. **Integration**: Connect widgets to screens and services

---

## References

- Nutrition widgets: `lib/widgets/nutrition/`
- Workout screens: `lib/screens/workout/`
- Design tokens: `lib/theme/design_tokens.dart`
- Locale helper: `lib/services/nutrition/locale_helper.dart`
- Share service: `lib/services/share/share_card_service.dart`