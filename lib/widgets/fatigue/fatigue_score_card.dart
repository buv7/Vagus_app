// lib/widgets/fatigue/fatigue_score_card.dart
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Large fatigue score card with status label and component chips
class FatigueScoreCard extends StatelessWidget {
  final int fatigueScore; // 0-100
  final int cnsScore; // 0-100
  final int localScore; // 0-100
  final int jointScore; // 0-100

  const FatigueScoreCard({
    super.key,
    required this.fatigueScore,
    required this.cnsScore,
    required this.localScore,
    required this.jointScore,
  });

  String get _statusLabel {
    if (fatigueScore <= 29) return 'Fresh';
    if (fatigueScore <= 59) return 'Accumulating';
    if (fatigueScore <= 79) return 'High';
    return 'Critical';
  }

  Color get _statusColor {
    if (fatigueScore <= 29) return DesignTokens.accentGreen;
    if (fatigueScore <= 59) return DesignTokens.accentBlue;
    if (fatigueScore <= 79) return DesignTokens.accentOrange;
    return DesignTokens.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fatigue Score',
                style: TextStyle(
                  fontSize: 16,
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Large score
          Center(
            child: Text(
              '$fatigueScore',
              style: const TextStyle(
                fontSize: 64,
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Score label
          const Center(
            child: Text(
              'out of 100',
              style: TextStyle(
                fontSize: 14,
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Component chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildComponentChip('CNS', cnsScore, DesignTokens.accentBlue),
              _buildComponentChip('Local', localScore, DesignTokens.accentGreen),
              _buildComponentChip('Joint', jointScore, DesignTokens.accentPurple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentChip(String label, int score, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: DesignTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
