import 'package:flutter/material.dart';
import '../../../models/workout/workout_plan.dart';
import '../../../models/workout/exercise.dart';
import 'exercise_completion_widget.dart';

/// Manages workout session state and progression
class WorkoutSessionManager {
  final WorkoutDay day;
  final Function(String exerciseId, ExerciseCompletionData) onExerciseComplete;
  final VoidCallback onSessionComplete;
  final Function(String message)? onRestTimerStart;

  DateTime? sessionStartTime;
  DateTime? sessionEndTime;
  int currentExerciseIndex = 0;
  bool isRestTimerActive = false;

  final Map<String, ExerciseCompletionData> completedExercises = {};
  final List<int> restTimerHistory = [];

  WorkoutSessionManager({
    required this.day,
    required this.onExerciseComplete,
    required this.onSessionComplete,
    this.onRestTimerStart,
  });

  /// Start the workout session
  void startSession() {
    sessionStartTime = DateTime.now();
    currentExerciseIndex = 0;
    completedExercises.clear();
    restTimerHistory.clear();
  }

  /// Mark an exercise as complete and move to next
  void completeExercise(String exerciseId, ExerciseCompletionData data) {
    completedExercises[exerciseId] = data;
    onExerciseComplete(exerciseId, data);

    // Start rest timer if not last exercise
    if (currentExerciseIndex < day.exercises.length - 1) {
      final currentExercise = day.exercises[currentExerciseIndex];
      if (currentExercise.rest != null && currentExercise.rest! > 0) {
        startRestTimer(currentExercise.rest!);
      }
    }

    // Move to next exercise
    currentExerciseIndex++;

    // Check if session is complete
    if (currentExerciseIndex >= day.exercises.length) {
      endSession();
    }
  }

  /// Start rest timer between exercises
  void startRestTimer(int seconds) {
    isRestTimerActive = true;
    restTimerHistory.add(seconds);

    if (onRestTimerStart != null) {
      final nextExercise = day.exercises[currentExerciseIndex + 1];
      onRestTimerStart!(
        'Rest for $seconds seconds. Next: ${nextExercise.name}',
      );
    }
  }

  /// Skip rest timer
  void skipRestTimer() {
    isRestTimerActive = false;
  }

  /// End the workout session
  void endSession() {
    sessionEndTime = DateTime.now();
    onSessionComplete();
  }

  /// Get session duration in minutes
  int getSessionDuration() {
    if (sessionStartTime == null) return 0;
    final endTime = sessionEndTime ?? DateTime.now();
    return endTime.difference(sessionStartTime!).inMinutes;
  }

  /// Get total volume for session (sets × reps × weight)
  double getTotalVolume() {
    double total = 0;
    for (final data in completedExercises.values) {
      final sets = data.completedSets;
      final reps = int.tryParse(data.completedReps) ?? 0;
      final weight = data.weightUsed;
      total += sets * reps * weight;
    }
    return total;
  }

  /// Get completion percentage
  double getCompletionPercentage() {
    if (day.exercises.isEmpty) return 0;
    return (completedExercises.length / day.exercises.length) * 100;
  }

  /// Get current exercise
  Exercise? getCurrentExercise() {
    if (currentExerciseIndex >= day.exercises.length) return null;
    return day.exercises[currentExerciseIndex];
  }

  /// Get next exercise
  Exercise? getNextExercise() {
    if (currentExerciseIndex + 1 >= day.exercises.length) return null;
    return day.exercises[currentExerciseIndex + 1];
  }

  /// Check if exercise is complete
  bool isExerciseComplete(String exerciseId) {
    return completedExercises.containsKey(exerciseId);
  }

  /// Get session summary
  SessionSummary getSessionSummary() {
    final totalSets = completedExercises.values
        .map((e) => e.completedSets)
        .fold(0, (a, b) => a + b);

    final avgRpe = completedExercises.values
        .where((e) => e.rpeRating != null)
        .map((e) => e.rpeRating!)
        .fold(0, (a, b) => a + b) /
        (completedExercises.values.where((e) => e.rpeRating != null).length.clamp(1, double.infinity));

    return SessionSummary(
      duration: getSessionDuration(),
      totalVolume: getTotalVolume(),
      totalSets: totalSets,
      completedExercises: completedExercises.length,
      totalExercises: day.exercises.length,
      averageRpe: avgRpe.isNaN ? 0 : avgRpe,
      startTime: sessionStartTime!,
      endTime: sessionEndTime ?? DateTime.now(),
    );
  }
}

/// Session summary data
class SessionSummary {
  final int duration; // minutes
  final double totalVolume; // kg
  final int totalSets;
  final int completedExercises;
  final int totalExercises;
  final double averageRpe;
  final DateTime startTime;
  final DateTime endTime;

  SessionSummary({
    required this.duration,
    required this.totalVolume,
    required this.totalSets,
    required this.completedExercises,
    required this.totalExercises,
    required this.averageRpe,
    required this.startTime,
    required this.endTime,
  });

  String get durationDisplay {
    if (duration < 60) {
      return '$duration min';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      return '${hours}h ${minutes}m';
    }
  }

  String get volumeDisplay {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)} tons';
    } else {
      return '${totalVolume.toStringAsFixed(0)} kg';
    }
  }

  double get completionRate {
    if (totalExercises == 0) return 0;
    return (completedExercises / totalExercises) * 100;
  }
}

/// Rest timer controller for managing rest periods
class RestTimerController extends ChangeNotifier {
  int? _remainingSeconds;
  DateTime? _startTime;
  bool _isActive = false;
  String? _nextExerciseName;

  int? get remainingSeconds => _remainingSeconds;
  bool get isActive => _isActive;
  String? get nextExerciseName => _nextExerciseName;

  /// Start rest timer
  void startTimer(int seconds, {String? nextExercise}) {
    _remainingSeconds = seconds;
    _startTime = DateTime.now();
    _isActive = true;
    _nextExerciseName = nextExercise;
    notifyListeners();
  }

  /// Update remaining time
  void updateTimer() {
    if (!_isActive || _startTime == null) return;

    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    _remainingSeconds = (_remainingSeconds ?? 0) - elapsed;

    if (_remainingSeconds! <= 0) {
      stopTimer();
    } else {
      notifyListeners();
    }
  }

  /// Stop/skip timer
  void stopTimer() {
    _isActive = false;
    _remainingSeconds = null;
    _startTime = null;
    _nextExerciseName = null;
    notifyListeners();
  }

  /// Add time to timer
  void addTime(int seconds) {
    if (!_isActive) return;
    _remainingSeconds = (_remainingSeconds ?? 0) + seconds;
    notifyListeners();
  }

  /// Get progress (0.0 to 1.0)
  double getProgress(int totalSeconds) {
    if (!_isActive || _remainingSeconds == null) return 0;
    return 1 - (_remainingSeconds! / totalSeconds);
  }
}

/// View mode for workout viewer
enum ViewMode {
  overview, // Viewing workout plan
  session,  // Active workout session
}