import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/supplement.dart';

/// Service for managing supplements in nutrition plans
class SupplementsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache for supplements by plan and day
  final Map<String, List<Supplement>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTTL = Duration(minutes: 10);

  /// Get all supplements for a specific day in a plan
  Future<List<Supplement>> listForDay(String planId, int dayIndex) async {
    final cacheKey = '${planId}_$dayIndex';
    
    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheTTL) {
        return _cache[cacheKey]!;
      } else {
        _cache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    try {
      final response = await _supabase
          .from('nutrition_supplements')
          .select('*')
          .eq('plan_id', planId)
          .eq('day_index', dayIndex)
          .order('created_at', ascending: true);

      final supplements = response
          .map((row) => Supplement.fromMap(row))
          .toList();

      // Update cache
      _cache[cacheKey] = supplements;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return supplements;
    } catch (e) {
      debugPrint('Error fetching supplements for day: $e');
      return [];
    }
  }

  /// Get all supplements for a plan (all days)
  Future<List<Supplement>> listForPlan(String planId) async {
    try {
      final response = await _supabase
          .from('nutrition_supplements')
          .select('*')
          .eq('plan_id', planId)
          .order('day_index', ascending: true)
          .order('created_at', ascending: true);

      return response
          .map((row) => Supplement.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('Error fetching supplements for plan: $e');
      return [];
    }
  }

  /// Add a new supplement
  Future<Supplement> add(Supplement supplement) async {
    try {
      final response = await _supabase
          .from('nutrition_supplements')
          .insert(supplement.toMap())
          .select()
          .single();

      final newSupplement = Supplement.fromMap(response);
      
      // Clear cache for this plan/day
      _clearCacheForPlanDay(supplement.planId, supplement.dayIndex);
      
      return newSupplement;
    } catch (e) {
      debugPrint('Error adding supplement: $e');
      rethrow;
    }
  }

  /// Update an existing supplement
  Future<Supplement> update(Supplement supplement) async {
    if (supplement.id == null) {
      throw ArgumentError('Supplement ID is required for update');
    }

    try {
      final response = await _supabase
          .from('nutrition_supplements')
          .update(supplement.toMap())
          .eq('id', supplement.id!)
          .select()
          .single();

      final updatedSupplement = Supplement.fromMap(response);
      
      // Clear cache for this plan/day
      _clearCacheForPlanDay(supplement.planId, supplement.dayIndex);
      
      return updatedSupplement;
    } catch (e) {
      debugPrint('Error updating supplement: $e');
      rethrow;
    }
  }

  /// Delete a supplement
  Future<void> delete(String id) async {
    try {
      // Get supplement info before deleting for cache clearing
      final supplement = await getById(id);
      
      await _supabase
          .from('nutrition_supplements')
          .delete()
          .eq('id', id);

      // Clear cache for this plan/day
      if (supplement != null) {
        _clearCacheForPlanDay(supplement.planId, supplement.dayIndex);
      }
    } catch (e) {
      debugPrint('Error deleting supplement: $e');
      rethrow;
    }
  }

  /// Get a supplement by ID
  Future<Supplement?> getById(String id) async {
    try {
      final response = await _supabase
          .from('nutrition_supplements')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return Supplement.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching supplement by ID: $e');
      return null;
    }
  }

  /// Get supplements by timing for a specific day
  Future<List<Supplement>> getByTiming(String planId, int dayIndex, String timing) async {
    try {
      final response = await _supabase
          .from('nutrition_supplements')
          .select('*')
          .eq('plan_id', planId)
          .eq('day_index', dayIndex)
          .eq('timing', timing)
          .order('created_at', ascending: true);

      return response
          .map((row) => Supplement.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('Error fetching supplements by timing: $e');
      return [];
    }
  }

  /// Get all unique supplement names for a plan
  Future<List<String>> getUniqueNames(String planId) async {
    try {
      final response = await _supabase
          .from('nutrition_supplements')
          .select('name')
          .eq('plan_id', planId);

      final names = response
          .map((row) => row['name'] as String)
          .toSet()
          .toList();
      
      names.sort();
      return names;
    } catch (e) {
      debugPrint('Error fetching unique supplement names: $e');
      return [];
    }
  }

  /// Get supplements summary for a plan
  Future<SupplementsSummary> getSummary(String planId) async {
    try {
      final supplements = await listForPlan(planId);
      
      if (supplements.isEmpty) {
        return SupplementsSummary.empty();
      }

      final totalSupplements = supplements.length;
      final uniqueNames = supplements.map((s) => s.name).toSet().length;
      final withTiming = supplements.where((s) => s.hasTiming).length;
      final withDosage = supplements.where((s) => s.hasDosage).length;
      
      final timings = supplements
          .where((s) => s.timing != null)
          .map((s) => s.timing!)
          .toSet()
          .toList();

      return SupplementsSummary(
        totalSupplements: totalSupplements,
        uniqueNames: uniqueNames,
        withTiming: withTiming,
        withDosage: withDosage,
        timings: timings,
      );
    } catch (e) {
      debugPrint('Error calculating supplements summary: $e');
      return SupplementsSummary.empty();
    }
  }

  /// Clear cache for a specific plan and day
  void _clearCacheForPlanDay(String planId, int dayIndex) {
    final cacheKey = '${planId}_$dayIndex';
    _cache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'cachedEntries': _cache.keys.length,
    };
  }
}

/// Supplements summary model
class SupplementsSummary {
  final int totalSupplements;
  final int uniqueNames;
  final int withTiming;
  final int withDosage;
  final List<String> timings;

  const SupplementsSummary({
    required this.totalSupplements,
    required this.uniqueNames,
    required this.withTiming,
    required this.withDosage,
    required this.timings,
  });

  factory SupplementsSummary.empty() {
    return const SupplementsSummary(
      totalSupplements: 0,
      uniqueNames: 0,
      withTiming: 0,
      withDosage: 0,
      timings: [],
    );
  }

  /// Get timing coverage percentage
  double get timingCoverage {
    if (totalSupplements == 0) return 0.0;
    return (withTiming / totalSupplements) * 100;
  }

  /// Get dosage coverage percentage
  double get dosageCoverage {
    if (totalSupplements == 0) return 0.0;
    return (withDosage / totalSupplements) * 100;
  }

  /// Get formatted timing coverage
  String get formattedTimingCoverage => '${timingCoverage.toStringAsFixed(1)}%';

  /// Get formatted dosage coverage
  String get formattedDosageCoverage => '${dosageCoverage.toStringAsFixed(1)}%';

  /// Check if plan has supplements
  bool get hasSupplements => totalSupplements > 0;

  /// Check if plan has supplements with timing
  bool get hasTimedSupplements => withTiming > 0;
}
