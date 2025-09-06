import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/pantry_item.dart';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/food_item.dart' as fi;
import '../nutrition/text_normalizer.dart';

/// Service for managing pantry items and recipe matching
class PantryService {
  static final PantryService _instance = PantryService._internal();
  factory PantryService() => _instance;
  PantryService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // In-memory cache with TTL
  final Map<String, _CachedPantryData> _cache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Get all pantry items for a user
  Future<List<PantryItem>> list(String userId, {bool refresh = false}) async {
    try {
      // Check cache first
      if (!refresh && _cache.containsKey(userId)) {
        final cached = _cache[userId]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
          return cached.items;
        } else {
          _cache.remove(userId);
        }
      }

      // Fetch from database
      final response = await _supabase
          .from('nutrition_pantry_items')
          .select()
          .eq('user_id', userId)
          .order('name');

      final items = response.map<PantryItem>((item) => PantryItem.fromMap(item)).toList();
      
      // Update cache
      _cache[userId] = _CachedPantryData(
        items: items,
        timestamp: DateTime.now(),
      );
      
      return items;
    } catch (e) {
      print('Failed to fetch pantry items: $e');
      return [];
    }
  }

  /// Upsert a pantry item (insert or update by user_id + key)
  Future<void> upsert(PantryItem item) async {
    try {
      await _supabase
          .from('nutrition_pantry_items')
          .upsert(item.toMap(), onConflict: 'user_id,key');

      // Invalidate cache
      _cache.remove(item.userId);
    } catch (e) {
      print('Failed to upsert pantry item: $e');
      rethrow;
    }
  }

  /// Delete a pantry item
  Future<void> delete({required String userId, required String key}) async {
    try {
      await _supabase
          .from('nutrition_pantry_items')
          .delete()
          .eq('user_id', userId)
          .eq('key', key);

      // Invalidate cache
      _cache.remove(userId);
    } catch (e) {
      print('Failed to delete pantry item: $e');
      rethrow;
    }
  }

  /// Calculate how much of a recipe can be covered by pantry items (0.0 to 1.0)
  Future<double> matchRecipe({
    required Recipe recipe,
    required String userId,
    double servings = 1.0,
  }) async {
    try {
      final coverage = await computeCoverage(
        recipe: recipe,
        userId: userId,
        servings: servings,
      );
      return coverage.ratio;
    } catch (e) {
      print('Failed to match recipe: $e');
      return 0.0;
    }
  }

  /// Compute detailed coverage for a recipe
  Future<PantryCoverage> computeCoverage({
    required Recipe recipe,
    required String userId,
    double servings = 1.0,
  }) async {
    try {
      final pantryItems = await list(userId);
      final coverageRows = <CoverageRow>[];
      double totalNeed = 0.0;
      double totalAvailable = 0.0;

      for (final ingredient in recipe.ingredients) {
        final ingredientName = ingredient.name;
        final requiredQty = (ingredient.amount as num).toDouble() * servings;
        final requiredUnit = ingredient.unit;

        // Find matching pantry items
        final matchingItems = _findMatchingPantryItems(
          pantryItems,
          ingredientName,
          requiredQty,
          requiredUnit,
        );

        // Calculate available quantity
        double available = 0.0;
        for (final pantryItem in matchingItems) {
          available += pantryItem.convertToUnit(requiredUnit).amount;
        }

        final used = available >= requiredQty ? requiredQty : available;
        
        coverageRows.add(CoverageRow(
          ingredientName: ingredientName,
          need: requiredQty,
          available: available,
          used: used,
          unit: requiredUnit,
        ));

        totalNeed += requiredQty;
        totalAvailable += used;
      }

      final ratio = totalNeed > 0 ? totalAvailable / totalNeed : 0.0;
      return PantryCoverage(ratio, coverageRows);
    } catch (e) {
      print('Failed to compute coverage: $e');
      return PantryCoverage(0.0, []);
    }
  }

  /// Plan consumption for a recipe (returns pantry diffs, no DB writes)
  Future<List<PantryItem>> planConsumption({
    required Recipe recipe,
    required String userId,
    double servings = 1.0,
  }) async {
    try {
      final pantryItems = await list(userId);
      final deltas = <PantryItem>[];

      for (final ingredient in recipe.ingredients) {
        final ingredientName = ingredient.name;
        final requiredQty = (ingredient.amount as num).toDouble() * servings;
        final requiredUnit = ingredient.unit;

        // Find matching pantry items
        final matchingItems = _findMatchingPantryItems(
          pantryItems,
          ingredientName,
          requiredQty,
          requiredUnit,
        );

        double remainingNeed = requiredQty;
        
        for (final pantryItem in matchingItems) {
          if (remainingNeed <= 0) break;
          
          final availableInRequiredUnit = pantryItem.convertToUnit(requiredUnit).amount;
          final toConsume = remainingNeed > availableInRequiredUnit 
              ? availableInRequiredUnit 
              : remainingNeed;
          
          // Convert back to pantry item's unit
          final toConsumeInPantryUnit = _convertQuantity(
            toConsume,
            requiredUnit,
            pantryItem.unit,
          );
          
          // Create delta (negative quantity for consumption)
          final delta = pantryItem.copyWith(
            amount: -toConsumeInPantryUnit,
            updatedAt: DateTime.now(),
          );
          
          deltas.add(delta);
          remainingNeed -= toConsume;
        }
      }

      return deltas;
    } catch (e) {
      print('Failed to plan consumption: $e');
      return [];
    }
  }

  /// Apply consumption deltas to pantry (DB writes)
  Future<void> applyConsumption({
    required String userId,
    required List<PantryItem> deltas,
  }) async {
    try {
      // Start transaction
      await _supabase.rpc('begin_transaction');

      try {
        for (final delta in deltas) {
          final key = delta.key;
          
          // Get current pantry item
          final response = await _supabase
              .from('nutrition_pantry_items')
              .select()
              .eq('user_id', userId)
              .eq('key', key)
              .maybeSingle();

          if (response != null) {
            final currentItem = PantryItem.fromMap(response);
            final newQty = currentItem.qty + delta.qty; // delta.qty is negative
            
            if (newQty <= 0) {
              // Delete item if quantity becomes zero or negative
              await _supabase
                  .from('nutrition_pantry_items')
                  .delete()
                  .eq('user_id', userId)
                  .eq('key', key);
            } else {
              // Update quantity
              await _supabase
                  .from('nutrition_pantry_items')
                  .update({'qty': newQty, 'updated_at': DateTime.now().toIso8601String()})
                  .eq('user_id', userId)
                  .eq('key', key);
            }
          }
        }

        // Commit transaction
        await _supabase.rpc('commit_transaction');
        
        // Invalidate cache
        _cache.remove(userId);
      } catch (e) {
        // Rollback on error
        await _supabase.rpc('rollback_transaction');
        rethrow;
      }
    } catch (e) {
      print('Failed to apply consumption: $e');
      rethrow;
    }
  }

  /// Find pantry items that can be used for an ingredient
  List<PantryItem> _findMatchingPantryItems(
    List<PantryItem> pantryItems,
    String ingredientName,
    double requiredQty,
    String requiredUnit,
  ) {
    final normalizedIngredient = TextNormalizer.normalizeForSearch(ingredientName);
    final matchingItems = <PantryItem>[];

    for (final pantryItem in pantryItems) {
      final normalizedPantryName = TextNormalizer.normalizeForSearch(pantryItem.name);
      
      // Check if names match (simple contains check, could be enhanced with fuzzy matching)
      if (normalizedPantryName.contains(normalizedIngredient) ||
          normalizedIngredient.contains(normalizedPantryName)) {
        
        // Check if we have enough quantity
        final availableQty = pantryItem.convertToUnit(requiredUnit).amount;
        if (availableQty > 0) {
          matchingItems.add(pantryItem);
        }
      }
    }

    // Sort by quantity (descending) to use items with more quantity first
    matchingItems.sort((a, b) {
      final aQty = a.convertToUnit(requiredUnit).amount;
      final bQty = b.convertToUnit(requiredUnit).amount;
      return bQty.compareTo(aQty);
    });

    return matchingItems;
  }

  /// Convert quantity between units
  double _convertQuantity(double qty, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return qty;
    
    // Convert to base unit first
    double baseQty = qty;
    switch (fromUnit) {
      case 'kg':
        baseQty = qty * 1000; // kg to g
        break;
      case 'l':
        baseQty = qty * 1000; // l to ml
        break;
      case 'pcs':
        return qty; // pieces don't convert
    }
    
    // Convert from base unit to target
    switch (toUnit) {
      case 'g':
        return baseQty;
      case 'kg':
        return baseQty / 1000;
      case 'ml':
        return baseQty;
      case 'l':
        return baseQty / 1000;
      case 'pcs':
        return qty; // pieces don't convert
      default:
        return qty;
    }
  }

  /// Clear cache for a user
  void clearCache(String userId) {
    _cache.remove(userId);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'cachedUsers': _cache.keys.toList(),
    };
  }

  /// Get debug statistics for diagnostics
  Map<String, dynamic> debugStats() {
    final stats = getCacheStats();
    final now = DateTime.now();
    int validEntries = 0;
    
    for (final entry in _cache.values) {
      if (now.difference(entry.timestamp) < _cacheTTL) {
        validEntries++;
      }
    }
    
    final hitRate = _cache.length > 0 ? validEntries / _cache.length : 0.0;
    
    return {
      'cacheSize': stats['cacheSize'],
      'hitRate': hitRate,
    };
  }

  /// Save a meal item as a pantry leftover
  Future<void> saveLeftoverFromFoodItem(fi.FoodItem item, {required String userId}) async {
    final key = TextNormalizer.canonicalKey(item.name);
    final qtyBase = (item.amount ?? 0).toDouble();
    final unit = (item.unit ?? 'g');
    final normalized = _normalizeToBase(qtyBase, unit);
    
    final now = DateTime.now();
    final pantryItem = PantryItem(
      id: key,
      userId: userId,
      name: item.name,
      amount: normalized['qty'] as double,
      unit: normalized['unit'] as String, // 'g' | 'ml' | 'pcs'
      expiresAt: now.add(const Duration(days: 3)), // sensible default
      notes: 'Leftover from meal',
      createdAt: now,
      updatedAt: now,
    );
    
    await upsert(pantryItem);
  }

  /// Normalize quantity to base unit
  Map<String, dynamic> _normalizeToBase(double qty, String unit) {
    // Simple normalization - in a real app, you'd have proper conversion factors
    switch (unit.toLowerCase()) {
      case 'kg':
        return {'qty': qty * 1000, 'unit': 'g'};
      case 'l':
        return {'qty': qty * 1000, 'unit': 'ml'};
      case 'lb':
        return {'qty': qty * 453.592, 'unit': 'g'};
      case 'oz':
        return {'qty': qty * 28.3495, 'unit': 'g'};
      case 'cup':
        return {'qty': qty * 240, 'unit': 'ml'};
      case 'tbsp':
        return {'qty': qty * 15, 'unit': 'ml'};
      case 'tsp':
        return {'qty': qty * 5, 'unit': 'ml'};
      default:
        return {'qty': qty, 'unit': unit};
    }
  }
}

