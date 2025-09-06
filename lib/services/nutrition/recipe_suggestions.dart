import '../../models/nutrition/recipe.dart';
import 'recipe_service.dart';

/// Service for finding recipe suggestions based on various criteria
class RecipeSuggestionsService {
  final RecipeService _recipeService = RecipeService();

  /// Find similar recipes based on protein content and cuisine tags
  /// 
  /// [base] - The base recipe to find similar recipes for
  /// [tolerance] - Protein tolerance as a decimal (0.15 = ±15%)
  /// [limit] - Maximum number of suggestions to return
  Future<List<Recipe>> similarByProteinAndCuisine({
    required Recipe base,
    double tolerance = 0.15,
    int limit = 3,
  }) async {
    try {
      // Calculate protein range
      final proteinMin = base.protein * (1 - tolerance);
      final proteinMax = base.protein * (1 + tolerance);

      // Get recipes with similar protein content
      final recipes = await _recipeService.fetchRecipes(
        visibility: RecipeVisibility.public,
        limit: limit * 2, // Get more to filter by cuisine
      );

      // Filter by protein range and cuisine tags
      final filteredRecipes = recipes
          .where((recipe) => 
              recipe.id != base.id && // Exclude the base recipe
              recipe.protein >= proteinMin && 
              recipe.protein <= proteinMax &&
              _hasMatchingCuisine(recipe.cuisineTags, base.cuisineTags))
          .take(limit)
          .toList();

      // If we don't have enough with matching cuisine, add more with just protein match
      if (filteredRecipes.length < limit) {
        final additionalRecipes = recipes
            .where((recipe) => 
                recipe.id != base.id &&
                !filteredRecipes.any((r) => r.id == recipe.id) &&
                recipe.protein >= proteinMin && 
                recipe.protein <= proteinMax)
            .take(limit - filteredRecipes.length)
            .toList();
        
        filteredRecipes.addAll(additionalRecipes);
      }

      return filteredRecipes;
    } catch (e) {
      throw Exception('Failed to find similar recipes: $e');
    }
  }

  /// Check if two cuisine tag lists have any overlap
  bool _hasMatchingCuisine(List<String> tags1, List<String> tags2) {
    if (tags1.isEmpty || tags2.isEmpty) return true; // No cuisine filter
    return tags1.any((tag) => tags2.contains(tag));
  }

  /// Find recipes by diet preferences
  Future<List<Recipe>> findByDietTags({
    required List<String> dietTags,
    int limit = 5,
  }) async {
    try {
      return await _recipeService.fetchRecipes(
        dietTags: dietTags,
        visibility: RecipeVisibility.public,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to find recipes by diet: $e');
    }
  }

  /// Find Halal recipes
  Future<List<Recipe>> findHalalRecipes({
    int limit = 5,
  }) async {
    try {
      return await _recipeService.fetchRecipes(
        halal: true,
        visibility: RecipeVisibility.public,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to find Halal recipes: $e');
    }
  }

  /// Find quick recipes (under 20 minutes total time)
  Future<List<Recipe>> findQuickRecipes({
    int limit = 5,
  }) async {
    try {
      return await _recipeService.getQuickRecipes(limit: limit);
    } catch (e) {
      throw Exception('Failed to find quick recipes: $e');
    }
  }

  /// Find budget-friendly recipes
  Future<List<Recipe>> findBudgetRecipes({
    int limit = 5,
  }) async {
    try {
      return await _recipeService.getBudgetRecipes(limit: limit);
    } catch (e) {
      throw Exception('Failed to find budget recipes: $e');
    }
  }

  /// Find recipes excluding specific allergens
  Future<List<Recipe>> findRecipesExcludingAllergens({
    required List<String> allergens,
    int limit = 5,
  }) async {
    try {
      final recipes = await _recipeService.fetchRecipes(
        visibility: RecipeVisibility.public,
        limit: limit * 2, // Get more to filter
      );

      // Filter out recipes that contain any of the specified allergens
      return recipes
          .where((recipe) => 
              !allergens.any((allergen) => 
                  recipe.allergens.any((recipeAllergen) => 
                      recipeAllergen.toLowerCase().contains(allergen.toLowerCase()))))
          .take(limit)
          .toList();
    } catch (e) {
      throw Exception('Failed to find recipes excluding allergens: $e');
    }
  }
}
