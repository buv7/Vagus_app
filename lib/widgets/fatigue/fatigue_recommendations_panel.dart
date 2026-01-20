// lib/widgets/fatigue/fatigue_recommendations_panel.dart
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Deterministic recommendations based on fatigue scores (NO AI)
class FatigueRecommendationsPanel extends StatelessWidget {
  final int fatigueScore; // 0-100
  final int cnsScore; // 0-100
  final int localScore; // 0-100
  final int jointScore; // 0-100

  const FatigueRecommendationsPanel({
    super.key,
    required this.fatigueScore,
    required this.cnsScore,
    required this.localScore,
    required this.jointScore,
  });

  List<String> get _recommendations {
    final recommendations = <String>[];

    // Overall fatigue recommendations
    if (fatigueScore > 80) {
      recommendations.add('🔴 Critical fatigue: Consider deload week or rest day');
    } else if (fatigueScore > 60) {
      recommendations.add('🟠 High fatigue: Reduce volume or intensity tomorrow');
    } else if (fatigueScore > 40) {
      recommendations.add('🟡 Moderate fatigue: Monitor recovery, adjust if needed');
    } else {
      recommendations.add('🟢 Fresh: Ready for high-intensity training');
    }

    // CNS-specific recommendations
    if (cnsScore > 60) {
      recommendations.add('🧠 High CNS load: Reduce compound movements and intensity methods');
    } else if (cnsScore > 40) {
      recommendations.add('🧠 Moderate CNS load: Limit heavy compounds to 1-2 exercises');
    }

    // Joint-specific recommendations
    if (jointScore > 60) {
      recommendations.add('🦴 High joint stress: Avoid loaded stretches and ROM extremes');
    } else if (jointScore > 40) {
      recommendations.add('🦴 Moderate joint stress: Reduce tempo work and partials');
    }

    // Local muscle-specific recommendations
    if (localScore > 60) {
      recommendations.add('💪 High local fatigue: Rotate movement patterns, avoid same muscle groups');
    } else if (localScore > 40) {
      recommendations.add('💪 Moderate local fatigue: Consider active recovery or lighter work');
    }

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = _recommendations;

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: DesignTokens.accentOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recovery Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  color: DesignTokens.neutralWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 14,
                color: DesignTokens.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
