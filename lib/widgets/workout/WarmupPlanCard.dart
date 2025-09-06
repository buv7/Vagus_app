// lib/widgets/workout/WarmupPlanCard.dart
import 'package:flutter/material.dart';
import '../../utils/load_math.dart';

class WarmupPlanCard extends StatelessWidget {
  final double topSet;         // same unit as chosen in bar
  final LoadUnit unit;
  final double barWeight;
  
  const WarmupPlanCard({
    super.key, 
    required this.topSet, 
    required this.unit, 
    required this.barWeight
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warmupSets = LoadMath.buildWarmup(
      topSet: topSet,
      unit: unit,
      barWeight: barWeight,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Warm-up Plan',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${topSet.toStringAsFixed(0)} ${unit.name} top set',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warmupSets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            final plates = LoadMath.platesPerSide(
              total: set.weight,
              unit: unit,
              barWeight: barWeight,
            );
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < warmupSets.length - 1 ? 8 : 0),
              child: _buildWarmupSetRow(set, plates, theme, isDark),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWarmupSetRow(WarmupSet set, List<double> plates, ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Set info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${set.percent}% × ${set.reps}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${set.weight.toStringAsFixed(0)} ${unit.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        
        // Plate breakdown
        if (plates.isNotEmpty) ...[
          const SizedBox(width: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: plates.map((plate) => _buildPlateChip(plate, theme, isDark)).toList(),
          ),
        ] else ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Bar only',
              style: theme.textTheme.labelSmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlateChip(double plate, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${plate.toStringAsFixed(plate < 1 ? 1 : 0)}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
