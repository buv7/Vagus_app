import 'package:flutter/material.dart';
import '../../models/nutrition/money.dart';
import '../../services/nutrition/locale_helper.dart';

/// Cost summary chip for daily/weekly cost display
class CostSummaryChip extends StatelessWidget {
  final String labelKey; // 'daily_cost' or 'weekly_cost'
  final Money amount;
  final VoidCallback? onTap;
  
  const CostSummaryChip({
    super.key, 
    required this.labelKey, 
    required this.amount, 
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final label = '${LocaleHelper.t(labelKey, language)}: ${amount.toStringDisplay(locale: language)}';
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Chip(
        avatar: const Icon(Icons.payments_outlined, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Cost breakdown row for modal display
class CostBreakdownRow {
  final String title;
  final Money amount;
  
  const CostBreakdownRow(this.title, this.amount);
}

/// Show cost breakdown in a modal bottom sheet
Future<void> showCostBreakdownSheet(
  BuildContext context, {
  required String titleKey, // 'daily_cost' / 'weekly_cost'
  required List<CostBreakdownRow> rows,
  required Money total,
}) async {
  final language = Localizations.localeOf(context).languageCode;
  
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleHelper.t(titleKey, language),
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  LocaleHelper.t('no_cost_data', language),
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...rows.map((r) => ListTile(
                dense: true,
                title: Text(r.title),
                trailing: Text(
                  r.amount.toStringDisplay(locale: language),
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
            if (rows.isNotEmpty) ...[
              const Divider(),
              ListTile(
                dense: true,
                title: Text(
                  LocaleHelper.t('cost', language),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  total.toStringDisplay(locale: language),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
