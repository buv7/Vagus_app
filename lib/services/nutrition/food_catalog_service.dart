import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'text_normalizer.dart';
import '../../models/nutrition/food_item.dart' as food;

class CatalogFoodItem {
  final String id;
  final String nameEn;
  final String? nameAr;
  final String? nameKu;
  final double portionGrams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int? sodiumMg;
  final int? potassiumMg;
  final List<String> tags;
  final String source; // 'database' or 'asset'

  CatalogFoodItem({
    required this.id,
    required this.nameEn,
    this.nameAr,
    this.nameKu,
    required this.portionGrams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.sodiumMg,
    this.potassiumMg,
    required this.tags,
    required this.source,
  });

  factory CatalogFoodItem.fromJson(Map<String, dynamic> json, {String source = 'asset'}) {
    return CatalogFoodItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'],
      nameKu: json['name_ku'],
      portionGrams: (json['portion_grams'] ?? 100.0).toDouble(),
      kcal: (json['kcal'] ?? 0.0).toDouble(),
      proteinG: (json['protein_g'] ?? 0.0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0.0).toDouble(),
      fatG: (json['fat_g'] ?? 0.0).toDouble(),
      sodiumMg: json['sodium_mg'],
      potassiumMg: json['potassium_mg'],
      tags: List<String>.from(json['tags'] ?? []),
      source: source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_ar': nameAr,
      'name_ku': nameKu,
      'portion_grams': portionGrams,
      'kcal': kcal,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'sodium_mg': sodiumMg,
      'potassium_mg': potassiumMg,
      'tags': tags,
    };
  }

  // Get name in specified language
  String getName(String lang) {
    switch (lang) {
      case 'ar':
        return nameAr ?? nameEn;
      case 'ku':
        return nameKu ?? nameEn;
      default:
        return nameEn;
    }
  }

  // Scale macros for different portion sizes
  CatalogFoodItem scaleToGrams(double grams) {
    final scale = grams / portionGrams;
    return CatalogFoodItem(
      id: id,
      nameEn: nameEn,
      nameAr: nameAr,
      nameKu: nameKu,
      portionGrams: grams,
      kcal: kcal * scale,
      proteinG: proteinG * scale,
      carbsG: carbsG * scale,
      fatG: fatG * scale,
      sodiumMg: sodiumMg != null ? (sodiumMg! * scale).round() : null,
      potassiumMg: potassiumMg != null ? (potassiumMg! * scale).round() : null,
      tags: tags,
      source: source,
    );
  }
}

class FoodCatalogService {
  static final FoodCatalogService _instance = FoodCatalogService._internal();
  factory FoodCatalogService() => _instance;
  FoodCatalogService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, List<CatalogFoodItem>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int _cacheSize = 100;
  static const Duration _cacheTTL = Duration(minutes: 10);
  
  // Seed management
  static const String _seedVersionKey = 'mena_seed_version';
  static const String _currentSeedVersion = '1.0.0';

