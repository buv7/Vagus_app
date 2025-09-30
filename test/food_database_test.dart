import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/nutrition/food_database_service.dart';

/// Test food database service functionality
void main() {
  group('FoodDatabaseService', () {
    late FoodDatabaseService service;

    setUp(() {
      service = FoodDatabaseService();
    });

    test('searchLocalDatabase finds common foods', () {
      final result = service.searchLocalDatabase('chicken');
      expect(result, isNotNull);
      expect(result!.name.toLowerCase(), contains('chicken'));
    });

    test('searchLocalDatabase returns null for unknown foods', () {
      final result = service.searchLocalDatabase('xyzabc123');
      expect(result, isNull);
    });

    test('FoodNutrition calculates portion correctly for grams', () {
      final nutrition = FoodNutrition(
        name: 'Test Food',
        proteinPer100g: 20.0,
        carbsPer100g: 30.0,
        fatPer100g: 10.0,
        caloriesPer100g: 300.0,
      );

      final portion = nutrition.calculateForPortion(200, 'g');

      expect(portion['protein'], 40.0); // 20g * 2
      expect(portion['carbs'], 60.0);   // 30g * 2
      expect(portion['fat'], 20.0);     // 10g * 2
      expect(portion['calories'], 600.0); // 300 * 2
    });

    test('FoodNutrition calculates portion correctly for oz', () {
      final nutrition = FoodNutrition(
        name: 'Test Food',
        proteinPer100g: 20.0,
        carbsPer100g: 30.0,
        fatPer100g: 10.0,
        caloriesPer100g: 300.0,
      );

      final portion = nutrition.calculateForPortion(1, 'oz');
      // 1 oz = 28.35g, so multiplier = 28.35 / 100 = 0.2835

      expect(portion['protein'], closeTo(5.67, 0.1)); // 20 * 0.2835
      expect(portion['carbs'], closeTo(8.505, 0.1));  // 30 * 0.2835
    });

    test('FoodNutrition calculates portion correctly for cup', () {
      final nutrition = FoodNutrition(
        name: 'Test Food',
        proteinPer100g: 10.0,
        carbsPer100g: 20.0,
        fatPer100g: 5.0,
        caloriesPer100g: 200.0,
      );

      final portion = nutrition.calculateForPortion(1, 'cup');
      // 1 cup = 240g, multiplier = 240 / 100 = 2.4

      expect(portion['protein'], 24.0);   // 10 * 2.4
      expect(portion['carbs'], 48.0);     // 20 * 2.4
      expect(portion['fat'], 12.0);       // 5 * 2.4
      expect(portion['calories'], 480.0); // 200 * 2.4
    });

    test('Common foods database contains expected foods', () {
      final chickenBreast = service.searchLocalDatabase('chicken breast');
      expect(chickenBreast, isNotNull);
      expect(chickenBreast!.proteinPer100g, 31.0);

      final egg = service.searchLocalDatabase('egg');
      expect(egg, isNotNull);
      expect(egg!.proteinPer100g, 13.0);

      final salmon = service.searchLocalDatabase('salmon');
      expect(salmon, isNotNull);
      expect(salmon!.proteinPer100g, 25.0);
    });
  });
}