// test/set_type_format_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/utils/set_type_format.dart';
import 'package:vagus_app/services/workout/exercise_local_log_service.dart';

void main() {
  group('SetTypeFormat', () {
    test('descriptor for drop set with weights', () {
      final descriptor = SetTypeFormat.descriptor(
        weight: 80,
        unit: 'kg',
        reps: 15,
        setType: SetType.drop,
        dropWeights: [72, 65],
      );
      expect(descriptor, 'Drop ×2 (80 → 72 → 65)');
    });

    test('descriptor for drop set with percents', () {
      final descriptor = SetTypeFormat.descriptor(
        weight: 80,
        unit: 'kg',
        reps: 15,
        setType: SetType.drop,
        dropPercents: [-10, -10],
      );
      expect(descriptor, 'Drop ×2 (-10%, -10%)');
    });

    test('descriptor for rest-pause', () {
      final descriptor = SetTypeFormat.descriptor(
        weight: 80,
        unit: 'kg',
        reps: 13,
        setType: SetType.restPause,
        rpBursts: [8, 3, 2],
        rpRestSec: 20,
      );
      expect(descriptor, 'Rest-Pause 20s (8+3+2)');
    });

    test('descriptor for cluster', () {
      final descriptor = SetTypeFormat.descriptor(
        weight: 100,
        unit: 'kg',
        reps: 15,
        setType: SetType.cluster,
        clusterSize: 3,
        clusterRestSec: 15,
        clusterTotalReps: 15,
      );
      expect(descriptor, 'Cluster 3x/15s (total 15)');
    });

    test('descriptor for AMRAP', () {
      final descriptor = SetTypeFormat.descriptor(
        weight: 70,
        unit: 'kg',
        reps: 13,
        setType: SetType.amrap,
        amrap: true,
      );
      expect(descriptor, 'AMRAP 13');
    });

    test('descriptor for normal set returns empty', () {
      final descriptor = SetTypeFormat.descriptor(
        weight: 80,
        unit: 'kg',
        reps: 8,
        setType: SetType.normal,
      );
      expect(descriptor, '');
    });

    test('descriptor for null setType returns empty', () {
      final descriptor = SetTypeFormat.descriptor(
        weight: 80,
        unit: 'kg',
        reps: 8,
        setType: null,
      );
      expect(descriptor, '');
    });
  });
}
