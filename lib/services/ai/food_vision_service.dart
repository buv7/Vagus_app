import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../models/nutrition/food_item.dart';

/// Food Vision Service using Google Gemini AI for food recognition
/// and CalorieNinjas for nutrition data lookup
class FoodVisionService {
  static final FoodVisionService _instance = FoodVisionService._internal();
  factory FoodVisionService() => _instance;
  FoodVisionService._internal();

  GenerativeModel? _geminiModel;
  bool _initialized = false;

  /// Initialize the Gemini model
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('⚠️ GEMINI_API_KEY not found in .env - using fallback estimation');
      return;
    }

    try {
      _geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash', // Free tier model with vision capabilities
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, // Low temperature for more consistent results
        ),
      );
      _initialized = true;
      debugPrint('✅ Gemini AI initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Gemini: $e');
    }
  }

  /// Analyze food image and return estimated nutrition
  Future<FoodItem?> analyzeImage(Uint8List imageBytes, {String? locale}) async {
    await _ensureInitialized();

    // Try Gemini AI first
    if (_geminiModel != null) {
      final result = await _analyzeWithGemini(imageBytes, locale);
      if (result != null) return result;
    }

    // Fallback to basic estimation
    return _fallbackEstimation();
  }

  /// Analyze image using Google Gemini AI
  Future<FoodItem?> _analyzeWithGemini(Uint8List imageBytes, String? locale) async {
    try {
      final languageHint = locale == 'ar' ? 'Arabic' : locale == 'ku' ? 'Kurdish' : 'English';
      
      final prompt = '''
Analyze this food image and provide nutritional estimation.

Return a JSON object with the following structure:
{
  "name": "Name of the food/dish in $languageHint",
  "name_en": "Name in English",
  "description": "Brief description of what you see",
  "estimated_weight_grams": <number>,
  "confidence": <0.0 to 1.0>,
  "nutrition_per_serving": {
    "calories": <number>,
    "protein_g": <number>,
    "carbs_g": <number>,
    "fat_g": <number>,
    "fiber_g": <number>,
    "sodium_mg": <number>,
    "potassium_mg": <number>
  },
  "ingredients": ["list", "of", "visible", "ingredients"],
  "food_category": "meal|snack|drink|dessert|fruit|vegetable|protein|grain"
}

Be realistic with portion sizes. If you can't identify the food clearly, set confidence below 0.5.
If this is not a food image, return {"error": "Not a food image", "confidence": 0}.
''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await _geminiModel!.generateContent([content]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        debugPrint('❌ Empty response from Gemini');
        return null;
      }

      debugPrint('📸 Gemini response: $responseText');

      // Parse the JSON response
      final jsonData = _parseJsonResponse(responseText);
      if (jsonData == null) {
        debugPrint('❌ Failed to parse Gemini response as JSON');
        return null;
      }

      // Check for error response
      if (jsonData.containsKey('error')) {
        debugPrint('⚠️ Gemini error: ${jsonData['error']}');
        return null;
      }

      // Check confidence threshold
      final confidence = (jsonData['confidence'] as num?)?.toDouble() ?? 0.5;
      if (confidence < 0.3) {
        debugPrint('⚠️ Low confidence result: $confidence');
        return null;
      }

      // Extract nutrition data
      final nutrition = jsonData['nutrition_per_serving'] as Map<String, dynamic>?;
      if (nutrition == null) {
        debugPrint('❌ No nutrition data in response');
        return null;
      }

      // Create FoodItem
      final foodItem = FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: jsonData['name'] as String? ?? jsonData['name_en'] as String? ?? 'Unknown Food',
        protein: (nutrition['protein_g'] as num?)?.toDouble() ?? 0.0,
        carbs: (nutrition['carbs_g'] as num?)?.toDouble() ?? 0.0,
        fat: (nutrition['fat_g'] as num?)?.toDouble() ?? 0.0,
        kcal: (nutrition['calories'] as num?)?.toDouble() ?? 0.0,
        sodium: (nutrition['sodium_mg'] as num?)?.toDouble() ?? 0.0,
        potassium: (nutrition['potassium_mg'] as num?)?.toDouble() ?? 0.0,
        amount: (jsonData['estimated_weight_grams'] as num?)?.toDouble() ?? 100.0,
        unit: 'g',
        estimated: true,
        source: 'ai_photo',
      );

      debugPrint('✅ Food identified: ${foodItem.name} (${foodItem.kcal} kcal)');
      return foodItem;
    } catch (e) {
      debugPrint('❌ Gemini analysis error: $e');
      return null;
    }
  }

  /// Parse JSON from potentially malformed response
  Map<String, dynamic>? _parseJsonResponse(String text) {
    try {
      // Try direct parsing first
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      // Try to extract JSON from markdown code blocks
      final jsonMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
      if (jsonMatch != null) {
        try {
          return jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
        } catch (_) {}
      }

      // Try to find JSON object in text
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (objectMatch != null) {
        try {
          return jsonDecode(objectMatch.group(0)!) as Map<String, dynamic>;
        } catch (_) {}
      }

      return null;
    }
  }

  /// Lookup nutrition from CalorieNinjas API (for text-based food queries)
  Future<FoodItem?> lookupNutrition(String foodName) async {
    final apiKey = dotenv.env['CALORIE_NINJAS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('⚠️ CALORIE_NINJAS_API_KEY not found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.calorieninjas.com/v1/nutrition?query=${Uri.encodeComponent(foodName)}'),
        headers: {'X-Api-Key': apiKey},
      );

      if (response.statusCode != 200) {
        debugPrint('❌ CalorieNinjas API error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      final items = data['items'] as List?;

      if (items == null || items.isEmpty) {
        debugPrint('⚠️ No nutrition data found for: $foodName');
        return null;
      }

      // Aggregate nutrition if multiple items returned
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalSodium = 0;
      double totalPotassium = 0;
      double totalWeight = 0;

      for (final item in items) {
        final servingSize = (item['serving_size_g'] as num?)?.toDouble() ?? 100.0;
        totalWeight += servingSize;
        totalCalories += (item['calories'] as num?)?.toDouble() ?? 0;
        totalProtein += (item['protein_g'] as num?)?.toDouble() ?? 0;
        totalCarbs += (item['carbohydrates_total_g'] as num?)?.toDouble() ?? 0;
        totalFat += (item['fat_total_g'] as num?)?.toDouble() ?? 0;
        totalSodium += (item['sodium_mg'] as num?)?.toDouble() ?? 0;
        totalPotassium += (item['potassium_mg'] as num?)?.toDouble() ?? 0;
      }

      return FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: foodName,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
        kcal: totalCalories,
        sodium: totalSodium,
        potassium: totalPotassium,
        amount: totalWeight,
        unit: 'g',
        estimated: false,
        source: 'calorie_ninjas',
      );
    } catch (e) {
      debugPrint('❌ CalorieNinjas lookup error: $e');
      return null;
    }
  }

  /// Fallback estimation when AI is not available
  FoodItem _fallbackEstimation() {
    return FoodItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Estimated Meal',
      protein: 25.0,
      carbs: 40.0,
      fat: 15.0,
      kcal: 400.0,
      sodium: 600.0,
      potassium: 400.0,
      amount: 250.0,
      unit: 'g',
      estimated: true,
      source: 'fallback',
    );
  }

  /// Check if the service is properly configured
  Future<bool> isConfigured() async {
    await _ensureInitialized();
    return _geminiModel != null;
  }
}
