import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../widgets/shared/macro_ring_chart.dart';

/// Beautiful macro breakdown visualization for meals
class MacroBreakdownChart extends StatefulWidget {
  final Meal meal;
  final bool showCalories;
  final bool interactive;

  const MacroBreakdownChart({
    super.key,
    required this.meal,
    this.showCalories = true,
    this.interactive = true,
  });

  @override
  State<MacroBreakdownChart> createState() => _MacroBreakdownChartState();
}

class _MacroBreakdownChartState extends State<MacroBreakdownChart>
    with TickerProviderStateMixin {
  late AnimationController _pieController;
  late AnimationController _ringController;
  late Animation<double> _pieAnimation;
  late Animation<double> _ringAnimation;

  int _selectedSegment = -1;

  @override
  void initState() {
    super.initState();

    _pieController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _ringController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pieAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pieController,
        curve: Curves.easeOutBack,
      ),
    );

    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _pieController.forward();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      _ringController.forward();
    });
  }

  @override
  void dispose() {
    _pieController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final macros = _calculateMacroData();

    return Column(
      children: [
        // Main chart
        Container(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pie chart
              AnimatedBuilder(
                animation: _pieAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(220, 220),
                    painter: _MacroPiePainter(
                      macros: macros,
                      progress: _pieAnimation.value,
                      selectedSegment: _selectedSegment,
                      interactive: widget.interactive,
                    ),
                  );
                },
              ),

              // Center info
              AnimatedBuilder(
                animation: _ringAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _ringAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.mediumGrey.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.meal.mealSummary.totalKcal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Tap detector for interactive mode
              if (widget.interactive)
                GestureDetector(
                  onTapDown: (details) => _handleTap(details, macros),
                  child: Container(
                    width: 220,
                    height: 220,
                    color: Colors.transparent,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.space24),

        // Macro legend with detailed info
        _buildMacroLegend(macros),

        const SizedBox(height: DesignTokens.space16),

        // Percentage breakdown
        _buildPercentageBreakdown(macros),
      ],
    );
  }

  List<_MacroData> _calculateMacroData() {
    final summary = widget.meal.mealSummary;
    final totalKcal = summary.totalKcal;

    if (totalKcal == 0) {
      return [
        _MacroData('Protein', 0, 0, Colors.red),
        _MacroData('Carbs', 0, 0, Colors.orange),
        _MacroData('Fat', 0, 0, Colors.yellow.shade700),
      ];
    }

    // Calculate calories from each macro
    final proteinKcal = summary.totalProtein * 4;
    final carbsKcal = summary.totalCarbs * 4;
    final fatKcal = summary.totalFat * 9;

    return [
      _MacroData(
        'Protein',
        summary.totalProtein,
        proteinKcal / totalKcal,
        Colors.red,
      ),
      _MacroData(
        'Carbs',
        summary.totalCarbs,
        carbsKcal / totalKcal,
        Colors.orange,
      ),
      _MacroData(
        'Fat',
        summary.totalFat,
        fatKcal / totalKcal,
        Colors.yellow.shade700,
      ),
    ];
  }

  void _handleTap(TapDownDetails details, List<_MacroData> macros) {
    if (!widget.interactive) return;

    final center = const Offset(110, 110); // Half of 220x220
    final tapPosition = details.localPosition;
    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Check if tap is within the pie chart
    if (distance > 110 || distance < 50) {
      setState(() {
        _selectedSegment = -1;
      });
      return;
    }

    // Calculate angle
    var angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    // Convert to start from top (12 o'clock)
    angle = (angle + math.pi / 2) % (2 * math.pi);

    // Find which segment was tapped
    double currentAngle = 0;
    for (int i = 0; i < macros.length; i++) {
      final segmentAngle = macros[i].percentage * 2 * math.pi;
      if (angle >= currentAngle && angle <= currentAngle + segmentAngle) {
        setState(() {
          _selectedSegment = _selectedSegment == i ? -1 : i;
        });
        return;
      }
      currentAngle += segmentAngle;
    }

    setState(() {
      _selectedSegment = -1;
    });
  }

  Widget _buildMacroLegend(List<_MacroData> macros) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: macros.asMap().entries.map((entry) {
        final index = entry.key;
        final macro = entry.value;
        final isSelected = _selectedSegment == index;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
            padding: const EdgeInsets.all(DesignTokens.space12),
            decoration: BoxDecoration(
              color: isSelected
                ? macro.color.withOpacity(0.1)
                : AppTheme.cardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
              border: Border.all(
                color: isSelected
                  ? macro.color.withOpacity(0.5)
                  : AppTheme.mediumGrey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: macro.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: macro.color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space8),
                Text(
                  macro.name,
                  style: TextStyle(
                    color: isSelected ? macro.color : AppTheme.lightGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  '${macro.grams.toStringAsFixed(1)}g',
                  style: TextStyle(
                    color: isSelected ? AppTheme.neutralWhite : AppTheme.lightGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPercentageBreakdown(List<_MacroData> macros) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.mediumGrey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calorie Distribution',
            style: TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space12),
          ...macros.map((macro) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: macro.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  child: Text(
                    macro.name,
                    style: const TextStyle(
                      color: AppTheme.lightGrey,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${(macro.percentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: macro.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _MacroData {
  final String name;
  final double grams;
  final double percentage;
  final Color color;

  _MacroData(this.name, this.grams, this.percentage, this.color);
}

class _MacroPiePainter extends CustomPainter {
  final List<_MacroData> macros;
  final double progress;
  final int selectedSegment;
  final bool interactive;

  _MacroPiePainter({
    required this.macros,
    required this.progress,
    required this.selectedSegment,
    required this.interactive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double currentAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < macros.length; i++) {
      final macro = macros[i];
      final sweepAngle = macro.percentage * 2 * math.pi * progress;
      final isSelected = selectedSegment == i;

      // Adjust radius for selected segment
      final segmentRadius = radius - (isSelected ? 5 : 10);

      final paint = Paint()
        ..color = macro.color
        ..style = PaintingStyle.fill;

      // Add shadow for selected segment
      if (isSelected) {
        final shadowPaint = Paint()
          ..color = macro.color.withOpacity(0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: segmentRadius + 2),
          currentAngle,
          sweepAngle,
          true,
          shadowPaint,
        );
      }

      // Draw the segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: segmentRadius),
        currentAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw segment outline
      final outlinePaint = Paint()
        ..color = AppTheme.primaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: segmentRadius),
        currentAngle,
        sweepAngle,
        true,
        outlinePaint,
      );

      currentAngle += sweepAngle;
    }

    // Draw inner circle to create donut effect
    final innerPaint = Paint()
      ..color = AppTheme.primaryDark
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _MacroPiePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.selectedSegment != selectedSegment;
  }
}