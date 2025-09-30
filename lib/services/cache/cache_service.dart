import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../models/nutrition/nutrition_plan.dart' hide Meal, FoodItem;
import '../../models/nutrition/meal.dart';
import '../../models/nutrition/food_item.dart' as food;

/// Simple cache service stub (Hive not installed)
/// This is a minimal implementation using SharedPreferences
class CacheService {
  static final _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  bool _isInitialized = false;

  /// Initialize cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      debugPrint('✅ Cache service initialized (stub mode)');
    } catch (e) {
      debugPrint('❌ Failed to initialize cache service: $e');
    }
  }

  /// Check if cache is initialized
  bool get isInitialized => _isInitialized;

  /// Store value in memory cache
  void setMemory(String key, dynamic value) {
    _memoryCache[key] = value;
  }

  /// Get value from memory cache
  dynamic getMemory(String key) {
    return _memoryCache[key];
  }

  /// Store string in persistent cache
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  /// Get string from persistent cache
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Clear all caches
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _prefs?.clear();
  }

  /// Cache a nutrition plan
  Future<void> cacheNutritionPlan(NutritionPlan plan) async {
    setMemory('nutrition_plan_${plan.id}', plan);
  }

  /// Get cached nutrition plan
  NutritionPlan? getCachedNutritionPlan(String planId) {
    return getMemory('nutrition_plan_$planId') as NutritionPlan?;
  }

  /// Cache a meal
  Future<void> cacheMeal(Meal meal) async {
    setMemory('meal_${meal.id}', meal);
  }

  /// Get cached meal
  Meal? getCachedMeal(String mealId) {
    return getMemory('meal_$mealId') as Meal?;
  }

  /// Cache a food item
  Future<void> cacheFoodItem(food.FoodItem item) async {
    setMemory('food_${item.id}', item);
  }

  /// Get cached food item
  food.FoodItem? getCachedFoodItem(String foodId) {
    return getMemory('food_$foodId') as food.FoodItem?;
  }

  /// Remove item from cache
  void remove(String key) {
    _memoryCache.remove(key);
    _prefs?.remove(key);
  }

  /// Check if key exists in cache
  bool contains(String key) {
    return _memoryCache.containsKey(key) || (_prefs?.containsKey(key) ?? false);
  }

  /// Smart cache getter with TTL
  dynamic getSmartCache(String key) {
    return getMemory(key);
  }

  /// Smart cache setter with TTL
  Future<void> setSmartCache(String key, dynamic value, {Duration? ttl}) async {
    setMemory(key, value);
    // For persistent storage, serialize if needed
    if (value is String) {
      await setString(key, value);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryItems': _memoryCache.length,
      'persistentKeys': _prefs?.getKeys().length ?? 0,
    };
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
  }

  /// Get cached meals for a date
  List<Meal>? getCachedMeals(String date) {
    final cached = getMemory('meals_$date');
    return cached as List<Meal>?;
  }

  /// Cache meals for a date
  Future<void> cacheMeals(String date, List<Meal> meals) async {
    setMemory('meals_$date', meals);
  }
}