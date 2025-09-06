import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/preferences.dart';
import '../../models/nutrition/recipe.dart';

class PreferencesService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // In-memory cache for preferences to avoid chatty reads
  final Map<String, _CachedPreferences> _preferencesCache = {};
  final Duration _defaultCacheTtl = const Duration(minutes: 10);

  // ========================================
  // PREFERENCES MANAGEMENT
  // ========================================

  /// Get preferences for a user with optional caching
  Future<Preferences?> getPrefs(String userId, {Duration? cacheTtl}) async {
    try {
      final ttl = cacheTtl ?? _defaultCacheTtl;
      final now = DateTime.now();
      
      // Check cache first
      final cached = _preferencesCache[userId];
      if (cached != null && now.difference(cached.timestamp) < ttl) {
        return cached.preferences;
      }

      // Fetch from database
      final response = await _supabase
          .from('nutrition_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      Preferences? preferences;
      if (response != null) {
        preferences = Preferences.fromMap(response);
      }

      // Update cache
      _preferencesCache[userId] = _CachedPreferences(
        preferences: preferences,
        timestamp: now,
      );

      return preferences;
    } catch (e) {
      throw Exception('Failed to fetch preferences: $e');
    }
  }

  /// Upsert preferences for a user
  Future<void> upsertPrefs(Preferences prefs) async {
    try {
      await _supabase.rpc('upsert_nutrition_preferences', params: {
        'user_uuid': prefs.userId,
        'calorie_target_val': prefs.calorieTarget,
        'protein_g_val': prefs.proteinG,
        'carbs_g_val': prefs.carbsG,
        'fat_g_val': prefs.fatG,
        'sodium_max_mg_val': prefs.sodiumMaxMg,
        'potassium_min_mg_val': prefs.potassiumMinMg,
        'diet_tags_val': prefs.dietTags.isNotEmpty ? prefs.dietTags : null,
        'cuisine_prefs_val': prefs.cuisinePrefs.isNotEmpty ? prefs.cuisinePrefs : null,
        'cost_tier_val': prefs.costTier,
        'halal_val': prefs.halal,
        'fasting_window_val': prefs.fastingWindow,
      });

      // Invalidate cache
      _preferencesCache.remove(prefs.userId);
    } catch (e) {
      throw Exception('Failed to upsert preferences: $e');
    }
  }

  // ========================================
  // ALLERGIES MANAGEMENT
  // ========================================

  /// Get allergies for a user
  Future<List<String>> getAllergies(String userId) async {
    try {
      final response = await _supabase
          .from('nutrition_allergies')
          .select('allergen')
          .eq('user_id', userId);

      return (response as List<dynamic>)
          .map((item) => item['allergen'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch allergies: $e');
    }
  }

  /// Set allergies for a user (replaces all existing)
  Future<void> setAllergies(String userId, List<String> allergens) async {
    try {
      await _supabase.rpc('set_nutrition_allergies', params: {
        'user_uuid': userId,
        'allergens_list': allergens,
      });
    } catch (e) {
      throw Exception('Failed to set allergies: $e');
    }
  }

  // ========================================
  // GUARDRAILS & VALIDATION
  // ========================================

  /// Validate a recipe against user preferences and allergies
  PreferencesWarnings validateRecipeAgainstPrefs(
    Recipe recipe,
    Preferences prefs,
    List<String> allergens,
  ) {
    final warnings = <String>[];
    bool sodiumExceeded = false;
    bool notHalal = false;

    // Check halal requirement
    if (prefs.halal == true && !_isRecipeHalal(recipe)) {
      notHalal = true;
    }

    // Check allergens
    final matchedAllergens = _findMatchingAllergens(recipe, allergens);
    warnings.addAll(matchedAllergens);

    // Check sodium (per serving)
    if (prefs.sodiumMaxMg != null) {
      final sodiumPerServing = recipe.sodium * 1000; // Convert to mg
      if (sodiumPerServing > prefs.sodiumMaxMg!) {
        sodiumExceeded = true;
      }
    }

    return PreferencesWarnings(
      sodiumExceeded: sodiumExceeded,
      notHalal: notHalal,
      allergens: matchedAllergens,
    );
  }

  /// Filter recipes by preferences and allergies
  List<Recipe> filterRecipesByPrefs(
    List<Recipe> recipes,
    Preferences prefs,
    List<String> allergens,
  ) {
    return recipes.where((recipe) {
      final warnings = validateRecipeAgainstPrefs(recipe, prefs, allergens);
      return !warnings.hasWarnings;
    }).toList();
  }

  /// Check if daily sodium is exceeded
  bool isDailySodiumExceeded({
    required int dailySodiumMg,
    required Preferences prefs,
  }) {
    if (prefs.sodiumMaxMg == null) return false;
    return dailySodiumMg > prefs.sodiumMaxMg!;
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Check if a recipe is halal
  bool _isRecipeHalal(Recipe recipe) {
    // Simple heuristic: check for common non-halal ingredients
    final nonHalalKeywords = [
      'pork', 'bacon', 'ham', 'sausage', 'lard',
      'alcohol', 'wine', 'beer', 'liquor',
      'gelatin', 'rennet', 'whey'
    ];

    final recipeText = '${recipe.title} ${recipe.summary} ${recipe.ingredients.map((i) => i.name).join(' ')}'.toLowerCase();
    
    return !nonHalalKeywords.any((keyword) => recipeText.contains(keyword));
  }

  /// Find allergens that match recipe ingredients
  List<String> _findMatchingAllergens(Recipe recipe, List<String> allergens) {
    final matched = <String>[];
    
    for (final allergen in allergens) {
      final allergenLower = allergen.toLowerCase();
      
      // Check recipe title and summary
      if (recipe.title.toLowerCase().contains(allergenLower) ||
          (recipe.summary?.toLowerCase() ?? '').contains(allergenLower)) {
        matched.add(allergen);
        continue;
      }
      
      // Check ingredients
      for (final ingredient in recipe.ingredients) {
        if (ingredient.name.toLowerCase().contains(allergenLower)) {
          matched.add(allergen);
          break;
        }
      }
    }
    
    return matched;
  }

  /// Clear cache for a specific user or all users
  void clearCache([String? userId]) {
    if (userId != null) {
      _preferencesCache.remove(userId);
    } else {
      _preferencesCache.clear();
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;
    
    for (final entry in _preferencesCache.values) {
      if (now.difference(entry.timestamp) < _defaultCacheTtl) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }
    
    return {
      'total_entries': _preferencesCache.length,
      'valid_entries': validEntries,
      'expired_entries': expiredEntries,
      'cache_ttl_minutes': _defaultCacheTtl.inMinutes,
    };
  }

  /// Get debug statistics for diagnostics
  Map<String, dynamic> debugStats() {
    final stats = getCacheStats();
    final hitRate = stats['valid_entries'] / (stats['total_entries'] > 0 ? stats['total_entries'] : 1);
    
    return {
      'cacheSize': stats['total_entries'],
      'hitRate': hitRate,
    };
  }
}

/// Internal class for caching preferences
class _CachedPreferences {
  final Preferences? preferences;
  final DateTime timestamp;

  _CachedPreferences({
    required this.preferences,
    required this.timestamp,
  });
}
