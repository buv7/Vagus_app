import 'package:flutter/material.dart';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/preferences.dart';
import '../../models/nutrition/money.dart';
import '../../services/nutrition/recipe_service.dart';
import '../../services/nutrition/preferences_service.dart';
import '../../services/nutrition/costing_service.dart';
import '../../services/nutrition/integrations/pantry_recipe_adapter.dart';
import '../../services/nutrition/pantry_service.dart';
import '../../components/nutrition/recipe_card.dart';
import '../../theme/design_tokens.dart';
import '../../services/nutrition/locale_helper.dart';
import 'pantry_screen.dart';

class RecipeLibraryScreen extends StatefulWidget {
  final bool isPickerMode;
  final Function(Recipe)? onRecipeSelected;
  final String? selectedRecipeId;

  const RecipeLibraryScreen({
    super.key,
    this.isPickerMode = false,
    this.onRecipeSelected,
    this.selectedRecipeId,
  });

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  final RecipeService _recipeService = RecipeService();
  final PreferencesService _preferencesService = PreferencesService();
  final CostingService _costing = CostingService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = false;
  bool _isGridView = true;
  String _searchQuery = '';
  
  // Preferences and allergies
  Preferences? _userPreferences;
  List<String> _userAllergies = [];
  bool _preferencesLoaded = false;
  
  // Filter states
  final List<String> _selectedCuisineTags = [];
  final List<String> _selectedDietTags = [];
  final List<String> _selectedAllergens = [];
  bool? _halalFilter;
  bool _quickFilter = false;
  bool _budgetFilter = false;
  
  // Preference-based filter toggles
  bool _halalOnly = false;
  bool _excludeAllergens = false;
  bool _respectBudget = false;
  bool _favorCuisines = false;
  
  // Pantry integration
  PantryRecipeAdapter? _pantryAdapter;
  final Map<String, double> _coverageCache = <String, double>{}; // recipeId -> ratio 0..1
  
  // Cost caching
  final Map<String, Money> _costCache = <String, Money>{}; // recipeId -> cost

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _loadRecipes();
    _searchController.addListener(_onSearchChanged);
    
