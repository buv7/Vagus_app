import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/food_item.dart';

/// Service for managing barcode scanning and product lookup
class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache for recent lookups (in-memory)
  final Map<String, _CachedBarcode> _lookupCache = {};
  static const Duration _cacheTTL = Duration(minutes: 10);
  static const int _maxCacheSize = 100;

  /// Look up a barcode in the local cache
  Future<BarcodeProduct?> lookup(String code) async {
    try {
      // Check in-memory cache first
      if (_lookupCache.containsKey(code)) {
        final cached = _lookupCache[code]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
          return cached.product;
        } else {
          _lookupCache.remove(code);
        }
      }

      // Query database
      final response = await _supabase
          .from('nutrition_barcodes')
          .select()
          .eq('code', code)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      // Update last_seen timestamp
      await _supabase
          .from('nutrition_barcodes')
          .update({'last_seen': DateTime.now().toIso8601String()})
          .eq('code', code);

      final product = BarcodeProduct.fromMap(response);
      
      // Cache the result
      _updateCache(code, product);
      
      return product;
    } catch (e) {
      debugPrint('Barcode lookup failed: $e');
      return null;
    }
  }

  /// Save a barcode product to the local cache
  Future<void> save({
    required String code,
    required String name,
    required Map<String, dynamic> per100g,
    String? brand,
    String? category,
  }) async {
    try {
      final data = {
        'code': code,
        'name': name,
        'per_100g': per100g,
        'brand': brand,
        'category': category,
        'last_seen': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Upsert the barcode
      await _supabase
          .from('nutrition_barcodes')
          .upsert(data, onConflict: 'code');

      // Create product object and cache it
      final product = BarcodeProduct(
        code: code,
        name: name,
        per100g: per100g,
        brand: brand,
        category: category,
      );
      
      _updateCache(code, product);
    } catch (e) {
      debugPrint('Failed to save barcode: $e');
      rethrow;
    }
  }

  /// Search barcodes by name or brand
  Future<List<BarcodeProduct>> search(String query) async {
    try {
      final response = await _supabase
          .from('nutrition_barcodes')
          .select()
          .or('name.ilike.%$query%,brand.ilike.%$query%')
          .order('last_seen', ascending: false)
          .limit(20);

      return response.map<BarcodeProduct>((item) => BarcodeProduct.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Barcode search failed: $e');
      return [];
    }
  }

  /// Get recent barcodes (last 30 days)
  Future<List<BarcodeProduct>> getRecentBarcodes({int limit = 20}) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final response = await _supabase
          .from('nutrition_barcodes')
          .select()
          .gte('last_seen', thirtyDaysAgo.toIso8601String())
          .order('last_seen', ascending: false)
          .limit(limit);

      return response.map<BarcodeProduct>((item) => BarcodeProduct.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Failed to get recent barcodes: $e');
      return [];
    }
  }

  /// Convert barcode product to FoodItem
  FoodItem toFoodItem(BarcodeProduct product, {double amount = 100.0}) {
    final nutrition = product.per100g;
    final scale = amount / 100.0;
    
    return FoodItem(
      id: 'barcode_${product.code}',
      name: product.name,
      amount: amount,
      protein: (nutrition['protein'] ?? 0.0) * scale,
      carbs: (nutrition['carbs'] ?? 0.0) * scale,
      fat: (nutrition['fat'] ?? 0.0) * scale,
      kcal: (nutrition['kcal'] ?? 0.0) * scale,
      sodium: nutrition['sodium'] != null ? (nutrition['sodium'] * scale).round() : null,
      potassium: nutrition['potassium'] != null ? (nutrition['potassium'] * scale).round() : null,
      estimated: false, // Barcode data is considered accurate
    );
  }

  /// Update cache with new barcode
  void _updateCache(String code, BarcodeProduct product) {
    // Remove oldest entries if cache is full
    if (_lookupCache.length >= _maxCacheSize) {
      final oldestKey = _lookupCache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _lookupCache.remove(oldestKey);
    }
    
    _lookupCache[code] = _CachedBarcode(
      product: product,
      timestamp: DateTime.now(),
    );
  }

  /// Clear cache
  void clearCache() {
    _lookupCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _lookupCache.length,
      'maxCacheSize': _maxCacheSize,
    };
  }
}

/// Cached barcode data
class _CachedBarcode {
  final BarcodeProduct product;
  final DateTime timestamp;
  
  _CachedBarcode({
    required this.product,
    required this.timestamp,
  });
}

/// Barcode product model
class BarcodeProduct {
  final String code;
  final String name;
  final Map<String, dynamic> per100g;
  final String? brand;
  final String? category;
  
  BarcodeProduct({
    required this.code,
    required this.name,
    required this.per100g,
    this.brand,
    this.category,
  });
  
  factory BarcodeProduct.fromMap(Map<String, dynamic> map) {
    return BarcodeProduct(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      per100g: Map<String, dynamic>.from(map['per_100g'] ?? {}),
      brand: map['brand'],
      category: map['category'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'per_100g': per100g,
      'brand': brand,
      'category': category,
    };
  }
  
  String get displayName {
    if (brand != null && brand!.isNotEmpty) {
      return '$brand $name';
    }
    return name;
  }
  
  @override
  String toString() {
    return 'BarcodeProduct(code: $code, name: $name, brand: $brand)';
  }
}
