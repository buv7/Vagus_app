import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../services/coach/weekly_review_service.dart';

class WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  const WeeklySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: DesignTokens.neutralWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: DesignTokens.accentBlue,
                      size: 20,
                    ),
                    SizedBox(width: DesignTokens.space8),
                    Text(
                      'Weekly Summary',
                      style: TextStyle(
                        color: DesignTokens.neutralWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space16),
                Row(
                  children: [
                    tile('Compliance', '${summary.compliancePercent.toStringAsFixed(1)}%'),
                    const SizedBox(width: DesignTokens.space8),
                    tile('Sessions', '${summary.sessionsDone} done • ${summary.sessionsSkipped} skipped'),
                  ],
                ),
                const SizedBox(height: DesignTokens.space8),
                Row(
                  children: [
                    tile('Tonnage', '${summary.totalTonnage.toStringAsFixed(0)} kg'),
                    const SizedBox(width: DesignTokens.space8),
                    tile('Cardio', '${summary.cardioMinutes} mins'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
