// lib/widgets/fatigue/muscle_fatigue_list.dart
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// List of muscles sorted by fatigue level with progress bars
class MuscleFatigueList extends StatelessWidget {
  final Map<String, dynamic> muscleFatigue; // {"chest": 18, "back": 12, ...}

  const MuscleFatigueList({
    super.key,
    required this.muscleFatigue,
  });

  List<MapEntry<String, int>> get _sortedMuscles {
    final entries = <MapEntry<String, int>>[];
    
    muscleFatigue.forEach((key, value) {
      final score = value is int ? value : (value is num ? value.toInt() : 0);
      if (score > 0) {
        entries.add(MapEntry(key, score));
      }
    });

    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String _formatMuscleName(String name) {
    // Capitalize first letter and replace underscores
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedMuscles;

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
                Icons.fitness_center,
                color: DesignTokens.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No muscle fatigue data',
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
            'Muscle Fatigue',
            style: TextStyle(
              fontSize: 18,
              color: DesignTokens.neutralWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.map((entry) => _buildMuscleRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildMuscleRow(String muscle, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMuscleName(muscle),
                style: const TextStyle(
                  fontSize: 14,
                  color: DesignTokens.neutralWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 14,
                  color: DesignTokens.accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 6,
              backgroundColor: DesignTokens.primaryDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getMuscleColor(score),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMuscleColor(int score) {
    if (score >= 60) return DesignTokens.danger;
    if (score >= 40) return DesignTokens.accentOrange;
    if (score >= 20) return DesignTokens.accentBlue;
    return DesignTokens.accentGreen;
  }
}
