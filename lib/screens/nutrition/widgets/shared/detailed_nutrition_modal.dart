import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../models/nutrition/food_item.dart';

/// Detailed nutrition modal with comprehensive food information
/// Features: Expandable sections, % daily values, colorized nutrients
class DetailedNutritionModal extends StatefulWidget {
  final FoodItem food;
  final double quantity;
  final String serving;

  const DetailedNutritionModal({
    super.key,
    required this.food,
    this.quantity = 1.0,
    this.serving = '100g',
  });

  @override
  State<DetailedNutritionModal> createState() => _DetailedNutritionModalState();
}

class _DetailedNutritionModalState extends State<DetailedNutritionModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _macrosExpanded = true;
  bool _vitaminsExpanded = false;
  bool _mineralsExpanded = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.mediumGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Food image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.accentGreen.withOpacity(0.1),
            ),
            child: widget.food.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.food.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.restaurant,
                        color: AppTheme.accentGreen,
                        size: 32,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.restaurant,
                  color: AppTheme.accentGreen,
                  size: 32,
                ),
          ),

          const SizedBox(width: DesignTokens.space16),

          // Food info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.food.name,
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.food.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.food.brand!,
                    style: TextStyle(
                      color: AppTheme.lightGrey.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.quantity} × ${widget.serving}',
                    style: const TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Close button
          GestureDetector(
            onTap: () {
              Haptics.tap();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.mediumGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: AppTheme.lightGrey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calories summary
          _buildCaloriesSummary(),
          const SizedBox(height: DesignTokens.space24),

          // Macronutrients section
          _buildNutrientSection(
            title: 'Macronutrients',
            icon: Icons.pie_chart,
            isExpanded: _macrosExpanded,
            onToggle: () => setState(() => _macrosExpanded = !_macrosExpanded),
            child: _buildMacronutrients(),
          ),

          const SizedBox(height: DesignTokens.space16),

          // Vitamins section
          _buildNutrientSection(
            title: 'Vitamins',
            icon: Icons.local_pharmacy,
            isExpanded: _vitaminsExpanded,
            onToggle: () => setState(() => _vitaminsExpanded = !_vitaminsExpanded),
            child: _buildVitamins(),
          ),

          const SizedBox(height: DesignTokens.space16),

          // Minerals section
          _buildNutrientSection(
            title: 'Minerals',
            icon: Icons.science,
            isExpanded: _mineralsExpanded,
            onToggle: () => setState(() => _mineralsExpanded = !_mineralsExpanded),
            child: _buildMinerals(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesSummary() {
    final calories = widget.food.calories != null
      ? (widget.food.calories! * widget.quantity).round()
      : 0;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightOrange.withOpacity(0.1),
            AppTheme.lightOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.lightOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: AppTheme.lightOrange,
              size: 32,
            ),
          ),
          const SizedBox(width: DesignTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$calories',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Calories',
                  style: TextStyle(
                    color: AppTheme.lightOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'From ${widget.quantity} ${widget.serving}',
                  style: TextStyle(
                    color: AppTheme.lightGrey.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // % Daily Value placeholder
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.lightOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${((calories / 2000) * 100).round()}%',
                  style: const TextStyle(
                    color: AppTheme.lightOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'DV',
                  style: TextStyle(
                    color: AppTheme.lightOrange,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mediumGrey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Section header
          GestureDetector(
            onTap: () {
              onToggle();
              Haptics.tap();
            },
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme.accentGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.lightGrey,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Section content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space16,
                0,
                DesignTokens.space16,
                DesignTokens.space16,
              ),
              child: child,
            ),
            crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrients() {
    final protein = widget.food.protein != null
      ? (widget.food.protein! * widget.quantity)
      : 0.0;
    final carbs = widget.food.carbs != null
      ? (widget.food.carbs! * widget.quantity)
      : 0.0;
    final fat = widget.food.fat != null
      ? (widget.food.fat! * widget.quantity)
      : 0.0;
    // Fiber is not available in FoodItem model
    final fiber = 0.0;

    return Column(
      children: [
        _buildNutrientRow(
          'Protein',
          '${protein.toStringAsFixed(1)}g',
          protein / 50, // Based on 50g daily protein goal
          AppTheme.accentGreen,
        ),
        _buildNutrientRow(
          'Carbohydrates',
          '${carbs.toStringAsFixed(1)}g',
          carbs / 300, // Based on 300g daily carb goal
          AppTheme.lightOrange,
        ),
        _buildNutrientRow(
          'Fat',
          '${fat.toStringAsFixed(1)}g',
          fat / 70, // Based on 70g daily fat goal
          AppTheme.lightYellow,
        ),
        if (fiber > 0)
          _buildNutrientRow(
            'Dietary Fiber',
            '${fiber.toStringAsFixed(1)}g',
            fiber / 25, // Based on 25g daily fiber goal
            AppTheme.accentGreen,
          ),
      ],
    );
  }

  Widget _buildVitamins() {
    // Placeholder vitamin data - in real app, this would come from the food item
    final vitamins = [
      {'name': 'Vitamin A', 'amount': '120 IU', 'dv': 0.24, 'color': AppTheme.lightOrange},
      {'name': 'Vitamin C', 'amount': '5.2 mg', 'dv': 0.08, 'color': AppTheme.accentGreen},
      {'name': 'Vitamin D', 'amount': '0 IU', 'dv': 0.0, 'color': AppTheme.lightBlue},
      {'name': 'Vitamin E', 'amount': '0.8 mg', 'dv': 0.05, 'color': AppTheme.lightYellow},
    ];

    return Column(
      children: vitamins.map((vitamin) {
        return _buildNutrientRow(
          vitamin['name'] as String,
          vitamin['amount'] as String,
          vitamin['dv'] as double,
          vitamin['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildMinerals() {
    // Placeholder mineral data
    final minerals = [
      {'name': 'Calcium', 'amount': '45 mg', 'dv': 0.04, 'color': AppTheme.lightBlue},
      {'name': 'Iron', 'amount': '2.1 mg', 'dv': 0.12, 'color': AppTheme.lightOrange},
      {'name': 'Potassium', 'amount': '320 mg', 'dv': 0.09, 'color': AppTheme.accentGreen},
      {'name': 'Sodium', 'amount': '85 mg', 'dv': 0.04, 'color': AppTheme.lightYellow},
    ];

    return Column(
      children: minerals.map((mineral) {
        return _buildNutrientRow(
          mineral['name'] as String,
          mineral['amount'] as String,
          mineral['dv'] as double,
          mineral['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildNutrientRow(String name, String amount, double dvPercentage, Color color) {
    final percentage = (dvPercentage * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Row(
        children: [
          // Nutrient name
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 14,
              ),
            ),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: Text(
              amount,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Progress bar and percentage
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: dvPercentage.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 35,
                  child: Text(
                    '$percentage%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.mediumGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Export button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportNutrition,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.lightGrey,
                side: BorderSide(color: AppTheme.mediumGrey.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

          // Add to meal button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _addToMeal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add to Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportNutrition() {
    Haptics.tap();
    // TODO: Implement nutrition export (image/PDF)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _addToMeal() {
    Haptics.success();
    Navigator.of(context).pop();
    // TODO: Add food to current meal
  }
}