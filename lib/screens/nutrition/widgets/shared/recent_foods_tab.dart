import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../services/nutrition/food_catalog_service.dart';
import '../../../../models/nutrition/food_item.dart';
import '../../../../widgets/anim/vagus_loader.dart';
import '../../../../widgets/anim/empty_state.dart';
import 'enhanced_food_card.dart';

/// Recent foods tab with smart categorization and quick access
/// Features: Recent 20 foods, time-based grouping, quick re-add functionality
class RecentFoodsTab extends StatefulWidget {
  final bool multiSelectMode;
  final List<FoodItem> selectedFoods;
  final Function(FoodItem) onFoodSelected;
  final Function(FoodItem) onFoodToggled;

  const RecentFoodsTab({
    super.key,
    required this.multiSelectMode,
    required this.selectedFoods,
    required this.onFoodSelected,
    required this.onFoodToggled,
  });

  @override
  State<RecentFoodsTab> createState() => _RecentFoodsTabState();
}

class _RecentFoodsTabState extends State<RecentFoodsTab>
    with AutomaticKeepAliveClientMixin {
  List<RecentFoodGroup> _recentGroups = [];
  bool _isLoading = true;
  RecentFoodFilter _activeFilter = RecentFoodFilter.all;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
  }

  Future<void> _loadRecentFoods() async {
    setState(() => _isLoading = true);

    try {
      // Simulate loading recent foods from storage/API
      await Future.delayed(const Duration(milliseconds: 800));

      final catalogService = FoodCatalogService();
      final recentCatalogFoods = await catalogService.getRecentFoods(limit: 20);
      // Convert CatalogFoodItem to FoodItem
      final recentFoods = recentCatalogFoods.map((catalogItem) => FoodItem(
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
      final groupedFoods = _groupFoodsByTime(recentFoods);

      if (mounted) {
        setState(() {
          _recentGroups = groupedFoods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentGroups = [];
          _isLoading = false;
        });
      }
    }
  }

  List<RecentFoodGroup> _groupFoodsByTime(List<FoodItem> foods) {
    final groups = <RecentFoodGroup>[];
    final now = DateTime.now();

    // Group foods by time periods
    final todayFoods = <FoodItem>[];
    final yesterdayFoods = <FoodItem>[];
    final thisWeekFoods = <FoodItem>[];
    final olderFoods = <FoodItem>[];

    for (final food in foods) {
      // FoodItem doesn't have lastUsed, so use current time as placeholder
      final lastUsed = DateTime.now().subtract(Duration(days: foods.indexOf(food)));
      final difference = now.difference(lastUsed);

      if (difference.inDays == 0) {
        todayFoods.add(food);
      } else if (difference.inDays == 1) {
        yesterdayFoods.add(food);
      } else if (difference.inDays <= 7) {
        thisWeekFoods.add(food);
      } else {
        olderFoods.add(food);
      }
    }

    // Create groups
    if (todayFoods.isNotEmpty) {
      groups.add(RecentFoodGroup(
        title: 'Today',
        foods: todayFoods,
        icon: Icons.today,
        color: AppTheme.accentGreen,
      ));
    }

    if (yesterdayFoods.isNotEmpty) {
      groups.add(RecentFoodGroup(
        title: 'Yesterday',
        foods: yesterdayFoods,
        icon: Icons.schedule,
        color: AppTheme.lightBlue,
      ));
    }

    if (thisWeekFoods.isNotEmpty) {
      groups.add(RecentFoodGroup(
        title: 'This Week',
        foods: thisWeekFoods,
        icon: Icons.date_range,
        color: AppTheme.lightOrange,
      ));
    }

    if (olderFoods.isNotEmpty) {
      groups.add(RecentFoodGroup(
        title: 'Older',
        foods: olderFoods,
        icon: Icons.history,
        color: AppTheme.lightGrey,
      ));
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        children: [
          // Title and actions
          Row(
            children: [
              Icon(
                Icons.history,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: DesignTokens.space8),
              const Expanded(
                child: Text(
                  'Recent Foods',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _clearRecentFoods,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGrey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.clear_all,
                        color: AppTheme.lightGrey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Clear',
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RecentFoodFilter.values.map((filter) {
                final isActive = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setFilter(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                          ? AppTheme.accentGreen.withOpacity(0.2)
                          : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(20),
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
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
              'Loading recent foods...',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_recentGroups.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        title: 'No recent foods',
        subtitle: 'Foods you add will appear here for quick re-access',
        actionLabel: 'Browse Foods',
        onAction: () {
          // TODO: Switch to search tab
        },
      );
    }

    final filteredGroups = _getFilteredGroups();

    if (filteredGroups.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off,
        title: 'No foods match filter',
        subtitle: 'Try selecting a different time period',
        actionLabel: 'Show All',
        onAction: () => _setFilter(RecentFoodFilter.all),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecentFoods,
      backgroundColor: AppTheme.cardDark,
      color: AppTheme.accentGreen,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space20,
          0,
          DesignTokens.space20,
          DesignTokens.space20,
        ),
        itemCount: filteredGroups.length,
        separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space24),
        itemBuilder: (context, index) {
          final group = filteredGroups[index];
          return _buildFoodGroup(group);
        },
      ),
    );
  }

  Widget _buildFoodGroup(RecentFoodGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space12,
            vertical: DesignTokens.space8,
          ),
          decoration: BoxDecoration(
            color: group.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                group.icon,
                color: group.color,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space6),
              Text(
                group.title,
                style: TextStyle(
                  color: group.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: DesignTokens.space6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: group.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${group.foods.length}',
                  style: TextStyle(
                    color: group.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.space12),

        // Group foods
        ...group.foods.map((food) {
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
        }).toList(),
      ],
    );
  }

  List<RecentFoodGroup> _getFilteredGroups() {
    switch (_activeFilter) {
      case RecentFoodFilter.all:
        return _recentGroups;
      case RecentFoodFilter.today:
        return _recentGroups.where((g) => g.title == 'Today').toList();
      case RecentFoodFilter.yesterday:
        return _recentGroups.where((g) => g.title == 'Yesterday').toList();
      case RecentFoodFilter.thisWeek:
        return _recentGroups.where((g) => g.title == 'This Week').toList();
      case RecentFoodFilter.protein:
        return _recentGroups.map((group) {
          final proteinFoods = group.foods.where((food) =>
            food.protein != null && food.protein! > 15).toList();
          return RecentFoodGroup(
            title: group.title,
            foods: proteinFoods,
            icon: group.icon,
            color: group.color,
          );
        }).where((group) => group.foods.isNotEmpty).toList();
      case RecentFoodFilter.lowCarb:
        return _recentGroups.map((group) {
          final lowCarbFoods = group.foods.where((food) =>
            food.carbs != null && food.carbs! < 10).toList();
          return RecentFoodGroup(
            title: group.title,
            foods: lowCarbFoods,
            icon: group.icon,
            color: group.color,
          );
        }).where((group) => group.foods.isNotEmpty).toList();
    }
  }

  void _setFilter(RecentFoodFilter filter) {
    setState(() => _activeFilter = filter);
    Haptics.tap();
  }

  String _getFilterLabel(RecentFoodFilter filter) {
    switch (filter) {
      case RecentFoodFilter.all:
        return 'All';
      case RecentFoodFilter.today:
        return 'Today';
      case RecentFoodFilter.yesterday:
        return 'Yesterday';
      case RecentFoodFilter.thisWeek:
        return 'This Week';
      case RecentFoodFilter.protein:
        return 'High Protein';
      case RecentFoodFilter.lowCarb:
        return 'Low Carb';
    }
  }

  void _clearRecentFoods() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Clear Recent Foods?',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: const Text(
          'This will remove all foods from your recent list. This action cannot be undone.',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performClearRecentFoods();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _performClearRecentFoods() {
    setState(() => _recentGroups = []);
    Haptics.success();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recent foods cleared'),
        backgroundColor: AppTheme.accentGreen,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: _loadRecentFoods,
        ),
      ),
    );
  }
}

class RecentFoodGroup {
  final String title;
  final List<FoodItem> foods;
  final IconData icon;
  final Color color;

  RecentFoodGroup({
    required this.title,
    required this.foods,
    required this.icon,
    required this.color,
  });
}

enum RecentFoodFilter {
  all,
  today,
  yesterday,
  thisWeek,
  protein,
  lowCarb,
}