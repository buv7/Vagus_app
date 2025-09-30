import 'package:flutter/material.dart';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/preferences.dart';
import '../../services/nutrition/recipe_suggestions.dart';
import '../../services/nutrition/preferences_service.dart';
import '../../services/nutrition/integrations/pantry_recipe_adapter.dart';
import '../../services/nutrition/pantry_service.dart';
import '../../services/nutrition/recipe_service.dart';
import '../../services/nutrition/locale_helper.dart';
import 'recipe_card.dart';

/// Bottom sheet for quick recipe swapping
class RecipeQuickSwapSheet extends StatefulWidget {
  final Recipe baseRecipe;
  final Function(Recipe) onRecipeSelected;
  final VoidCallback? onCancel;
  final bool preferPantry;

  const RecipeQuickSwapSheet({
    super.key,
    required this.baseRecipe,
    required this.onRecipeSelected,
    this.onCancel,
    this.preferPantry = false,
  });

  @override
  State<RecipeQuickSwapSheet> createState() => _RecipeQuickSwapSheetState();
}

class _RecipeQuickSwapSheetState extends State<RecipeQuickSwapSheet> {
  final RecipeSuggestionsService _suggestionsService = RecipeSuggestionsService();
  final PreferencesService _preferencesService = PreferencesService();
  final PantryRecipeAdapter _pantryAdapter = PantryRecipeAdapter(PantryService(), RecipeService());
  
  List<Recipe> _suggestions = [];
  bool _loading = true;
  String? _error;
  Preferences? _userPreferences;
  List<String> _userAllergies = [];
  Map<String, double> _coverageMap = {};

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _loadSuggestions();
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
      });
    } catch (e) {
      // Handle error silently - preferences are optional
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      var suggestions = await _suggestionsService.similarByProteinAndCuisine(
        base: widget.baseRecipe,
        tolerance: 0.15,
        limit: 5, // Get more to filter by preferences
      );

      // Apply preference-based filtering
      if (_userPreferences != null) {
        suggestions = _preferencesService.filterRecipesByPrefs(
          suggestions,
          _userPreferences!,
          _userAllergies,
        );
      }

      // Sort by pantry coverage if preferPantry is enabled
      if (widget.preferPantry && suggestions.isNotEmpty) {
        final userId = 'current_user_id'; // TODO: Get actual user ID
        final coverages = <String, double>{};
        
        await Future.wait(suggestions.map((r) async {
          final c = await _pantryAdapter.pantryCoverage(
            recipeId: r.id, 
            userId: userId, 
            servings: 1.0
          );
          coverages[r.id] = c;
        }));

        suggestions.sort((a, b) {
          final ca = coverages[a.id] ?? 0.0;
          final cb = coverages[b.id] ?? 0.0;
          // Stable sort: if equal, keep prior order
          final diff = cb.compareTo(ca);
          return diff != 0 ? diff : 0;
        });
        
        _coverageMap = coverages;
      }

      setState(() {
        _suggestions = suggestions.take(3).toList(); // Limit to 3 final suggestions
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final isRTL = LocaleHelper.isRTL(language);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LocaleHelper.t('quick_swap', language),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCancel?.call();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Base recipe info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${LocaleHelper.t('current_recipe', language)}: ${widget.baseRecipe.title}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleHelper.t('error_loading_suggestions', language),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSuggestions,
                      child: Text(LocaleHelper.t('retry', language)),
                    ),
                  ],
                ),
              )
            else if (_suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      color: Colors.grey.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleHelper.t('no_matching_recipes', language),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleHelper.t('try_relaxing_filters', language),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _relaxFiltersAndRetry,
                      child: Text(LocaleHelper.t('relax_filters', language)),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final recipe = _suggestions[index];
                    final coverage = _coverageMap[recipe.id] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RecipeCard(
                        recipe: recipe,
                        isCompact: true,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onRecipeSelected(recipe);
                        },
                        showSelectionIndicator: false,
                        pantryCoverage: widget.preferPantry ? coverage : null,
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _relaxFiltersAndRetry() {
    // Temporarily clear preferences to get more suggestions
    setState(() {
      _userPreferences = null;
      _userAllergies = [];
    });
    _loadSuggestions();
  }
}

/// Helper function to show the quick swap sheet
Future<Recipe?> showRecipeQuickSwapSheet({
  required BuildContext context,
  required Recipe baseRecipe,
  bool preferPantry = false,
}) async {
  Recipe? selectedRecipe;
  
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RecipeQuickSwapSheet(
      baseRecipe: baseRecipe,
      onRecipeSelected: (recipe) {
        selectedRecipe = recipe;
      },
      preferPantry: preferPantry,
    ),
  );
  
  return selectedRecipe;
}
