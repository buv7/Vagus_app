import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/food_item.dart';

/// AI-powered nutrition estimation service
class NutritionAI {
  static final NutritionAI _instance = NutritionAI._internal();
  factory NutritionAI() => _instance;
  NutritionAI._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache for estimations
  final Map<String, _CachedEstimation> _estimationCache = {};
  final int _maxCacheSize = 100;
  
  // Rate limiting
  final Map<String, DateTime> _rateLimitMap = {};
  final Duration _rateLimitWindow = const Duration(minutes: 1);
  final int _maxRequestsPerWindow = 10;

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
      print('Error estimating nutrition from photo: $e');
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
