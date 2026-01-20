// lib/widgets/fatigue/intensifier_contribution_list.dart
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// List of top intensifiers by fatigue contribution
class IntensifierContributionList extends StatelessWidget {
  final Map<String, dynamic> intensifierFatigue; // {"rest_pause": 14, ...}
  final int limit; // Top N intensifiers

  const IntensifierContributionList({
    super.key,
    required this.intensifierFatigue,
    this.limit = 5,
  });

  List<MapEntry<String, int>> get _sortedIntensifiers {
    final entries = <MapEntry<String, int>>[];
    
    intensifierFatigue.forEach((key, value) {
      final score = value is int ? value : (value is num ? value.toInt() : 0);
      if (score > 0) {
        entries.add(MapEntry(key, score));
      }
    });

    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  String _formatIntensifierName(String name) {
    // Capitalize and format
    if (name.isEmpty) return name;
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  IconData _getIntensifierIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rest') || lower.contains('pause')) {
      return Icons.pause_circle;
    }
    if (lower.contains('drop')) {
      return Icons.trending_down;
    }
    if (lower.contains('cluster')) {
      return Icons.view_module;
    }
    if (lower.contains('myo')) {
      return Icons.flash_on;
    }
    if (lower.contains('tempo')) {
      return Icons.timer;
    }
    if (lower.contains('isometric')) {
      return Icons.lock;
    }
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedIntensifiers;

    if (sorted.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: DesignTokens.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No intensifier data',
                style: TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
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
          const Text(
            'Intensifier Contribution',
            style: TextStyle(
              fontSize: 18,
              color: DesignTokens.neutralWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.map((entry) => _buildIntensifierRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildIntensifierRow(String intensifier, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.accentPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIntensifierIcon(intensifier),
              color: DesignTokens.accentPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatIntensifierName(intensifier),
              style: const TextStyle(
                fontSize: 14,
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 14,
              color: DesignTokens.accentPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
