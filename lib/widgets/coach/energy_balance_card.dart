import 'package:flutter/material.dart';
import '../../services/coach/weekly_review_service.dart';

class EnergyBalanceCard extends StatelessWidget {
  final EnergyBalance energy;
  const EnergyBalanceCard({super.key, required this.energy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = energy.net;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metric(context, 'Total In', '${energy.totalIn.toStringAsFixed(0)} kcal'),
          ),
          Expanded(
            child: _metric(context, 'Total Out', '${energy.totalOut.toStringAsFixed(0)} kcal'),
          ),
          Expanded(
            child: _metric(context, 'Net', '${net >= 0 ? '+' : ''}${net.toStringAsFixed(0)} kcal'),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.7))),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }
}
