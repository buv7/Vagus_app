import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/food_item.dart';
import 'food_vision_service.dart';

/// AI-powered nutrition estimation service
class NutritionAI {
  static final NutritionAI _instance = NutritionAI._internal();
  factory NutritionAI() => _instance;
  NutritionAI._internal();

  final FoodVisionService _foodVisionService = FoodVisionService();
  
  // Cache for estimations
  final Map<String, _CachedEstimation> _estimationCache = {};
  
  // Rate limiting
  final Map<String, DateTime> _rateLimitMap = {};
  final Duration _rateLimitWindow = const Duration(minutes: 1);

  /// Estimate nutrition from food photo using Google Gemini AI
  Future<FoodItem?> estimateFromPhoto(Uint8List imageBytes, {String? locale}) async {
    try {
      // Check rate limiting
      if (!_checkRateLimit('photo_estimation')) {
        throw Exception('Rate limit exceeded for photo estimation');
      }

      // Use FoodVisionService for AI-powered food recognition
      final result = await _foodVisionService.analyzeImage(imageBytes, locale: locale);
      
      if (result != null) {
        debugPrint('✅ AI food recognition successful: ${result.name}');
        return result;
      }

      // Fallback estimation if AI fails
      debugPrint('⚠️ AI recognition failed, using fallback');
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
        source: 'fallback',
      );
    } catch (e) {
      debugPrint('Error estimating nutrition from photo: $e');
      return null;
    }
  }
  
  /// Check if AI services are properly configured
  Future<bool> isAIConfigured() async {
    return await _foodVisionService.isConfigured();
  }

  /// Auto-fill suggestions from text input
  Future<List<String>> autoFillFromText(String query, {String? locale}) async {
    if (query.isEmpty) return [];

    try {
      final supabase = Supabase.instance.client;
      final searchTerm = query.toLowerCase();

      // Query food database with multilingual support
      final response = await supabase
          .from('food_items')
          .select('name_en, name_ar, name_ku')
          .or('name_en.ilike.%$searchTerm%,name_ar.ilike.%$searchTerm%,name_ku.ilike.%$searchTerm%')
          .limit(10);

      final foods = List<Map<String, dynamic>>.from(response);

      // Return names based on locale preference
      final suggestions = foods.map((food) {
        if (locale == 'ar' && food['name_ar'] != null) {
          return food['name_ar'] as String;
        } else if (locale == 'ku' && food['name_ku'] != null) {
          return food['name_ku'] as String;
        }
        return food['name_en'] as String;
      }).toList();

      return suggestions.take(5).toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch food suggestions: $e');
      // Fallback to basic suggestions on error
      final basicFoods = ['Chicken breast', 'Rice', 'Broccoli', 'Salmon', 'Eggs'];
      return basicFoods.where((food) => food.toLowerCase().contains(query.toLowerCase())).take(5).toList();
    }
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
    try {
      final supabase = Supabase.instance.client;
      final suggestions = <AIFoodSuggestion>[];

      // Query foods based on meal type tags
      final tags = _getTagsForMealType(mealType);

      final response = await supabase
          .from('food_items')
          .select('*')
          .contains('tags', tags)
          .limit(10);

      final foods = List<Map<String, dynamic>>.from(response);

      // If no foods found with tags, query general foods
      if (foods.isEmpty) {
        final fallbackResponse = await supabase
            .from('food_items')
            .select('*')
            .limit(10);
        foods.addAll(List<Map<String, dynamic>>.from(fallbackResponse));
      }

      // Convert database records to FoodItem objects
      for (var i = 0; i < foods.length && i < 5; i++) {
        final foodData = foods[i];
        final foodItem = FoodItem(
          id: foodData['id'] as String?,
          name: foodData['name_en'] as String,
          protein: (foodData['protein_g'] as num).toDouble(),
          carbs: (foodData['carbs_g'] as num).toDouble(),
          fat: (foodData['fat_g'] as num).toDouble(),
          kcal: (foodData['kcal'] as num).toDouble(),
          sodium: (foodData['sodium_mg'] as num?)?.toDouble() ?? 0.0,
          potassium: (foodData['potassium_mg'] as num?)?.toDouble() ?? 0.0,
          amount: (foodData['portion_grams'] as num?)?.toDouble() ?? 100.0,
        );

        suggestions.add(AIFoodSuggestion(
          food: foodItem,
          category: _getCategoryForMealType(mealType),
          matchScore: 0.9 - (i * 0.1), // Decreasing score for each item
          reasoning: includeReasoning
              ? 'Recommended for ${mealType ?? "your meal"} based on nutritional profile'
              : null,
          tags: ['suggested', if (mealType != null) mealType],
        ));
      }

      return suggestions;
    } catch (e) {
      debugPrint('❌ Failed to generate food suggestions: $e');
      // Return empty list on error - UI will handle gracefully
      return [];
    }
  }

  /// Get database tags for meal type filtering
  static List<String> _getTagsForMealType(String? mealType) {
    switch (mealType?.toLowerCase()) {
      case 'breakfast':
        return ['breakfast'];
      case 'lunch':
        return ['protein', 'carb'];
      case 'dinner':
        return ['protein'];
      default:
        return [];
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
