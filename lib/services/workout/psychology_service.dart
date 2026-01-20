import '../../models/workout/fatigue_models.dart';

class WorkoutPsychologyService {
  WorkoutPsychologyService._();
  static final WorkoutPsychologyService I = WorkoutPsychologyService._();

  String getMotivationalMessage({
    required ReadinessIndicator readiness,
    required TransformationMode mode,
  }) {
    // Keep it short, high-impact, no cringe.
    switch (readiness.label) {
      case 'Green':
        return 'You\'re primed. Execute clean reps and take what\'s yours.';
      case 'Yellow':
        return 'Strong day. Win the main sets, control fatigue after.';
      case 'Orange':
        return 'Today is about precision. Quality > ego.';
      case 'Red':
        return 'Smart athletes recover. Keep momentum with a deload-style session.';
      default:
        return 'Show up. Execute. Leave better.';
    }
  }

  String getEncouragement({
    required int completedSets,
    required int totalSets,
  }) {
    final pct = totalSets == 0 ? 0 : ((completedSets / totalSets) * 100).round();
    if (pct >= 80) return 'Finish strong. You\'re almost done.';
    if (pct >= 50) return 'Halfway. Stay locked in.';
    return 'Start smooth. Stack clean sets.';
  }
}
