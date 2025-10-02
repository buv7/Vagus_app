import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../services/nutrition/food_catalog_service.dart';
import '../../../../models/nutrition/food_item.dart';
import '../../../../widgets/anim/vagus_loader.dart';
import '../../../../widgets/anim/empty_state.dart';

/// Advanced food picker with search, barcode scanning, and smart suggestions
/// Features: Real-time search, nutritional database, barcode integration, AI suggestions
class AdvancedFoodPicker extends StatefulWidget {
  final Function(FoodItem) onFoodSelected;
  final List<String>? recentFoods;
  final List<String>? suggestedFoods;
  final String? mealType;
  final bool showBarcodeScanner;
  final bool showAISuggestions;
  final bool showNutritionalInfo;

  const AdvancedFoodPicker({
    super.key,
    required this.onFoodSelected,
    this.recentFoods,
    this.suggestedFoods,
    this.mealType,
    this.showBarcodeScanner = true,
    this.showAISuggestions = true,
    this.showNutritionalInfo = true,
  });

  @override
  State<AdvancedFoodPicker> createState() => _AdvancedFoodPickerState();
}

class _AdvancedFoodPickerState extends State<AdvancedFoodPicker>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final FoodCatalogService _foodCatalogService = FoodCatalogService();
  Timer? _debounceTimer;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  List<FoodItem> _searchResults = [];
  List<FoodItem> _recentItems = [];
  List<FoodItem> _suggestedItems = [];
  bool _isLoading = false;
  bool _showResults = false;
  String _currentQuery = '';
  FoodPickerTab _activeTab = FoodPickerTab.search;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupSearch();
    _loadInitialData();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _slideController.forward();
        _fadeController.forward();
      }
    });
  }

  void _setupSearch() {
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != _currentQuery) {
        _currentQuery = query;
        _debounceSearch(query);
      }
    });

    // Auto-focus search field
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _searchFocus.requestFocus();
    });
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
        _showResults = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showResults = true;
    });

    try {
      // Search using food catalog service
      final catalogResults = await _foodCatalogService.searchFoods(query, limit: 20);

      // Convert CatalogFoodItem to FoodItem
      final results = catalogResults.map((item) => FoodItem(
        id: item.id,
        name: item.nameEn,
        protein: item.proteinG,
        carbs: item.carbsG,
        fat: item.fatG,
        kcal: item.kcal,
        sodium: item.sodiumMg?.toDouble() ?? 0.0,
        potassium: item.potassiumMg?.toDouble() ?? 0.0,
        amount: item.portionGrams,
        unit: 'g',
        estimated: false,
        source: 'catalog',
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

  Future<void> _loadInitialData() async {
    // Load recent and suggested foods
    try {
      final recentCatalog = await _foodCatalogService.getRecentFoods(limit: 10);
      final suggestedCatalog = await _foodCatalogService.getSuggestedFoods(
        mealType: widget.mealType,
        limit: 15,
      );

      // Convert CatalogFoodItem to FoodItem
      final recent = recentCatalog.map((item) => FoodItem(
        id: item.id,
        name: item.nameEn,
        protein: item.proteinG,
        carbs: item.carbsG,
        fat: item.fatG,
        kcal: item.kcal,
        sodium: item.sodiumMg?.toDouble() ?? 0.0,
        potassium: item.potassiumMg?.toDouble() ?? 0.0,
        amount: item.portionGrams,
        unit: 'g',
        estimated: false,
        source: 'catalog',
      )).toList();

      final suggested = suggestedCatalog.map((item) => FoodItem(
        id: item.id,
        name: item.nameEn,
        protein: item.proteinG,
        carbs: item.carbsG,
        fat: item.fatG,
        kcal: item.kcal,
        sodium: item.sodiumMg?.toDouble() ?? 0.0,
        potassium: item.potassiumMg?.toDouble() ?? 0.0,
        amount: item.portionGrams,
        unit: 'g',
        estimated: false,
        source: 'catalog',
      )).toList();

      if (mounted) {
        setState(() {
          _recentItems = recent;
          _suggestedItems = suggested;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounceTimer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTabs(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Row(
        children: [
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
                color: AppTheme.mediumGrey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: AppTheme.lightGrey,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Food',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.mealType != null)
                  Text(
                    'to ${widget.mealType}',
                    style: TextStyle(
                      color: AppTheme.lightGrey.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          // Barcode scanner button
          if (widget.showBarcodeScanner)
            GestureDetector(
              onTap: _openBarcodeScanner,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _searchFocus.hasFocus
              ? AppTheme.accentGreen.withValues(alpha: 0.5)
              : AppTheme.mediumGrey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search foods, brands, or barcodes...',
            hintStyle: TextStyle(
              color: AppTheme.lightGrey.withValues(alpha: 0.6),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppTheme.lightGrey.withValues(alpha: 0.6),
              size: 20,
            ),
            suffixIcon: _currentQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _searchFocus.requestFocus();
                  },
                  child: Icon(
                    Icons.clear,
                    color: AppTheme.lightGrey.withValues(alpha: 0.6),
                    size: 20,
                  ),
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space16,
              vertical: DesignTokens.space16,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _activeTab = FoodPickerTab.search;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTabs() {
    if (_showResults && _currentQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(DesignTokens.space20),
      child: Row(
        children: [
          _buildTab(FoodPickerTab.recent, 'Recent', Icons.history),
          const SizedBox(width: DesignTokens.space12),
          if (widget.showAISuggestions)
            _buildTab(FoodPickerTab.suggested, 'Suggested', Icons.auto_awesome),
        ],
      ),
    );
  }

  Widget _buildTab(FoodPickerTab tab, String label, IconData icon) {
    final isActive = _activeTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeTab = tab);
          Haptics.tap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space12,
          ),
          decoration: BoxDecoration(
            color: isActive
              ? AppTheme.accentGreen.withValues(alpha: 0.2)
              : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                ? AppTheme.accentGreen.withValues(alpha: 0.5)
                : AppTheme.mediumGrey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? AppTheme.accentGreen : AppTheme.lightGrey,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.accentGreen : AppTheme.lightGrey,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_showResults && _currentQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildTabContent(),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: VagusLoader(size: 40),
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No foods found',
        subtitle: 'Try a different search term or scan a barcode',
        actionLabel: 'Scan Barcode',
        onAction: widget.showBarcodeScanner ? _openBarcodeScanner : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.space20),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space12),
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return _buildFoodCard(food, showNutrition: widget.showNutritionalInfo);
      },
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case FoodPickerTab.recent:
        return _buildRecentFoods();
      case FoodPickerTab.suggested:
        return _buildSuggestedFoods();
      case FoodPickerTab.search:
        return _buildSearchPrompt();
    }
  }

  Widget _buildRecentFoods() {
    if (_recentItems.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No recent foods',
        subtitle: 'Foods you add will appear here for quick access',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.space20),
      itemCount: _recentItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space12),
      itemBuilder: (context, index) {
        final food = _recentItems[index];
        return _buildFoodCard(food, isRecent: true);
      },
    );
  }

  Widget _buildSuggestedFoods() {
    if (_suggestedItems.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_awesome,
        title: 'No suggestions yet',
        subtitle: 'AI suggestions will appear based on your eating patterns',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(DesignTokens.space20),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'AI Suggestions for ${widget.mealType ?? 'this meal'}',
                style: const TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
            itemCount: _suggestedItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space12),
            itemBuilder: (context, index) {
              final food = _suggestedItems[index];
              return _buildFoodCard(food, isSuggested: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPrompt() {
    return const EmptyState(
      icon: Icons.search,
      title: 'Search for foods',
      subtitle: 'Start typing to search our database of millions of foods',
    );
  }

  Widget _buildFoodCard(
    FoodItem food, {
    bool isRecent = false,
    bool isSuggested = false,
    bool showNutrition = false,
  }) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        widget.onFoodSelected(food);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.mediumGrey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Food image or icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: food.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          food.imageUrl!,
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
                        food.name,
                        style: const TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (food.brand != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          food.brand!,
                          style: TextStyle(
                            color: AppTheme.lightGrey.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tags
                if (isRecent)
                  _buildTag('Recent', Icons.history, AppTheme.lightBlue),
                if (isSuggested)
                  _buildTag('AI', Icons.auto_awesome, AppTheme.accentGreen),
              ],
            ),

            // Nutrition info
            if (showNutrition) ...[
              const SizedBox(height: DesignTokens.space12),
              Container(
                padding: const EdgeInsets.all(DesignTokens.space12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientInfo('${food.calories}', 'kcal', AppTheme.lightOrange),
                    _buildNutrientInfo('${food.protein}g', 'protein', AppTheme.accentGreen),
                    _buildNutrientInfo('${food.carbs}g', 'carbs', AppTheme.lightOrange),
                    _buildNutrientInfo('${food.fat}g', 'fat', AppTheme.lightYellow),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
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
    );
  }

  void _openBarcodeScanner() {
    Haptics.tap();
    // TODO: Implement barcode scanner
    // This would typically open the camera and scan barcodes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode scanner coming soon!'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}

enum FoodPickerTab {
  search,
  recent,
  suggested,
}