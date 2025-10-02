import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../models/nutrition/food_item.dart';
// import 'compact_macro_balance.dart'; // File does not exist

/// Detailed food search result card with portion selector and nutrition preview
/// Features: Portion adjustment, macro visualization, serving size options
class FoodSearchResultCard extends StatefulWidget {
  final FoodItem food;
  final Function(FoodItem, double) onSelected;
  final bool showNutritionalInfo;
  final bool showPortionSelector;
  final double initialPortion;

  const FoodSearchResultCard({
    super.key,
    required this.food,
    required this.onSelected,
    this.showNutritionalInfo = true,
    this.showPortionSelector = true,
    this.initialPortion = 1.0,
  });

  @override
  State<FoodSearchResultCard> createState() => _FoodSearchResultCardState();
}

class _FoodSearchResultCardState extends State<FoodSearchResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  double _currentPortion = 1.0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentPortion = widget.initialPortion;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTapDown: (_) {
                _controller.forward();
                Haptics.tap();
              },
              onTapUp: (_) {
                _controller.reverse();
                if (!_isExpanded && !widget.showPortionSelector) {
                  widget.onSelected(widget.food, _currentPortion);
                } else {
                  setState(() => _isExpanded = !_isExpanded);
                }
              },
              onTapCancel: () {
                _controller.reverse();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: DesignTokens.space12),
                padding: const EdgeInsets.all(DesignTokens.space16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isExpanded
                      ? AppTheme.accentGreen.withValues(alpha: 0.5)
                      : AppTheme.mediumGrey.withValues(alpha: 0.3),
                    width: _isExpanded ? 2 : 1,
                  ),
                  boxShadow: _isExpanded ? [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ] : [],
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    if (_isExpanded) ...[
                      const SizedBox(height: DesignTokens.space16),
                      _buildExpandedContent(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Food image
        _buildFoodImage(),
        const SizedBox(width: DesignTokens.space12),

        // Food info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.food.name,
                style: const TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.food.brand != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.food.brand!,
                  style: TextStyle(
                    color: AppTheme.lightGrey.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              _buildQuickNutrition(),
            ],
          ),
        ),

        // Action button
        _buildActionButton(),
      ],
    );
  }

  Widget _buildFoodImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.accentGreen.withValues(alpha: 0.1),
      ),
      child: widget.food.imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.food.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.restaurant,
                  color: AppTheme.accentGreen,
                  size: 28,
                );
              },
            ),
          )
        : const Icon(
            Icons.restaurant,
            color: AppTheme.accentGreen,
            size: 28,
          ),
    );
  }

  Widget _buildQuickNutrition() {
    if (!widget.showNutritionalInfo) {
      return Text(
        'Tap to view nutrition info',
        style: TextStyle(
          color: AppTheme.lightGrey.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      );
    }

    final calories = (widget.food.calories * _currentPortion).round();
    final protein = (widget.food.protein * _currentPortion).round();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.lightOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$calories kcal',
            style: const TextStyle(
              color: AppTheme.lightOrange,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${protein}g protein',
            style: const TextStyle(
              color: AppTheme.accentGreen,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _isExpanded
          ? AppTheme.accentGreen.withValues(alpha: 0.2)
          : AppTheme.mediumGrey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _isExpanded ? Icons.keyboard_arrow_up : Icons.add,
        color: _isExpanded ? AppTheme.accentGreen : AppTheme.lightGrey,
        size: 20,
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        // Portion selector
        if (widget.showPortionSelector)
          _buildPortionSelector(),

        // Detailed nutrition
        if (widget.showNutritionalInfo)
          _buildDetailedNutrition(),

        const SizedBox(height: DesignTokens.space16),

        // Add button
        _buildAddButton(),
      ],
    );
  }

  Widget _buildPortionSelector() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.scale,
                color: AppTheme.accentGreen,
                size: 16,
              ),
              SizedBox(width: DesignTokens.space8),
              Text(
                'Portion Size',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space12),

          // Portion controls
          Row(
            children: [
              // Decrease button
              GestureDetector(
                onTap: () {
                  if (_currentPortion > 0.25) {
                    setState(() => _currentPortion -= 0.25);
                    Haptics.tap();
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: AppTheme.lightGrey,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: DesignTokens.space12),

              // Portion input
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${_currentPortion.toStringAsFixed(_currentPortion == _currentPortion.roundToDouble() ? 0 : 2)} serving${_currentPortion != 1 ? 's' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: DesignTokens.space12),

              // Increase button
              GestureDetector(
                onTap: () {
                  setState(() => _currentPortion += 0.25);
                  Haptics.tap();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppTheme.accentGreen,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space12),

          // Quick portion buttons
          Row(
            children: [
              _buildQuickPortionButton(0.5, '½'),
              const SizedBox(width: DesignTokens.space8),
              _buildQuickPortionButton(1.0, '1'),
              const SizedBox(width: DesignTokens.space8),
              _buildQuickPortionButton(1.5, '1½'),
              const SizedBox(width: DesignTokens.space8),
              _buildQuickPortionButton(2.0, '2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPortionButton(double portion, String label) {
    final isSelected = _currentPortion == portion;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentPortion = portion);
          Haptics.tap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
              ? AppTheme.accentGreen.withValues(alpha: 0.2)
              : AppTheme.mediumGrey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                ? AppTheme.accentGreen.withValues(alpha: 0.5)
                : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.accentGreen : AppTheme.lightGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedNutrition() {
    final calories = (widget.food.calories * _currentPortion);
    final protein = (widget.food.protein * _currentPortion);
    final carbs = (widget.food.carbs * _currentPortion);
    final fat = (widget.food.fat * _currentPortion);

    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.accentGreen,
                size: 16,
              ),
              SizedBox(width: DesignTokens.space8),
              Text(
                'Nutrition Facts',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space12),

          // Macro breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroInfo(calories.round().toString(), 'Calories', AppTheme.lightOrange),
              _buildMacroInfo('${protein.round()}g', 'Protein', AppTheme.accentGreen),
              _buildMacroInfo('${carbs.round()}g', 'Carbs', AppTheme.lightOrange),
              _buildMacroInfo('${fat.round()}g', 'Fat', AppTheme.lightYellow),
            ],
          ),

          const SizedBox(height: DesignTokens.space12),

          // Macro balance visualization
          if (protein > 0 || carbs > 0 || fat > 0)
            CompactMacroBalance(
              protein: protein,
              carbs: carbs,
              fat: fat,
            ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.lightGrey.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Haptics.success();
          widget.onSelected(widget.food, _currentPortion);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGreen,
          foregroundColor: AppTheme.backgroundDark,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 18),
            const SizedBox(width: DesignTokens.space8),
            Text(
              'Add ${_currentPortion != 1 ? '${_currentPortion.toStringAsFixed(_currentPortion == _currentPortion.roundToDouble() ? 0 : 2)} servings' : 'to meal'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact macro balance widget for smaller spaces
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