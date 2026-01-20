import 'digestion_tracking_service.dart';

class AdherencePsychologyService {
  AdherencePsychologyService._();
  static final AdherencePsychologyService I = AdherencePsychologyService._();

  Future<double> getAdherenceScore({
    required String userId,
    int days = 7,
  }) async {
    final trends = await DigestionTrackingService.I.getBloatTrends(
      userId: userId,
      days: days,
    );

    final avgCompliance = trends['avgCompliance'] as double;
    final avgBloat = trends['avgBloat'] as double;

    // Score: compliance weighted 70%, bloat inverse weighted 30%
    final complianceScore = avgCompliance * 0.7;
    final bloatScore = (10 - avgBloat) / 10 * 100 * 0.3;

    return (complianceScore + bloatScore).clamp(0.0, 100.0);
  }

  String getMotivationNudge({
    required double adherenceScore,
    required double avgBloat,
    required double avgCompliance,
  }) {
    if (adherenceScore >= 80) {
      return 'You\'re crushing it. Keep the momentum.';
    } else if (adherenceScore >= 60) {
      return 'Solid progress. Small tweaks can push you higher.';
    } else if (avgBloat > 6) {
      return 'Bloat is elevated. Focus on digestion-friendly choices today.';
    } else if (avgCompliance < 50) {
      return 'Compliance is slipping. One meal at a time—you\'ve got this.';
    } else {
      return 'You\'re building the habit. Consistency > perfection.';
    }
  }

  Future<Map<String, dynamic>> getRiskFlags({
    required String userId,
    int days = 7,
  }) async {
    final trends = await DigestionTrackingService.I.getBloatTrends(
      userId: userId,
      days: days,
    );

    final avgCompliance = trends['avgCompliance'] as double;
    final avgBloat = trends['avgBloat'] as double;
    final trend = trends['trend'] as String;

    final flags = <String, bool>{
      'lowAdherence': avgCompliance < 50,
      'highBloat': avgBloat > 7,
      'bloatIncreasing': trend == 'increasing',
      'complianceDeclining': avgCompliance < 60 && trend == 'decreasing',
    };

    return {
      'flags': flags,
      'severity': _calculateSeverity(flags),
      'recommendations': _getRecommendations(flags, avgCompliance, avgBloat),
    };
  }

  String _calculateSeverity(Map<String, bool> flags) {
    final highRiskCount = flags.values.where((v) => v).length;
    if (highRiskCount >= 3) return 'high';
    if (highRiskCount >= 2) return 'medium';
    if (highRiskCount >= 1) return 'low';
    return 'none';
  }

  List<String> _getRecommendations(
    Map<String, bool> flags,
    double avgCompliance,
    double avgBloat,
  ) {
    final recommendations = <String>[];

    if (flags['lowAdherence'] == true) {
      recommendations.add('Focus on hitting protein targets first.');
    }
    if (flags['highBloat'] == true) {
      recommendations.add('Reduce processed foods and large meals.');
    }
    if (flags['bloatIncreasing'] == true) {
      recommendations.add('Track bloating factors to identify triggers.');
    }
    if (flags['complianceDeclining'] == true) {
      recommendations.add('Simplify meal prep for easier adherence.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Keep tracking. You\'re on the right track.');
    }

    return recommendations;
  }
}
