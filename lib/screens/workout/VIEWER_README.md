# Workout Plan Viewer - Modular Architecture

## Overview
The WorkoutPlanViewerScreen has been refactored into a production-quality implementation with session mode, progress tracking, and offline support.

## Main File
- **`workout_plan_viewer_screen_refactored.dart`** - Core screen with session management, navigation, and sync

## Implemented Widget Modules

### 1. `widgets/exercise_completion_widget.dart`
**Purpose**: Exercise completion tracking for workout sessions

**Key Features**:
- ✅ Exercise card with expandable details
- ✅ Set-by-set completion tracking with checkboxes
- ✅ Weight and reps input for each set
- ✅ RPE (Rate of Perceived Exertion) rating slider (1-10)
- ✅ Form quality rating (1-5)
- ✅ Difficulty rating (1-5)
- ✅ Session notes input
- ✅ Quick actions (demo video, history, substitution request)
- ✅ Completion indicator with visual feedback
- ✅ Auto-calculation of average weight and reps
- ✅ Data persistence with ExerciseCompletionData model

**Usage**:
```dart
ExerciseCompletionWidget(
  exercise: exercise,
  completionData: completionDataMap[exercise.id],
  isSessionActive: _isSessionActive,
  onComplete: () => _handleExerciseComplete(exercise.id),
  onDataChanged: (data) => _handleDataChanged(exercise.id, data),
  onViewHistory: () => _showExerciseHistory(exercise),
  onPlayDemo: () => _playExerciseDemo(exercise),
)
```

### 2. `widgets/workout_session_manager.dart`
**Purpose**: Manages workout session state and progression

**Key Features**:
- ✅ Session lifecycle management (start/end)
- ✅ Exercise progression tracking
- ✅ Rest timer integration
- ✅ Session duration calculation
- ✅ Total volume tracking (sets × reps × weight)
- ✅ Completion percentage calculation
- ✅ Session summary generation with metrics
- ✅ Current and next exercise tracking

**Key Classes**:
```dart
class WorkoutSessionManager {
  void startSession();
  void completeExercise(String exerciseId, ExerciseCompletionData data);
  void startRestTimer(int seconds);
  void endSession();
  int getSessionDuration();
  double getTotalVolume();
  double getCompletionPercentage();
  SessionSummary getSessionSummary();
}

class SessionSummary {
  final int duration; // minutes
  final double totalVolume; // kg
  final int totalSets;
  final int completedExercises;
  final int totalExercises;
  final double averageRpe;
  String get durationDisplay; // "1h 30m"
  String get volumeDisplay; // "1.5 tons"
}

class RestTimerController extends ChangeNotifier {
  void startTimer(int seconds, {String? nextExercise});
  void updateTimer();
  void stopTimer();
  void addTime(int seconds);
  double getProgress(int totalSeconds);
}

enum ViewMode { overview, session }
```

### 3. `widgets/rest_timer_widget.dart`
**Purpose**: Rest timer with notifications and audio cues

**Key Features**:
- ✅ Circular progress timer with countdown
- ✅ Pause/resume functionality
- ✅ Add time buttons (+15s, +30s)
- ✅ Skip rest option
- ✅ Color-coded urgency (green → orange → red)
- ✅ Haptic feedback at milestones (10s, 5s, 3s)
- ✅ Pulse animation for last 10 seconds
- ✅ Next exercise preview
- ✅ Compact banner mode for persistent display

**Components**:
```dart
// Full dialog timer
RestTimerWidget(
  initialSeconds: 90,
  nextExerciseName: 'Bench Press',
  onComplete: () => moveToNextExercise(),
  onSkip: () => skipRest(),
)

// Compact banner
RestTimerBanner(
  initialSeconds: 90,
  nextExerciseName: 'Bench Press',
  onComplete: () => moveToNextExercise(),
  onExpand: () => showFullTimer(),
  onSkip: () => skipRest(),
)
```

**Audio/Haptic Feedback**:
- Light haptic at 10s, 5s
- Medium haptic at 3s
- Heavy haptic + completion sound at 0s
- Note: Audio integration requires `audioplayers` package (commented placeholders included)

### 4. `widgets/progress_chart_widget.dart`
**Purpose**: Performance visualization with fl_chart

**Key Features**:
- ✅ Four chart types: Volume, Weight, 1RM, Reps
- ✅ Line charts for continuous metrics (volume, weight, 1RM)
- ✅ Bar chart for reps progression
- ✅ Interactive chart type selector with chips
- ✅ Trend analysis (improving/stable/declining)
- ✅ Stats summary with best performance
- ✅ Session count tracking
- ✅ Date-based x-axis labels
- ✅ Auto-scaling y-axis based on data range
- ✅ Empty state handling with helpful message

