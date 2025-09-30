import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../cache/cache_service.dart';
import '../../models/nutrition/meal.dart';
import '../../models/nutrition/food_item.dart';

/// Performance optimization service with intelligent caching and lazy loading
/// Features: Macro calculation caching, pagination, debouncing, memory management
class PerformanceService {
  static final _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final CacheService _cache = CacheService();

  // Cache for expensive calculations
  final Map<String, MacroSummary> _macroCache = {};
  final Map<String, DateTime> _macroCacheTimestamps = {};
  final Map<String, Timer> _debouncers = {};

  // Performance monitoring
  final Map<String, List<Duration>> _operationTimes = {};

  static const Duration _macroCacheTimeout = Duration(minutes: 10);
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  /// Calculate macros with intelligent caching
  MacroSummary getMacros(Meal meal, {bool useCache = true}) {
    final cacheKey = _generateMacroCacheKey(meal);

    if (useCache) {
      final cached = _getCachedMacros(cacheKey);
      if (cached != null) return cached;
    }

    final stopwatch = Stopwatch()..start();
    final macros = _calculateMacros(meal);
    stopwatch.stop();

    _recordOperationTime('macro_calculation', stopwatch.elapsed);
    _setCachedMacros(cacheKey, macros);

    return macros;
  }

  /// Batch calculate macros for multiple meals
  List<MacroSummary> getBatchMacros(List<Meal> meals) {
    final stopwatch = Stopwatch()..start();

    final results = meals.map((meal) {
      final cacheKey = _generateMacroCacheKey(meal);
      final cached = _getCachedMacros(cacheKey);

      if (cached != null) return cached;

      final macros = _calculateMacros(meal);
      _setCachedMacros(cacheKey, macros);
      return macros;
    }).toList();

    stopwatch.stop();
    _recordOperationTime('batch_macro_calculation', stopwatch.elapsed);

    return results;
  }

  /// Debounced macro calculation for real-time updates
  void debouncedMacroCalculation(
    String key,
    Meal meal,
    Function(MacroSummary) callback,
  ) {
    _debouncers[key]?.cancel();

    _debouncers[key] = Timer(_debounceDelay, () {
      final macros = getMacros(meal);
      callback(macros);
      _debouncers.remove(key);
    });
  }

