import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/money.dart';
import '../../models/nutrition/recipe.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../models/nutrition/nutrition_plan_compat.dart';
import '../../models/nutrition/food_item.dart' as fi;
import '../../models/nutrition/grocery_list.dart';
import '../../models/nutrition/preferences.dart';
import 'preferences_service.dart';

extension _FoodItemCompat on fi.FoodItem {
  String get unitCompat {
    try { return (this as dynamic).unit ?? (this as dynamic).servingUnit ?? 'g'; }
    catch (_) { return 'g'; }
  }
}

/// Service for calculating nutrition costs across recipes, meals, days, and weeks
class CostingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PreferencesService _preferencesService = PreferencesService();
  
  // Cache for price lookups
  final Map<String, Money> _priceCache = {};
  static const Duration _cacheTTL = Duration(minutes: 10);
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Estimate cost for a recipe with given servings
  Future<Money> estimateRecipeCost(Recipe recipe, {double servings = 1.0}) async {
    if (recipe.ingredients.isEmpty) {
      return Money.zero(_getDefaultCurrency());
    }

    Money totalCost = Money.zero(_getDefaultCurrency());
    String? primaryCurrency;

    for (final ingredient in recipe.ingredients) {
      final ingredientCost = await _getIngredientCost(ingredient);
      if (ingredientCost != null) {
        // Scale by servings
        final scaledCost = ingredientCost * servings;
        
        if (primaryCurrency == null) {
          primaryCurrency = ingredientCost.currency;
          totalCost = scaledCost;
        } else if (ingredientCost.currency == primaryCurrency) {
          totalCost = totalCost + scaledCost;
        } else {
          // Different currency - convert or use primary
          // For now, just use the primary currency and log a warning
          print('Warning: Mixed currencies in recipe ${recipe.id}: $primaryCurrency and ${ingredientCost.currency}');
        }
      }
    }

    return totalCost;
  }

  /// Estimate cost for a meal
  Future<Money> estimateMealCost(Meal meal) async {
    if (meal.items.isEmpty) {
      return Money.zero(_getDefaultCurrency());
    }

    Money totalCost = Money.zero(_getDefaultCurrency());
    String? primaryCurrency;

    for (final item in meal.items) {
      final itemCost = await _getFoodItemCost(item);
      if (itemCost != null) {
        if (primaryCurrency == null) {
          primaryCurrency = itemCost.currency;
          totalCost = itemCost;
        } else if (itemCost.currency == primaryCurrency) {
          totalCost = totalCost + itemCost;
        } else {
          print('Warning: Mixed currencies in meal: $primaryCurrency and ${itemCost.currency}');
        }
      }
    }

    return totalCost;
  }

  /// Estimate cost for a specific day in a nutrition plan
  Future<Money> estimateDayCost(NutritionPlan plan, int dayIndex) async {
    if (dayIndex < 0 || dayIndex >= plan.days.length) {
      return Money.zero(_getDefaultCurrency());
    }

    final day = plan.days[dayIndex];
    Money totalCost = Money.zero(_getDefaultCurrency());
    String? primaryCurrency;

    for (final meal in day.meals) {
      final mealCost = await estimateMealCost(meal);
      if (mealCost.amount > 0) {
        if (primaryCurrency == null) {
          primaryCurrency = mealCost.currency;
          totalCost = mealCost;
        } else if (mealCost.currency == primaryCurrency) {
          totalCost = totalCost + mealCost;
        } else {
          print('Warning: Mixed currencies in day $dayIndex: $primaryCurrency and ${mealCost.currency}');
        }
      }
    }

    return totalCost;
  }

  /// Estimate cost for a specific week in a nutrition plan
  Future<Money> estimateWeekCost(NutritionPlan plan, int weekIndex) async {
    final startDay = weekIndex * 7;
    final endDay = (startDay + 7).clamp(0, plan.days.length);
    
    Money totalCost = Money.zero(_getDefaultCurrency());
    String? primaryCurrency;

    for (int dayIndex = startDay; dayIndex < endDay; dayIndex++) {
      final dayCost = await estimateDayCost(plan, dayIndex);
      if (dayCost.amount > 0) {
        if (primaryCurrency == null) {
          primaryCurrency = dayCost.currency;
          totalCost = dayCost;
        } else if (dayCost.currency == primaryCurrency) {
          totalCost = totalCost + dayCost;
        } else {
          print('Warning: Mixed currencies in week $weekIndex: $primaryCurrency and ${dayCost.currency}');
        }
      }
    }

    return totalCost;
  }

  /// Estimate cost for a grocery list
  Future<Money> estimateGroceryListCost(GroceryList list) async {
    try {
      // Get grocery items
      final response = await _supabase
          .from('nutrition_grocery_items')
          .select('*')
          .eq('list_id', list.id!);

      if (response.isEmpty) {
        return Money.zero(_getDefaultCurrency());
      }

      Money totalCost = Money.zero(_getDefaultCurrency());
      String? primaryCurrency;

      for (final item in response) {
        final amount = (item['amount'] ?? 0.0).toDouble();
        final unit = item['unit'] ?? 'g';
        final name = item['name'] ?? '';

        if (amount > 0) {
          // Try to get cost from nutrition_prices table
          final priceKey = _generatePriceKey(name, unit);
          final price = await _getPriceFromCache(priceKey);
          
          if (price != null) {
            final itemCost = price * amount;
            
            if (primaryCurrency == null) {
              primaryCurrency = price.currency;
              totalCost = itemCost;
            } else if (price.currency == primaryCurrency) {
              totalCost = totalCost + itemCost;
            } else {
              print('Warning: Mixed currencies in grocery list: $primaryCurrency and ${price.currency}');
            }
          }
        }
      }

      return totalCost;
    } catch (e) {
      print('Error estimating grocery list cost: $e');
      return Money.zero(_getDefaultCurrency());
    }
  }

  /// Get cost for a recipe ingredient
  Future<Money?> _getIngredientCost(RecipeIngredient ingredient) async {
    // First try to get cost from the ingredient itself
    if (ingredient.costPerUnit != null && ingredient.currency != null) {
      final cost = Money(ingredient.costPerUnit!, ingredient.currency!);
      return cost * ingredient.amount;
    }

    // Fallback to nutrition_prices table
    final priceKey = _generatePriceKey(ingredient.name, ingredient.unit);
    final price = await _getPriceFromCache(priceKey);
    
    if (price != null) {
      return price * ingredient.amount;
    }

    return null;
  }

  /// Get cost for a food item
  Future<Money?> _getFoodItemCost(FoodItem item) async {
    // First try to get cost from the item itself
    if (item.costPerUnit != null && item.currency != null) {
      final cost = Money(item.costPerUnit!, item.currency!);
      return cost * item.amount;
    }

    // Fallback to nutrition_prices table
    final priceKey = _generatePriceKey(item.name, (item as fi.FoodItem).unitCompat);
    final price = await _getPriceFromCache(priceKey);
    
    if (price != null) {
      return price * item.amount;
    }

    return null;
  }

  /// Get price from cache or database
  Future<Money?> _getPriceFromCache(String key) async {
    // Check cache first
    if (_priceCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheTTL) {
        return _priceCache[key];
      } else {
        _priceCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }

    try {
      // Fetch from database
      final response = await _supabase
          .from('nutrition_prices')
          .select('cost_per_unit, currency')
          .eq('key', key)
          .maybeSingle();

      if (response != null) {
        final cost = Money(
          (response['cost_per_unit'] ?? 0.0).toDouble(),
          response['currency'] ?? 'USD',
        );
        
        // Cache the result
        _priceCache[key] = cost;
        _cacheTimestamps[key] = DateTime.now();
        
        return cost;
      }
    } catch (e) {
      print('Error fetching price for key $key: $e');
    }

    return null;
  }

  /// Generate a price key for ingredient/food item
  String _generatePriceKey(String name, String unit) {
    return '${name.toLowerCase().trim()}_$unit'.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  }

  /// Get default currency (prefer user preferences, fallback to USD)
  String _getDefaultCurrency() {
    // TODO: Get from user preferences when available
    // For now, return USD as default
    return 'USD';
  }

  /// Get user's preferred currency
  Future<String> getUserCurrency(String userId) async {
    try {
      final preferences = await _preferencesService.getPrefs(userId);
      // TODO: Add currency field to Preferences model
      return preferences?.currency ?? 'USD';
    } catch (e) {
      return 'USD';
    }
  }

  /// Check if a recipe is budget-friendly based on user preferences
  Future<bool> isBudgetFriendly(Recipe recipe, String userId, {double servings = 1.0}) async {
    try {
      final preferences = await _preferencesService.getPrefs(userId);
      if (preferences?.costTier == null) {
        return true; // No budget restriction
      }

      final recipeCost = await estimateRecipeCost(recipe, servings: servings);
      final costPerServing = recipeCost / servings;
      
      // Define budget thresholds (these could be configurable)
      final thresholds = _getBudgetThresholds(preferences!.costTier!);
      
      return costPerServing.amount <= thresholds;
    } catch (e) {
      print('Error checking budget friendliness: $e');
      return true; // Default to friendly if error
    }
  }

  /// Get budget thresholds based on cost tier
  double _getBudgetThresholds(String costTier) {
    switch (costTier.toLowerCase()) {
      case 'low':
        return 2.0; // $2.00 per serving
      case 'medium':
        return 5.0; // $5.00 per serving
      case 'high':
        return 10.0; // $10.00 per serving
      default:
        return 5.0; // Default to medium
    }
  }

  /// Clear price cache
  void clearCache() {
    _priceCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _priceCache.length,
      'cachedPrices': _priceCache.keys.length,
    };
  }

  /// Get debug statistics for diagnostics
  Map<String, dynamic> debugStats() {
    final stats = getCacheStats();
    final now = DateTime.now();
    int validEntries = 0;
    
    for (final timestamp in _cacheTimestamps.values) {
      if (now.difference(timestamp) < _cacheTTL) {
        validEntries++;
      }
    }
    
    final hitRate = _priceCache.length > 0 ? validEntries / _priceCache.length : 0.0;
    
    return {
      'cacheSize': stats['cacheSize'],
      'hitRate': hitRate,
    };
  }

  /// Add or update a price in the nutrition_prices table
  Future<void> setPrice(String key, Money price) async {
    try {
      await _supabase.from('nutrition_prices').upsert({
        'key': key,
        'cost_per_unit': price.amount,
        'currency': price.currency,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update cache
      _priceCache[key] = price;
      _cacheTimestamps[key] = DateTime.now();
    } catch (e) {
      print('Error setting price for key $key: $e');
      rethrow;
    }
  }

  /// Get all prices (for admin/coach use)
  Future<Map<String, Money>> getAllPrices() async {
    try {
      final response = await _supabase
          .from('nutrition_prices')
          .select('key, cost_per_unit, currency');

      final prices = <String, Money>{};
      for (final row in response) {
        final key = row['key'] as String;
        final cost = Money(
          (row['cost_per_unit'] ?? 0.0).toDouble(),
          row['currency'] ?? 'USD',
        );
        prices[key] = cost;
      }

      return prices;
    } catch (e) {
      print('Error fetching all prices: $e');
      return {};
    }
  }
}
