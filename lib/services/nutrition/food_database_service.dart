import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for fetching food nutrition data from USDA FoodData Central API
/// Free API key from: https://fdc.nal.usda.gov/api-key-signup.html
class FoodDatabaseService {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  // Fallback to DEMO_KEY for testing (limited to 1000 requests/hour)
  // Replace with your own API key for production
  static const String _apiKey = 'DEMO_KEY';

  /// Search for foods by name
  Future<List<FoodSearchResult>> searchFoods(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/foods/search').replace(
          queryParameters: {
            'api_key': _apiKey,
            'query': query,
            'dataType': 'Foundation,SR Legacy', // Most reliable data types
            'pageSize': '5',
          },
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List;
        return foods.map((f) => FoodSearchResult.fromJson(f)).toList();
      }

      return [];
    } catch (e) {
      // Error searching foods: $e
      return [];
    }
  }

  /// Get detailed nutrition information for a specific food
  Future<FoodNutrition?> getFoodNutrition(int fdcId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/food/$fdcId').replace(
          queryParameters: {
            'api_key': _apiKey,
            'format': 'full',
          },
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FoodNutrition.fromUsdaJson(data);
      }

      return null;
    } catch (e) {
      // Error fetching food nutrition: $e
      return null;
    }
  }

  /// Fallback: Search local database for common foods
  FoodNutrition? searchLocalDatabase(String query) {
    final lowerQuery = query.toLowerCase().trim();

    for (final entry in _commonFoods.entries) {
      if (entry.key.toLowerCase().contains(lowerQuery) ||
          lowerQuery.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return null;
  }

  // Common foods database (fallback when API fails)
  static final Map<String, FoodNutrition> _commonFoods = {
    'chicken breast': FoodNutrition(
      name: 'Chicken Breast (cooked)',
      proteinPer100g: 31.0,
      carbsPer100g: 0.0,
      fatPer100g: 3.6,
      caloriesPer100g: 165.0,
    ),
    'brown rice': FoodNutrition(
      name: 'Brown Rice (cooked)',
      proteinPer100g: 2.6,
      carbsPer100g: 23.0,
      fatPer100g: 0.9,
      caloriesPer100g: 111.0,
    ),
    'egg': FoodNutrition(
      name: 'Egg (whole, cooked)',
      proteinPer100g: 13.0,
      carbsPer100g: 1.1,
      fatPer100g: 11.0,
      caloriesPer100g: 155.0,
    ),
    'banana': FoodNutrition(
      name: 'Banana',
      proteinPer100g: 1.1,
      carbsPer100g: 23.0,
      fatPer100g: 0.3,
      caloriesPer100g: 89.0,
    ),
    'oatmeal': FoodNutrition(
      name: 'Oatmeal (cooked)',
      proteinPer100g: 2.4,
      carbsPer100g: 12.0,
      fatPer100g: 1.4,
      caloriesPer100g: 71.0,
    ),
    'salmon': FoodNutrition(
      name: 'Salmon (cooked)',
      proteinPer100g: 25.0,
      carbsPer100g: 0.0,
      fatPer100g: 13.0,
      caloriesPer100g: 206.0,
    ),
    'broccoli': FoodNutrition(
      name: 'Broccoli (cooked)',
      proteinPer100g: 2.4,
      carbsPer100g: 7.2,
      fatPer100g: 0.4,
      caloriesPer100g: 35.0,
    ),
    'sweet potato': FoodNutrition(
      name: 'Sweet Potato (cooked)',
      proteinPer100g: 2.0,
      carbsPer100g: 20.0,
      fatPer100g: 0.2,
      caloriesPer100g: 90.0,
    ),
    'greek yogurt': FoodNutrition(
      name: 'Greek Yogurt (plain)',
      proteinPer100g: 10.0,
      carbsPer100g: 3.6,
      fatPer100g: 0.4,
      caloriesPer100g: 59.0,
    ),
    'almonds': FoodNutrition(
      name: 'Almonds',
      proteinPer100g: 21.0,
      carbsPer100g: 22.0,
      fatPer100g: 49.0,
      caloriesPer100g: 579.0,
    ),
  };
}

/// Search result from USDA database
class FoodSearchResult {
  final int fdcId;
  final String description;
  final String? brandName;
  final double? servingSize;
  final String? servingSizeUnit;

  FoodSearchResult({
    required this.fdcId,
    required this.description,
    this.brandName,
    this.servingSize,
    this.servingSizeUnit,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      fdcId: json['fdcId'],
      description: json['description'] ?? '',
      brandName: json['brandOwner'],
      servingSize: json['servingSize']?.toDouble(),
      servingSizeUnit: json['servingSizeUnit'],
    );
  }

  String get displayName {
    if (brandName != null) {
      return '$brandName - $description';
    }
    return description;
  }
}

/// Nutrition information per 100g
class FoodNutrition {
  final String name;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double caloriesPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumPer100g;

  FoodNutrition({
    required this.name,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.caloriesPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
  });

  /// Parse USDA JSON response
  factory FoodNutrition.fromUsdaJson(Map<String, dynamic> json) {
    double getNutrient(int nutrientId) {
      final nutrients = json['foodNutrients'] as List?;
      if (nutrients == null) return 0.0;

      final nutrient = nutrients.firstWhere(
        (n) => n['nutrient']?['id'] == nutrientId,
        orElse: () => null,
      );

      if (nutrient == null) return 0.0;

      final amount = nutrient['amount'];
      return (amount is num) ? amount.toDouble() : 0.0;
    }

    return FoodNutrition(
      name: json['description'] ?? 'Unknown Food',
      proteinPer100g: getNutrient(1003), // Protein
      carbsPer100g: getNutrient(1005),   // Carbs
      fatPer100g: getNutrient(1004),     // Fat
      caloriesPer100g: getNutrient(1008), // Calories
      fiberPer100g: getNutrient(1079),   // Fiber
      sugarPer100g: getNutrient(2000),   // Sugar
      sodiumPer100g: getNutrient(1093),  // Sodium
    );
  }

  /// Calculate macros for specific portion
  Map<String, double> calculateForPortion(double amount, String unit) {
    final multiplier = _getMultiplier(amount, unit);

    return {
      'protein': proteinPer100g * multiplier,
      'carbs': carbsPer100g * multiplier,
      'fat': fatPer100g * multiplier,
      'calories': caloriesPer100g * multiplier,
    };
  }

  double _getMultiplier(double amount, String unit) {
    switch (unit.toLowerCase()) {
      case 'g':
        return amount / 100;
      case 'oz':
        return (amount * 28.35) / 100; // oz to grams
      case 'cup':
        return (amount * 240) / 100; // approximate for liquids
      case 'tbsp':
        return (amount * 15) / 100;
      case 'tsp':
        return (amount * 5) / 100;
      case 'serving':
        return amount; // assume serving = 100g
      default:
        return amount / 100;
    }
  }
}