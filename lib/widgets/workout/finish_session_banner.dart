// lib/widgets/workout/finish_session_banner.dart
import 'package:flutter/material.dart';

class FinishSessionBanner extends StatelessWidget {
  final String exerciseName;
  final int done;
  final int planned;
  final double tonnage;
  final ({double? w, int? r, double rir})? bestSet; // pick by highest weight*reps or weight then reps
  final VoidCallback onSendToCoach;
  final VoidCallback onSaveDraft;
  final VoidCallback onClearLocal;
  final String? draftText; // optional draft text for today
  final VoidCallback? onRestoreDraft; // optional restore draft callback

  const FinishSessionBanner({
    super.key,
    required this.exerciseName,
    required this.done,
    required this.planned,
    required this.tonnage,
    required this.bestSet,
    required this.onSendToCoach,
    required this.onSaveDraft,
    required this.onClearLocal,
    this.draftText,
    this.onRestoreDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finish Session',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          // Draft restore affordance
          if (draftText != null && draftText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Draft exists for today',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (onRestoreDraft != null)
                  TextButton(
                    onPressed: onRestoreDraft,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Restore',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$done/$planned sets',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Text(
                'Tonnage: ${tonnage.toStringAsFixed(0)}',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (bestSet != null)
                Text(
                  'Best: ${(bestSet!.w ?? 0).toStringAsFixed(0)} × ${bestSet!.r ?? 0} (RIR ${bestSet!.rir.toStringAsFixed(1)})',
                  style: theme.textTheme.labelMedium,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onSendToCoach,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send to coach'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onSaveDraft,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save draft'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onClearLocal,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
