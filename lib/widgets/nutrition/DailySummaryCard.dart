import 'package:flutter/material.dart';
import '../../models/nutrition/nutrition_plan.dart';

class DailySummaryCard extends StatelessWidget {
  final DailySummary summary;
  final bool isCompact;

  const DailySummaryCard({
    super.key,
    required this.summary,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Daily Totals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Macros row
            Row(
              children: [
                Expanded(
                  child: _buildMacroItem(
                    'Protein',
                    '${summary.totalProtein.toStringAsFixed(1)}g',
                    Colors.red.shade600,
                  ),
                ),
                Expanded(
                  child: _buildMacroItem(
                    'Carbs',
                    '${summary.totalCarbs.toStringAsFixed(1)}g',
                    Colors.orange.shade600,
                  ),
                ),
                Expanded(
                  child: _buildMacroItem(
                    'Fat',
                    '${summary.totalFat.toStringAsFixed(1)}g',
                    Colors.yellow.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMacroItem(
                    'Calories',
                    '${summary.totalKcal.toStringAsFixed(0)} kcal',
                    Colors.green.shade600,
                  ),
                ),
              ],
            ),
            
            if (!isCompact) ...[
              const SizedBox(height: 12),
              
              // Minerals row
              Row(
                children: [
                  Expanded(
                    child: _buildMineralItem(
                      'Sodium',
                      '${summary.totalSodium.toStringAsFixed(0)}mg',
                      summary.totalSodium,
                      isSodium: true,
                    ),
                  ),
                  Expanded(
                    child: _buildMineralItem(
                      'Potassium',
                      '${summary.totalPotassium.toStringAsFixed(0)}mg',
                      summary.totalPotassium,
                      isSodium: false,
                    ),
                  ),
                ],
              ),
              
              // Warnings
              if (_hasWarnings()) ...[
                const SizedBox(height: 12),
                _buildWarnings(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMineralItem(String label, String value, double amount, {required bool isSodium}) {
    final isHigh = isSodium ? amount > 2300 : amount > 4700;
    final isLow = isSodium ? amount < 500 : amount < 3500;
    
    Color color = Colors.grey.shade600;
    if (isHigh) {
      color = Colors.red.shade600;
    } else if (isLow) {
      color = Colors.orange.shade600;
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  bool _hasWarnings() {
    return summary.totalSodium > 2300 ||
           summary.totalSodium < 500 ||
           summary.totalPotassium > 4700 ||
           summary.totalPotassium < 3500;
  }

  Widget _buildWarnings() {
    final warnings = <String>[];
    
    if (summary.totalSodium > 2300) {
      warnings.add('High sodium intake');
    } else if (summary.totalSodium < 500) {
      warnings.add('Low sodium intake');
    }
    
    if (summary.totalPotassium > 4700) {
      warnings.add('High potassium intake');
    } else if (summary.totalPotassium < 3500) {
      warnings.add('Low potassium intake');
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 4),
              Text(
                'Mineral Warnings',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...warnings.map((warning) => Text(
            '• $warning',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade700,
            ),
          )),
        ],
      ),
    );
  }
}
