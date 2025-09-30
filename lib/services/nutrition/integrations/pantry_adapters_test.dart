import 'package:flutter/foundation.dart';
import 'pantry_grocery_adapter.dart';
import 'pantry_recipe_adapter.dart';
import '../pantry_service.dart';
import '../grocery_service.dart';
import '../recipe_service.dart';

/// Test file demonstrating pantry adapter usage
/// This can be used to verify the adapters work correctly
class PantryAdaptersTest {
  final PantryService _pantryService = PantryService();
  final GroceryService _groceryService = GroceryService();
  final RecipeService _recipeService = RecipeService();
  
  late final PantryGroceryAdapter _groceryAdapter;
  late final PantryRecipeAdapter _recipeAdapter;

  PantryAdaptersTest() {
    _groceryAdapter = PantryGroceryAdapter(_pantryService, _groceryService);
    _recipeAdapter = PantryRecipeAdapter(_pantryService, _recipeService);
  }

  /// Test pantry-aware grocery generation
  Future<void> testGroceryGeneration() async {
    try {
      debugPrint('Testing pantry-aware grocery generation...');
      
      final result = await _groceryAdapter.generateWithPantry(
        planId: 'test_plan_id',
        weekIndex: 0,
        ownerId: 'test_user_id',
        usePantry: true,
      );
      
      final (groceryList, pantrySummary) = result;
      
      debugPrint('Generated grocery list: ${groceryList.id}');
      debugPrint('Pantry coverage: ${pantrySummary?.coveragePercent.toStringAsFixed(1)}%');
      debugPrint('Items covered: ${pantrySummary?.itemsCovered}');
      debugPrint('Covered ingredients: ${pantrySummary?.coveredIngredients}');
      
    } catch (e) {
      debugPrint('Grocery generation test failed: $e');
    }
  }

  /// Test recipe pantry coverage
  Future<void> testRecipeCoverage() async {
    try {
      debugPrint('Testing recipe pantry coverage...');
      
      final coverage = await _recipeAdapter.pantryCoverage(
        recipeId: 'test_recipe_id',
        userId: 'test_user_id',
        servings: 2.0,
      );
      
      debugPrint('Recipe coverage: ${(coverage * 100).toStringAsFixed(1)}%');
      
      // Test detailed coverage
      final detailedCoverage = await _recipeAdapter.getDetailedCoverage(
        recipeId: 'test_recipe_id',
        userId: 'test_user_id',
        servings: 2.0,
      );
      
      debugPrint('Detailed coverage ratio: ${detailedCoverage.ratio}');
      debugPrint('Coverage rows: ${detailedCoverage.rows.length}');
      
      for (final row in detailedCoverage.rows) {
        debugPrint('  ${row.ingredientName}: ${row.used}/${row.need} ${row.unit} (${(row.coverageRatio * 100).toStringAsFixed(1)}%)');
      }
      
    } catch (e) {
      debugPrint('Recipe coverage test failed: $e');
    }
  }

  /// Test bulk coverage for multiple recipes
  Future<void> testBulkCoverage() async {
    try {
      debugPrint('Testing bulk recipe coverage...');
      
      final recipeIds = ['recipe_1', 'recipe_2', 'recipe_3'];
      final coverageMap = await _recipeAdapter.getBulkCoverage(
        recipeIds: recipeIds,
        userId: 'test_user_id',
        servings: 1.0,
      );
      
      debugPrint('Bulk coverage results:');
      for (final entry in coverageMap.entries) {
        debugPrint('  ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%');
      }
      
    } catch (e) {
      debugPrint('Bulk coverage test failed: $e');
    }
  }

  /// Test consumption planning and application
  Future<void> testConsumption() async {
    try {
      debugPrint('Testing consumption planning...');
      
      // Plan consumption (no DB writes)
      final deltas = await _recipeAdapter.planConsumption(
        recipeId: 'test_recipe_id',
        userId: 'test_user_id',
        servings: 1.0,
      );
      
      debugPrint('Consumption plan: ${deltas.length} items to consume');
      for (final delta in deltas) {
        debugPrint('  ${delta.name}: ${delta.qty} ${delta.unit}');
      }
      
      // Note: Uncomment to actually apply consumption
      // await _recipeAdapter.applyConsumption(
      //   recipeId: 'test_recipe_id',
      //   userId: 'test_user_id',
      //   servings: 1.0,
      // );
      // debugPrint('Consumption applied successfully');
      
    } catch (e) {
      debugPrint('Consumption test failed: $e');
    }
  }

  /// Run all tests
  Future<void> runAllTests() async {
    debugPrint('=== Pantry Adapters Test Suite ===');
    
    await testGroceryGeneration();
    debugPrint('');
    
    await testRecipeCoverage();
    debugPrint('');
    
    await testBulkCoverage();
    debugPrint('');
    
    await testConsumption();
    debugPrint('');
    
    debugPrint('=== Test Suite Complete ===');
  }
}

/// Usage example:
/// 
/// ```dart
/// void main() async {
///   final test = PantryAdaptersTest();
///   await test.runAllTests();
/// }
/// ```
