// test/progression_rules_advanced_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/utils/progression_rules.dart';
import 'package:vagus_app/services/workout/exercise_local_log_service.dart';

void main() {
  group('ProgressionRules Advanced Set Types', () {
    test('AMRAP high-reps suggests increase', () {
      final advice = ProgressionRules.suggest(
        targetReps: 8,
        lastWeight: 80.0,
        lastReps: 12, // High reps (target + 4)
        lastRir: 1.5, // Good RIR
        useKg: true,
        setType: SetType.amrap,
        amrap: true,
      );

      expect(advice.title, 'Add +2.5 kg');
      expect(advice.delta, 2.5);
      expect(advice.rationale, contains('AMRAP exceeded target by 2+ reps'));
    });

    test('AMRAP low-reps suggests reduce', () {
      final advice = ProgressionRules.suggest(
        targetReps: 8,
        lastWeight: 80.0,
        lastReps: 4, // Low reps (target - 4)
        lastRir: 4.5, // High RIR
        useKg: true,
        setType: SetType.amrap,
        amrap: true,
      );

      expect(advice.title, 'Reduce -2.5 kg');
      expect(advice.delta, -2.5);
      expect(advice.rationale, contains('AMRAP reps low'));
    });

    test('AMRAP middle-reps suggests keep same', () {
      final advice = ProgressionRules.suggest(
        targetReps: 8,
        lastWeight: 80.0,
        lastReps: 8, // Target reps
        lastRir: 2.5, // Good RIR
        useKg: true,
        setType: SetType.amrap,
        amrap: true,
      );

      expect(advice.title, 'Keep same');
      expect(advice.delta, null);
      expect(advice.rationale, contains('AMRAP performance within target range'));
    });

    test('Rest-Pause total reps feeds into suggestion correctly', () {
      final advice = ProgressionRules.suggest(
        targetReps: 10,
        lastWeight: 80.0,
        lastReps: 13, // Total reps from rest-pause (8+3+2)
        lastRir: 2.0, // Good RIR
        useKg: true,
        setType: SetType.restPause,
      );

      expect(advice.title, 'Add +2.5 kg');
      expect(advice.delta, 2.5);
      expect(advice.rationale, contains('Rest-pause total reps achieved'));
    });

    test('Cluster total reps feeds into suggestion correctly', () {
      final advice = ProgressionRules.suggest(
        targetReps: 12,
        lastWeight: 100.0,
        lastReps: 15, // Total reps from cluster
        lastRir: 1.5, // Good RIR
        useKg: true,
        setType: SetType.cluster,
      );

      expect(advice.title, 'Add +2.5 kg');
      expect(advice.delta, 2.5);
      expect(advice.rationale, contains('Cluster total reps achieved'));
    });

    test('Drop-set total reps feeds into suggestion correctly', () {
      final advice = ProgressionRules.suggest(
        targetReps: 12,
        lastWeight: 80.0,
        lastReps: 18, // Total reps from drop-set
        lastRir: 2.0, // Good RIR
        useKg: true,
        setType: SetType.drop,
      );

      expect(advice.title, 'Add +2.5 kg');
      expect(advice.delta, 2.5);
      expect(advice.rationale, contains('Drop-set total reps achieved'));
    });

    test('Normal set uses standard progression', () {
      final advice = ProgressionRules.suggest(
        targetReps: 8,
        lastWeight: 80.0,
        lastReps: 8, // Target reps
        lastRir: 2.0, // Good RIR
        useKg: true,
        setType: SetType.normal,
      );

      expect(advice.title, 'Add +2.5 kg');
      expect(advice.delta, 2.5);
      expect(advice.rationale, contains('Target reps achieved'));
    });
  });
}