  /// Paginated food item loading
  Future<PaginatedFoodResult> loadFoodItems({
    String? query,
    List<String>? filters,
    int page = 0,
    int pageSize = 20,
    String? cacheKey,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Check cache first
    if (cacheKey != null) {
      final cached = await _cache.getSmartCache('${cacheKey}_page_$page') as Map<String, dynamic>?;

      if (cached != null) {
        stopwatch.stop();
        _recordOperationTime('food_load_cached', stopwatch.elapsed);

        return PaginatedFoodResult.fromJson(cached);
      }
    }

    // Simulate API call with pagination
    await Future.delayed(const Duration(milliseconds: 200));

    final allItems = _generateMockFoodItems(query, filters);
    final startIndex = page * pageSize;
    final endIndex = math.min(startIndex + pageSize, allItems.length);

    final pageItems = allItems.sublist(
      startIndex.clamp(0, allItems.length),
      endIndex.clamp(0, allItems.length),
    );

    final result = PaginatedFoodResult(
      items: pageItems,
      page: page,
      pageSize: pageSize,
      totalItems: allItems.length,
      hasMore: endIndex < allItems.length,
    );

    // Cache the result
    if (cacheKey != null) {
      await _cache.setSmartCache(
        '${cacheKey}_page_$page',
        result.toJson(),
        ttl: const Duration(minutes: 30),
      );
    }

    stopwatch.stop();
    _recordOperationTime('food_load_network', stopwatch.elapsed);

    return result;
  }

  /// Intelligent image preloading
  Future<void> preloadImages(List<String> imageUrls, {int maxConcurrent = 3}) async {
    final stopwatch = Stopwatch()..start();

    // Process images in batches to avoid memory issues
    for (int i = 0; i < imageUrls.length; i += maxConcurrent) {
      final batch = imageUrls.skip(i).take(maxConcurrent);

      await Future.wait(
        batch.map((url) => _preloadSingleImage(url)),
        eagerError: false, // Continue even if some images fail
      );

      // Small delay between batches to prevent overwhelming the system
      if (i + maxConcurrent < imageUrls.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    stopwatch.stop();
    _recordOperationTime('image_preload', stopwatch.elapsed);
  }

  /// Memory-efficient image processing
  Future<void> _preloadSingleImage(String url) async {
    try {
      // TODO: Implement actual image preloading
      // For now, just simulate the process
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      debugPrint('Failed to preload image: $url');
    }
  }

  /// Optimized search with caching and debouncing
  Stream<List<FoodItem>> searchFoodsOptimized(String query) async* {
    if (query.isEmpty) {
      yield [];
      return;
    }

    // First, yield cached results if available
    final cacheKey = 'search_${_hashString(query)}';
    final cached = await _cache.getSmartCache(cacheKey) as List<dynamic>?;

    if (cached != null) {
      yield cached.map((item) => FoodItem.fromJson(item)).toList();
    }

    // Then perform actual search
    await Future.delayed(const Duration(milliseconds: 300)); // Debounce

    final results = _performSearch(query);

    // Cache the results
    await _cache.setSmartCache(
      cacheKey,
      results.map((item) => item.toJson()).toList(),
      ttl: const Duration(minutes: 15),
    );

    yield results;
  }

  /// Background computation for expensive operations
  Future<T> computeInBackground<T>(T Function() computation) async {
    if (kIsWeb) {
      // On web, just run synchronously
      return computation();
    } else {
      // On mobile, use compute isolate
      return await compute((_) => computation(), null);
    }
  }

  /// Batch operations for efficiency
  Future<List<T>> batchProcess<T, R>(
    List<T> items,
    Future<R> Function(T) processor, {
    int batchSize = 10,
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    final results = <T>[];

    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize);

      final batchResults = await Future.wait(
        batch.map(processor),
        eagerError: false,
      );

      // Process batch results
      for (int j = 0; j < batchResults.length; j++) {
        if (batchResults[j] != null) {
          results.add(batch.elementAt(j));
        }
      }

      // Delay between batches to prevent blocking
      if (i + batchSize < items.length) {
        await Future.delayed(delay);
      }
    }

    return results;
  }

  /// Performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{};

    for (final entry in _operationTimes.entries) {
      final times = entry.value;
      if (times.isNotEmpty) {
        final totalMs = times.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
        metrics[entry.key] = {
          'count': times.length,
          'total_ms': totalMs,
          'average_ms': totalMs / times.length,
          'min_ms': times.map((d) => d.inMilliseconds).reduce(math.min),
          'max_ms': times.map((d) => d.inMilliseconds).reduce(math.max),
        };
      }
    }

    metrics['cache_stats'] = _cache.getCacheStats();
    metrics['active_debouncers'] = _debouncers.length;
    metrics['cached_macros'] = _macroCache.length;

    return metrics;
  }

  /// Clear performance data
  void clearMetrics() {
    _operationTimes.clear();
    _clearExpiredMacroCache();
  }

  /// Optimize memory usage
  void optimizeMemory() {
    _clearExpiredMacroCache();
    _cache.clearMemoryCache();

    // Cancel unused debouncers
    final now = DateTime.now();
    _debouncers.removeWhere((key, timer) {
      if (!timer.isActive) {
        timer.cancel();
        return true;
      }
      return false;
    });

    // Limit operation time history
    _operationTimes.forEach((key, times) {
      if (times.length > 100) {
        _operationTimes[key] = times.sublist(times.length - 50);
      }
    });

    // Force garbage collection hint
    SystemChannels.platform.invokeMethod('System.requestGC');
  }

  // Private methods
  MacroSummary _calculateMacros(Meal meal) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSodium = 0;
    double totalPotassium = 0;

    for (final item in meal.items) {
      final food = item.foodItem;
      final quantity = item.quantity;

      totalCalories += food.kcal * quantity;
      totalProtein += food.protein * quantity;
      totalCarbs += food.carbs * quantity;
      totalFat += food.fat * quantity;
      totalFiber += 0.0; // fiber not available in FoodItem
      totalSodium += food.sodium * quantity;
      totalPotassium += food.potassium * quantity;
    }

    return MacroSummary(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sodium: totalSodium,
      potassium: totalPotassium,
    );
  }

