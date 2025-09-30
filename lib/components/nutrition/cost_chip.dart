import 'package:flutter/material.dart';
import '../../models/nutrition/money.dart';

/// Reusable cost chip for displaying per-serving costs
class CostChip extends StatelessWidget {
  final Money costPerServing;
  final EdgeInsetsGeometry padding;
  final bool compact;
  
  const CostChip({
    super.key, 
    required this.costPerServing, 
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = costPerServing.toStringDisplay(locale: Localizations.localeOf(context).languageCode);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_money, size: 16),
          const SizedBox(width: 4),
          Text(
            compact ? text : '$text / ${MaterialLocalizations.of(context).scriptCategory == ScriptCategory.tall ? "serv" : "serv"}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
