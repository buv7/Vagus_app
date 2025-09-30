// lib/widgets/workout/ExerciseHistoryCard.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../services/workout/exercise_history_service.dart';
import '../../utils/set_type_format.dart';
import '../../services/workout/exercise_local_log_service.dart';

class ExerciseHistoryCard extends StatefulWidget {
  final String clientId;
  final Map<String, dynamic> exercise;
  final bool useKg; // for labels
  final Function(List<ExerciseSetLog>)? onLogsLoaded; // callback to pass logs to parent
  
  const ExerciseHistoryCard({
    super.key, 
    required this.clientId, 
    required this.exercise, 
    required this.useKg,
    this.onLogsLoaded,
  });

  @override
  State<ExerciseHistoryCard> createState() => _ExerciseHistoryCardState();
}

class _ExerciseHistoryCardState extends State<ExerciseHistoryCard> {
  List<ExerciseSetLog> _logs = [];
  ExercisePRs? _prs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      // Try to get real data first
      final logs = await ExerciseHistoryService.instance.lastLogs(
        clientId: widget.clientId,
        exerciseName: (widget.exercise['name'] ?? '').toString(),
        limit: 3,
      );
      
      // If no real data, use mock data for demonstration
      final finalLogs = logs.isEmpty 
        ? await ExerciseHistoryService.instance.getMockLogs(
            exerciseName: (widget.exercise['name'] ?? '').toString(),
            limit: 3,
          )
        : logs;
      
      final prs = ExerciseHistoryService.instance.computePRs(finalLogs);
      
      if (mounted) {
        setState(() {
          _logs = finalLogs;
          _prs = prs;
          _loading = false;
        });
        widget.onLogsLoaded?.call(finalLogs);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
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
              Text(
                'History & PR',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_loading) ...[
            // Loading state
            Text(
              'Loading history...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              ),
            ),
          ] else if (_logs.isEmpty) ...[
            // Empty state
            Text(
              'No history yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              ),
            ),
          ] else ...[
            // PRs row
            if (_prs != null) _buildPRsRow(theme, isDark),
            const SizedBox(height: 12),
            
            // History list
            ..._logs.asMap().entries.map((entry) {
              final index = entry.key;
              final log = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < _logs.length - 1 ? 8 : 0),
                child: _buildLogRow(log, theme, isDark),
              );
            }),
          ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPRsRow(ThemeData theme, bool isDark) {
    final prs = _prs!;
    final unit = widget.useKg ? 'kg' : 'lb';
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'PRs: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          if (prs.bestWeight != null) ...[
            Text('${prs.bestWeight!.toStringAsFixed(0)} $unit', style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
          ],
          if (prs.bestReps != null) ...[
            Text('${prs.bestReps} reps', style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
          ],
          if (prs.bestEst1RM != null) ...[
            Text('${prs.bestEst1RM!.toStringAsFixed(0)} $unit 1RM', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildLogRow(ExerciseSetLog log, ThemeData theme, bool isDark) {
    final unit = widget.useKg ? 'kg' : 'lb';
    final dateStr = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text('—', style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            if (log.weight != null) ...[
              Text(
                '${log.weight!.toStringAsFixed(0)} $unit',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (log.reps != null) ...[
                Text(' × ${log.reps}', style: theme.textTheme.bodySmall),
              ],
              if (log.rir != null) ...[
                Text(' @ RIR ${log.rir!.toStringAsFixed(1)}', style: theme.textTheme.bodySmall),
              ],
            ] else ...[
              Text(
                'No weight recorded',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        // Advanced set type info
        if (log.setType != null && log.setType != SetType.normal) ...[
          const SizedBox(height: 4),
          _buildSetTypeDescriptor(log, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildSetTypeDescriptor(ExerciseSetLog log, ThemeData theme, bool isDark) {
    final descriptor = SetTypeFormat.descriptor(
      weight: log.weight ?? 0,
      unit: widget.useKg ? 'kg' : 'lb',
      reps: log.reps ?? 0,
      setType: log.setType,
      dropWeights: log.dropWeights,
      dropPercents: log.dropPercents,
      rpBursts: log.rpBursts,
      rpRestSec: log.rpRestSec,
      clusterSize: log.clusterSize,
      clusterRestSec: log.clusterRestSec,
      clusterTotalReps: log.clusterTotalReps,
      amrap: log.amrap,
    );
    
    if (descriptor.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        descriptor,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
