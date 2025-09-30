import 'package:flutter/foundation.dart';
import '../pantry_service.dart';
import '../recipe_service.dart';
import 'package:vagus_app/models/nutrition/pantry_item.dart';

/// Non-invasive adapter for pantry-aware recipe operations
class PantryRecipeAdapter {
  final PantryService _pantry;
  final RecipeService _recipes;
  
  PantryRecipeAdapter(this._pantry, this._recipes);

  /// Get pantry coverage for a specific recipe
  Future<double> pantryCoverage({
    required String recipeId,
    required String userId,
    double servings = 1.0,
  }) async {
    try {
      final recipe = await _recipes.getRecipe(recipeId);
      if (recipe == null) return 0.0;
      
      return await _pantry.matchRecipe(
        recipe: recipe,
        userId: userId,
        servings: servings,
      );
    } catch (e) {
      debugPrint('Failed to get pantry coverage for recipe: $e');
      return 0.0;
    }
  }

  /// Get detailed pantry coverage for a recipe
  Future<PantryCoverage> getDetailedCoverage({
    required String recipeId,
    required String userId,
    double servings = 1.0,
  }) async {
    try {
      final recipe = await _recipes.getRecipe(recipeId);
      if (recipe == null) {
        return const PantryCoverage(0.0, []);
      }
      
      return await _pantry.computeCoverage(
        recipe: recipe,
        userId: userId,
        servings: servings,
      );
    } catch (e) {
      debugPrint('Failed to get detailed pantry coverage: $e');
      return const PantryCoverage(0.0, []);
    }
  }

  /// Plan consumption for a recipe
  Future<List<PantryItem>> planConsumption({
    required String recipeId,
    required String userId,
    double servings = 1.0,
  }) async {
    try {
      final recipe = await _recipes.getRecipe(recipeId);
      if (recipe == null) return [];
      
      return await _pantry.planConsumption(
        recipe: recipe,
        userId: userId,
        servings: servings,
      );
    } catch (e) {
      debugPrint('Failed to plan consumption: $e');
      return [];
    }
  }

  /// Apply consumption for a recipe
  Future<void> applyConsumption({
    required String recipeId,
    required String userId,
    double servings = 1.0,
  }) async {
    try {
      final deltas = await planConsumption(
        recipeId: recipeId,
        userId: userId,
        servings: servings,
      );
      
      if (deltas.isNotEmpty) {
        await _pantry.applyConsumption(
          userId: userId,
          deltas: deltas,
        );
      }
    } catch (e) {
      debugPrint('Failed to apply consumption: $e');
      rethrow;
    }
  }

  /// Get pantry coverage for multiple recipes
  Future<Map<String, double>> getBulkCoverage({
    required List<String> recipeIds,
    required String userId,
    double servings = 1.0,
  }) async {
    final coverageMap = <String, double>{};
    
    for (final recipeId in recipeIds) {
      try {
        final coverage = await pantryCoverage(
          recipeId: recipeId,
          userId: userId,
          servings: servings,
        );
        coverageMap[recipeId] = coverage;
      } catch (e) {
        debugPrint('Failed to get coverage for recipe $recipeId: $e');
        coverageMap[recipeId] = 0.0;
      }
    }
    
    return coverageMap;
  }
}
