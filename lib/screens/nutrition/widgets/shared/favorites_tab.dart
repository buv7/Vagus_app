import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../services/nutrition/food_catalog_service.dart';
import '../../../../models/nutrition/food_item.dart';
import '../../../../widgets/anim/vagus_loader.dart';
import '../../../../widgets/anim/empty_state.dart';
import '../../../../widgets/supplements/pill_icon.dart';
import 'enhanced_food_card.dart';

/// Favorites tab with starred foods and smart categorization
/// Features: Persistent favorites, categories, search within favorites
class FavoritesTab extends StatefulWidget {
  final bool multiSelectMode;
  final List<FoodItem> selectedFoods;
  final Function(FoodItem) onFoodSelected;
  final Function(FoodItem) onFoodToggled;

  const FavoritesTab({
    super.key,
    required this.multiSelectMode,
    required this.selectedFoods,
    required this.onFoodSelected,
    required this.onFoodToggled,
  });

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  List<FoodItem> _allFavorites = [];
  List<FoodItem> _filteredFavorites = [];
  List<FavoriteCategory> _categories = [];
  bool _isLoading = true;
  FavoriteCategory? _selectedCategory;
  bool _showSearch = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _setupSearch();
  }

  void _setupSearch() {
    _searchController.addListener(() {
      _filterFavorites(_searchController.text);
    });
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      // Load favorites from Supabase
      await Future.delayed(const Duration(milliseconds: 600));

      final favorites = await FoodCatalogService.getFavoriteFoods();
      final categories = _categorizeFavorites(favorites);

      if (mounted) {
        setState(() {
          _allFavorites = favorites;
          _filteredFavorites = favorites;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allFavorites = [];
          _filteredFavorites = [];
          _categories = [];
          _isLoading = false;
        });
      }
    }
  }

  List<FavoriteCategory> _categorizeFavorites(List<FoodItem> favorites) {
    final categories = <FavoriteCategory>[];

    // Categorize by food type
    final proteins = favorites.where((food) =>
      food.protein > 15).toList();
    final carbs = favorites.where((food) =>
      food.carbs > food.protein).toList();
    final snacks = favorites.where((food) =>
      food.calories < 200).toList();
    final drinks = favorites.where((food) =>
      food.name.toLowerCase().contains('drink') ||
      food.name.toLowerCase().contains('juice') ||
      food.name.toLowerCase().contains('smoothie') ||
      food.name.toLowerCase().contains('water')).toList();
    final supplements = favorites.where((food) =>
      food.name.toLowerCase().contains('vitamin') ||
      food.name.toLowerCase().contains('protein powder') ||
      food.name.toLowerCase().contains('supplement')).toList();

    if (proteins.isNotEmpty) {
      categories.add(FavoriteCategory(
        name: 'Proteins',
        foods: proteins,
        icon: Icons.fitness_center,
        color: AppTheme.accentGreen,
      ));
    }

    if (carbs.isNotEmpty) {
      categories.add(FavoriteCategory(
        name: 'Carbohydrates',
        foods: carbs,
        icon: Icons.grain,
        color: AppTheme.lightOrange,
      ));
    }

    if (snacks.isNotEmpty) {
      categories.add(FavoriteCategory(
        name: 'Snacks',
        foods: snacks,
        icon: Icons.cookie,
        color: AppTheme.lightYellow,
      ));
    }

    if (drinks.isNotEmpty) {
      categories.add(FavoriteCategory(
        name: 'Drinks',
        foods: drinks,
        icon: Icons.local_drink,
        color: AppTheme.lightBlue,
      ));
    }

    if (supplements.isNotEmpty) {
      categories.add(FavoriteCategory(
        name: 'Supplements',
        foods: supplements,
        icon: Icons.medical_services,
        color: AppTheme.lightBlue,
      ));
    }

    return categories;
  }

  void _filterFavorites(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFavorites = _selectedCategory?.foods ?? _allFavorites;
      } else {
        final searchFoods = _selectedCategory?.foods ?? _allFavorites;
        _filteredFavorites = searchFoods.where((food) =>
          food.name.toLowerCase().contains(query.toLowerCase()) ||
          (food.brand?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildHeader(),
        if (_showSearch) _buildSearchBar(),
        if (_categories.isNotEmpty) _buildCategories(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Row(
        children: [
          const Icon(
            Icons.favorite,
            color: AppTheme.accentGreen,
            size: 24,
          ),
          const SizedBox(width: DesignTokens.space8),
          const Expanded(
            child: Text(
              'Favorite Foods',
              style: TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Search toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                }
              });
              Haptics.tap();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showSearch
                  ? AppTheme.accentGreen.withValues(alpha: 0.2)
                  : AppTheme.mediumGrey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.search,
                color: _showSearch ? AppTheme.accentGreen : AppTheme.lightGrey,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: DesignTokens.space8),

          // Clear category filter
          if (_selectedCategory != null)
            GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = null);
                _filterFavorites(_searchController.text);
                Haptics.tap();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.clear,
                  color: AppTheme.lightOrange,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.space20,
        0,
        DesignTokens.space20,
        DesignTokens.space16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mediumGrey.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: AppTheme.neutralWhite,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search favorites...',
          hintStyle: TextStyle(
            color: AppTheme.lightGrey.withValues(alpha: 0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.lightGrey.withValues(alpha: 0.6),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
            ? GestureDetector(
                onTap: () => _searchController.clear(),
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
            vertical: DesignTokens.space12,
          ),
        ),
        autofocus: true,
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1, // +1 for "All" category
        separatorBuilder: (context, index) => const SizedBox(width: DesignTokens.space12),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" category
            return _buildCategoryCard(
              name: 'All',
              count: _allFavorites.length,
              icon: Icons.apps,
              color: AppTheme.neutralWhite,
              isSelected: _selectedCategory == null,
              onTap: () {
                setState(() => _selectedCategory = null);
                _filterFavorites(_searchController.text);
                Haptics.tap();
              },
            );
          }

          final category = _categories[index - 1];
          return _buildCategoryCard(
            name: category.name,
            count: category.foods.length,
            icon: category.icon,
            color: category.color,
            isSelected: _selectedCategory == category,
            onTap: () {
              setState(() => _selectedCategory = category);
              _filterFavorites(_searchController.text);
              Haptics.tap();
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard({
    required String name,
    required int count,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(DesignTokens.space12),
        decoration: BoxDecoration(
          color: isSelected
            ? color.withValues(alpha: 0.2)
            : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
              ? color.withValues(alpha: 0.5)
              : AppTheme.mediumGrey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            name == 'Supplements'
                ? const PillIcon(size: 24)
                : Icon(
                    icon,
                    color: isSelected ? color : AppTheme.lightGrey,
                    size: 24,
                  ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : AppTheme.lightGrey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$count',
              style: TextStyle(
                color: isSelected ? color : AppTheme.lightGrey.withValues(alpha: 0.6),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VagusLoader(size: 40),
            SizedBox(height: DesignTokens.space16),
            Text(
              'Loading favorites...',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_allFavorites.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: 'No favorite foods yet',
        subtitle: 'Star foods to save them here for quick access',
        actionLabel: 'Browse Foods',
        onAction: () {
          // TODO: Switch to search tab
        },
      );
    }

    if (_filteredFavorites.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No foods found',
        subtitle: _selectedCategory != null
          ? 'No foods in ${_selectedCategory!.name} category'
          : 'No favorites match your search',
        actionLabel: _selectedCategory != null ? 'Show All' : 'Clear Search',
        onAction: () {
          if (_selectedCategory != null) {
            setState(() => _selectedCategory = null);
          } else {
            _searchController.clear();
          }
          _filterFavorites('');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      backgroundColor: AppTheme.cardDark,
      color: AppTheme.accentGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(DesignTokens.space20),
        itemCount: _filteredFavorites.length,
        itemBuilder: (context, index) {
          final food = _filteredFavorites[index];
          final isSelected = widget.selectedFoods.contains(food);

          return EnhancedFoodCard(
            food: food,
            multiSelectMode: widget.multiSelectMode,
            isSelected: isSelected,
            onTap: () => widget.onFoodSelected(food),
            onToggle: () => widget.onFoodToggled(food),
            showNutritionalInfo: true,
            showServingSelector: false,
            showFavoriteButton: true,
          );
        },
      ),
    );
  }
}

class FavoriteCategory {
  final String name;
  final List<FoodItem> foods;
  final IconData icon;
  final Color color;

  FavoriteCategory({
    required this.name,
    required this.foods,
    required this.icon,
    required this.color,
  });
}