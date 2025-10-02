import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../models/nutrition/food_item.dart';
import 'detailed_nutrition_modal.dart';

/// Enhanced food card with beautiful design and advanced functionality
/// Features: Large photos, macro chips, serving selector, quantity controls, favorites
class EnhancedFoodCard extends StatefulWidget {
  final FoodItem food;
  final bool multiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final bool showNutritionalInfo;
  final bool showServingSelector;
  final bool showFavoriteButton;
  final double initialQuantity;

  const EnhancedFoodCard({
    super.key,
    required this.food,
    this.multiSelectMode = false,
    this.isSelected = false,
    required this.onTap,
    required this.onToggle,
    this.showNutritionalInfo = true,
    this.showServingSelector = false,
    this.showFavoriteButton = true,
    this.initialQuantity = 1.0,
  });

  @override
  State<EnhancedFoodCard> createState() => _EnhancedFoodCardState();
}

class _EnhancedFoodCardState extends State<EnhancedFoodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  double _quantity = 1.0;
  String _selectedServing = '100g';
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // TODO: Load favorite status from backend
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    // TODO: Check if food is in user's favorites
    setState(() => _isFavorite = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              widget.onTap();
            },
            onTapCancel: () => _controller.reverse(),
            child: Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.space16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                    ? AppTheme.accentGreen.withValues(alpha: 0.5)
                    : AppTheme.mediumGrey.withValues(alpha: 0.3),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  if (widget.isSelected)
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 0),
                    ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildNutritionSummary(),
                  if (widget.showServingSelector || widget.showNutritionalInfo)
                    _buildControls(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Row(
        children: [
          // Multi-select checkbox
          if (widget.multiSelectMode) ...[
            GestureDetector(
              onTap: widget.onToggle,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isSelected ? AppTheme.accentGreen : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected ? AppTheme.accentGreen : AppTheme.mediumGrey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: widget.isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
          ],

          // Food image
          _buildFoodImage(),

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
                const SizedBox(height: 6),
                _buildMacroChips(),
              ],
            ),
          ),

          // Action buttons
          Column(
            children: [
              // Favorite button
              if (widget.showFavoriteButton)
                GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isFavorite
                        ? AppTheme.accentGreen.withValues(alpha: 0.2)
                        : AppTheme.mediumGrey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? AppTheme.accentGreen : AppTheme.lightGrey,
                      size: 18,
                    ),
                  ),
                ),

              const SizedBox(height: DesignTokens.space8),

              // Info button
              GestureDetector(
                onTap: _showDetailedNutrition,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGrey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppTheme.lightGrey,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.accentGreen.withValues(alpha: 0.1),
      ),
      child: widget.food.imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.food.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackIcon();
              },
            ),
          )
        : _buildFallbackIcon(),
    );
  }

  Widget _buildFallbackIcon() {
    return const Icon(
      Icons.restaurant,
      color: AppTheme.accentGreen,
      size: 40,
    );
  }

  Widget _buildMacroChips() {
    if (!widget.showNutritionalInfo) {
      return const SizedBox.shrink();
    }

    final calories = (widget.food.calories * _quantity).round();
    final protein = (widget.food.protein * _quantity).round();
    final carbs = (widget.food.carbs * _quantity).round();
    final fat = (widget.food.fat * _quantity).round();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _buildMacroChip('$calories kcal', AppTheme.lightOrange, Icons.local_fire_department),
        _buildMacroChip('${protein}g P', AppTheme.accentGreen, Icons.fitness_center),
        _buildMacroChip('${carbs}g C', AppTheme.lightOrange, Icons.grain),
        _buildMacroChip('${fat}g F', AppTheme.lightYellow, Icons.water_drop),
      ],
    );
  }

  Widget _buildMacroChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    // Compact macro visualization
    if (!widget.showNutritionalInfo) {
      return const SizedBox.shrink();
    }

    final protein = widget.food.protein;
    final carbs = widget.food.carbs;
    final fat = widget.food.fat;
    final total = protein + carbs + fat;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      child: Column(
        children: [
          // Macro balance bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(
                children: [
                  if (protein > 0)
                    Expanded(
                      flex: ((protein / total) * 100).round(),
                      child: Container(color: const Color(0xFF00D9A3)),
                    ),
                  if (carbs > 0)
                    Expanded(
                      flex: ((carbs / total) * 100).round(),
                      child: Container(color: const Color(0xFFFF9A3C)),
                    ),
                  if (fat > 0)
                    Expanded(
                      flex: ((fat / total) * 100).round(),
                      child: Container(color: const Color(0xFFFFD93C)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Row(
        children: [
          // Serving selector
          if (widget.showServingSelector) ...[
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedServing,
                    onChanged: _onServingChanged,
                    dropdownColor: AppTheme.cardDark,
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 12,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.lightGrey,
                      size: 16,
                    ),
                    items: _getServingOptions().map((serving) {
                      return DropdownMenuItem(
                        value: serving,
                        child: Text(serving),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
          ],

          // Quantity controls
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Decrease button
                  GestureDetector(
                    onTap: () => _adjustQuantity(-0.25),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: AppTheme.lightGrey,
                        size: 16,
                      ),
                    ),
                  ),

                  // Quantity display
                  Expanded(
                    child: Text(
                      _quantity == _quantity.roundToDouble()
                        ? _quantity.toInt().toString()
                        : _quantity.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Increase button
                  GestureDetector(
                    onTap: () => _adjustQuantity(0.25),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppTheme.accentGreen,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

          // Quick add button
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getServingOptions() {
    return [
      '100g',
      '1 serving',
      '1 cup',
      '1 piece',
      '1 slice',
      '1 tbsp',
      '1 tsp',
    ];
  }

  void _onServingChanged(String? serving) {
    if (serving != null) {
      setState(() => _selectedServing = serving);
      Haptics.tap();
    }
  }

  void _adjustQuantity(double delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(0.25, 10.0);
    });
    Haptics.tap();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    Haptics.tap();
    // TODO: Update favorite status in backend
  }

  void _showDetailedNutrition() {
    Haptics.tap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailedNutritionModal(
        food: widget.food,
        quantity: _quantity,
        serving: _selectedServing,
      ),
    );
  }
}