**Chart Types**:
```dart
enum ChartType {
  volume,  // Total volume (sets × reps × weight)
  weight,  // Weight used over time
  oneRM,   // Estimated 1RM progression
  reps,    // Reps completed per session
}
```

**Usage**:
```dart
ProgressChartWidget(
  clientId: clientId,
  exerciseName: 'Bench Press',
  chartType: ChartType.volume,
)
```

**Dependencies**: Requires `fl_chart: ^0.69.0` in pubspec.yaml

### 5. `widgets/offline_sync_manager.dart`
**Purpose**: Offline data storage and automatic synchronization

**Key Features**:
- ✅ Queue-based sync system with SharedPreferences
- ✅ Automatic sync every 5 minutes
- ✅ Immediate sync attempts when online
- ✅ Exercise completion data queuing
- ✅ Day comment queuing
- ✅ Retry logic for failed syncs
- ✅ Online/offline status tracking
- ✅ Last sync time persistence
- ✅ Pending item count tracking
- ✅ Visual sync status widget with color coding

**Key Classes**:
```dart
class OfflineSyncManager extends ChangeNotifier {
  Future<void> queueExerciseCompletion({required String clientId, required ExerciseCompletionData data});
  Future<void> queueDayComment({required String dayId, required String comment, required String clientId});
  Future<bool> syncPendingData();
  SyncStatus getSyncStatus();
  void setOfflineMode(bool offline); // for testing
}

class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  String get statusMessage; // "Syncing...", "Offline - 3 items pending", etc.
  String get lastSyncDisplay; // "2m ago", "1h ago", etc.
}

// Visual widget
SyncStatusWidget(
  syncManager: _syncManager,
  onTap: () => _showSyncDetails(),
)
```

**Storage Keys**:
- `workout_completion_queue` - Pending sync items (JSON array)
- `workout_last_sync` - Last successful sync timestamp

### 6. `widgets/validation_helper.dart` *(Already implemented in CoachPlanBuilder)*
**Purpose**: Comprehensive validation and safety checks

**Key Features**:
- ✅ Plan structure validation
- ✅ Exercise data validation
- ✅ Muscle group balance checking
- ✅ Rest day recommendations
- ✅ Excessive volume warnings
- ✅ Exercise name validation with fuzzy matching (Levenshtein distance)

Detailed documentation in `REFACTOR_README.md`.

## Architecture Patterns

### 1. State Management
- **Local State**: `setState()` for UI state
- **ChangeNotifier**: For cross-widget state (OfflineSyncManager, RestTimerController)
- **Callbacks**: Parent manages state, children emit events
- **Immutable Models**: Use `copyWith()` for updates

### 2. Data Flow
```
User Action
    ↓
Widget Event (callback)
    ↓
Screen State Update
    ↓
Queue for Sync (OfflineSyncManager)
    ↓
Background Sync (5-minute timer)
    ↓
Server Update (WorkoutService)
```

### 3. Offline-First Approach
1. User completes exercise → Data stored locally
2. Mark as "not synced" → Add to sync queue
3. Auto-sync attempts every 5 minutes
4. On success → Mark as synced, remove from queue
5. On failure → Keep in queue, retry next interval

### 4. Session Flow
```
1. User clicks "Start Workout"
    ↓
2. WorkoutSessionManager initialized
    ↓
3. Exercise completion tracking begins
    ↓
4. Complete exercise → Start rest timer
    ↓
5. Rest complete → Move to next exercise
    ↓
6. All exercises complete → Show session summary
    ↓
7. End session → Generate SessionSummary
```

## Integration Guide

### 1. Update Main Viewer Screen
Replace imports and add supporting widgets:

```dart
import 'widgets/exercise_completion_widget.dart';
import 'widgets/workout_session_manager.dart';
import 'widgets/rest_timer_widget.dart';
import 'widgets/progress_chart_widget.dart';
import 'widgets/offline_sync_manager.dart';
```

### 2. Initialize Managers
```dart
class _WorkoutPlanViewerScreenState extends State<WorkoutPlanViewerScreen> {
  late OfflineSyncManager _syncManager;
  WorkoutSessionManager? _sessionManager;

  @override
  void initState() {
    super.initState();
    _syncManager = OfflineSyncManager();
    _syncManager.addListener(_handleSyncChange);
  }
}
```

### 3. Exercise List Builder
```dart
ListView.builder(
  itemCount: currentDay.exercises.length,
  itemBuilder: (context, index) {
    final exercise = currentDay.exercises[index];
    return ExerciseCompletionWidget(
      exercise: exercise,
      completionData: _completedExercises[exercise.id],
      isSessionActive: _isSessionActive,
      onComplete: () => _handleExerciseComplete(exercise.id),
      onDataChanged: (data) => _handleDataChanged(exercise.id, data),
    );
  },
)
```

