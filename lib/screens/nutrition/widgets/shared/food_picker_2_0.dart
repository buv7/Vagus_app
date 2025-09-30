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
import 'smart_food_search.dart';
import 'barcode_scanner_tab.dart';
import 'recent_foods_tab.dart';
import 'favorites_tab.dart';
import 'custom_foods_tab.dart';

/// Food Picker 2.0 - Delightful tabbed interface with advanced features
/// Features: 5 tabs, smart search, multi-select, voice search, filters
class FoodPicker2_0 extends StatefulWidget {
  final Function(List<FoodItem>) onFoodsSelected;
  final String? mealType;
  final String? targetMeal;
  final bool multiSelectMode;
  final List<String>? dietaryFilters;

  const FoodPicker2_0({
    super.key,
    required this.onFoodsSelected,
    this.mealType,
    this.targetMeal,
    this.multiSelectMode = false,
    this.dietaryFilters,
  });

  @override
  State<FoodPicker2_0> createState() => _FoodPicker2_0State();
}

class _FoodPicker2_0State extends State<FoodPicker2_0>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  FoodPickerTab _activeTab = FoodPickerTab.search;
  List<FoodItem> _selectedFoods = [];
  bool _isMultiSelectMode = false;
  int _selectedCount = 0;

  @override
  void initState() {
    super.initState();
    _isMultiSelectMode = widget.multiSelectMode;

    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: 0,
    );

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

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTab = FoodPickerTab.values[_tabController.index];
        });
      }
    });

    _slideController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
            if (_isMultiSelectMode) _buildBulkActionBar(),
          ],
        ),
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

          const SizedBox(width: DesignTokens.space12),

          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Add Food',
                      style: TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isMultiSelectMode) ...[
                      const SizedBox(width: DesignTokens.space8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Multi-Select',
                          style: TextStyle(
                            color: AppTheme.accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.targetMeal != null)
                  Text(
                    'to ${widget.targetMeal}',
                    style: TextStyle(
                      color: AppTheme.lightGrey.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          // Multi-select toggle
          GestureDetector(
            onTap: _toggleMultiSelectMode,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isMultiSelectMode
                  ? AppTheme.accentGreen.withOpacity(0.2)
                  : AppTheme.mediumGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isMultiSelectMode ? Icons.check_box : Icons.check_box_outline_blank,
                color: _isMultiSelectMode ? AppTheme.accentGreen : AppTheme.lightGrey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: AppTheme.accentGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppTheme.accentGreen,
        unselectedLabelColor: AppTheme.lightGrey,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          _buildTab(Icons.search, 'Search'),
          _buildTab(Icons.qr_code_scanner, 'Scan'),
          _buildTab(Icons.history, 'Recent'),
          _buildTab(Icons.favorite, 'Favorites'),
          _buildTab(Icons.add_circle_outline, 'Custom'),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        SmartFoodSearch(
          mealType: widget.mealType,
          dietaryFilters: widget.dietaryFilters,
          multiSelectMode: _isMultiSelectMode,
          selectedFoods: _selectedFoods,
          onFoodSelected: _handleFoodSelection,
          onFoodToggled: _handleFoodToggle,
        ),
        BarcodeScannerTab(
          multiSelectMode: _isMultiSelectMode,
          selectedFoods: _selectedFoods,
          onFoodSelected: _handleFoodSelection,
          onFoodToggled: _handleFoodToggle,
        ),
        RecentFoodsTab(
          multiSelectMode: _isMultiSelectMode,
          selectedFoods: _selectedFoods,
          onFoodSelected: _handleFoodSelection,
          onFoodToggled: _handleFoodToggle,
        ),
        FavoritesTab(
          multiSelectMode: _isMultiSelectMode,
          selectedFoods: _selectedFoods,
          onFoodSelected: _handleFoodSelection,
          onFoodToggled: _handleFoodToggle,
        ),
        CustomFoodsTab(
          multiSelectMode: _isMultiSelectMode,
          selectedFoods: _selectedFoods,
          onFoodSelected: _handleFoodSelection,
          onFoodToggled: _handleFoodToggle,
          onFoodCreated: _handleCustomFoodCreated,
        ),
      ],
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.mediumGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Selection info
          Row(
            children: [
              Text(
                '$_selectedCount item${_selectedCount != 1 ? 's' : ''} selected',
                style: const TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_selectedCount > 0) ...[
                TextButton(
                  onPressed: _selectAll,
                  child: const Text(
                    'Select All',
                    style: TextStyle(color: AppTheme.accentGreen),
                  ),
                ),
                TextButton(
                  onPressed: _deselectAll,
                  child: const Text(
                    'Deselect All',
                    style: TextStyle(color: AppTheme.lightGrey),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: DesignTokens.space12),

          // Action buttons
          Row(
            children: [
              // Quantity adjuster
              if (_selectedCount > 0) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space12,
                      vertical: DesignTokens.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Adjust All Quantities',
                          style: TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _adjustAllQuantities(-0.25),
                              icon: const Icon(Icons.remove, size: 16),
                              color: AppTheme.lightGrey,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '1.0x',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.neutralWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _adjustAllQuantities(0.25),
                              icon: const Icon(Icons.add, size: 16),
                              color: AppTheme.accentGreen,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space12),
              ],

              // Add all button
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedCount > 0 ? _addAllSelected : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: AppTheme.backgroundDark,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_shopping_cart, size: 18),
                      const SizedBox(width: DesignTokens.space8),
                      Text(
                        _selectedCount > 0
                          ? 'Add $_selectedCount Food${_selectedCount != 1 ? 's' : ''}'
                          : 'Select Foods',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedFoods.clear();
        _selectedCount = 0;
      }
    });
    Haptics.tap();
  }

  void _handleFoodSelection(FoodItem food) {
    if (_isMultiSelectMode) {
      _handleFoodToggle(food);
    } else {
      widget.onFoodsSelected([food]);
      Navigator.of(context).pop();
    }
  }

  void _handleFoodToggle(FoodItem food) {
    setState(() {
      if (_selectedFoods.contains(food)) {
        _selectedFoods.remove(food);
      } else {
        _selectedFoods.add(food);
      }
      _selectedCount = _selectedFoods.length;
    });
    Haptics.tap();
  }

  void _selectAll() {
    // TODO: Implement select all from current tab
    Haptics.tap();
  }

  void _deselectAll() {
    setState(() {
      _selectedFoods.clear();
      _selectedCount = 0;
    });
    Haptics.tap();
  }

  void _adjustAllQuantities(double delta) {
    // TODO: Implement quantity adjustment for all selected foods
    Haptics.tap();
  }

  void _addAllSelected() {
    if (_selectedFoods.isNotEmpty) {
      Haptics.success();
      widget.onFoodsSelected(_selectedFoods);
      Navigator.of(context).pop();
    }
  }

  void _handleCustomFoodCreated(FoodItem food) {
    _handleFoodSelection(food);
  }
}

enum FoodPickerTab {
  search,
  scan,
  recent,
  favorites,
  custom,
}