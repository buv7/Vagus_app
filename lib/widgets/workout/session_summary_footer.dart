// lib/widgets/workout/session_summary_footer.dart
import 'package:flutter/material.dart';

class SessionSummaryFooter extends StatelessWidget {
  final int done;
  final int planned;
  final double tonnage; // sum(weight*reps) from this sheet's set rows
  final VoidCallback onCopy;

  const SessionSummaryFooter({
    super.key,
    required this.done,
    required this.planned,
    required this.tonnage,
    required this.onCopy,
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
      child: Row(
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
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy summary'),
          ),
        ],
      ),
    );
  }
}
