import 'package:flutter/material.dart';
import '../charts/macro_donut.dart';
import '../charts/na_k_gauge.dart';
import '../charts/weekly_trend_spark.dart';
import '../../../theme/design_tokens.dart';

class DayInsightsPanel extends StatelessWidget {
  final double proteinG, carbsG, fatG;
  final int sodiumMg, potassiumMg, kcal;
  final List<double>? weeklyTrend; // Optional 7-day trend data
  
  const DayInsightsPanel({
    super.key, 
    required this.proteinG, 
    required this.carbsG, 
    required this.fatG, 
    required this.sodiumMg, 
    required this.potassiumMg, 
    required this.kcal,
    this.weeklyTrend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Main content row
            Row(
              children: [
                // Macro Donut
                MacroDonut(
                  proteinG: proteinG, 
                  carbsG: carbsG, 
                  fatG: fatG, 
                  centerLabel: '$kcal',
                  size: 100,
                ),
                const SizedBox(width: 16),
                
                // Na/K Gauge
                Expanded(
                  child: NaKGauge(
                    sodiumMg: sodiumMg, 
                    potassiumMg: potassiumMg
                  ),
                ),
              ],
            ),
            
            // Weekly trend (if available)
            if (weeklyTrend != null && weeklyTrend!.length == 7) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: theme.colorScheme.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '7-Day Trend',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              WeeklyTrendSpark(
                points: weeklyTrend!,
                color: theme.colorScheme.secondary,
                height: 30,
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Macro breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem(
                  'Protein', 
                  '${proteinG.toStringAsFixed(1)}g', 
                  theme.colorScheme.primary,
                ),
                _buildMacroItem(
                  'Carbs', 
                  '${carbsG.toStringAsFixed(1)}g', 
                  theme.colorScheme.tertiary,
                ),
                _buildMacroItem(
                  'Fat', 
                  '${fatG.toStringAsFixed(1)}g', 
                  theme.colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
