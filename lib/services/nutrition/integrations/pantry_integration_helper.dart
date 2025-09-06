import 'package:flutter/material.dart';
import '../pantry_service.dart';
import '../locale_helper.dart';
import 'pantry_grocery_adapter.dart' as pga;
import 'pantry_recipe_adapter.dart';
import 'package:vagus_app/services/nutrition/pantry_service.dart' as ps;
import 'package:vagus_app/models/nutrition/recipe.dart';
import 'package:vagus_app/screens/nutrition/pantry_screen.dart';
import '../grocery_service.dart';
import '../recipe_service.dart';

/// Helper class for pantry integration across screens
class PantryIntegrationHelper {
  static final PantryService _pantryService = PantryService();
  static final pga.PantryGroceryAdapter _groceryAdapter = pga.PantryGroceryAdapter(_pantryService, GroceryService());
  static final PantryRecipeAdapter _recipeAdapter = PantryRecipeAdapter(_pantryService, RecipeService());
  
  // Cache for coverage results
  static final Map<String, double> _coverageCache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Get pantry coverage for a recipe with caching
  static Future<double> getRecipeCoverage({
    required String recipeId,
    required String userId,
    double servings = 1.0,
  }) async {
    final cacheKey = '${recipeId}_${userId}_${servings}';
    
    // Check cache first
    if (_coverageCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheTTL) {
        return _coverageCache[cacheKey]!;
      } else {
        _coverageCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }
    
    try {
      final coverage = await _recipeAdapter.pantryCoverage(
        recipeId: recipeId,
        userId: userId,
        servings: servings,
      );
      
      // Cache the result
      _coverageCache[cacheKey] = coverage;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return coverage;
    } catch (e) {
      print('Failed to get recipe coverage: $e');
      return 0.0;
    }
  }

  /// Get bulk coverage for multiple recipes
  static Future<Map<String, double>> getBulkCoverage({
    required List<String> recipeIds,
    required String userId,
    double servings = 1.0,
  }) async {
    final results = <String, double>{};
    
    for (final recipeId in recipeIds) {
      results[recipeId] = await getRecipeCoverage(
        recipeId: recipeId,
        userId: userId,
        servings: servings,
      );
    }
    
    return results;
  }

  /// Sort recipes by pantry coverage
  static List<Recipe> sortRecipesByCoverage({
    required List<Recipe> recipes,
    required Map<String, double> coverageMap,
  }) {
    final sortedRecipes = List<Recipe>.from(recipes);
    sortedRecipes.sort((a, b) {
      final coverageA = coverageMap[a.id] ?? 0.0;
      final coverageB = coverageMap[b.id] ?? 0.0;
      
      // Sort by coverage descending, then by original order
      final coverageComparison = coverageB.compareTo(coverageA);
      if (coverageComparison != 0) return coverageComparison;
      
      // Maintain original order for equal coverage
      return recipes.indexOf(a).compareTo(recipes.indexOf(b));
    });
    
    return sortedRecipes;
  }

  /// Clear coverage cache
  static void clearCache() {
    _coverageCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear cache for specific user
  static void clearUserCache(String userId) {
    final keysToRemove = _coverageCache.keys
        .where((key) => key.contains('_${userId}_'))
        .toList();
    
    for (final key in keysToRemove) {
      _coverageCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _coverageCache.length,
      'cachedRecipes': _coverageCache.keys.length,
    };
  }

  /// Show pantry coverage banner
  static Widget buildCoverageBanner({
    required PantrySummary summary,
    required String language,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocaleHelper.t('pantry_coverage_banner', language)
                  .replaceAll('{percent}', summary.coveragePercent.toStringAsFixed(0))
                  .replaceAll('{count}', summary.itemsCovered.toString()),
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get current user ID (placeholder - should be replaced with actual auth service)
  static String getCurrentUserId() {
    // TODO: Replace with actual auth service call
    return 'current_user_id';
  }

  /// Navigate to pantry screen
  static void navigateToPantry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PantryScreen(),
      ),
    );
  }
}

