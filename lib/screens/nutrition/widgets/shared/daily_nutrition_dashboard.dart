import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import '../../../../services/haptics.dart';
import 'nutrition_card.dart';
import 'animated_circular_progress_rings.dart';

/// Comprehensive nutrition dashboard with card grid layout
/// Features: 8 cards (calories, macros, fiber, water, sodium, potassium)
class DailyNutritionDashboard extends StatefulWidget {
  final NutritionPlan plan;
  final double hydrationGlasses;
  final Function(String)? onCardTapped;

  const DailyNutritionDashboard({
    super.key,
    required this.plan,
    this.hydrationGlasses = 0,
    this.onCardTapped,
  });

  @override
  State<DailyNutritionDashboard> createState() =>
      _DailyNutritionDashboardState();
}

class _DailyNutritionDashboardState extends State<DailyNutritionDashboard>
    with TickerProviderStateMixin {
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  // Target values (could be made configurable per user)
  final Map<String, double> _targets = {
    'calories': 2000.0,
    'protein': 150.0,
    'carbs': 200.0,
    'fat': 80.0,
    'fiber': 30.0,
    'water': 8.0, // glasses
    'sodium': 2300.0, // mg
    'potassium': 3500.0, // mg
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _cardControllers = [];
    _cardAnimations = [];

    // Create 8 controllers for the 8 cards
    for (int i = 0; i < 8; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 400 + (i * 100)),
        vsync: this,
      );

      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );

      _cardControllers.add(controller);
      _cardAnimations.add(animation);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final summary = widget.plan.dailySummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          LocaleHelper.t('nutrition_dashboard', locale),
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: DesignTokens.space16),

        // Card grid (2 columns)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: DesignTokens.space12,
          mainAxisSpacing: DesignTokens.space12,
          childAspectRatio: 1.0,
          children: [
            // Calories card (index 0)
            _buildAnimatedCard(
              0,
              _buildCaloriesCard(summary.totalKcal, locale),
              'calories',
            ),

            // Protein card (index 1)
            _buildAnimatedCard(
              1,
              _buildProteinCard(summary.totalProtein, locale),
              'protein',
            ),

            // Carbs card (index 2)
            _buildAnimatedCard(
              2,
              _buildCarbsCard(summary.totalCarbs, locale),
              'carbs',
            ),

            // Fat card (index 3)
            _buildAnimatedCard(
              3,
              _buildFatCard(summary.totalFat, locale),
              'fat',
            ),

            // Fiber card (index 4)
            _buildAnimatedCard(
              4,
              _buildFiberCard(25.0, locale), // Estimated fiber
              'fiber',
            ),

            // Water card (index 5)
            _buildAnimatedCard(
              5,
              _buildWaterCard(widget.hydrationGlasses, locale),
              'water',
            ),

            // Sodium card (index 6)
            _buildAnimatedCard(
              6,
              _buildSodiumCard(summary.totalSodium, locale),
              'sodium',
            ),

            // Potassium card (index 7)
            _buildAnimatedCard(
              7,
              _buildPotassiumCard(summary.totalPotassium, locale),
              'potassium',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(int index, Widget card, String cardType) {
    if (index >= _cardAnimations.length) return card;

    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimations[index].value,
          child: Opacity(
            opacity: _cardAnimations[index].value,
            child: GestureDetector(
              onTap: () {
                Haptics.tap();
                widget.onCardTapped?.call(cardType);
              },
              child: card,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaloriesCard(double calories, String locale) {
    final target = _targets['calories']!;
    final progress = calories / target;
    final remaining = target - calories;

    return NutritionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Color(0xFFEF4444),
              size: 24,
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Value
          Text(
            '${calories.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Label
          const Text(
            'kcal',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Progress bar
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _getCalorieStatusColor(progress),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.space4),

          // Status text
          Text(
            remaining > 0
              ? '${remaining.toStringAsFixed(0)} left'
              : '${(-remaining).toStringAsFixed(0)} over',
            style: TextStyle(
              color: _getCalorieStatusColor(progress),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProteinCard(double protein, String locale) {
    final target = _targets['protein']!;
    final progress = protein / target;

    return NutritionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ring chart
          SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(
              painter: _MiniRingPainter(
                progress: progress,
                color: const Color(0xFF00D9A3),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  color: const Color(0xFF00D9A3),
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Value
          Text(
            '${protein.toStringAsFixed(0)}g',
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Label
          const Text(
            'Protein',
            style: TextStyle(
              color: Color(0xFF00D9A3),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: DesignTokens.space4),

          // Percentage
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: _getStatusColor(progress),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbsCard(double carbs, String locale) {
    final target = _targets['carbs']!;
    final progress = carbs / target;

    return NutritionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ring chart
          SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(
              painter: _MiniRingPainter(
                progress: progress,
                color: const Color(0xFFFF9A3C),
              ),
              child: Center(
                child: Icon(
                  Icons.grain,
                  color: const Color(0xFFFF9A3C),
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Value
          Text(
            '${carbs.toStringAsFixed(0)}g',
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Label
          const Text(
            'Carbs',
            style: TextStyle(
              color: Color(0xFFFF9A3C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: DesignTokens.space4),

          // Percentage
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: _getStatusColor(progress),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFatCard(double fat, String locale) {
    final target = _targets['fat']!;
    final progress = fat / target;

    return NutritionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ring chart
          SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(
              painter: _MiniRingPainter(
                progress: progress,
                color: const Color(0xFFFFD93C),
              ),
              child: Center(
                child: Icon(
                  Icons.eco,
                  color: const Color(0xFFFFD93C),
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Value
          Text(
            '${fat.toStringAsFixed(0)}g',
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Label
          const Text(
            'Fat',
            style: TextStyle(
              color: Color(0xFFFFD93C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: DesignTokens.space4),

          // Percentage
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: _getStatusColor(progress),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiberCard(double fiber, String locale) {
    final target = _targets['fiber']!;
    final progress = fiber / target;

    return NutritionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Linear gauge
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.space12),

          // Value
          Text(
            '${fiber.toStringAsFixed(0)}g',
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Label
          const Text(
            'Fiber',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: DesignTokens.space4),

          // Target info
          Text(
            'Goal: ${target.toStringAsFixed(0)}g',
            style: TextStyle(
              color: AppTheme.lightGrey.withOpacity(0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(double glasses, String locale) {
    final target = _targets['water']!;
    final progress = glasses / target;

    return NutritionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Water waves animation
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Water level
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: (52 * progress).clamp(0.0, 52.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
                // Water drop icon
                Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Value
          Text(
            '${glasses.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Label
          const Text(
            'Glasses',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: DesignTokens.space4),

          // Progress
          Text(
            '${(progress * 100).round()}% of 8',
            style: TextStyle(
              color: AppTheme.lightGrey.withOpacity(0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSodiumCard(double sodium, String locale) {
    final target = _targets['sodium']!;
    final progress = sodium / target;
    final status = _getSodiumStatus(sodium);

    return NutritionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Warning indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: Icon(
              status.icon,
              color: status.color,
              size: 20,
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Value
          Text(
            '${sodium.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Unit
          const Text(
            'mg',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 10,
            ),
          ),

          // Label
          Text(
            'Sodium',
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: DesignTokens.space4),

          // Status
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPotassiumCard(double potassium, String locale) {
    final target = _targets['potassium']!;
    final gap = target - potassium;

    return NutritionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.purple,
              size: 20,
            ),
          ),

          const SizedBox(height: DesignTokens.space8),

          // Value
          Text(
            '${potassium.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Unit
          const Text(
            'mg',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 10,
            ),
          ),

          // Label
          const Text(
            'Potassium',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: DesignTokens.space4),

          // Gap info
          Text(
            gap > 0
              ? '${gap.toStringAsFixed(0)} to go'
              : 'Target met!',
            style: TextStyle(
              color: gap > 0 ? Colors.orange : AppTheme.accentGreen,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCalorieStatusColor(double progress) {
    if (progress >= 0.9 && progress <= 1.1) return AppTheme.accentGreen;
    if (progress < 0.9) return Colors.blue;
    return Colors.red;
  }

  Color _getStatusColor(double progress) {
    if (progress >= 0.8 && progress <= 1.2) return AppTheme.accentGreen;
    if (progress < 0.8) return Colors.orange;
    return Colors.red;
  }

  _SodiumStatus _getSodiumStatus(double sodium) {
    if (sodium < 2300) {
      return _SodiumStatus(
        color: AppTheme.accentGreen,
        icon: Icons.check_circle,
        label: 'Good',
      );
    } else if (sodium < 3000) {
      return _SodiumStatus(
        color: Colors.orange,
        icon: Icons.warning,
        label: 'High',
      );
    } else {
      return _SodiumStatus(
        color: Colors.red,
        icon: Icons.error,
        label: 'Too High',
      );
    }
  }
}

class _SodiumStatus {
  final Color color;
  final IconData icon;
  final String label;

  _SodiumStatus({
    required this.color,
    required this.icon,
    required this.label,
  });
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MiniRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 / 2; // Start from top
    final sweepAngle = progress * 2 * 3.14159;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}