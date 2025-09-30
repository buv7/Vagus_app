import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../services/nutrition/food_catalog_service.dart';
import '../../../../models/nutrition/food_item.dart';
import '../../../../widgets/anim/vagus_loader.dart';
import '../../../../widgets/anim/empty_state.dart';
import 'enhanced_food_card.dart';

/// Smart food search with debounced queries, filters, and voice search
/// Features: Real-time search, dietary filters, sorting options, voice input
class SmartFoodSearch extends StatefulWidget {
  final String? mealType;
  final List<String>? dietaryFilters;
  final bool multiSelectMode;
  final List<FoodItem> selectedFoods;
  final Function(FoodItem) onFoodSelected;
  final Function(FoodItem) onFoodToggled;

  const SmartFoodSearch({
    super.key,
    this.mealType,
    this.dietaryFilters,
    required this.multiSelectMode,
    required this.selectedFoods,
    required this.onFoodSelected,
    required this.onFoodToggled,
  });

  @override
  State<SmartFoodSearch> createState() => _SmartFoodSearchState();
}

class _SmartFoodSearchState extends State<SmartFoodSearch>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounceTimer;

  late AnimationController _filterController;
  late AnimationController _voiceController;
  late Animation<double> _filterSlideAnimation;
  late Animation<double> _voicePulseAnimation;

  List<FoodItem> _searchResults = [];
  List<FoodFilter> _activeFilters = [];
  FoodSortOption _sortOption = FoodSortOption.relevance;
  bool _isLoading = false;
  bool _showFilters = false;
  bool _isVoiceListening = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupSearch();
    _initializeFilters();
  }

  void _setupAnimations() {
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _voiceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _filterSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeOutCubic,
    ));

    _voicePulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _voiceController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupSearch() {
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != _currentQuery) {
        _currentQuery = query;
        _debounceSearch(query);
      }
    });
  }

  void _initializeFilters() {
    if (widget.dietaryFilters != null) {
      for (final filter in widget.dietaryFilters!) {
        final foodFilter = _getFoodFilterFromString(filter);
        if (foodFilter != null) {
          _activeFilters.add(foodFilter);
        }
      }
    }
  }

  void _debounceSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final catalogService = FoodCatalogService();
      final catalogResults = await catalogService.search(query, limit: 50);

      // Convert CatalogFoodItem to FoodItem
      final results = catalogResults.map((catalogItem) => FoodItem(
        id: catalogItem.id,
        name: catalogItem.nameEn,
        protein: catalogItem.proteinG,
        carbs: catalogItem.carbsG,
        fat: catalogItem.fatG,
        kcal: catalogItem.kcal,
        sodium: catalogItem.sodiumMg?.toDouble() ?? 0.0,
        potassium: catalogItem.potassiumMg?.toDouble() ?? 0.0,
        amount: catalogItem.portionGrams,
      )).toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounceTimer?.cancel();
    _filterController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchHeader(),
        if (_showFilters) _buildFiltersSection(),
        Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _searchFocus.hasFocus
                  ? AppTheme.accentGreen.withOpacity(0.5)
                  : AppTheme.mediumGrey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Search input
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search foods, brands, or categories...',
                      hintStyle: TextStyle(
                        color: AppTheme.lightGrey.withOpacity(0.6),
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.lightGrey.withOpacity(0.6),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space16,
                        vertical: DesignTokens.space16,
                      ),
                    ),
                  ),
                ),

                // Voice search button
                GestureDetector(
                  onTap: _toggleVoiceSearch,
                  child: AnimatedBuilder(
                    animation: _voicePulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isVoiceListening ? _voicePulseAnimation.value : 1.0,
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _isVoiceListening
                              ? AppTheme.accentGreen.withOpacity(0.2)
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _isVoiceListening ? Icons.mic : Icons.mic_none,
                            color: _isVoiceListening
                              ? AppTheme.accentGreen
                              : AppTheme.lightGrey.withOpacity(0.6),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Clear button
                if (_currentQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _searchFocus.requestFocus();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.clear,
                        color: AppTheme.lightGrey.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.space12),

          // Filter and sort controls
          Row(
            children: [
              // Filter button
              GestureDetector(
                onTap: _toggleFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: _showFilters || _activeFilters.isNotEmpty
                      ? AppTheme.accentGreen.withOpacity(0.2)
                      : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showFilters || _activeFilters.isNotEmpty
                        ? AppTheme.accentGreen.withOpacity(0.5)
                        : AppTheme.mediumGrey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        color: _showFilters || _activeFilters.isNotEmpty
                          ? AppTheme.accentGreen
                          : AppTheme.lightGrey,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filters',
                        style: TextStyle(
                          color: _showFilters || _activeFilters.isNotEmpty
                            ? AppTheme.accentGreen
                            : AppTheme.lightGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_activeFilters.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${_activeFilters.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: DesignTokens.space12),

              // Sort dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.mediumGrey.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FoodSortOption>(
                      value: _sortOption,
                      onChanged: _onSortChanged,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 14,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.lightGrey,
                        size: 20,
                      ),
                      items: FoodSortOption.values.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(_getSortOptionLabel(option)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return AnimatedBuilder(
      animation: _filterSlideAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _filterSlideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.space12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FoodFilter.values.map((filter) {
                    final isActive = _activeFilters.contains(filter);
                    return GestureDetector(
                      onTap: () => _toggleFilter(filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                            ? AppTheme.accentGreen.withOpacity(0.2)
                            : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive
                              ? AppTheme.accentGreen.withOpacity(0.5)
                              : AppTheme.mediumGrey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getFilterLabel(filter),
                          style: TextStyle(
                            color: isActive ? AppTheme.accentGreen : AppTheme.lightGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: DesignTokens.space16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_currentQuery.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search for foods',
        subtitle: 'Start typing to search our database\nor use voice search',
      );
    }

    if (_isLoading) {
      return const Center(
        child: VagusLoader(size: 40),
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No foods found',
        subtitle: 'Try a different search term\nor adjust your filters',
        actionLabel: 'Clear Filters',
        onAction: _activeFilters.isNotEmpty ? _clearAllFilters : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.space20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        final isSelected = widget.selectedFoods.contains(food);

        return EnhancedFoodCard(
          food: food,
          multiSelectMode: widget.multiSelectMode,
          isSelected: isSelected,
          onTap: () => widget.onFoodSelected(food),
          onToggle: () => widget.onFoodToggled(food),
          showNutritionalInfo: true,
          showServingSelector: true,
        );
      },
    );
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
    Haptics.tap();
  }

  void _toggleFilter(FoodFilter filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });

    if (_currentQuery.isNotEmpty) {
      _performSearch(_currentQuery);
    }

    Haptics.tap();
  }

  void _clearAllFilters() {
    setState(() => _activeFilters.clear());
    if (_currentQuery.isNotEmpty) {
      _performSearch(_currentQuery);
    }
    Haptics.tap();
  }

  void _onSortChanged(FoodSortOption? option) {
    if (option != null && option != _sortOption) {
      setState(() => _sortOption = option);
      if (_currentQuery.isNotEmpty) {
        _performSearch(_currentQuery);
      }
      Haptics.tap();
    }
  }

  void _toggleVoiceSearch() {
    setState(() => _isVoiceListening = !_isVoiceListening);

    if (_isVoiceListening) {
      _voiceController.repeat(reverse: true);
      _startVoiceRecognition();
    } else {
      _voiceController.stop();
      _voiceController.reset();
      _stopVoiceRecognition();
    }

    Haptics.tap();
  }

  void _startVoiceRecognition() async {
    // TODO: Implement speech-to-text
    // Simulate voice recognition
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _isVoiceListening) {
      _searchController.text = 'chicken breast'; // Simulated result
      setState(() => _isVoiceListening = false);
      _voiceController.stop();
      _voiceController.reset();
    }
  }

  void _stopVoiceRecognition() {
    // TODO: Stop speech-to-text service
  }

  String _getSortOptionLabel(FoodSortOption option) {
    switch (option) {
      case FoodSortOption.relevance:
        return 'Relevance';
      case FoodSortOption.proteinHighToLow:
        return 'Protein (High→Low)';
      case FoodSortOption.caloriesLowToHigh:
        return 'Calories (Low→High)';
      case FoodSortOption.alphabetical:
        return 'A-Z';
    }
  }

  String _getFilterLabel(FoodFilter filter) {
    switch (filter) {
      case FoodFilter.highProtein:
        return 'High Protein (>20g)';
      case FoodFilter.lowCarb:
        return 'Low Carb (<10g)';
      case FoodFilter.lowCalorie:
        return 'Low Calorie (<200)';
      case FoodFilter.keto:
        return 'Keto Friendly';
      case FoodFilter.vegan:
        return 'Vegan';
      case FoodFilter.glutenFree:
        return 'Gluten-Free';
      case FoodFilter.halal:
        return 'Halal';
    }
  }

  FoodFilter? _getFoodFilterFromString(String filter) {
    switch (filter.toLowerCase()) {
      case 'high_protein':
        return FoodFilter.highProtein;
      case 'low_carb':
        return FoodFilter.lowCarb;
      case 'low_calorie':
        return FoodFilter.lowCalorie;
      case 'keto':
        return FoodFilter.keto;
      case 'vegan':
        return FoodFilter.vegan;
      case 'gluten_free':
        return FoodFilter.glutenFree;
      case 'halal':
        return FoodFilter.halal;
      default:
        return null;
    }
  }
}

enum FoodFilter {
  highProtein,
  lowCarb,
  lowCalorie,
  keto,
  vegan,
  glutenFree,
  halal,
}

enum FoodSortOption {
  relevance,
  proteinHighToLow,
  caloriesLowToHigh,
  alphabetical,
}