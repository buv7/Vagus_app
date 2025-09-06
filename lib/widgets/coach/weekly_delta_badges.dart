import 'package:flutter/material.dart';
import '../../services/coach/weekly_review_service.dart';

class WeeklyDeltaBadges extends StatelessWidget {
  final WeeklyComparison cmp;
  const WeeklyDeltaBadges({super.key, required this.cmp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget badge(String label, Delta d, {String unit = ''}) {
      final color = d.up ? Colors.greenAccent.shade400 : (d.value == 0 ? (isDark ? Colors.white70 : Colors.black54) : Colors.redAccent.shade400);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(d.up ? Icons.trending_up : (d.value == 0 ? Icons.horizontal_rule : Icons.trending_down), size: 16, color: color),
            const SizedBox(width: 6),
            Text('$label ${d.signed(digits: unit.isEmpty ? 0 : 0)}$unit',
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        badge('Compliance', cmp.compliance, unit: '%'),
        badge('Tonnage', cmp.tonnage, unit: ' kg'),
        badge('Cardio', cmp.cardioMins, unit: ' min'),
        badge('Kcal In', cmp.kcalIn, unit: ' kcal'),
        badge('Kcal Out', cmp.kcalOut, unit: ' kcal'),
      ],
    );
  }
}