  String _generateMacroCacheKey(Meal meal) {
    final itemsHash = meal.items
        .map((item) => '${item.foodItem.id}_${item.quantity}')
        .join('|');
    return '${meal.id}_${meal.updatedAt?.millisecondsSinceEpoch}_${_hashString(itemsHash)}';
  }

  MacroSummary? _getCachedMacros(String key) {
    final timestamp = _macroCacheTimestamps[key];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _macroCacheTimeout) {
      _macroCache.remove(key);
      _macroCacheTimestamps.remove(key);
      return null;
    }

    return _macroCache[key];
  }

  void _setCachedMacros(String key, MacroSummary macros) {
    _macroCache[key] = macros;
    _macroCacheTimestamps[key] = DateTime.now();
  }

  void _clearExpiredMacroCache() {
    final now = DateTime.now();
    final expiredKeys = _macroCacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > _macroCacheTimeout)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _macroCache.remove(key);
      _macroCacheTimestamps.remove(key);
    }
  }

  void _recordOperationTime(String operation, Duration time) {
    _operationTimes.putIfAbsent(operation, () => []).add(time);

    // Keep only recent measurements
    final times = _operationTimes[operation]!;
    if (times.length > 50) {
      _operationTimes[operation] = times.sublist(times.length - 25);
    }
  }

  List<FoodItem> _generateMockFoodItems(String? query, List<String>? filters) {
    // Mock data generation for demonstration
    final items = <FoodItem>[];

    for (int i = 0; i < 100; i++) {
      items.add(FoodItem(
        id: 'food_$i',
        name: 'Food Item $i',
        kcal: (100 + (i * 10) % 300).toDouble(),
        protein: (5 + (i * 2) % 25).toDouble(),
        carbs: (10 + (i * 3) % 40).toDouble(),
        fat: (2 + (i) % 15).toDouble(),
        sodium: 0.0,
        potassium: 0.0,
        amount: 100.0,
      ));
    }

    if (query != null && query.isNotEmpty) {
      return items.where((item) =>
        item.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    return items;
  }

  List<FoodItem> _performSearch(String query) {
    // Mock search implementation
    return _generateMockFoodItems(query, null);
  }

  String _hashString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xffffffff;
    }
    return hash.toString();
  }

  void dispose() {
    for (final timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();
    _macroCache.clear();
    _macroCacheTimestamps.clear();
    _operationTimes.clear();
  }
}

/// Macro summary data class
class MacroSummary {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final double potassium;

  const MacroSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sodium = 0,
    this.potassium = 0,
  });

  MacroSummary operator +(MacroSummary other) {
    return MacroSummary(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      sodium: sodium + other.sodium,
      potassium: potassium + other.potassium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
      'potassium': potassium,
    };
  }

  factory MacroSummary.fromJson(Map<String, dynamic> json) {
    return MacroSummary(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      potassium: (json['potassium'] ?? 0).toDouble(),
    );
  }
}

/// Paginated food result
class PaginatedFoodResult {
  final List<FoodItem> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final bool hasMore;

  const PaginatedFoodResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.hasMore,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'page': page,
      'pageSize': pageSize,
      'totalItems': totalItems,
      'hasMore': hasMore,
    };
  }

  factory PaginatedFoodResult.fromJson(Map<String, dynamic> json) {
    return PaginatedFoodResult(
      items: (json['items'] as List<dynamic>)
          .map((item) => FoodItem.fromJson(item))
          .toList(),
      page: json['page'],
      pageSize: json['pageSize'],
      totalItems: json['totalItems'],
      hasMore: json['hasMore'],
    );
  }
}