  // Search food items with enhanced normalization and MENA seed support
  Future<List<CatalogFoodItem>> search(String query, {String lang = 'en', int limit = 20, List<String>? cuisinePrefs}) async {
    // Normalize query using text normalizer
    final normalizedQuery = TextNormalizer.normalizeQuery(query);
    final cacheKey = '${normalizedQuery}_$lang';
    
    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheTTL) {
        return _cache[cacheKey]!.take(limit).toList();
      }
    }

    final List<CatalogFoodItem> results = [];

    // Try database first
    try {
      final dbResults = await _searchDatabase(normalizedQuery, lang, limit);
      results.addAll(dbResults);
    } catch (e) {
      // Database failed, continue with asset fallback
    }

    // If database didn't return enough results, try asset fallback
    if (results.length < limit) {
      try {
        final assetResults = await _searchAsset(normalizedQuery, lang, limit - results.length);
        results.addAll(assetResults);
      } catch (e) {
        // Asset search failed, continue with what we have
      }
    }

    // Sort by relevance with cuisine preference boost
    results.sort((a, b) {
      final aName = TextNormalizer.normalizeForSearch(a.getName(lang));
      final bName = TextNormalizer.normalizeForSearch(b.getName(lang));
      
      // Exact match boost
      final aExact = aName == normalizedQuery;
      final bExact = bName == normalizedQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      // Starts with boost
      final aStartsWith = aName.startsWith(normalizedQuery);
      final bStartsWith = bName.startsWith(normalizedQuery);
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;
      
      // Cuisine preference boost
      if (cuisinePrefs != null && cuisinePrefs.isNotEmpty) {
        final aCuisineMatch = a.tags.any((tag) => cuisinePrefs.contains(tag));
        final bCuisineMatch = b.tags.any((tag) => cuisinePrefs.contains(tag));
        if (aCuisineMatch && !bCuisineMatch) return -1;
        if (!aCuisineMatch && bCuisineMatch) return 1;
      }
      
      // Language match boost
      final aLangMatch = a.getName(lang) != a.nameEn;
      final bLangMatch = b.getName(lang) != b.nameEn;
      if (aLangMatch && !bLangMatch) return -1;
      if (!aLangMatch && bLangMatch) return 1;
      
      return aName.compareTo(bName);
    });

    // Update cache
    _updateCache(cacheKey, results);
    
    return results.take(limit).toList();
  }

  Future<List<CatalogFoodItem>> _searchDatabase(String query, String lang, int limit) async {
    try {
      String nameColumn = 'name_en';
      switch (lang) {
        case 'ar':
          nameColumn = 'name_ar';
          break;
        case 'ku':
          nameColumn = 'name_ku';
          break;
      }

      final response = await _supabase
          .from('food_items')
          .select()
          .ilike(nameColumn, '%$query%')
          .limit(limit)
          .order(nameColumn);

      return response.map<CatalogFoodItem>((item) => CatalogFoodItem.fromJson(item, source: 'database')).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<CatalogFoodItem>> _searchAsset(String query, String lang, int limit) async {
    try {
      final jsonString = await rootBundle.loadString('assets/foods/arabic_kurdish_foods.json');
      final jsonData = json.decode(jsonString);
      final items = jsonData['items'] as List;

      final results = <CatalogFoodItem>[];
      
      for (final item in items) {
        final foodItem = CatalogFoodItem.fromJson(item, source: 'asset');
        final itemName = foodItem.getName(lang).toLowerCase();
        
        if (itemName.contains(query) || 
            foodItem.nameEn.toLowerCase().contains(query) ||
            (foodItem.nameAr?.toLowerCase().contains(query) ?? false) ||
            (foodItem.nameKu?.toLowerCase().contains(query) ?? false)) {
          results.add(foodItem);
          if (results.length >= limit) break;
        }
      }
      
      return results;
    } catch (e) {
      return [];
    }
  }

  void _updateCache(String key, List<CatalogFoodItem> items) {
    // Remove oldest entries if cache is full
    if (_cache.length >= _cacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _cache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }

    _cache[key] = items;
    _cacheTimestamps[key] = DateTime.now();
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // ========================================
  // MENA SEED MANAGEMENT
  // ========================================

  /// Append MENA seed data to the database if not already present
  Future<void> appendMenaSeedIfNeeded({bool force = false}) async {
    try {
      // Check if seed has already been applied
      if (!force) {
        final prefs = await SharedPreferences.getInstance();
        final appliedVersion = prefs.getString(_seedVersionKey);
        if (appliedVersion == _currentSeedVersion) {
          return; // Already applied
        }
      }

      // Load MENA seed data
      final seedData = await _loadMenaSeedData();
      if (seedData.isEmpty) return;

      // Insert seed items into database
      await _insertSeedItems(seedData);

      // Mark seed as applied
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seedVersionKey, _currentSeedVersion);

    } catch (e) {
      // Handle error silently - seed is optional
      debugPrint('Failed to append MENA seed: $e');
    }
  }

  /// Load MENA seed data from assets
  Future<List<Map<String, dynamic>>> _loadMenaSeedData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/nutrition/mena_seed.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Insert seed items into database (non-duplicates only)
  Future<void> _insertSeedItems(List<Map<String, dynamic>> seedData) async {
    for (final item in seedData) {
      try {
        // Check if item already exists by key
        final key = item['key'] as String;
        final existing = await _supabase
            .from('food_items')
            .select('id')
            .eq('key', key)
            .maybeSingle();

        if (existing != null) continue; // Skip if already exists

        // Prepare item for insertion
        final names = item['names'] as Map<String, dynamic>;
        final nutrition = item['per_100g'] ?? item['per_100ml'] ?? {};
        final tags = List<String>.from(item['tags'] ?? []);

        final insertData = {
          'key': key,
          'name_en': names['en'] ?? '',
          'name_ar': names['ar'],
          'name_ku': names['ku'],
          'unit': item['unit'] ?? 'g',
          'portion_grams': 100.0, // Standard 100g/100ml portion
          'kcal': (nutrition['kcal'] ?? 0.0).toDouble(),
          'protein_g': (nutrition['protein_g'] ?? 0.0).toDouble(),
          'carbs_g': (nutrition['carbs_g'] ?? 0.0).toDouble(),
          'fat_g': (nutrition['fat_g'] ?? 0.0).toDouble(),
          'sodium_mg': nutrition['sodium_mg'],
          'potassium_mg': nutrition['potassium_mg'],
          'fiber_g': nutrition['fiber_g'],
          'tags': tags,
          'source': 'mena_seed',
          'created_at': DateTime.now().toIso8601String(),
        };

        await _supabase
            .from('food_items')
            .insert(insertData);

      } catch (e) {
        // Continue with next item if one fails
        debugPrint('Failed to insert seed item ${item['key']}: $e');
      }
    }
  }




  /// Initialize MENA seed on first app launch
  Future<void> initializeMenaSeed() async {
    try {
      // Check if catalog is empty or feature flag is enabled
      final prefs = await SharedPreferences.getInstance();
      final featureEnabled = prefs.getBool('nutrition.regionalFoods') ?? true;
      
      if (featureEnabled) {
        await appendMenaSeedIfNeeded();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Seed MENA foods for diagnostics
  Future<void> seedMenaFoods() async {
    try {
      await appendMenaSeedIfNeeded();
    } catch (e) {
      debugPrint('Error seeding MENA foods: $e');
    }
  }

  /// Search foods with pagination support
  Future<List<CatalogFoodItem>> searchFoods(String query, {String lang = 'en', int limit = 20}) async {
    return search(query, lang: lang, limit: limit);
  }

  /// Get recently used foods for a user
  Future<List<CatalogFoodItem>> getRecentFoods({String lang = 'en', int limit = 10}) async {
    // TODO: Implement user-specific recent foods tracking
    // For now, return popular/common foods as a placeholder
    try {
      final commonFoods = ['chicken breast', 'rice', 'egg', 'potato', 'apple'];
      final results = <CatalogFoodItem>[];

      for (final food in commonFoods) {
        final searchResults = await search(food, lang: lang, limit: 1);
        if (searchResults.isNotEmpty) {
          results.add(searchResults.first);
        }
        if (results.length >= limit) break;
      }

      return results;
    } catch (e) {
      debugPrint('Error getting recent foods: $e');
      return [];
    }
  }

  /// Get user's custom foods
  static Future<List<dynamic>> getUserCustomFoods() async {
    try {
      // TODO: Query user_custom_foods table from Supabase
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      debugPrint('Error getting custom foods: $e');
      return [];
    }
  }

  /// Delete a custom food
  static Future<void> deleteCustomFood(String foodId) async {
    try {
      // TODO: Delete from user_custom_foods table
      final supabase = Supabase.instance.client;
      await supabase
          .from('user_custom_foods')
          .delete()
          .eq('id', foodId);
    } catch (e) {
      debugPrint('Error deleting custom food: $e');
      rethrow;
    }
  }

  /// Create a custom food
  static Future<dynamic> createCustomFood(dynamic food) async {
    try {
      // TODO: Insert into user_custom_foods table
      return food;
    } catch (e) {
      debugPrint('Error creating custom food: $e');
      rethrow;
    }
  }

  /// Update a custom food
  static Future<dynamic> updateCustomFood(dynamic food) async {
    try {
      // TODO: Update user_custom_foods table
      return food;
    } catch (e) {
      debugPrint('Error updating custom food: $e');
      rethrow;
    }
  }

  /// Get favorite foods
  static Future<List<food.FoodItem>> getFavoriteFoods() async {
    try {
      // TODO: Query user favorite foods from Supabase
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      debugPrint('Error getting favorite foods: $e');
      return [];
    }
  }

  /// Get suggested foods based on user preferences and meal context
  Future<List<CatalogFoodItem>> getSuggestedFoods({String lang = 'en', int limit = 10, String? mealType}) async {
    // TODO: Implement AI-powered food suggestions based on:
    // - User's dietary preferences
    // - Meal type (breakfast, lunch, dinner, snack)
    // - Nutritional goals
    // - Past food selections

    // For now, return category-appropriate foods as a placeholder
    try {
      List<String> suggestions;
      switch (mealType?.toLowerCase()) {
        case 'breakfast':
          suggestions = ['oatmeal', 'egg', 'banana', 'yogurt', 'toast'];
          break;
        case 'lunch':
          suggestions = ['chicken breast', 'rice', 'salad', 'fish', 'pasta'];
          break;
        case 'dinner':
          suggestions = ['salmon', 'broccoli', 'quinoa', 'beef', 'vegetables'];
          break;
        case 'snack':
          suggestions = ['apple', 'nuts', 'protein bar', 'cheese', 'hummus'];
          break;
        default:
          suggestions = ['chicken', 'rice', 'vegetables', 'fruit', 'fish'];
      }

      final results = <CatalogFoodItem>[];
      for (final food in suggestions) {
        final searchResults = await search(food, lang: lang, limit: 1);
        if (searchResults.isNotEmpty) {
          results.add(searchResults.first);
        }
        if (results.length >= limit) break;
      }

      return results;
    } catch (e) {
      debugPrint('Error getting suggested foods: $e');
      return [];
    }
  }
}
