import '../../models/nutrition/nutrition_plan.dart';
import 'dart:convert';

class NutritionAI {
  // Simplified AI service for now - can be enhanced later with real AI integration
  final Map<String, dynamic> _cache = {};
  final Map<String, int> _requestCounts = {};

  // MENA & Iraqi Food Database
  static const Map<String, Map<String, dynamic>> _menaFoodDatabase = {
    // Rice Varieties
    'white basmati rice': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 300,
      'protein': 2.7,
      'carbs': 28.0,
      'net_carbs': 27.0,
      'fat': 0.3,
      'calories': 121,
      'sodium': 1,
      'potassium': 35,
    },
    'jasmine rice': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 300,
      'protein': 2.7,
      'carbs': 28.0,
      'net_carbs': 27.0,
      'fat': 0.3,
      'calories': 121,
      'sodium': 1,
      'potassium': 35,
    },
    'parboiled rice': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 300,
      'protein': 2.9,
      'carbs': 28.0,
      'net_carbs': 27.0,
      'fat': 0.4,
      'calories': 123,
      'sodium': 1,
      'potassium': 40,
    },
    
    // Grains
    'bulgur wheat': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 250,
      'protein': 3.1,
      'carbs': 18.0,
      'net_carbs': 17.0,
      'fat': 0.2,
      'calories': 83,
      'sodium': 5,
      'potassium': 68,
    },
    'couscous': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 250,
      'protein': 3.8,
      'carbs': 23.0,
      'net_carbs': 22.0,
      'fat': 0.2,
      'calories': 112,
      'sodium': 5,
      'potassium': 58,
    },
    
    // Breads
    'iraqi samoon': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 8.5,
      'carbs': 49.0,
      'net_carbs': 47.0,
      'fat': 2.5,
      'calories': 265,
      'sodium': 450,
      'potassium': 120,
    },
    'pita bread': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 9.0,
      'carbs': 55.0,
      'net_carbs': 53.0,
      'fat': 1.2,
      'calories': 275,
      'sodium': 500,
      'potassium': 120,
    },
    'khubz tannour': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 8.0,
      'carbs': 52.0,
      'net_carbs': 50.0,
      'fat': 1.8,
      'calories': 260,
      'sodium': 400,
      'potassium': 110,
    },
    
    // Legumes
    'red lentils': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 200,
      'protein': 9.0,
      'carbs': 20.0,
      'net_carbs': 17.0,
      'fat': 0.4,
      'calories': 116,
      'sodium': 2,
      'potassium': 369,
    },
    'brown lentils': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 200,
      'protein': 9.0,
      'carbs': 20.0,
      'net_carbs': 17.0,
      'fat': 0.4,
      'calories': 116,
      'sodium': 2,
      'potassium': 369,
    },
    'chickpeas boiled': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 200,
      'protein': 8.9,
      'carbs': 27.0,
      'net_carbs': 23.0,
      'fat': 2.6,
      'calories': 164,
      'sodium': 6,
      'potassium': 291,
    },
    'fava beans boiled': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 200,
      'protein': 7.9,
      'carbs': 17.0,
      'net_carbs': 14.0,
      'fat': 0.4,
      'calories': 110,
      'sodium': 5,
      'potassium': 268,
    },
    
    // Fruits
    'dates fresh': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 1.8,
      'carbs': 75.0,
      'net_carbs': 63.0,
      'fat': 0.2,
      'calories': 282,
      'sodium': 1,
      'potassium': 656,
    },
    'dates dried': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 2.5,
      'carbs': 75.0,
      'net_carbs': 63.0,
      'fat': 0.4,
      'calories': 282,
      'sodium': 2,
      'potassium': 656,
    },
    
    // Meats
    'iraqi kebab': {
      'category': 'protein',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 80,
      'protein': 25.0,
      'carbs': 0.0,
      'net_carbs': 0.0,
      'fat': 15.0,
      'calories': 250,
      'sodium': 400,
      'potassium': 350,
    },
    'grilled chicken breast': {
      'category': 'protein',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 85,
      'protein': 31.0,
      'carbs': 0.0,
      'net_carbs': 0.0,
      'fat': 3.6,
      'calories': 165,
      'sodium': 74,
      'potassium': 256,
    },
    'grilled lamb': {
      'category': 'protein',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 80,
      'protein': 25.0,
      'carbs': 0.0,
      'net_carbs': 0.0,
      'fat': 18.0,
      'calories': 294,
      'sodium': 72,
      'potassium': 310,
    },
    'grilled fish zubaidi': {
      'category': 'protein',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 85,
      'protein': 22.0,
      'carbs': 0.0,
      'net_carbs': 0.0,
      'fat': 4.0,
      'calories': 130,
      'sodium': 78,
      'potassium': 356,
    },
    'grilled fish tilapia': {
      'category': 'protein',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 85,
      'protein': 26.0,
      'carbs': 0.0,
      'net_carbs': 0.0,
      'fat': 2.7,
      'calories': 128,
      'sodium': 52,
      'potassium': 302,
    },
    
    // Eggs
    'eggs boiled': {
      'category': 'protein',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 12.6,
      'carbs': 1.2,
      'net_carbs': 1.1,
      'fat': 10.6,
      'calories': 155,
      'sodium': 124,
      'potassium': 126,
    },
    'eggs fried': {
      'category': 'protein',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 13.6,
      'carbs': 1.2,
      'net_carbs': 1.1,
      'fat': 15.0,
      'calories': 196,
      'sodium': 140,
      'potassium': 126,
    },
    'eggs omelette': {
      'category': 'protein',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 13.0,
      'carbs': 1.5,
      'net_carbs': 1.4,
      'fat': 12.0,
      'calories': 180,
      'sodium': 130,
      'potassium': 120,
    },
    
    // Dairy
    'yogurt plain': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 3.5,
      'carbs': 4.7,
      'net_carbs': 4.7,
      'fat': 3.3,
      'calories': 61,
      'sodium': 36,
      'potassium': 141,
    },
    'yogurt low fat': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 3.5,
      'carbs': 4.7,
      'net_carbs': 4.7,
      'fat': 0.8,
      'calories': 42,
      'sodium': 36,
      'potassium': 141,
    },
    'yogurt full fat': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 3.5,
      'carbs': 4.7,
      'net_carbs': 4.7,
      'fat': 5.0,
      'calories': 72,
      'sodium': 36,
      'potassium': 141,
    },
    'labneh': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 8.0,
      'carbs': 3.0,
      'net_carbs': 3.0,
      'fat': 8.0,
      'calories': 120,
      'sodium': 40,
      'potassium': 150,
    },
    
    // Fats & Spreads
    'tahini': {
      'category': 'fat',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 17.0,
      'carbs': 18.0,
      'net_carbs': 6.0,
      'fat': 50.0,
      'calories': 595,
      'sodium': 115,
      'potassium': 414,
    },
    'olive oil': {
      'category': 'fat',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 0.0,
      'carbs': 0.0,
      'net_carbs': 0.0,
      'fat': 100.0,
      'calories': 884,
      'sodium': 2,
      'potassium': 1,
    },
    'peanut butter': {
      'category': 'fat',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 25.0,
      'carbs': 20.0,
      'net_carbs': 7.0,
      'fat': 50.0,
      'calories': 588,
      'sodium': 459,
      'potassium': 649,
    },
    'hummus': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 8.0,
      'carbs': 14.0,
      'net_carbs': 8.0,
      'fat': 6.0,
      'calories': 166,
      'sodium': 379,
      'potassium': 173,
    },
    'falafel': {
      'category': 'mixed',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 13.0,
      'carbs': 32.0,
      'net_carbs': 26.0,
      'fat': 18.0,
      'calories': 333,
      'sodium': 294,
      'potassium': 585,
    },
    
    // Potatoes
    'potatoes boiled': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 2.0,
      'carbs': 17.0,
      'net_carbs': 15.0,
      'fat': 0.1,
      'calories': 77,
      'sodium': 5,
      'potassium': 421,
    },
    'potatoes baked': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 2.5,
      'carbs': 21.0,
      'net_carbs': 19.0,
      'fat': 0.1,
      'calories': 93,
      'sodium': 5,
      'potassium': 535,
    },
    'potatoes fried': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 3.4,
      'carbs': 35.0,
      'net_carbs': 31.0,
      'fat': 14.0,
      'calories': 312,
      'sodium': 210,
      'potassium': 535,
    },
    'sweet potatoes boiled': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 1.6,
      'carbs': 20.0,
      'net_carbs': 17.0,
      'fat': 0.1,
      'calories': 86,
      'sodium': 41,
      'potassium': 337,
    },
    'sweet potatoes baked': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 2.0,
      'carbs': 24.0,
      'net_carbs': 21.0,
      'fat': 0.2,
      'calories': 103,
      'sodium': 41,
      'potassium': 438,
    },
    
    // Vegetables
    'tomatoes': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 0.9,
      'carbs': 3.9,
      'net_carbs': 2.7,
      'fat': 0.2,
      'calories': 18,
      'sodium': 5,
      'potassium': 237,
    },
    'cucumbers': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 0.7,
      'carbs': 3.6,
      'net_carbs': 2.2,
      'fat': 0.1,
      'calories': 16,
      'sodium': 2,
      'potassium': 147,
    },
    'onions': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 1.1,
      'carbs': 9.3,
      'net_carbs': 7.6,
      'fat': 0.1,
      'calories': 40,
      'sodium': 4,
      'potassium': 146,
    },
    'lettuce': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 1.4,
      'carbs': 2.9,
      'net_carbs': 1.4,
      'fat': 0.2,
      'calories': 15,
      'sodium': 28,
      'potassium': 194,
    },
    
    // Fruits
    'watermelon': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 0.6,
      'carbs': 7.6,
      'net_carbs': 7.6,
      'fat': 0.2,
      'calories': 30,
      'sodium': 1,
      'potassium': 112,
    },
    'melon': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 0.8,
      'carbs': 8.0,
      'net_carbs': 7.0,
      'fat': 0.2,
      'calories': 34,
      'sodium': 16,
      'potassium': 267,
    },
    'grapes': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 0.7,
      'carbs': 18.0,
      'net_carbs': 16.0,
      'fat': 0.2,
      'calories': 62,
      'sodium': 2,
      'potassium': 191,
    },
    'pomegranate': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 1.7,
      'carbs': 19.0,
      'net_carbs': 14.0,
      'fat': 1.2,
      'calories': 83,
      'sodium': 3,
      'potassium': 236,
    },
    'figs': {
      'category': 'carb',
      'raw_weight_100g': 100,
      'cooked_weight_100g': 100,
      'protein': 0.8,
      'carbs': 19.0,
      'net_carbs': 16.0,
      'fat': 0.3,
      'calories': 74,
      'sodium': 1,
      'potassium': 232,
    },
  };

  NutritionAI();

  /// Get all foods from MENA database by category
  List<String> getMenaFoodsByCategory(String category) {
    return _menaFoodDatabase.keys
        .where((food) => _menaFoodDatabase[food]!['category'] == category)
        .toList();
  }

  /// Get all available categories in MENA database
  List<String> getMenaFoodCategories() {
    return _menaFoodDatabase.values
        .map((food) => food['category'] as String)
        .toSet()
        .toList();
  }

  /// Search MENA foods by name (partial match)
  List<String> searchMenaFoods(String query) {
    final lowerQuery = query.toLowerCase();
    return _menaFoodDatabase.keys
        .where((food) => food.contains(lowerQuery))
        .toList();
  }

  /// Calculate cooked weight needed for target macro from MENA food
  double? calculateMenaFoodWeight(String foodName, String targetMacro, double targetAmount) {
    final foodData = _menaFoodDatabase[foodName.toLowerCase()];
    if (foodData == null) return null;

    final macroValue = (foodData[targetMacro] as num?)?.toDouble();
    if (macroValue == null || macroValue == 0) return null;

    // Calculate weight needed: (target amount / macro per 100g) * 100
    return (targetAmount / macroValue) * 100;
  }

  /// Get MENA food data by name
  Map<String, dynamic>? getMenaFoodData(String foodName) {
    return _menaFoodDatabase[foodName.toLowerCase()];
  }

  /// Create FoodItem from MENA food with calculated weight
  FoodItem? createMenaFoodItem(String foodName, double cookedWeight) {
    final foodData = _menaFoodDatabase[foodName.toLowerCase()];
    if (foodData == null) return null;

    // Safe casting that handles both int and double values
    final protein = ((foodData['protein'] as num?)?.toDouble() ?? 0.0) * cookedWeight / 100;
    final carbs = ((foodData['carbs'] as num?)?.toDouble() ?? 0.0) * cookedWeight / 100;
    final fat = ((foodData['fat'] as num?)?.toDouble() ?? 0.0) * cookedWeight / 100;
    final sodium = ((foodData['sodium'] as num?)?.toDouble() ?? 0.0) * cookedWeight / 100;
    final potassium = ((foodData['potassium'] as num?)?.toDouble() ?? 0.0) * cookedWeight / 100;

    return FoodItem(
      name: foodName,
      amount: cookedWeight,
      protein: protein,
      carbs: carbs,
      fat: fat,
      kcal: NutritionPlan.calcKcal(protein, carbs, fat),
      sodium: sodium,
      potassium: potassium,
    );
  }

  /// Generate MENA food suggestions based on target macros
  List<FoodItem> generateMenaFoodSuggestions(Map<String, double> targetMacros) {
    final suggestions = <FoodItem>[];
    
    // Prioritize MENA foods for each macro target
    if (targetMacros['protein'] != null && targetMacros['protein']! > 0) {
      final proteinFoods = getMenaFoodsByCategory('protein');
      for (final food in proteinFoods.take(3)) { // Top 3 protein foods
        final weight = calculateMenaFoodWeight(food, 'protein', targetMacros['protein']!);
        if (weight != null && weight > 0) {
          final item = createMenaFoodItem(food, weight);
          if (item != null) suggestions.add(item);
        }
      }
    }

    if (targetMacros['carbs'] != null && targetMacros['carbs']! > 0) {
      final carbFoods = getMenaFoodsByCategory('carb');
      for (final food in carbFoods.take(3)) { // Top 3 carb foods
        final weight = calculateMenaFoodWeight(food, 'carbs', targetMacros['carbs']!);
        if (weight != null && weight > 0) {
          final item = createMenaFoodItem(food, weight);
          if (item != null) suggestions.add(item);
        }
      }
    }

    if (targetMacros['fat'] != null && targetMacros['fat']! > 0) {
      final fatFoods = getMenaFoodsByCategory('fat');
      for (final food in fatFoods.take(2)) { // Top 2 fat foods
        final weight = calculateMenaFoodWeight(food, 'fat', targetMacros['fat']!);
        if (weight != null && weight > 0) {
          final item = createMenaFoodItem(food, weight);
          if (item != null) suggestions.add(item);
        }
      }
    }

    return suggestions;
  }

  bool _canMakeRequest(String category) {
    final count = _requestCounts[category] ?? 0;
    return count < 10; // Simple rate limiting
  }

  void _incrementRequestCount(String category) {
    _requestCounts[category] = (_requestCounts[category] ?? 0) + 1;
  }

  /// Auto-fill food items from text input
  Future<List<FoodItem>> autoFillFromText(String text, {String locale = 'en'}) async {
    // Check cache first
    final cacheKey = 'nutrition_autofill_${text.hashCode}_$locale';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return (cached as List<dynamic>)
          .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    // Check rate limit
    if (!_canMakeRequest('nutrition')) {
      throw Exception('Rate limit exceeded for nutrition AI features');
    }

    _incrementRequestCount('nutrition');

    try {
      // Simulated AI response based on common foods
      final items = _simulateFoodItems(text);
      
      // Cache the result
      _cache[cacheKey] = items.map((item) => item.toMap()).toList();
      
      return items;
    } catch (e) {
      throw Exception('Failed to auto-fill nutrition data: $e');
    }
  }

  /// Generate food item with target macro amounts
  Future<List<FoodItem>> generateFoodWithTargetMacros(String foodName, Map<String, double> targetMacros, {String locale = 'en'}) async {
    // Check cache first
    final cacheKey = 'nutrition_target_${foodName.hashCode}_${targetMacros.hashCode}_$locale';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return (cached as List<dynamic>)
          .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    // Check rate limit
    if (!_canMakeRequest('nutrition')) {
      throw Exception('Rate limit exceeded for nutrition AI features');
    }

    _incrementRequestCount('nutrition');

    try {
      // Simulated AI response for target macro calculation
      final items = _simulateFoodWithTargetMacros(foodName, targetMacros);
      
      // Cache the result
      _cache[cacheKey] = items.map((item) => item.toMap()).toList();
      
      return items;
    } catch (e) {
      throw Exception('Failed to generate food with target macros: $e');
    }
  }

  List<FoodItem> _simulateFoodItems(String text) {
    final lowerText = text.toLowerCase();
    final items = <FoodItem>[];

    // Parse amounts from text (e.g., "100g chicken", "1 cup rice")
    double parseAmount(String foodText) {
      // Look for patterns like "100g", "1 cup", "2 tbsp", etc.
      final amountRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(g|gram|grams|cup|cups|tbsp|tablespoon|tablespoons|tsp|teaspoon|teaspoons|oz|ounce|ounces|lb|pound|pounds)');
      final match = amountRegex.firstMatch(foodText);
      
      if (match != null) {
        final value = double.tryParse(match.group(1) ?? '0') ?? 0;
        final unit = match.group(2)?.toLowerCase() ?? 'g';
        
        // Convert to grams
        switch (unit) {
          case 'g':
          case 'gram':
          case 'grams':
            return value;
          case 'cup':
          case 'cups':
            return value * 240; // 1 cup ≈ 240g
          case 'tbsp':
          case 'tablespoon':
          case 'tablespoons':
            return value * 15; // 1 tbsp ≈ 15g
          case 'tsp':
          case 'teaspoon':
          case 'teaspoons':
            return value * 5; // 1 tsp ≈ 5g
          case 'oz':
          case 'ounce':
          case 'ounces':
            return value * 28.35; // 1 oz ≈ 28.35g
          case 'lb':
          case 'pound':
          case 'pounds':
            return value * 453.59; // 1 lb ≈ 453.59g
          default:
            return value;
        }
      }
      
      return 100.0; // Default amount
    }

    // First, try to find exact matches in MENA database
    final menaMatches = searchMenaFoods(lowerText);
    if (menaMatches.isNotEmpty) {
      for (final foodName in menaMatches.take(2)) { // Limit to 2 suggestions
        final foodData = getMenaFoodData(foodName);
        if (foodData != null) {
          // Parse amount from text or use default
          final amount = parseAmount(text);
          final item = createMenaFoodItem(foodName, amount);
          if (item != null) items.add(item);
        }
      }
      if (items.isNotEmpty) return items;
    }

    // Fallback to global food database if no MENA matches found
    if (lowerText.contains('chicken') || lowerText.contains('دجاج')) {
      final amount = parseAmount(text);
      items.add(FoodItem(
        name: 'Chicken Breast',
        amount: amount,
        protein: (31 * amount) / 100, // Scale based on amount
        carbs: 0,
        fat: (3.6 * amount) / 100,
        kcal: NutritionPlan.calcKcal((31 * amount) / 100, 0, (3.6 * amount) / 100),
        sodium: (74 * amount) / 100,
        potassium: (256 * amount) / 100,
      ));
    }

    if (lowerText.contains('rice') || lowerText.contains('أرز')) {
      final amount = parseAmount(text);
      items.add(FoodItem(
        name: 'White Rice',
        amount: amount,
        protein: (4.5 * amount) / 100,
        carbs: (45 * amount) / 100,
        fat: (0.4 * amount) / 100,
        kcal: NutritionPlan.calcKcal((4.5 * amount) / 100, (45 * amount) / 100, (0.4 * amount) / 100),
        sodium: (1 * amount) / 100,
        potassium: (55 * amount) / 100,
      ));
    }

    if (lowerText.contains('egg') || lowerText.contains('بيض')) {
      final amount = parseAmount(text);
      items.add(FoodItem(
        name: 'Egg',
        amount: amount,
        protein: (12.6 * amount) / 100,
        carbs: (1.2 * amount) / 100,
        fat: (10.6 * amount) / 100,
        kcal: NutritionPlan.calcKcal((12.6 * amount) / 100, (1.2 * amount) / 100, (10.6 * amount) / 100),
        sodium: (124 * amount) / 100,
        potassium: (126 * amount) / 100,
      ));
    }

    if (lowerText.contains('salmon') || lowerText.contains('سلمون')) {
      final amount = parseAmount(text);
      items.add(FoodItem(
        name: 'Salmon',
        amount: amount,
        protein: (20 * amount) / 100,
        carbs: 0,
        fat: (13 * amount) / 100,
        kcal: NutritionPlan.calcKcal((20 * amount) / 100, 0, (13 * amount) / 100),
        sodium: (59 * amount) / 100,
        potassium: (363 * amount) / 100,
      ));
    }

    if (lowerText.contains('broccoli') || lowerText.contains('بروكلي')) {
      final amount = parseAmount(text);
      items.add(FoodItem(
        name: 'Broccoli',
        amount: amount,
        protein: (2.8 * amount) / 100,
        carbs: (7 * amount) / 100,
        fat: (0.4 * amount) / 100,
        kcal: NutritionPlan.calcKcal((2.8 * amount) / 100, (7 * amount) / 100, (0.4 * amount) / 100),
        sodium: (33 * amount) / 100,
        potassium: (316 * amount) / 100,
      ));
    }

    // Default fallback
    if (items.isEmpty) {
      final amount = parseAmount(text);
      items.add(FoodItem(
        name: 'Food Item',
        amount: amount,
        protein: (10 * amount) / 100,
        carbs: (20 * amount) / 100,
        fat: (5 * amount) / 100,
        kcal: NutritionPlan.calcKcal((10 * amount) / 100, (20 * amount) / 100, (5 * amount) / 100),
        sodium: (100 * amount) / 100,
        potassium: (200 * amount) / 100,
      ));
    }

    return items;
  }

  List<FoodItem> _simulateFoodWithTargetMacros(String foodName, Map<String, double> targetMacros) {
    final lowerFoodName = foodName.toLowerCase();
    final items = <FoodItem>[];

    // First, try to find the food in MENA database
    final menaFoodData = getMenaFoodData(lowerFoodName);
    if (menaFoodData != null) {
      // Calculate the required weight to achieve target macros
      double requiredWeight = 100.0; // Default to 100g
      String weightDescription = '100g';

      // Find the limiting macro (the one that requires the most weight)
      final baseProtein = (menaFoodData['protein'] as num?)?.toDouble() ?? 0.0;
      final baseCarbs = (menaFoodData['carbs'] as num?)?.toDouble() ?? 0.0;
      final baseFat = (menaFoodData['fat'] as num?)?.toDouble() ?? 0.0;

      if (targetMacros['protein'] != null && baseProtein > 0) {
        final proteinWeight = (targetMacros['protein']! / baseProtein) * 100;
        if (proteinWeight > requiredWeight) {
          requiredWeight = proteinWeight;
          weightDescription = '${requiredWeight.round()}g';
        }
      }

      if (targetMacros['carbs'] != null && baseCarbs > 0) {
        final carbsWeight = (targetMacros['carbs']! / baseCarbs) * 100;
        if (carbsWeight > requiredWeight) {
          requiredWeight = carbsWeight;
          weightDescription = '${requiredWeight.round()}g';
        }
      }

      if (targetMacros['fat'] != null && baseFat > 0) {
        final fatWeight = (targetMacros['fat']! / baseFat) * 100;
        if (fatWeight > requiredWeight) {
          requiredWeight = fatWeight;
          weightDescription = '${requiredWeight.round()}g';
        }
      }

      // Create the food item with calculated weight and macros
      final item = createMenaFoodItem(lowerFoodName, requiredWeight.round().toDouble());
      if (item != null) {
        items.add(item);
        return items;
      }
    }

    // Fallback to global food database
    final baseNutrition = _getBaseNutritionPer100g(lowerFoodName);
    if (baseNutrition == null) {
      // Fallback to estimated food item with calculated amount
      final totalTargetMacros = (targetMacros['protein'] ?? 0) + (targetMacros['carbs'] ?? 0) + (targetMacros['fat'] ?? 0);
      final estimatedAmount = totalTargetMacros > 0 ? (totalTargetMacros * 4) : 100.0; // Rough estimate based on macros
      
      items.add(FoodItem(
        name: '$foodName (estimated)',
        amount: estimatedAmount,
        protein: targetMacros['protein'] ?? 0,
        carbs: targetMacros['carbs'] ?? 0,
        fat: targetMacros['fat'] ?? 0,
        kcal: NutritionPlan.calcKcal(
          targetMacros['protein'] ?? 0,
          targetMacros['carbs'] ?? 0,
          targetMacros['fat'] ?? 0,
        ),
        sodium: 100,
        potassium: 200,
      ));
      return items;
    }

    // Calculate the required weight to achieve target macros
    double requiredWeight = 100.0; // Default to 100g
    String weightDescription = '100g';

    // Find the limiting macro (the one that requires the most weight)
    final baseProtein = baseNutrition['protein'] ?? 0.0;
    final baseCarbs = baseNutrition['carbs'] ?? 0.0;
    final baseFat = baseNutrition['fat'] ?? 0.0;

    if (targetMacros['protein'] != null && baseProtein > 0) {
      final proteinWeight = (targetMacros['protein']! / baseProtein) * 100;
      if (proteinWeight > requiredWeight) {
        requiredWeight = proteinWeight;
        weightDescription = '${requiredWeight.round()}g';
      }
    }

    if (targetMacros['carbs'] != null && baseCarbs > 0) {
      final carbsWeight = (targetMacros['carbs']! / baseCarbs) * 100;
      if (carbsWeight > requiredWeight) {
        requiredWeight = carbsWeight;
        weightDescription = '${requiredWeight.round()}g';
      }
    }

    if (targetMacros['fat'] != null && baseFat > 0) {
      final fatWeight = (targetMacros['fat']! / baseFat) * 100;
      if (fatWeight > requiredWeight) {
        requiredWeight = fatWeight;
        weightDescription = '${requiredWeight.round()}g';
      }
    }

    // Calculate actual macros for the required weight
    final actualProtein = (baseProtein * requiredWeight) / 100;
    final actualCarbs = (baseCarbs * requiredWeight) / 100;
    final actualFat = (baseFat * requiredWeight) / 100;
    final actualSodium = ((baseNutrition['sodium'] ?? 0.0) * requiredWeight) / 100;
    final actualPotassium = ((baseNutrition['potassium'] ?? 0.0) * requiredWeight) / 100;

    // Create the food item with calculated weight and macros
    items.add(FoodItem(
      name: '$foodName $weightDescription',
      amount: requiredWeight.round().toDouble(),
      protein: actualProtein,
      carbs: actualCarbs,
      fat: actualFat,
      kcal: NutritionPlan.calcKcal(actualProtein, actualCarbs, actualFat),
      sodium: actualSodium,
      potassium: actualPotassium,
    ));

    return items;
  }

  Map<String, double>? _getBaseNutritionPer100g(String foodName) {
    // Comprehensive database of common foods with nutrition per 100g
    if (foodName.contains('chicken') || foodName.contains('دجاج')) {
      return {
        'protein': 31.0,
        'carbs': 0.0,
        'fat': 3.6,
        'sodium': 74.0,
        'potassium': 256.0,
      };
    }

    if (foodName.contains('rice') || foodName.contains('أرز')) {
      return {
        'protein': 4.5,
        'carbs': 45.0,
        'fat': 0.4,
        'sodium': 1.0,
        'potassium': 55.0,
      };
    }

    if (foodName.contains('brown rice')) {
      return {
        'protein': 7.5,
        'carbs': 77.0,
        'fat': 2.7,
        'sodium': 5.0,
        'potassium': 223.0,
      };
    }

    if (foodName.contains('egg') || foodName.contains('بيض')) {
      return {
        'protein': 12.6,
        'carbs': 1.2,
        'fat': 10.6,
        'sodium': 124.0,
        'potassium': 126.0,
      };
    }

    if (foodName.contains('salmon') || foodName.contains('سلمون')) {
      return {
        'protein': 20.0,
        'carbs': 0.0,
        'fat': 13.0,
        'sodium': 59.0,
        'potassium': 363.0,
      };
    }

    if (foodName.contains('broccoli') || foodName.contains('بروكلي')) {
      return {
        'protein': 2.8,
        'carbs': 7.0,
        'fat': 0.4,
        'sodium': 33.0,
        'potassium': 316.0,
      };
    }

    if (foodName.contains('oatmeal') || foodName.contains('oat')) {
      return {
        'protein': 13.5,
        'carbs': 68.0,
        'fat': 6.5,
        'sodium': 49.0,
        'potassium': 350.0,
      };
    }

    if (foodName.contains('quinoa')) {
      return {
        'protein': 14.1,
        'carbs': 64.0,
        'fat': 6.1,
        'sodium': 7.0,
        'potassium': 563.0,
      };
    }

    if (foodName.contains('sweet potato')) {
      return {
        'protein': 1.6,
        'carbs': 20.0,
        'fat': 0.1,
        'sodium': 41.0,
        'potassium': 337.0,
      };
    }

    if (foodName.contains('almond') || foodName.contains('لوز')) {
      return {
        'protein': 21.2,
        'carbs': 21.7,
        'fat': 49.9,
        'sodium': 1.0,
        'potassium': 733.0,
      };
    }

    if (foodName.contains('banana')) {
      return {
        'protein': 1.1,
        'carbs': 23.0,
        'fat': 0.3,
        'sodium': 1.0,
        'potassium': 358.0,
      };
    }

    if (foodName.contains('apple')) {
      return {
        'protein': 0.3,
        'carbs': 14.0,
        'fat': 0.2,
        'sodium': 1.0,
        'potassium': 107.0,
      };
    }

    if (foodName.contains('spinach')) {
      return {
        'protein': 2.9,
        'carbs': 3.6,
        'fat': 0.4,
        'sodium': 79.0,
        'potassium': 558.0,
      };
    }

    if (foodName.contains('greek yogurt')) {
      return {
        'protein': 10.0,
        'carbs': 3.6,
        'fat': 0.4,
        'sodium': 36.0,
        'potassium': 141.0,
      };
    }

    if (foodName.contains('milk')) {
      return {
        'protein': 3.4,
        'carbs': 4.8,
        'fat': 3.6,
        'sodium': 44.0,
        'potassium': 143.0,
      };
    }

    if (foodName.contains('beef') || foodName.contains('لحم بقري')) {
      return {
        'protein': 26.0,
        'carbs': 0.0,
        'fat': 15.0,
        'sodium': 72.0,
        'potassium': 318.0,
      };
    }

    if (foodName.contains('fish') || foodName.contains('سمك')) {
      return {
        'protein': 20.0,
        'carbs': 0.0,
        'fat': 4.0,
        'sodium': 78.0,
        'potassium': 356.0,
      };
    }

    if (foodName.contains('pasta')) {
      return {
        'protein': 12.5,
        'carbs': 71.0,
        'fat': 1.5,
        'sodium': 6.0,
        'potassium': 223.0,
      };
    }

    if (foodName.contains('bread')) {
      return {
        'protein': 9.0,
        'carbs': 49.0,
        'fat': 3.2,
        'sodium': 491.0,
        'potassium': 115.0,
      };
    }

    // Return null if food not found in database
    return null;
  }

  /// Generate a full day of meals based on target macros and meal count
  Future<List<Meal>> generateFullDay(Map<String, double> targets, int mealCount, {String locale = 'en'}) async {
    // Check cache first
    final cacheKey = 'nutrition_fullday_${targets.hashCode}_${mealCount}_$locale';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return (cached as List<dynamic>)
          .map((meal) => Meal.fromMap(meal as Map<String, dynamic>))
          .toList();
    }

    // Check rate limit
    if (!_canMakeRequest('nutrition')) {
      throw Exception('Rate limit exceeded for nutrition AI features');
    }

    _incrementRequestCount('nutrition');

    try {
      // Simulated meal generation
      final meals = _simulateFullDay(targets, mealCount);
      
      // Cache the result
      _cache[cacheKey] = meals.map((meal) => meal.toMap()).toList();
      
      return meals;
    } catch (e) {
      throw Exception('Failed to generate full day: $e');
    }
  }

  List<Meal> _simulateFullDay(Map<String, double> targets, int mealCount) {
    final protein = targets['protein'] ?? 160;
    final carbs = targets['carbs'] ?? 140;
    final fat = targets['fat'] ?? 50;
    final kcal = targets['kcal'] ?? 1860;

    // Smart distribution based on meal count
    final distribution = _getMealDistribution(mealCount);
    
    final meals = <Meal>[];
    final mealLabels = _getMealLabels(mealCount);
    
    for (int i = 0; i < mealCount; i++) {
      final ratio = distribution[i];
      final mealProtein = protein * ratio;
      final mealCarbs = carbs * ratio;
      final mealFat = fat * ratio;
      
      meals.add(_createMeal(mealLabels[i], mealProtein, mealCarbs, mealFat, i));
    }
    
    return meals;
  }

  List<double> _getMealDistribution(int mealCount) {
    switch (mealCount) {
      case 1:
        return [1.0];
      case 2:
        return [0.4, 0.6]; // Breakfast lighter, dinner heavier
      case 3:
        return [0.25, 0.35, 0.4]; // Breakfast, lunch, dinner
      case 4:
        return [0.2, 0.3, 0.3, 0.2]; // Breakfast, lunch, snack, dinner
      case 5:
        return [0.2, 0.25, 0.2, 0.2, 0.15]; // Breakfast, lunch, snack, dinner, evening
      case 6:
        return [0.15, 0.2, 0.15, 0.2, 0.2, 0.1]; // Multiple smaller meals
      case 7:
        return [0.12, 0.18, 0.15, 0.18, 0.15, 0.12, 0.1]; // Very frequent meals
      case 8:
        return [0.1, 0.15, 0.12, 0.15, 0.12, 0.15, 0.12, 0.09]; // Grazing pattern
      case 9:
        return [0.09, 0.12, 0.1, 0.12, 0.1, 0.12, 0.1, 0.12, 0.13]; // Very frequent
      case 10:
        return [0.08, 0.1, 0.08, 0.1, 0.08, 0.1, 0.08, 0.1, 0.1, 0.18]; // Many small + one larger
      default:
        return [0.25, 0.35, 0.4]; // Default to 3 meals
    }
  }

  List<String> _getMealLabels(int mealCount) {
    switch (mealCount) {
      case 1:
        return ['Main Meal'];
      case 2:
        return ['Breakfast', 'Dinner'];
      case 3:
        return ['Breakfast', 'Lunch', 'Dinner'];
      case 4:
        return ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
      case 5:
        return ['Breakfast', 'Lunch', 'Snack', 'Dinner', 'Evening'];
      case 6:
        return ['Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Evening'];
      case 7:
        return ['Early Breakfast', 'Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Evening'];
      case 8:
        return ['Early Breakfast', 'Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Evening Snack', 'Late Evening'];
      case 9:
        return ['Early Breakfast', 'Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Evening Snack', 'Late Evening', 'Night'];
      case 10:
        return ['Early Breakfast', 'Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Evening Snack', 'Late Evening', 'Night', 'Main Meal'];
      default:
        return ['Breakfast', 'Lunch', 'Dinner'];
    }
  }

  Meal _createMeal(String label, double protein, double carbs, double fat, int mealIndex) {
    // Create food items based on meal type and macros
    final items = <FoodItem>[];
    
    if (label.toLowerCase().contains('breakfast')) {
      items.addAll(_createBreakfastFoods(protein, carbs, fat));
    } else if (label.toLowerCase().contains('lunch')) {
      items.addAll(_createLunchFoods(protein, carbs, fat));
    } else if (label.toLowerCase().contains('dinner')) {
      items.addAll(_createDinnerFoods(protein, carbs, fat));
    } else if (label.toLowerCase().contains('snack')) {
      items.addAll(_createSnackFoods(protein, carbs, fat));
    } else {
      items.addAll(_createGeneralFoods(protein, carbs, fat));
    }
    
    return Meal(
      label: label,
      items: items,
      mealSummary: MealSummary(
        totalProtein: protein,
        totalCarbs: carbs,
        totalFat: fat,
        totalKcal: NutritionPlan.calcKcal(protein, carbs, fat),
        totalSodium: _estimateSodium(items),
        totalPotassium: _estimatePotassium(items),
      ),
    );
  }

  List<FoodItem> _createBreakfastFoods(double protein, double carbs, double fat) {
    final items = <FoodItem>[];
    
    if (protein > 0) {
      // Try MENA foods first, then fallback to global
      final menaProteinFoods = getMenaFoodsByCategory('protein');
      if (menaProteinFoods.isNotEmpty) {
        // Use eggs or labneh for breakfast protein
        final breakfastProteinFoods = menaProteinFoods.where((food) => 
          food.contains('egg') || food.contains('labneh') || food.contains('yogurt')).toList();
        
        if (breakfastProteinFoods.isNotEmpty) {
          final foodName = breakfastProteinFoods.first;
          final weight = calculateMenaFoodWeight(foodName, 'protein', protein * 0.6);
          if (weight != null && weight > 0) {
            final item = createMenaFoodItem(foodName, weight.round().toDouble());
            if (item != null) items.add(item);
          }
        }
      }
      
      // Fallback to global foods if no MENA protein found
      if (items.isEmpty) {
        final greekYogurtProteinPer100g = 10.0; // 10g protein per 100g Greek yogurt
        final greekYogurtAmount = (protein * 0.6) / greekYogurtProteinPer100g * 100;
        
        items.add(FoodItem(
          name: 'Greek Yogurt',
          amount: greekYogurtAmount.round().toDouble(),
          protein: protein * 0.6,
          carbs: carbs * 0.2,
          fat: fat * 0.3,
          kcal: NutritionPlan.calcKcal(protein * 0.6, carbs * 0.2, fat * 0.3),
          sodium: (80 * greekYogurtAmount) / 100,
          potassium: (150 * greekYogurtAmount) / 100,
        ));
      }
    }
    
    if (carbs > 0) {
      // Try MENA carb foods first
      final menaCarbFoods = getMenaFoodsByCategory('carb');
      if (menaCarbFoods.isNotEmpty) {
        // Use Iraqi samoon, pita, or dates for breakfast carbs
        final breakfastCarbFoods = menaCarbFoods.where((food) => 
          food.contains('samoon') || food.contains('pita') || food.contains('date') || food.contains('bread')).toList();
        
        if (breakfastCarbFoods.isNotEmpty) {
          final foodName = breakfastCarbFoods.first;
          final weight = calculateMenaFoodWeight(foodName, 'carbs', carbs * 0.8);
          if (weight != null && weight > 0) {
            final item = createMenaFoodItem(foodName, weight.round().toDouble());
            if (item != null) items.add(item);
          }
        }
      }
      
      // Fallback to global foods if no MENA carbs found
      if (items.length <= (protein > 0 ? 1 : 0)) {
        final oatmealCarbsPer100g = 68.0; // 68g carbs per 100g oatmeal
        final oatmealAmount = (carbs * 0.8) / oatmealCarbsPer100g * 100;
        
        items.add(FoodItem(
          name: 'Oatmeal with Berries',
          amount: oatmealAmount.round().toDouble(),
          protein: protein * 0.4,
          carbs: carbs * 0.8,
          fat: fat * 0.7,
          kcal: NutritionPlan.calcKcal(protein * 0.4, carbs * 0.8, fat * 0.7),
          sodium: (50 * oatmealAmount) / 100,
          potassium: (200 * oatmealAmount) / 100,
        ));
      }
    }
    
    return items;
  }

  List<FoodItem> _createLunchFoods(double protein, double carbs, double fat) {
    final items = <FoodItem>[];
    
    if (protein > 0) {
      // Try MENA protein foods first
      final menaProteinFoods = getMenaFoodsByCategory('protein');
      if (menaProteinFoods.isNotEmpty) {
        // Use Iraqi kebab, grilled chicken, or grilled lamb for lunch protein
        final lunchProteinFoods = menaProteinFoods.where((food) => 
          food.contains('kebab') || food.contains('chicken') || food.contains('lamb') || food.contains('fish')).toList();
        
        if (lunchProteinFoods.isNotEmpty) {
          final foodName = lunchProteinFoods.first;
          final weight = calculateMenaFoodWeight(foodName, 'protein', protein * 0.7);
          if (weight != null && weight > 0) {
            final item = createMenaFoodItem(foodName, weight.round().toDouble());
            if (item != null) items.add(item);
          }
        }
      }
      
      // Fallback to global foods if no MENA protein found
      if (items.isEmpty) {
        final chickenProteinPer100g = 31.0; // 31g protein per 100g chicken breast
        final chickenAmount = (protein * 0.7) / chickenProteinPer100g * 100;
        
        items.add(FoodItem(
          name: 'Grilled Chicken Breast',
          amount: chickenAmount.round().toDouble(),
          protein: protein * 0.7,
          carbs: 0,
          fat: fat * 0.4,
          kcal: NutritionPlan.calcKcal(protein * 0.7, 0, fat * 0.4),
          sodium: (200 * chickenAmount) / 100,
          potassium: (400 * chickenAmount) / 100,
        ));
      }
    }
    
    if (carbs > 0) {
      // Try MENA carb foods first
      final menaCarbFoods = getMenaFoodsByCategory('carb');
      if (menaCarbFoods.isNotEmpty) {
        // Use bulgur wheat, couscous, or rice for lunch carbs
        final lunchCarbFoods = menaCarbFoods.where((food) => 
          food.contains('bulgur') || food.contains('couscous') || food.contains('rice')).toList();
        
        if (lunchCarbFoods.isNotEmpty) {
          final foodName = lunchCarbFoods.first;
          final weight = calculateMenaFoodWeight(foodName, 'carbs', carbs * 0.6);
          if (weight != null && weight > 0) {
            final item = createMenaFoodItem(foodName, weight.round().toDouble());
            if (item != null) items.add(item);
          }
        }
      }
      
      // Fallback to global foods if no MENA carbs found
      if (items.length <= (protein > 0 ? 1 : 0)) {
        final riceCarbsPer100g = 77.0; // 77g carbs per 100g brown rice
        final riceAmount = (carbs * 0.6) / riceCarbsPer100g * 100;
        
        items.add(FoodItem(
          name: 'Brown Rice',
          amount: riceAmount.round().toDouble(),
          protein: protein * 0.3,
          carbs: carbs * 0.6,
          fat: fat * 0.2,
          kcal: NutritionPlan.calcKcal(protein * 0.3, carbs * 0.6, fat * 0.2),
          sodium: (5 * riceAmount) / 100,
          potassium: (150 * riceAmount) / 100,
        ));
      }
    }
    
    // Add vegetables or hummus
    final menaMixedFoods = getMenaFoodsByCategory('mixed');
    if (menaMixedFoods.isNotEmpty) {
      // Use hummus, falafel, or vegetables
      final sideFoods = menaMixedFoods.where((food) => 
        food.contains('hummus') || food.contains('falafel') || food.contains('lentil') || food.contains('chickpea')).toList();
      
      if (sideFoods.isNotEmpty) {
        final foodName = sideFoods.first;
        final weight = calculateMenaFoodWeight(foodName, 'carbs', carbs * 0.4);
        if (weight != null && weight > 0) {
          final item = createMenaFoodItem(foodName, weight.round().toDouble());
          if (item != null) items.add(item);
        }
      }
    }
    
    // Fallback to global vegetables if no MENA side found
    if (items.length <= (protein > 0 ? 1 : 0) + (carbs > 0 ? 1 : 0)) {
      final vegCarbsPer100g = 7.0; // 7g carbs per 100g mixed vegetables
      final vegAmount = (carbs * 0.4) / vegCarbsPer100g * 100;
      
      items.add(FoodItem(
        name: 'Mixed Vegetables',
        amount: vegAmount.round().toDouble(),
        protein: 0,
        carbs: carbs * 0.4,
        fat: fat * 0.4,
        kcal: NutritionPlan.calcKcal(0, carbs * 0.4, fat * 0.4),
        sodium: (50 * vegAmount) / 100,
        potassium: (300 * vegAmount) / 100,
      ));
    }
    
    return items;
  }

  List<FoodItem> _createDinnerFoods(double protein, double carbs, double fat) {
    final items = <FoodItem>[];
    
    if (protein > 0) {
      // Calculate amount of Salmon needed for the target protein
      final salmonProteinPer100g = 20.0; // 20g protein per 100g salmon
      final salmonAmount = (protein * 0.6) / salmonProteinPer100g * 100;
      
      items.add(FoodItem(
        name: 'Salmon Fillet',
        amount: salmonAmount.round().toDouble(),
        protein: protein * 0.6,
        carbs: 0,
        fat: fat * 0.5,
        kcal: NutritionPlan.calcKcal(protein * 0.6, 0, fat * 0.5),
        sodium: (150 * salmonAmount) / 100,
        potassium: (500 * salmonAmount) / 100,
      ));
    }
    
    if (carbs > 0) {
      // Calculate amount of Quinoa needed for the target carbs
      final quinoaCarbsPer100g = 64.0; // 64g carbs per 100g quinoa
      final quinoaAmount = (carbs * 0.7) / quinoaCarbsPer100g * 100;
      
      items.add(FoodItem(
        name: 'Quinoa',
        amount: quinoaAmount.round().toDouble(),
        protein: protein * 0.4,
        carbs: carbs * 0.7,
        fat: fat * 0.3,
        kcal: NutritionPlan.calcKcal(protein * 0.4, carbs * 0.7, fat * 0.3),
        sodium: (10 * quinoaAmount) / 100,
        potassium: (200 * quinoaAmount) / 100,
      ));
    }
    
    // Calculate amount of Broccoli needed
    final broccoliCarbsPer100g = 7.0; // 7g carbs per 100g broccoli
    final broccoliAmount = (carbs * 0.3) / broccoliCarbsPer100g * 100;
    
    items.add(FoodItem(
      name: 'Steamed Broccoli',
      amount: broccoliAmount.round().toDouble(),
      protein: 0,
      carbs: carbs * 0.3,
      fat: fat * 0.2,
      kcal: NutritionPlan.calcKcal(0, carbs * 0.3, fat * 0.2),
      sodium: (30 * broccoliAmount) / 100,
      potassium: (250 * broccoliAmount) / 100,
    ));
    
    return items;
  }

  List<FoodItem> _createSnackFoods(double protein, double carbs, double fat) {
    final items = <FoodItem>[];
    
    if (protein > 0) {
      // Calculate amount of Almonds needed for the target protein
      final almondProteinPer100g = 21.2; // 21.2g protein per 100g almonds
      final almondAmount = (protein * 0.4) / almondProteinPer100g * 100;
      
      items.add(FoodItem(
        name: 'Almonds',
        amount: almondAmount.round().toDouble(),
        protein: protein * 0.4,
        carbs: carbs * 0.2,
        fat: fat * 0.6,
        kcal: NutritionPlan.calcKcal(protein * 0.4, carbs * 0.2, fat * 0.6),
        sodium: (5 * almondAmount) / 100,
        potassium: (200 * almondAmount) / 100,
      ));
    }
    
    if (carbs > 0) {
      // Calculate amount of Apple needed for the target carbs
      final appleCarbsPer100g = 14.0; // 14g carbs per 100g apple
      final appleAmount = (carbs * 0.8) / appleCarbsPer100g * 100;
      
      items.add(FoodItem(
        name: 'Apple',
        amount: appleAmount.round().toDouble(),
        protein: protein * 0.1,
        carbs: carbs * 0.8,
        fat: fat * 0.1,
        kcal: NutritionPlan.calcKcal(protein * 0.1, carbs * 0.8, fat * 0.1),
        sodium: (1 * appleAmount) / 100,
        potassium: (100 * appleAmount) / 100,
      ));
    }
    
    return items;
  }

  List<FoodItem> _createGeneralFoods(double protein, double carbs, double fat) {
    final items = <FoodItem>[];
    
    if (protein > 0) {
      // Calculate amount of Lean Protein needed for the target protein
      final leanProteinPer100g = 26.0; // 26g protein per 100g lean beef
      final leanProteinAmount = (protein * 0.8) / leanProteinPer100g * 100;
      
      items.add(FoodItem(
        name: 'Lean Protein',
        amount: leanProteinAmount.round().toDouble(),
        protein: protein * 0.8,
        carbs: 0,
        fat: fat * 0.3,
        kcal: NutritionPlan.calcKcal(protein * 0.8, 0, fat * 0.3),
        sodium: (100 * leanProteinAmount) / 100,
        potassium: (300 * leanProteinAmount) / 100,
      ));
    }
    
    if (carbs > 0) {
      // Calculate amount of Complex Carbs needed for the target carbs
      final complexCarbsPer100g = 71.0; // 71g carbs per 100g pasta
      final complexCarbsAmount = (carbs * 0.9) / complexCarbsPer100g * 100;
      
      items.add(FoodItem(
        name: 'Complex Carbs',
        amount: complexCarbsAmount.round().toDouble(),
        protein: protein * 0.2,
        carbs: carbs * 0.9,
        fat: fat * 0.2,
        kcal: NutritionPlan.calcKcal(protein * 0.2, carbs * 0.9, fat * 0.2),
        sodium: (10 * complexCarbsAmount) / 100,
        potassium: (150 * complexCarbsAmount) / 100,
      ));
    }
    
    return items;
  }

  double _estimateSodium(List<FoodItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.sodium);
  }

  double _estimatePotassium(List<FoodItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.potassium);
  }

  /// Estimate minerals for a list of food items
  Future<Map<String, double>> estimateMinerals(List<FoodItem> items) async {
    // Check cache first
    final cacheKey = 'nutrition_minerals_${items.hashCode}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return Map<String, double>.from(cached as Map<String, dynamic>);
    }

    // Check rate limit
    if (!_canMakeRequest('nutrition')) {
      throw Exception('Rate limit exceeded for nutrition AI features');
    }

    _incrementRequestCount('nutrition');

    try {
      // Simulated mineral estimation
      double totalSodium = 0;
      double totalPotassium = 0;

      for (final item in items) {
        // Simple estimation based on food type
        final lowerName = item.name.toLowerCase();
        
        double sodium = 100; // default
        double potassium = 200; // default
        
        if (lowerName.contains('chicken')) {
          sodium = 74;
          potassium = 256;
        } else if (lowerName.contains('rice')) {
          sodium = 1;
          potassium = 55;
        } else if (lowerName.contains('salmon')) {
          sodium = 59;
          potassium = 363;
        } else if (lowerName.contains('broccoli')) {
          sodium = 33;
          potassium = 316;
        } else if (lowerName.contains('egg')) {
          sodium = 62;
          potassium = 63;
        }
        
        // Estimate portion size based on protein content
        final portionMultiplier = item.protein > 0 ? item.protein / 20.0 : 1.0;
        
        totalSodium += sodium * portionMultiplier;
        totalPotassium += potassium * portionMultiplier;
      }

      final result = {
        'totalSodium': totalSodium,
        'totalPotassium': totalPotassium,
      };

      // Cache the result
      _cache[cacheKey] = result;
      
      return Map<String, double>.from(result);
    } catch (e) {
      throw Exception('Failed to estimate minerals: $e');
    }
  }

  /// Get popular MENA food combinations for quick meal suggestions
  Map<String, List<String>> getPopularMenaCombinations() {
    return {
      'Breakfast': ['iraqi samoon', 'labneh', 'dates fresh', 'eggs boiled'],
      'Lunch': ['iraqi kebab', 'bulgur wheat', 'hummus', 'tomatoes'],
      'Dinner': ['grilled fish zubaidi', 'white basmati rice', 'falafel', 'cucumbers'],
      'Snack': ['tahini', 'pita bread', 'grapes', 'pomegranate'],
    };
  }

  /// Get all available MENA foods as a list for UI dropdowns
  List<String> getAllMenaFoods() {
    return _menaFoodDatabase.keys.toList()..sort();
  }

  /// Get MENA foods by macro category for UI filtering
  Map<String, List<String>> getMenaFoodsByMacroCategory() {
    return {
      'Protein': getMenaFoodsByCategory('protein'),
      'Carbs': getMenaFoodsByCategory('carb'),
      'Fat': getMenaFoodsByCategory('fat'),
      'Mixed': getMenaFoodsByCategory('mixed'),
    };
  }
}
