import 'package:flutter/material.dart';

class MiniDayCard extends StatelessWidget {
  final DateTime day;
  final double sleepH;
  final double steps;
  final double kcalIn;
  final double kcalOut;
  final double compliancePct; // use same weekly value as proxy or per-day if you add later

  const MiniDayCard({
    super.key,
    required this.day,
    required this.sleepH,
    required this.steps,
    required this.kcalIn,
    required this.kcalOut,
    required this.compliancePct,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String dow = ['M','T','W','T','F','S','S'][day.weekday - 1];

    Color compColor() {
      if (compliancePct >= 85) return Colors.greenAccent.shade400;
      if (compliancePct >= 60) return Colors.amberAccent.shade400;
      return Colors.redAccent.shade400;
    }

    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(dow, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: compColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${compliancePct.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w800, color: compColor())),
            ),
          ]),
          const SizedBox(height: 8),
          _kv(context, 'Sleep', '${sleepH.toStringAsFixed(1)}h'),
          _kv(context, 'Steps', steps.toStringAsFixed(0)),
          _kv(context, 'In', '${kcalIn.toStringAsFixed(0)} kcal'),
          _kv(context, 'Out', '${kcalOut.toStringAsFixed(0)} kcal'),
        ],
      ),
    );
  }

  Widget _kv(BuildContext ctx, String k, String v) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(k, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7))),
          const Spacer(),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