### 4. Session Controls
```dart
void _startSession() {
  setState(() {
    _isSessionActive = true;
    _sessionManager = WorkoutSessionManager(
      day: currentDay,
      onExerciseComplete: (exerciseId, data) {
        _syncManager.queueExerciseCompletion(
          clientId: _supabase.auth.currentUser!.id,
          data: data,
        );
      },
      onSessionComplete: _showSessionSummary,
    );
  });
}
```

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  fl_chart: ^0.69.0           # For progress charts
  shared_preferences: ^2.2.0  # For offline storage
```

## File Structure

```
lib/screens/workout/
├── workout_plan_viewer_screen_refactored.dart  (main screen)
├── VIEWER_README.md                             (this file)
└── widgets/
    ├── exercise_completion_widget.dart          ✅ Implemented
    ├── workout_session_manager.dart             ✅ Implemented
    ├── rest_timer_widget.dart                   ✅ Implemented
    ├── progress_chart_widget.dart               ✅ Implemented
    ├── offline_sync_manager.dart                ✅ Implemented
    └── validation_helper.dart                   ✅ Implemented (shared)
```

## Testing Checklist

### Session Mode
- [ ] Start workout session
- [ ] Complete individual sets with weight/reps
- [ ] Mark exercise complete
- [ ] Rest timer starts automatically
- [ ] Skip rest timer
- [ ] Add time to rest timer (+15s, +30s)
- [ ] Complete all exercises
- [ ] View session summary
- [ ] End session

### Progress Tracking
- [ ] View volume chart
- [ ] View weight progression
- [ ] View 1RM estimates
- [ ] View reps chart
- [ ] Switch between chart types
- [ ] View trend analysis
- [ ] View best performance

### Offline Support
- [ ] Complete exercises while offline
- [ ] Data queued for sync
- [ ] Sync status indicator shows pending items
- [ ] Auto-sync when back online
- [ ] View last sync time
- [ ] Manual sync trigger

### UI/UX
- [ ] Week tab navigation
- [ ] Day carousel navigation
- [ ] Previous/Next day buttons
- [ ] Exercise expansion/collapse
- [ ] Rating sliders (RPE, form, difficulty)
- [ ] Notes input
- [ ] Demo video playback
- [ ] Exercise history viewing
- [ ] Substitution requests

### Edge Cases
- [ ] Handle empty workout plan
- [ ] Handle missing exercise data
- [ ] Handle sync failures gracefully
- [ ] Handle rapid session start/stop
- [ ] Handle app backgrounding during session
- [ ] Persist session state on app restart

## Performance Optimizations

1. **Lazy Loading**: Exercise history loaded on-demand
2. **Pagination**: Limit history queries to last 30 entries
3. **Debouncing**: Save to queue only on significant changes
4. **Caching**: Chart data cached in memory
5. **Throttling**: Sync attempts limited to 5-minute intervals

## Accessibility

- ✅ Semantic labels on all interactive elements
- ✅ High contrast color coding (timer states)
- ✅ Haptic feedback for important events
- ✅ Large touch targets (44×44 minimum)
- ✅ Screen reader support with descriptive labels

## Known Limitations

1. **Audio Playback**: Requires `audioplayers` package (placeholders included)
2. **Push Notifications**: Rest timer notifications require platform-specific setup
3. **Background Sync**: Currently syncs only when app is active
4. **Chart Interactivity**: Basic touch interactions (tap to view values)

## Future Enhancements

1. **Session Pause/Resume**: Save active session state
2. **Voice Commands**: "Next exercise", "Start rest timer"
3. **Apple Watch Integration**: View workout on watch
4. **Workout Streaks**: Track consecutive training days
5. **Social Sharing**: Share workout summaries
6. **Exercise Substitutions**: AI-powered alternative suggestions
7. **Form Analysis**: Video recording with pose detection
8. **Training Load**: Calculate acute/chronic workload ratios

## Migration Path

1. ✅ Create refactored viewer screen with core architecture
2. ✅ Implement ExerciseCompletionWidget
3. ✅ Implement WorkoutSessionManager
4. ✅ Implement RestTimerWidget
5. ✅ Implement ProgressChartWidget
6. ✅ Implement OfflineSyncManager
7. ✅ Create documentation
8. [ ] Integration testing with WorkoutService
9. [ ] Add required dependencies to pubspec.yaml
10. [ ] Update navigation to use refactored screen
11. [ ] Parallel testing with old implementation
12. [ ] Full user acceptance testing
13. [ ] Replace old viewer screen
14. [ ] Remove deprecated code
15. [ ] Update app documentation

## Related Documentation

- `REFACTOR_README.md` - CoachPlanBuilder architecture
- `0004_workout_system_v2.sql` - Database schema
- `lib/models/workout/` - Data models
- `lib/services/workout/workout_service.dart` - Service layer

## Support

For questions or issues:
1. Check this documentation first
2. Review related READMEs
3. Test with example workout data
4. Review WorkoutService implementation