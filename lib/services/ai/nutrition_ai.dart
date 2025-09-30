import 'package:flutter/foundation.dart';
import '../../models/nutrition/food_item.dart';

/// AI-powered nutrition estimation service
class NutritionAI {
  static final NutritionAI _instance = NutritionAI._internal();
  factory NutritionAI() => _instance;
  NutritionAI._internal();

  
  // Cache for estimations
  final Map<String, _CachedEstimation> _estimationCache = {};
  
  // Rate limiting
  final Map<String, DateTime> _rateLimitMap = {};
  final Duration _rateLimitWindow = const Duration(minutes: 1);

  /// Estimate nutrition from food photo
  Future<FoodItem?> estimateFromPhoto(Uint8List imageBytes, {String? locale}) async {
    try {
      // Check rate limiting
      if (!_checkRateLimit('photo_estimation')) {
        throw Exception('Rate limit exceeded for photo estimation');
      }

      // For now, return a basic estimation
      // In a real implementation, this would call an AI service
      return FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Estimated Food Item',
        protein: 20.0,
        carbs: 30.0,
        fat: 10.0,
        kcal: 250.0,
        sodium: 500.0,
        potassium: 300.0,
        amount: 100.0,
        unit: 'g',
        estimated: true,
        source: 'photo',
      );
    } catch (e) {
      debugPrint('Error estimating nutrition from photo: $e');
      return null;
    }
  }

  /// Auto-fill suggestions from text input
  Future<List<String>> autoFillFromText(String query, {String? locale}) async {
    // Simple fallback implementation
    final suggestions = <String>[];

    if (query.isNotEmpty) {
      // Add some basic suggestions based on common foods
      final commonFoods = [
        'Chicken breast',
        'Rice',
        'Broccoli',
        'Salmon',
        'Eggs',
        'Banana',
        'Apple',
        'Oatmeal',
        'Greek yogurt',
        'Almonds',
      ];

      for (final food in commonFoods) {
        if (food.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(food);
        }
      }
    }

    return suggestions.take(5).toList();
  }

  /// Check rate limiting
  bool _checkRateLimit(String key) {
    final now = DateTime.now();
    final lastRequest = _rateLimitMap[key];
    
    if (lastRequest != null && now.difference(lastRequest) < _rateLimitWindow) {
      return false;
    }
    
    _rateLimitMap[key] = now;
    return true;
  }

  /// Get debug statistics
  Map<String, dynamic> debugStats() {
    return {
      'cacheSize': _estimationCache.length,
      'rateLimit': '${_rateLimitMap.length} active limits',
    };
  }

  /// Compatibility API for existing code
  Future<dynamic> generateFoodWithTargetMacros({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? locale,
  }) async {
    // Create a basic food item with target macros
    return FoodItem(
      name: 'Generated Food',
      kcal: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sodium: 0.0,
      potassium: 0.0,
      amount: 100.0,
    );
  }

  /// Compatibility API for existing code
  Future<dynamic> generateFullDay({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? locale,
  }) async {
    return {
      'meals': [
        await generateFoodWithTargetMacros(calories: calories*0.4, protein: protein*0.4, carbs: carbs*0.4, fat: fat*0.4, locale: locale),
        await generateFoodWithTargetMacros(calories: calories*0.35, protein: protein*0.35, carbs: carbs*0.35, fat: fat*0.35, locale: locale),
        await generateFoodWithTargetMacros(calories: calories*0.25, protein: protein*0.25, carbs: carbs*0.25, fat: fat*0.25, locale: locale),
      ],
    };
  }

  /// Generate food suggestions based on context
  static Future<List<AIFoodSuggestion>> generateFoodSuggestions({
    String? mealType,
    Map<String, double>? currentMacros,
    Map<String, double>? targetMacros,
    List<String>? recentFoods,
    List<String>? preferences,
    bool includeReasoning = true,
  }) async {
    // Placeholder implementation - return mock suggestions
    final suggestions = <AIFoodSuggestion>[];

    // Generate mock suggestions based on meal type
    final mockFoods = _getMockFoodsForMealType(mealType);

    for (var i = 0; i < mockFoods.length; i++) {
      suggestions.add(AIFoodSuggestion(
        food: mockFoods[i],
        category: _getCategoryForMealType(mealType),
        matchScore: 0.8 - (i * 0.1),
        reasoning: includeReasoning ? 'Good match for your $mealType based on nutritional goals' : null,
        tags: ['suggested', if (mealType != null) mealType],
      ));
    }

    return suggestions;
  }

  static List<FoodItem> _getMockFoodsForMealType(String? mealType) {
    switch (mealType?.toLowerCase()) {
      case 'breakfast':
        return [
          FoodItem(name: 'Oatmeal', protein: 5.0, carbs: 27.0, fat: 3.0, kcal: 150.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
          FoodItem(name: 'Eggs', protein: 13.0, carbs: 1.0, fat: 11.0, kcal: 155.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
          FoodItem(name: 'Banana', protein: 1.0, carbs: 23.0, fat: 0.3, kcal: 89.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
        ];
      case 'lunch':
        return [
          FoodItem(name: 'Chicken Breast', protein: 31.0, carbs: 0.0, fat: 3.6, kcal: 165.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
          FoodItem(name: 'Brown Rice', protein: 2.6, carbs: 23.0, fat: 0.9, kcal: 111.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
          FoodItem(name: 'Broccoli', protein: 2.8, carbs: 7.0, fat: 0.4, kcal: 34.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
        ];
      case 'dinner':
        return [
          FoodItem(name: 'Salmon', protein: 20.0, carbs: 0.0, fat: 13.0, kcal: 208.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
          FoodItem(name: 'Sweet Potato', protein: 1.6, carbs: 20.0, fat: 0.1, kcal: 86.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
          FoodItem(name: 'Spinach', protein: 2.9, carbs: 3.6, fat: 0.4, kcal: 23.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
        ];
      default:
        return [
          FoodItem(name: 'Chicken Breast', protein: 31.0, carbs: 0.0, fat: 3.6, kcal: 165.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
          FoodItem(name: 'Rice', protein: 2.7, carbs: 28.0, fat: 0.3, kcal: 130.0, sodium: 0.0, potassium: 0.0, amount: 100.0),
        ];
    }
  }

  static String _getCategoryForMealType(String? mealType) {
    return mealType?.toLowerCase() ?? 'smart';
  }
}

/// AI food suggestion model
class AIFoodSuggestion {
  final FoodItem food;
  final String category;
  final double matchScore;
  final String? reasoning;
  final List<String> tags;

  AIFoodSuggestion({
    required this.food,
    required this.category,
    required this.matchScore,
    this.reasoning,
    this.tags = const [],
  });
}

/// Cached estimation data
class _CachedEstimation {
  final FoodItem foodItem;
  final DateTime timestamp;
  
  _CachedEstimation({
    required this.foodItem,
    required this.timestamp,
  });
}