/// Cached pantry data
class _CachedPantryData {
  final List<PantryItem> items;
  final DateTime timestamp;
  
  _CachedPantryData({
    required this.items,
    required this.timestamp,
  });
}

/// Coverage information for a recipe
class PantryCoverage {
  final double ratio; // 0.0 to 1.0
  final List<CoverageRow> rows;
  
  const PantryCoverage(this.ratio, this.rows);
  
  /// Get coverage percentage (0-100)
  int get percentage => (ratio * 100).round();
  
  /// Check if fully covered
  bool get isFullyCovered => ratio >= 1.0;
  
  /// Check if partially covered
  bool get isPartiallyCovered => ratio > 0.0 && ratio < 1.0;
}

/// Coverage details for a single ingredient
class CoverageRow {
  final String ingredientName;
  final double need;
  final double available;
  final double used;
  final String unit;
  
  const CoverageRow({
    required this.ingredientName,
    required this.need,
    required this.available,
    required this.used,
    required this.unit,
  });
  
  /// Check if this ingredient is fully covered
  bool get isFullyCovered => used >= need;
  
  /// Check if this ingredient is partially covered
  bool get isPartiallyCovered => used > 0 && used < need;
  
  /// Get coverage percentage for this ingredient
  double get coverageRatio => need > 0 ? used / need : 0.0;
}

/// Summary of pantry usage in grocery generation
class PantrySummary {
  final double coveragePercent;
  final int itemsCovered;
  final List<String> coveredIngredients;
  
  const PantrySummary({
    required this.coveragePercent,
    required this.itemsCovered,
    required this.coveredIngredients,
  });
}
