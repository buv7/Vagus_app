import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../services/ai/nutrition_ai.dart' show NutritionAI, AIFoodSuggestion;
import '../../../../models/nutrition/food_item.dart';
import '../../../../widgets/anim/empty_state.dart';

/// AI-powered food suggestions with smart recommendations
/// Features: Contextual suggestions, macro-based recommendations, learning from preferences
class AIFoodSuggestionsPanel extends StatefulWidget {
  final String? mealType;
  final Map<String, double>? currentMacros;
  final Map<String, double>? targetMacros;
  final List<String>? recentFoods;
  final List<String>? preferences;
  final Function(FoodItem) onFoodSelected;
  final bool showReasoning;

  const AIFoodSuggestionsPanel({
    super.key,
    this.mealType,
    this.currentMacros,
    this.targetMacros,
    this.recentFoods,
    this.preferences,
    required this.onFoodSelected,
    this.showReasoning = true,
  });

  @override
  State<AIFoodSuggestionsPanel> createState() => _AIFoodSuggestionsPanelState();
}

class _AIFoodSuggestionsPanelState extends State<AIFoodSuggestionsPanel>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _cardController;
  late Animation<double> _cardSlideAnimation;

  List<AIFoodSuggestion> _suggestions = [];
  bool _isLoading = true;
  String? _errorMessage;
  SuggestionCategory _activeCategory = SuggestionCategory.smart;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSuggestions();
  }

  void _setupAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardSlideAnimation = Tween<double>(
      begin: 0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));

    _loadingController.repeat();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final suggestions = await NutritionAI.generateFoodSuggestions(
        mealType: widget.mealType,
        currentMacros: widget.currentMacros,
        targetMacros: widget.targetMacros,
        recentFoods: widget.recentFoods,
        preferences: widget.preferences,
        includeReasoning: widget.showReasoning,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });

        _animateCardsIn();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load suggestions';
          _isLoading = false;
        });
      }
    }
  }

  void _animateCardsIn() {
    _cardController.forward();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: DesignTokens.space16),
          _buildCategoryTabs(),
          const SizedBox(height: DesignTokens.space16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: AppTheme.accentGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Food Suggestions',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.mealType != null)
                Text(
                  'Optimized for ${widget.mealType}',
                  style: TextStyle(
                    color: AppTheme.lightGrey.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _loadSuggestions,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.refresh,
              color: AppTheme.lightGrey,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SuggestionCategory.values.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.space8),
            child: _buildCategoryTab(category),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(SuggestionCategory category) {
    final isActive = _activeCategory == category;
    final categoryData = _getCategoryData(category);

    return GestureDetector(
      onTap: () {
        setState(() => _activeCategory = category);
        Haptics.tap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: isActive
            ? AppTheme.accentGreen.withValues(alpha: 0.2)
            : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
              ? AppTheme.accentGreen.withValues(alpha: 0.5)
              : AppTheme.mediumGrey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryData['icon'],
              color: isActive ? AppTheme.accentGreen : AppTheme.lightGrey,
              size: 16,
            ),
            const SizedBox(width: DesignTokens.space6),
            Text(
              categoryData['label'],
              style: TextStyle(
                color: isActive ? AppTheme.accentGreen : AppTheme.lightGrey,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryData(SuggestionCategory category) {
    switch (category) {
      case SuggestionCategory.smart:
        return {'icon': Icons.auto_awesome, 'label': 'Smart'};
      case SuggestionCategory.macroBalanced:
        return {'icon': Icons.pie_chart, 'label': 'Macro Balanced'};
      case SuggestionCategory.highProtein:
        return {'icon': Icons.fitness_center, 'label': 'High Protein'};
      case SuggestionCategory.lowCalorie:
        return {'icon': Icons.local_fire_department, 'label': 'Low Calorie'};
      case SuggestionCategory.quick:
        return {'icon': Icons.timer, 'label': 'Quick'};
      case SuggestionCategory.popular:
        return {'icon': Icons.trending_up, 'label': 'Popular'};
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _loadingController.value * 2 * math.pi,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.accentGreen,
                    size: 40,
                  ),
                );
              },
            ),
            const SizedBox(height: DesignTokens.space16),
            const Text(
              'AI is analyzing your preferences...',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Unable to load suggestions',
        subtitle: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadSuggestions,
      );
    }

    final filteredSuggestions = _getFilteredSuggestions();

    if (filteredSuggestions.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No suggestions available',
        subtitle: 'Try adjusting your preferences or meal type',
        actionLabel: 'Refresh',
        onAction: _loadSuggestions,
      );
    }

    return AnimatedBuilder(
      animation: _cardSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value * 50),
          child: ListView.separated(
            itemCount: filteredSuggestions.length,
            separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space12),
            itemBuilder: (context, index) {
              final suggestion = filteredSuggestions[index];
              return _buildSuggestionCard(suggestion, index);
            },
          ),
        );
      },
    );
  }

  List<AIFoodSuggestion> _getFilteredSuggestions() {
    return _suggestions.where((suggestion) {
      switch (_activeCategory) {
        case SuggestionCategory.smart:
          return suggestion.category == 'smart';
        case SuggestionCategory.macroBalanced:
          return suggestion.category == 'macro_balanced';
        case SuggestionCategory.highProtein:
          return suggestion.category == 'high_protein';
        case SuggestionCategory.lowCalorie:
          return suggestion.category == 'low_calorie';
        case SuggestionCategory.quick:
          return suggestion.category == 'quick';
        case SuggestionCategory.popular:
          return suggestion.category == 'popular';
      }
    }).toList();
  }

  Widget _buildSuggestionCard(AIFoodSuggestion suggestion, int index) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        widget.onFoodSelected(suggestion.food);
      },
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.mediumGrey.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuggestionHeader(suggestion),
            if (widget.showReasoning && suggestion.reasoning != null) ...[
              const SizedBox(height: DesignTokens.space12),
              _buildReasoning(suggestion.reasoning!),
            ],
            const SizedBox(height: DesignTokens.space12),
            _buildNutritionPreview(suggestion.food),
            const SizedBox(height: DesignTokens.space12),
            _buildMatchScore(suggestion.matchScore),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionHeader(AIFoodSuggestion suggestion) {
    return Row(
      children: [
        // Food image
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.accentGreen.withValues(alpha: 0.1),
          ),
          child: suggestion.food.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  suggestion.food.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.restaurant,
                      color: AppTheme.accentGreen,
                      size: 24,
                    );
                  },
                ),
              )
            : const Icon(
                Icons.restaurant,
                color: AppTheme.accentGreen,
                size: 24,
              ),
        ),

        const SizedBox(width: DesignTokens.space12),

        // Food info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.food.name,
                style: const TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (suggestion.food.brand != null)
                Text(
                  suggestion.food.brand!,
                  style: TextStyle(
                    color: AppTheme.lightGrey.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        // AI badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.accentGreen,
                size: 12,
              ),
              SizedBox(width: 4),
              Text(
                'AI',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasoning(String reasoning) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppTheme.lightBlue,
            size: 16,
          ),
          const SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Text(
              reasoning,
              style: TextStyle(
                color: AppTheme.lightGrey.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionPreview(FoodItem food) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNutrientChip(
          '${food.calories}',
          'kcal',
          AppTheme.lightOrange,
          Icons.local_fire_department,
        ),
        _buildNutrientChip(
          '${food.protein}g',
          'protein',
          AppTheme.accentGreen,
          Icons.fitness_center,
        ),
        _buildNutrientChip(
          '${food.carbs}g',
          'carbs',
          AppTheme.lightOrange,
          Icons.grain,
        ),
        _buildNutrientChip(
          '${food.fat}g',
          'fat',
          AppTheme.lightYellow,
          Icons.water_drop,
        ),
      ],
    );
  }

  Widget _buildNutrientChip(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.lightGrey.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchScore(double score) {
    final percentage = (score * 100).round();
    final color = score >= 0.8
      ? AppTheme.accentGreen
      : score >= 0.6
        ? AppTheme.lightOrange
        : AppTheme.lightGrey;

    return Row(
      children: [
        Icon(
          Icons.stars,
          color: color,
          size: 16,
        ),
        const SizedBox(width: DesignTokens.space6),
        Text(
          'Match: $percentage%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: DesignTokens.space8),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum SuggestionCategory {
  smart,
  macroBalanced,
  highProtein,
  lowCalorie,
  quick,
  popular,
}