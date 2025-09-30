import 'package:flutter/material.dart';
import '../../screens/nutrition/food_snap_screen.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../models/nutrition/food_item.dart' as fi;
import 'nutrition_service.dart';

/// Integration helper for adding food items via photo to meals
class MealPhotoIntegration {
  /// Pushes FoodSnapScreen, awaits result, then inserts into meal and recalculates totals.
  /// Returns true if an item was added.
  static Future<bool> addViaPhoto({
    required BuildContext context,
    required NutritionPlan plan,
    required int dayIndex,
    required int mealIndex,
  }) async {
    try {
      final result = await Navigator.of(context).push<FoodItem>(
        MaterialPageRoute(
          builder: (_) => const FoodSnapScreen(),
        ),
      );
      
      if (result == null) return false;

      // Ensure the item is marked as estimated
      final foodItem = result.copyWith(estimated: true);

      // Persist via NutritionService and refresh plan in memory
      final svc = NutritionService();
      await svc.addItemToMeal(
        mealId: '${plan.id}_${dayIndex}_$mealIndex',
        item: foodItem as fi.FoodItem,
      );

      return true;
    } catch (e) {
      // Handle errors gracefully
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add food item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Alternative method that returns the FoodItem for custom handling
  static Future<FoodItem?> captureFoodItem({
    required BuildContext context,
  }) async {
    try {
      final result = await Navigator.of(context).push<FoodItem>(
        MaterialPageRoute(
          builder: (_) => const FoodSnapScreen(),
        ),
      );
      
      return result?.copyWith(estimated: true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture food item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
