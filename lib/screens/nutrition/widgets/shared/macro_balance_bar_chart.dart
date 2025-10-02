import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';

/// Gorgeous horizontal stacked bar chart for macro distribution
/// Features: Gradient fills, percentage labels, target comparison
class MacroBalanceBarChart extends StatefulWidget {
  final double protein;
  final double carbs;
  final double fat;
  final double targetProteinPercent;
  final double targetCarbsPercent;
  final double targetFatPercent;
  final bool showTargetComparison;
  final bool animated;

  const MacroBalanceBarChart({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.targetProteinPercent = 30.0,
    this.targetCarbsPercent = 40.0,
    this.targetFatPercent = 30.0,
    this.showTargetComparison = true,
    this.animated = true,
  });

  @override
  State<MacroBalanceBarChart> createState() => _MacroBalanceBarChartState();
}

class _MacroBalanceBarChartState extends State<MacroBalanceBarChart>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.animated) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Macro Distribution',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: DesignTokens.space16),

        // Current distribution bar
        _buildDistributionBar(isTarget: false),

        if (widget.showTargetComparison) ...[
          const SizedBox(height: DesignTokens.space12),

          // Target label
          Text(
            'Target Distribution',
            style: TextStyle(
              color: AppTheme.lightGrey.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Target distribution bar
          _buildDistributionBar(isTarget: true),
        ],

        const SizedBox(height: DesignTokens.space16),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildDistributionBar({required bool isTarget}) {
    final total = widget.protein + widget.carbs + widget.fat;

    final proteinPercent = isTarget
      ? widget.targetProteinPercent
      : total > 0 ? (widget.protein / total) * 100 : 0;
    final carbsPercent = isTarget
      ? widget.targetCarbsPercent
      : total > 0 ? (widget.carbs / total) * 100 : 0;
    final fatPercent = isTarget
      ? widget.targetFatPercent
      : total > 0 ? (widget.fat / total) * 100 : 0;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          height: isTarget ? 12 : 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTarget ? 6 : 10),
            boxShadow: isTarget ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isTarget ? 6 : 10),
            child: Row(
              children: [
                // Protein section
                Expanded(
                  flex: (proteinPercent * _widthAnimation.value).round(),
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00D9A3),
                          const Color(0xFF00D9A3).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: !isTarget && proteinPercent > 15
                      ? Center(
                          child: Text(
                            '${proteinPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  ),
                ),

                // Carbs section
                Expanded(
                  flex: (carbsPercent * _widthAnimation.value).round(),
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF9A3C),
                          const Color(0xFFFF9A3C).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: !isTarget && carbsPercent > 15
                      ? Center(
                          child: Text(
                            '${carbsPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  ),
                ),

                // Fat section
                Expanded(
                  flex: (fatPercent * _widthAnimation.value).round(),
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFD93C),
                          const Color(0xFFFFD93C).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: !isTarget && fatPercent > 15
                      ? Center(
                          child: Text(
                            '${fatPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    final total = widget.protein + widget.carbs + widget.fat;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(
          'Protein',
          const Color(0xFF00D9A3),
          widget.protein,
          total > 0 ? (widget.protein / total) * 100 : 0,
          widget.targetProteinPercent,
        ),
        _buildLegendItem(
          'Carbs',
          const Color(0xFFFF9A3C),
          widget.carbs,
          total > 0 ? (widget.carbs / total) * 100 : 0,
          widget.targetCarbsPercent,
        ),
        _buildLegendItem(
          'Fat',
          const Color(0xFFFFD93C),
          widget.fat,
          total > 0 ? (widget.fat / total) * 100 : 0,
          widget.targetFatPercent,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    double grams,
    double actualPercent,
    double targetPercent,
  ) {
    final difference = actualPercent - targetPercent;
    final isOnTrack = difference.abs() <= 5; // Within 5% is considered on track

    return Column(
      children: [
        // Color indicator
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.space8),

        // Label
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: DesignTokens.space4),

        // Grams
        Text(
          '${grams.toStringAsFixed(0)}g',
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: DesignTokens.space2),

        // Percentage with status
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${actualPercent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: isOnTrack ? AppTheme.accentGreen : AppTheme.lightGrey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isOnTrack) ...[
              const SizedBox(width: 2),
              Icon(
                difference > 0 ? Icons.trending_up : Icons.trending_down,
                size: 10,
                color: difference > 0 ? Colors.orange : Colors.blue,
              ),
            ],
          ],
        ),

        // Target comparison
        if (widget.showTargetComparison) ...[
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Target: ${targetPercent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: AppTheme.lightGrey.withValues(alpha: 0.6),
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }
}

/// Simplified macro balance widget for smaller spaces
class CompactMacroBalance extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;

  const CompactMacroBalance({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final total = protein + carbs + fat;

    if (total == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.mediumGrey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final proteinPercent = (protein / total) * 100;
    final carbsPercent = (carbs / total) * 100;
    final fatPercent = (fat / total) * 100;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            if (proteinPercent > 0)
              Expanded(
                flex: proteinPercent.round(),
                child: Container(
                  color: const Color(0xFF00D9A3),
                ),
              ),
            if (carbsPercent > 0)
              Expanded(
                flex: carbsPercent.round(),
                child: Container(
                  color: const Color(0xFFFF9A3C),
                ),
              ),
            if (fatPercent > 0)
              Expanded(
                flex: fatPercent.round(),
                child: Container(
                  color: const Color(0xFFFFD93C),
                ),
              ),
          ],
        ),
      ),
    );
  }
}