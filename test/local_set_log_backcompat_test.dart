// test/local_set_log_backcompat_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/workout/exercise_local_log_service.dart';

void main() {
  group('LocalSetLog Backward Compatibility', () {
    test('fromJson with old payload (no advanced fields) returns null fields', () {
      final oldPayload = {
        'date': '2024-01-01T00:00:00.000Z',
        'weight': 80.0,
        'reps': 8,
        'rir': 2.0,
        'unit': 'kg',
      };

      final log = LocalSetLog.fromJson(oldPayload);

      expect(log.date, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(log.weight, 80.0);
      expect(log.reps, 8);
      expect(log.rir, 2.0);
      expect(log.unit, 'kg');
      expect(log.setType, null);
      expect(log.dropWeights, null);
      expect(log.dropPercents, null);
      expect(log.rpBursts, null);
      expect(log.rpRestSec, null);
      expect(log.clusterSize, null);
      expect(log.clusterRestSec, null);
      expect(log.clusterTotalReps, null);
      expect(log.amrap, null);
    });

    test('fromJson with mixed int/double arrays normalizes types', () {
      final payload = {
        'date': '2024-01-01T00:00:00.000Z',
        'weight': 80.0,
        'reps': 8,
        'rir': 2.0,
        'unit': 'kg',
        'setType': 'restPause',
        'rpBursts': [8, 3, 2], // int array
        'dropWeights': [72.0, 65.0], // double array
      };

      final log = LocalSetLog.fromJson(payload);

      expect(log.setType, SetType.restPause);
      expect(log.rpBursts, [8, 3, 2]);
      expect(log.dropWeights, [72.0, 65.0]);
    });

    test('normalizeAdvancedFields removes invalid data', () {
      final log = LocalSetLog(
        date: DateTime.now(),
        weight: 80,
        reps: 8,
        rir: 2.0,
        unit: 'kg',
        setType: SetType.drop,
        dropWeights: [0, -5, 72, 65], // Invalid weights (0, negative)
        dropPercents: [10, -10, -15], // Invalid percents (positive)
        rpBursts: [0, -2, 8, 3], // Invalid bursts (0, negative)
        rpRestSec: 200, // Invalid rest time
        clusterSize: 1, // Invalid cluster size
        clusterRestSec: 200, // Invalid rest time
        clusterTotalReps: 2, // Invalid total reps
        amrap: true,
      );

      final normalized = LocalSetLog.normalizeAdvancedFields(log);

      expect(normalized.dropWeights, [72, 65]); // Only positive weights
      expect(normalized.dropPercents, [-10, -15]); // Only negative percents
      expect(normalized.rpBursts, [8, 3]); // Only positive bursts
      expect(normalized.rpRestSec, 60); // Clamped to max 60
      expect(normalized.clusterSize, 2); // Clamped to min 2
      expect(normalized.clusterRestSec, 60); // Clamped to max 60
      expect(normalized.clusterTotalReps, 6); // Clamped to min 6
    });

    test('normalizeAdvancedFields handles AMRAP with zero reps', () {
      final log = LocalSetLog(
        date: DateTime.now(),
        weight: 80,
        reps: 0, // Zero reps
        rir: 2.0,
        unit: 'kg',
        setType: SetType.amrap,
        amrap: true,
      );

      final normalized = LocalSetLog.normalizeAdvancedFields(log);

      expect(normalized.amrap, false); // AMRAP disabled for zero reps
    });
  });
}
