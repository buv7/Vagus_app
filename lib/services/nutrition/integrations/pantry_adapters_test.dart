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
      print('Testing pantry-aware grocery generation...');
      
      final result = await _groceryAdapter.generateWithPantry(
        planId: 'test_plan_id',
        weekIndex: 0,
        ownerId: 'test_user_id',
        usePantry: true,
      );
      
      final (groceryList, pantrySummary) = result;
      
      print('Generated grocery list: ${groceryList.id}');
      print('Pantry coverage: ${pantrySummary?.coveragePercent.toStringAsFixed(1)}%');
      print('Items covered: ${pantrySummary?.itemsCovered}');
      print('Covered ingredients: ${pantrySummary?.coveredIngredients}');
      
    } catch (e) {
      print('Grocery generation test failed: $e');
    }
  }

  /// Test recipe pantry coverage
  Future<void> testRecipeCoverage() async {
    try {
      print('Testing recipe pantry coverage...');
      
      final coverage = await _recipeAdapter.pantryCoverage(
        recipeId: 'test_recipe_id',
        userId: 'test_user_id',
        servings: 2.0,
      );
      
      print('Recipe coverage: ${(coverage * 100).toStringAsFixed(1)}%');
      
      // Test detailed coverage
      final detailedCoverage = await _recipeAdapter.getDetailedCoverage(
        recipeId: 'test_recipe_id',
        userId: 'test_user_id',
        servings: 2.0,
      );
      
      print('Detailed coverage ratio: ${detailedCoverage.ratio}');
      print('Coverage rows: ${detailedCoverage.rows.length}');
      
      for (final row in detailedCoverage.rows) {
        print('  ${row.ingredientName}: ${row.used}/${row.need} ${row.unit} (${(row.coverageRatio * 100).toStringAsFixed(1)}%)');
      }
      
    } catch (e) {
      print('Recipe coverage test failed: $e');
    }
  }

  /// Test bulk coverage for multiple recipes
  Future<void> testBulkCoverage() async {
    try {
      print('Testing bulk recipe coverage...');
      
      final recipeIds = ['recipe_1', 'recipe_2', 'recipe_3'];
      final coverageMap = await _recipeAdapter.getBulkCoverage(
        recipeIds: recipeIds,
        userId: 'test_user_id',
        servings: 1.0,
      );
      
      print('Bulk coverage results:');
      for (final entry in coverageMap.entries) {
        print('  ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%');
      }
      
    } catch (e) {
      print('Bulk coverage test failed: $e');
    }
  }

  /// Test consumption planning and application
  Future<void> testConsumption() async {
    try {
      print('Testing consumption planning...');
      
      // Plan consumption (no DB writes)
      final deltas = await _recipeAdapter.planConsumption(
        recipeId: 'test_recipe_id',
        userId: 'test_user_id',
        servings: 1.0,
      );
      
      print('Consumption plan: ${deltas.length} items to consume');
      for (final delta in deltas) {
        print('  ${delta.name}: ${delta.qty} ${delta.unit}');
      }
      
      // Note: Uncomment to actually apply consumption
      // await _recipeAdapter.applyConsumption(
      //   recipeId: 'test_recipe_id',
      //   userId: 'test_user_id',
      //   servings: 1.0,
      // );
      // print('Consumption applied successfully');
      
    } catch (e) {
      print('Consumption test failed: $e');
    }
  }

  /// Run all tests
  Future<void> runAllTests() async {
    print('=== Pantry Adapters Test Suite ===');
    
    await testGroceryGeneration();
    print('');
    
    await testRecipeCoverage();
    print('');
    
    await testBulkCoverage();
    print('');
    
    await testConsumption();
    print('');
    
    print('=== Test Suite Complete ===');
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