    // Initialize pantry adapters
    _pantryAdapter = PantryRecipeAdapter(PantryService(), _recipeService);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    try {
      // TODO: Get current user ID from auth service
      final userId = 'current_user_id'; // Replace with actual user ID
      
      final preferences = await _preferencesService.getPrefs(userId);
      final allergies = await _preferencesService.getAllergies(userId);
      
      setState(() {
        _userPreferences = preferences;
        _userAllergies = allergies;
        _preferencesLoaded = true;
        
        // Set default preference filters if preferences exist
        if (preferences != null) {
          _halalOnly = preferences.halal == true;
          _excludeAllergens = allergies.isNotEmpty;
          _respectBudget = preferences.costTier != null;
          _favorCuisines = preferences.cuisinePrefs.isNotEmpty;
        }
      });
    } catch (e) {
      // Handle error silently - preferences are optional
      setState(() => _preferencesLoaded = true);
    }
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    
    try {
      final recipes = await _recipeService.fetchPublicRecipes(limit: 50);
      setState(() {
        _recipes = recipes;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recipes: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<double> _coverageFor(String recipeId, String userId) async {
    if (_coverageCache.containsKey(recipeId)) return _coverageCache[recipeId]!;
    final ratio = await _pantryAdapter!.pantryCoverage(recipeId: recipeId, userId: userId, servings: 1.0);
    _coverageCache[recipeId] = ratio;
    return ratio;
  }

  Future<Money> _costFor(Recipe recipe) async {
    if (_costCache.containsKey(recipe.id)) return _costCache[recipe.id]!;
    final cost = await _costing.estimateRecipeCost(recipe, servings: 1.0);
    _costCache[recipe.id] = cost;
    return cost;
  }

  void _applyFilters() {
    var filteredRecipes = _recipes.where((recipe) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!recipe.title.toLowerCase().contains(query) &&
            !(recipe.summary?.toLowerCase() ?? '').contains(query)) {
          return false;
        }
      }

      // Cuisine tags filter
      if (_selectedCuisineTags.isNotEmpty) {
        if (!_selectedCuisineTags.any((tag) => recipe.cuisineTags.contains(tag))) {
          return false;
        }
      }

      // Diet tags filter
      if (_selectedDietTags.isNotEmpty) {
        if (!_selectedDietTags.any((tag) => recipe.dietTags.contains(tag))) {
          return false;
        }
      }

      // Allergens filter (exclude recipes with selected allergens)
      if (_selectedAllergens.isNotEmpty) {
        if (_selectedAllergens.any((allergen) => recipe.allergens.contains(allergen))) {
          return false;
        }
      }

      // Halal filter
      if (_halalFilter != null && recipe.halal != _halalFilter) {
        return false;
      }

      // Quick filter (< 20 minutes)
      if (_quickFilter && recipe.totalMinutes >= 20) {
        return false;
      }

      // Budget filter - check against user preferences
      if (_budgetFilter && _userPreferences != null) {
        final costTier = _userPreferences!.costTier;
        if (costTier != null) {
          // Simple heuristic for now - can be enhanced with actual cost data
          final isExpensive = recipe.ingredients.length > 8 || recipe.totalMinutes > 45;
          if (costTier == 'low' && isExpensive) return false;
          if (costTier == 'medium' && recipe.ingredients.length > 12) return false;
        }
      }

      return true;
    }).toList();

    // Apply preference-based filtering
    if (_userPreferences != null && _preferencesLoaded) {
      filteredRecipes = _preferencesService.filterRecipesByPrefs(
        filteredRecipes.toList(),
        _userPreferences!,
        _userAllergies,
      );
    }

    _filteredRecipes = filteredRecipes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPickerMode ? 'Select Recipe' : 'Recipe Library'),
        actions: [
          // View toggle
          IconButton(
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          ),
          
          // Filter button
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list),
          ),
          
          // Pantry button
          IconButton(
            tooltip: LocaleHelper.t('pantry', Localizations.localeOf(context).languageCode),
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PantryScreen())
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(theme),
          
          // Preference filter toggles
          if (_userPreferences != null) _buildPreferenceFilters(theme),
          
          // Filter chips
          _buildFilterChips(theme),
          
          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredRecipes.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildRecipeList(theme),
          ),
        ],
      ),
      floatingActionButton: widget.isPickerMode
          ? null
          : FloatingActionButton(
              onPressed: _navigateToRecipeEditor,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search recipes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final hasActiveFilters = _selectedCuisineTags.isNotEmpty ||
        _selectedDietTags.isNotEmpty ||
        _selectedAllergens.isNotEmpty ||
        _halalFilter != null ||
        _quickFilter ||
        _budgetFilter;

    if (!hasActiveFilters) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Cuisine tags
          ..._selectedCuisineTags.map((tag) => _buildFilterChip(theme, tag, () {
            setState(() {
              _selectedCuisineTags.remove(tag);
              _applyFilters();
            });
          })),
          
          // Diet tags
          ..._selectedDietTags.map((tag) => _buildFilterChip(theme, tag, () {
            setState(() {
              _selectedDietTags.remove(tag);
              _applyFilters();
            });
          })),
          
          // Allergens
          ..._selectedAllergens.map((allergen) => _buildFilterChip(theme, 'No $allergen', () {
            setState(() {
              _selectedAllergens.remove(allergen);
              _applyFilters();
            });
          })),
          
          // Halal
          if (_halalFilter != null)
            _buildFilterChip(theme, 'Halal', () {
              setState(() {
                _halalFilter = null;
                _applyFilters();
              });
            }),
          
          // Quick
          if (_quickFilter)
            _buildFilterChip(theme, 'Quick', () {
              setState(() {
                _quickFilter = false;
                _applyFilters();
              });
            }),
          
          // Budget
          if (_budgetFilter)
            _buildFilterChip(theme, 'Budget', () {
              setState(() {
                _budgetFilter = false;
                _applyFilters();
              });
            }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: DesignTokens.space8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildPreferenceFilters(ThemeData theme) {
    final language = Localizations.localeOf(context).languageCode;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16, vertical: DesignTokens.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleHelper.t('filtered_by_preferences', language),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showPreferenceDetails,
                child: Text(
                  LocaleHelper.t('details', language),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Wrap(
            spacing: DesignTokens.space8,
            runSpacing: DesignTokens.space4,
            children: [
              if (_halalOnly)
                _buildPreferenceChip(theme, LocaleHelper.t('halal_only', language), () {
                  setState(() {
                    _halalOnly = false;
                    _applyFilters();
                  });
                }),
              if (_excludeAllergens)
                _buildPreferenceChip(theme, LocaleHelper.t('exclude_allergens', language), () {
                  setState(() {
                    _excludeAllergens = false;
                    _applyFilters();
                  });
                }),
              if (_respectBudget)
                _buildPreferenceChip(theme, LocaleHelper.t('respect_budget', language), () {
                  setState(() {
                    _respectBudget = false;
                    _applyFilters();
                  });
                }),
              if (_favorCuisines)
                _buildPreferenceChip(theme, LocaleHelper.t('favor_cuisines', language), () {
                  setState(() {
                    _favorCuisines = false;
                    _applyFilters();
                  });
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceChip(ThemeData theme, String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: theme.colorScheme.onPrimaryContainer,
        fontSize: 12,
      ),
    );
  }

  void _showPreferenceDetails() {
    final language = Localizations.localeOf(context).languageCode;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleHelper.t('active_preference_filters', language),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignTokens.space16),
            if (_halalOnly)
              _buildPreferenceDetailRow(LocaleHelper.t('halal_only', language), LocaleHelper.t('halal_only_desc', language)),
            if (_excludeAllergens)
              _buildPreferenceDetailRow(LocaleHelper.t('exclude_allergens', language), LocaleHelper.t('exclude_allergens_desc', language)),
            if (_respectBudget)
              _buildPreferenceDetailRow(LocaleHelper.t('respect_budget', language), LocaleHelper.t('respect_budget_desc', language)),
            if (_favorCuisines)
              _buildPreferenceDetailRow(LocaleHelper.t('favor_cuisines', language), LocaleHelper.t('favor_cuisines_desc', language)),
            const SizedBox(height: DesignTokens.space24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleHelper.t('close', language)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceDetailRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final language = Localizations.localeOf(context).languageCode;
    final hasActiveFilters = _selectedCuisineTags.isNotEmpty ||
        _selectedDietTags.isNotEmpty ||
        _selectedAllergens.isNotEmpty ||
        _halalFilter != null ||
        _quickFilter ||
        _budgetFilter ||
        _halalOnly ||
        _excludeAllergens ||
        _respectBudget ||
        _favorCuisines;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            hasActiveFilters ? LocaleHelper.t('no_matching_recipes', language) : LocaleHelper.t('no_recipes_available', language),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            hasActiveFilters
                ? LocaleHelper.t('try_relaxing_filters', language)
                : LocaleHelper.t('create_first_recipe', language),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: DesignTokens.space24),
            ElevatedButton(
              onPressed: _relaxFilters,
              child: Text(LocaleHelper.t('relax_filters', language)),
            ),
          ] else if (!widget.isPickerMode) ...[
            const SizedBox(height: DesignTokens.space24),
            ElevatedButton(
              onPressed: _navigateToRecipeEditor,
              child: Text(LocaleHelper.t('create_recipe', language)),
            ),
          ],
        ],
      ),
    );
  }

  void _relaxFilters() {
    setState(() {
      // Keep allergen and halal filters, relax others
      _respectBudget = false;
      _favorCuisines = false;
      _quickFilter = false;
      _budgetFilter = false;
      _selectedCuisineTags.clear();
      _selectedDietTags.clear();
      _applyFilters();
    });
  }

  Widget _buildRecipeList(ThemeData theme) {
    if (_isGridView) {
      return _buildGridView();
    } else {
      return _buildListView();
    }
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: DesignTokens.space16,
          mainAxisSpacing: DesignTokens.space16,
        ),
        itemCount: _filteredRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _filteredRecipes[index];
          return FutureBuilder<Map<String, dynamic>>(
            future: Future.wait([
              _coverageFor(recipe.id, 'current_user_id'), // TODO: Get actual user ID
              _costFor(recipe),
            ]).then((results) => {
              'coverage': results[0] as double,
              'cost': results[1] as Money,
            }),
            builder: (context, snapshot) {
              final coverage = snapshot.data?['coverage'] ?? 0.0;
              final cost = snapshot.data?['cost'] as Money?;
              return RecipeCard(
                recipe: recipe,
                onTap: () => _onRecipeTap(recipe),
                isSelected: widget.selectedRecipeId == recipe.id,
                showSelectionIndicator: widget.isPickerMode,
                pantryCoverage: coverage,
                costPerServing: cost,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.space16),
      itemCount: _filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _filteredRecipes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: Future.wait([
              _coverageFor(recipe.id, 'current_user_id'), // TODO: Get actual user ID
              _costFor(recipe),
            ]).then((results) => {
              'coverage': results[0] as double,
              'cost': results[1] as Money,
            }),
            builder: (context, snapshot) {
              final coverage = snapshot.data?['coverage'] ?? 0.0;
              final cost = snapshot.data?['cost'] as Money?;
              return RecipeCard(
                recipe: recipe,
                isCompact: true,
                onTap: () => _onRecipeTap(recipe),
                isSelected: widget.selectedRecipeId == recipe.id,
                showSelectionIndicator: widget.isPickerMode,
                pantryCoverage: coverage,
                costPerServing: cost,
              );
            },
          ),
        );
      },
    );
  }

  void _onRecipeTap(Recipe recipe) {
    if (widget.isPickerMode) {
      widget.onRecipeSelected?.call(recipe);
      Navigator.of(context).pop();
    } else {
      _navigateToRecipeViewer(recipe);
    }
  }

  void _navigateToRecipeViewer(Recipe recipe) {
    // TODO: Navigate to recipe viewer screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing recipe: ${recipe.title}')),
    );
  }

  void _navigateToRecipeEditor() {
    // TODO: Navigate to recipe editor screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening recipe editor...')),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Filters',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCuisineTags.clear();
                    _selectedDietTags.clear();
                    _selectedAllergens.clear();
                    _halalFilter = null;
                    _quickFilter = false;
                    _budgetFilter = false;
                    _applyFilters();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space24),
          
          // Cuisine tags
          _buildFilterSection(
            theme,
            'Cuisine',
            ['Italian', 'Mexican', 'Asian', 'Mediterranean', 'Middle Eastern'],
            _selectedCuisineTags,
            (tag) {
              setState(() {
                if (_selectedCuisineTags.contains(tag)) {
                  _selectedCuisineTags.remove(tag);
                } else {
                  _selectedCuisineTags.add(tag);
                }
                _applyFilters();
              });
            },
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Diet tags
          _buildFilterSection(
            theme,
            'Diet',
            ['Vegetarian', 'Vegan', 'Keto', 'Paleo', 'Gluten-Free'],
            _selectedDietTags,
            (tag) {
              setState(() {
                if (_selectedDietTags.contains(tag)) {
                  _selectedDietTags.remove(tag);
                } else {
                  _selectedDietTags.add(tag);
                }
                _applyFilters();
              });
            },
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Allergens
          _buildFilterSection(
            theme,
            'Exclude Allergens',
            ['Nuts', 'Dairy', 'Eggs', 'Soy', 'Gluten'],
            _selectedAllergens,
            (allergen) {
              setState(() {
                if (_selectedAllergens.contains(allergen)) {
                  _selectedAllergens.remove(allergen);
                } else {
                  _selectedAllergens.add(allergen);
                }
                _applyFilters();
              });
            },
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Special filters
          _buildSpecialFilters(theme),
          
          const SizedBox(height: DesignTokens.space24),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    ThemeData theme,
    String title,
    List<String> options,
    List<String> selected,
    Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.space8),
        Wrap(
          spacing: DesignTokens.space8,
          runSpacing: DesignTokens.space8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onToggle(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecialFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.space8),
        Row(
          children: [
            Expanded(
              child: FilterChip(
                label: const Text('Halal'),
                selected: _halalFilter == true,
                onSelected: (selected) {
                  setState(() {
                    _halalFilter = selected ? true : null;
                    _applyFilters();
                  });
                },
              ),
            ),
            const SizedBox(width: DesignTokens.space8),
            Expanded(
              child: FilterChip(
                label: const Text('Quick (<20m)'),
                selected: _quickFilter,
                onSelected: (selected) {
                  setState(() {
                    _quickFilter = selected;
                    _applyFilters();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space8),
        FilterChip(
          label: const Text('Budget Friendly'),
          selected: _budgetFilter,
          onSelected: (selected) {
            setState(() {
              _budgetFilter = selected;
              _applyFilters();
            });
          },
        ),
      ],
    );
  }
}
