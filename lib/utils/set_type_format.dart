// lib/utils/set_type_format.dart
import '../services/workout/exercise_local_log_service.dart';

class SetTypeFormat {
  /// Generates a friendly descriptor string for advanced set types.
  /// Returns empty string for normal sets or null setType.
  static String descriptor({
    required double weight,
    required String unit,
    required int reps,
    SetType? setType,
    List<double>? dropWeights,
    List<double>? dropPercents,
    List<int>? rpBursts,
    int? rpRestSec,
    int? clusterSize,
    int? clusterRestSec,
    int? clusterTotalReps,
    bool? amrap,
  }) {
    if (setType == null) return '';
    
    switch (setType) {
      case SetType.drop:
        return _formatDropSet(weight, unit, dropWeights, dropPercents);
      case SetType.restPause:
        return _formatRestPause(rpBursts, rpRestSec);
      case SetType.cluster:
        return _formatCluster(clusterSize, clusterRestSec, clusterTotalReps, reps);
      case SetType.amrap:
        return 'AMRAP $reps';
      default:
        return '';
    }
  }

  static String _formatDropSet(double weight, String unit, List<double>? dropWeights, List<double>? dropPercents) {
    final drops = dropWeights?.length ?? dropPercents?.length ?? 0;
    if (drops == 0) return 'Drop ×0';
    
    if (dropWeights != null && dropWeights.isNotEmpty) {
      // Prefer weights if present: "Drop ×3 (80 → 72 → 65)"
      final weights = [weight, ...dropWeights];
      final weightStr = weights.map((w) => w.toStringAsFixed(0)).join(' → ');
      return 'Drop ×$drops ($weightStr)';
    } else if (dropPercents != null && dropPercents.isNotEmpty) {
      // Use percents: "Drop ×2 (-10%, -10%)"
      final percentStr = dropPercents.map((p) => '${p.toInt()}%').join(', ');
      return 'Drop ×$drops ($percentStr)';
    }
    
    return 'Drop ×$drops';
  }

  static String _formatRestPause(List<int>? rpBursts, int? rpRestSec) {
    final restSec = rpRestSec ?? 20;
    final bursts = rpBursts?.join('+') ?? '';
    return 'Rest-Pause ${restSec}s ($bursts)';
  }

  static String _formatCluster(int? clusterSize, int? clusterRestSec, int? clusterTotalReps, int reps) {
    final size = clusterSize ?? 2;
    final restSec = clusterRestSec ?? 15;
    final total = clusterTotalReps ?? reps;
    return 'Cluster ${size}x/${restSec}s (total $total)';
  }
}
