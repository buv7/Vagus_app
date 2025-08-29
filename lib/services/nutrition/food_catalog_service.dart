import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'locale_helper.dart';

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

  // Search food items with dual-source approach
  Future<List<CatalogFoodItem>> search(String query, {String lang = 'en', int limit = 20}) async {
    final normalizedQuery = LocaleHelper.normalizeNumber(query.toLowerCase().trim());
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

    // Sort by relevance (exact matches first, then partial)
    results.sort((a, b) {
      final aName = a.getName(lang).toLowerCase();
      final bName = b.getName(lang).toLowerCase();
      
      final aExact = aName == normalizedQuery;
      final bExact = bName == normalizedQuery;
      
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      final aStartsWith = aName.startsWith(normalizedQuery);
      final bStartsWith = bName.startsWith(normalizedQuery);
      
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;
      
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
}
