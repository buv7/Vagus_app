// lib/widgets/workout/AutoProgressionTip.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../services/workout/exercise_history_service.dart';
import '../../utils/progression_rules.dart';

class AutoProgressionTip extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final List<ExerciseSetLog> logs;
  final bool useKg;
  final void Function(double load, String unit)? onApply;
  
  const AutoProgressionTip({
    super.key, 
    required this.exercise, 
    required this.logs, 
    required this.useKg, 
    this.onApply
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine target reps and get last log
    final targetReps = exercise['reps'] as int?;
    final last = logs.isNotEmpty ? logs.first : null;
    
    // Compute advice
    final advice = ProgressionRules.suggest(
      targetReps: targetReps,
      lastWeight: last?.weight,
      lastReps: last?.reps,
      lastRir: last?.rir,
      useKg: useKg,
    );
    
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Auto-Progression',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Advice title
          Text(
            advice.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _getAdviceColor(advice, theme, isDark),
            ),
          ),
          const SizedBox(height: 4),
          
          // Rationale
          Text(
            advice.rationale,
            style: theme.textTheme.bodySmall?.copyWith(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              if (last?.weight != null) ...[
                OutlinedButton(
                  onPressed: () {
                    final weight = last!.weight!;
                    _applyLast(weight, theme);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: Builder(
                    builder: (context) {
                      final weight = last!.weight!;
                      return Text('Apply last (${weight.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'})');
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (advice.delta != null && last?.weight != null) ...[
                FilledButton(
                  onPressed: () {
                    final weight = last!.weight!;
                    final delta = advice.delta!;
                    _applySuggested(weight + delta, theme);
                  },
                  child: Builder(
                    builder: (context) {
                      final weight = last!.weight!;
                      final delta = advice.delta!;
                      return Text('Apply suggested (${(weight + delta).toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'})');
                    },
                  ),
                ),
              ] else if (last?.weight == null) ...[
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Apply last (no data)'),
                ),
              ],
            ],
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAdviceColor(ProgressionAdvice advice, ThemeData theme, bool isDark) {
    if (advice.title.contains('Add')) {
      return Colors.green;
    } else if (advice.title.contains('Reduce')) {
      return Colors.orange;
    } else {
      return (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7);
    }
  }

  void _applyLast(double weight, ThemeData theme) {
    final unit = useKg ? 'kg' : 'lb';
    onApply?.call(weight, unit);
    _showToast('Applied last weight: ${weight.toStringAsFixed(0)} $unit');
  }

  void _applySuggested(double weight, ThemeData theme) {
    final unit = useKg ? 'kg' : 'lb';
    onApply?.call(weight, unit);
    _showToast('Applied suggested weight: ${weight.toStringAsFixed(0)} $unit');
  }

  void _showToast(String message) {
    // This would typically use ScaffoldMessenger, but we need context
    // The parent widget should handle the toast display
  }
}
