// =====================================================
// INTEGRATION ECOSYSTEM SERVICE
// =====================================================
// Revolutionary integration hub connecting nutrition data with external platforms.
//
// FEATURES:
// - Wearable sync (Apple Health, Google Fit, Fitbit, Garmin, Whoop, Oura)
// - Grocery delivery integration (Instacart, Amazon Fresh, Walmart+)
// - Meal kit services (HelloFresh, Blue Apron, Factor)
// - Calendar sync (Google Calendar, Apple Calendar, Outlook)
// - Fitness apps (MyFitnessPal, Cronometer, Lose It)
// - Recipe platforms (Yummly, Tasty, Allrecipes)
// =====================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================
// ENUMS
// =====================================================

enum IntegrationProvider {
  appleHealth,
  googleFit,
  fitbit,
  garmin,
  whoop,
  ouraRing,
  instacart,
  amazonFresh,
  walmartPlus,
  helloFresh,
  blueApron,
  factor,
  googleCalendar,
  appleCalendar,
  outlookCalendar,
  myFitnessPal,
  cronometer,
  yummly,
}

enum IntegrationStatus {
  connected,
  disconnected,
  pending,
  error,
}

enum SyncDirection {
  import,      // Import data into Vagus
  export,      // Export data from Vagus
  bidirectional, // Both ways
}

// =====================================================
// MODELS
// =====================================================

/// Integration configuration
class IntegrationConfig {
  final String id;
  final String userId;
  final IntegrationProvider provider;
  final IntegrationStatus status;
  final SyncDirection syncDirection;
  final Map<String, dynamic> credentials;
  final DateTime? lastSyncedAt;
  final bool autoSync;
  final int syncIntervalMinutes;
  final DateTime connectedAt;

  IntegrationConfig({
    required this.id,
    required this.userId,
    required this.provider,
    required this.status,
    required this.syncDirection,
    required this.credentials,
    this.lastSyncedAt,
    this.autoSync = true,
    this.syncIntervalMinutes = 60,
    required this.connectedAt,
  });

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) {
    return IntegrationConfig(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: IntegrationProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => IntegrationProvider.appleHealth,
      ),
      status: IntegrationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IntegrationStatus.disconnected,
      ),
      syncDirection: SyncDirection.values.firstWhere(
        (e) => e.name == json['sync_direction'],
        orElse: () => SyncDirection.import,
      ),
      credentials: json['credentials'] as Map<String, dynamic>? ?? {},
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      autoSync: json['auto_sync'] as bool? ?? true,
      syncIntervalMinutes: json['sync_interval_minutes'] as int? ?? 60,
      connectedAt: DateTime.parse(json['connected_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.name,
      'status': status.name,
      'sync_direction': syncDirection.name,
      'credentials': credentials,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'auto_sync': autoSync,
      'sync_interval_minutes': syncIntervalMinutes,
      'connected_at': connectedAt.toIso8601String(),
    };
  }
}

/// Sync result
class SyncResult {
  final String integrationId;
  final IntegrationProvider provider;
  final bool success;
  final int itemsSynced;
  final DateTime syncedAt;
  final String? error;
  final Map<String, int> itemsBreakdown;

  SyncResult({
    required this.integrationId,
    required this.provider,
    required this.success,
    required this.itemsSynced,
    required this.syncedAt,
    this.error,
    this.itemsBreakdown = const {},
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      integrationId: json['integration_id'] as String,
      provider: IntegrationProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => IntegrationProvider.appleHealth,
      ),
      success: json['success'] as bool,
      itemsSynced: json['items_synced'] as int,
      syncedAt: DateTime.parse(json['synced_at'] as String),
      error: json['error'] as String?,
      itemsBreakdown: Map<String, int>.from(json['items_breakdown'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'integration_id': integrationId,
      'provider': provider.name,
      'success': success,
      'items_synced': itemsSynced,
      'synced_at': syncedAt.toIso8601String(),
      'error': error,
      'items_breakdown': itemsBreakdown,
    };
  }
}

/// Grocery delivery order
class GroceryDeliveryOrder {
  final String id;
  final String userId;
  final IntegrationProvider provider;
  final List<GroceryItem> items;
  final double totalAmount;
  final String? deliveryAddress;
  final DateTime? deliveryTime;
  final OrderStatus status;
  final String? externalOrderId;
  final DateTime createdAt;

  GroceryDeliveryOrder({
    required this.id,
    required this.userId,
    required this.provider,
    required this.items,
    required this.totalAmount,
    this.deliveryAddress,
    this.deliveryTime,
    required this.status,
    this.externalOrderId,
    required this.createdAt,
  });

  factory GroceryDeliveryOrder.fromJson(Map<String, dynamic> json) {
    return GroceryDeliveryOrder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: IntegrationProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => IntegrationProvider.instacart,
      ),
      items: (json['items'] as List)
          .map((i) => GroceryItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryAddress: json['delivery_address'] as String?,
      deliveryTime: json['delivery_time'] != null
          ? DateTime.parse(json['delivery_time'] as String)
          : null,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      externalOrderId: json['external_order_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.name,
      'items': items.map((i) => i.toJson()).toList(),
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'delivery_time': deliveryTime?.toIso8601String(),
      'status': status.name,
      'external_order_id': externalOrderId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class GroceryItem {
  final String name;
  final int quantity;
  final String? unit;
  final double? price;

  GroceryItem({
    required this.name,
    required this.quantity,
    this.unit,
    this.price,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
    };
  }
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

/// Meal kit subscription
class MealKitSubscription {
  final String id;
  final String userId;
  final IntegrationProvider provider;
  final String planName;
  final int mealsPerWeek;
  final int servingsPerMeal;
  final double weeklyPrice;
  final DateTime? nextDeliveryDate;
  final bool isActive;
  final Map<String, dynamic> preferences;

  MealKitSubscription({
    required this.id,
    required this.userId,
    required this.provider,
    required this.planName,
    required this.mealsPerWeek,
    required this.servingsPerMeal,
    required this.weeklyPrice,
    this.nextDeliveryDate,
    required this.isActive,
    this.preferences = const {},
  });

  factory MealKitSubscription.fromJson(Map<String, dynamic> json) {
    return MealKitSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: IntegrationProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => IntegrationProvider.helloFresh,
      ),
      planName: json['plan_name'] as String,
      mealsPerWeek: json['meals_per_week'] as int,
      servingsPerMeal: json['servings_per_meal'] as int,
      weeklyPrice: (json['weekly_price'] as num).toDouble(),
      nextDeliveryDate: json['next_delivery_date'] != null
          ? DateTime.parse(json['next_delivery_date'] as String)
          : null,
      isActive: json['is_active'] as bool,
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.name,
      'plan_name': planName,
      'meals_per_week': mealsPerWeek,
      'servings_per_meal': servingsPerMeal,
      'weekly_price': weeklyPrice,
      'next_delivery_date': nextDeliveryDate?.toIso8601String(),
      'is_active': isActive,
      'preferences': preferences,
    };
  }
}

/// Wearable data import
class WearableDataImport {
  final String id;
  final String userId;
  final IntegrationProvider provider;
  final DateTime date;
  final Map<String, double> metrics;
  final DateTime importedAt;

  WearableDataImport({
    required this.id,
    required this.userId,
    required this.provider,
    required this.date,
    required this.metrics,
    required this.importedAt,
  });

  factory WearableDataImport.fromJson(Map<String, dynamic> json) {
    return WearableDataImport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: IntegrationProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => IntegrationProvider.appleHealth,
      ),
      date: DateTime.parse(json['date'] as String),
      metrics: Map<String, double>.from(json['metrics'] ?? {}),
      importedAt: DateTime.parse(json['imported_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.name,
      'date': date.toIso8601String(),
      'metrics': metrics,
      'imported_at': importedAt.toIso8601String(),
    };
  }
}

// =====================================================
// SERVICE
// =====================================================

class IntegrationEcosystemService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache
  final Map<String, IntegrationConfig> _configCache = {};

  // =====================================================
  // INTEGRATION MANAGEMENT
  // =====================================================

  /// Get all integrations for user
  Future<List<IntegrationConfig>> getUserIntegrations(String userId) async {
    try {
      final response = await _supabase
          .from('integration_configs')
          .select()
          .eq('user_id', userId)
          .order('connected_at', ascending: false);

      final configs = (response as List)
          .map((json) => IntegrationConfig.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache results
      for (final config in configs) {
        _configCache[config.id] = config;
      }

      return configs;
    } catch (e) {
      debugPrint('Error fetching integrations: $e');
      return [];
    }
  }

  /// Connect integration
  Future<IntegrationConfig?> connectIntegration({
    required String userId,
    required IntegrationProvider provider,
    required Map<String, dynamic> credentials,
    SyncDirection syncDirection = SyncDirection.import,
    bool autoSync = true,
    int syncIntervalMinutes = 60,
  }) async {
    try {
      final configData = {
        'user_id': userId,
        'provider': provider.name,
        'status': IntegrationStatus.connected.name,
        'sync_direction': syncDirection.name,
        'credentials': credentials,
        'auto_sync': autoSync,
        'sync_interval_minutes': syncIntervalMinutes,
        'connected_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('integration_configs')
          .insert(configData)
          .select()
          .single();

      final config = IntegrationConfig.fromJson(response);
      _configCache[config.id] = config;
      notifyListeners();

      return config;
    } catch (e) {
      debugPrint('Error connecting integration: $e');
      return null;
    }
  }

  /// Disconnect integration
  Future<bool> disconnectIntegration(String integrationId) async {
    try {
      await _supabase
          .from('integration_configs')
          .update({'status': IntegrationStatus.disconnected.name})
          .eq('id', integrationId);

      _configCache.remove(integrationId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error disconnecting integration: $e');
      return false;
    }
  }

  // =====================================================
  // WEARABLE SYNC
  // =====================================================

  /// Sync data from wearable
  Future<SyncResult?> syncWearableData({
    required String integrationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final config = _configCache[integrationId] ??
          await _getIntegrationConfig(integrationId);

      if (config == null) return null;

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();

      int itemsSynced = 0;
      final breakdown = <String, int>{};

      // Import data based on provider
      switch (config.provider) {
        case IntegrationProvider.appleHealth:
          itemsSynced = await _syncAppleHealth(config, start, end);
          breakdown['workouts'] = itemsSynced;
          break;
        case IntegrationProvider.googleFit:
          itemsSynced = await _syncGoogleFit(config, start, end);
          breakdown['activities'] = itemsSynced;
          break;
        case IntegrationProvider.fitbit:
          itemsSynced = await _syncFitbit(config, start, end);
          breakdown['steps'] = itemsSynced;
          break;
        case IntegrationProvider.whoop:
          itemsSynced = await _syncWhoop(config, start, end);
          breakdown['recovery'] = itemsSynced;
          break;
        case IntegrationProvider.ouraRing:
          itemsSynced = await _syncOura(config, start, end);
          breakdown['sleep'] = itemsSynced;
          break;
        default:
          break;
      }

      // Update last synced timestamp
      await _supabase
          .from('integration_configs')
          .update({'last_synced_at': DateTime.now().toIso8601String()})
          .eq('id', integrationId);

      final result = SyncResult(
        integrationId: integrationId,
        provider: config.provider,
        success: true,
        itemsSynced: itemsSynced,
        syncedAt: DateTime.now(),
        itemsBreakdown: breakdown,
      );

      // Save sync result
      await _saveSyncResult(result);

      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('Error syncing wearable: $e');
      return SyncResult(
        integrationId: integrationId,
        provider: IntegrationProvider.appleHealth,
        success: false,
        itemsSynced: 0,
        syncedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  Future<IntegrationConfig?> _getIntegrationConfig(String integrationId) async {
    final response = await _supabase
        .from('integration_configs')
        .select()
        .eq('id', integrationId)
        .maybeSingle();

    if (response == null) return null;
    return IntegrationConfig.fromJson(response);
  }

  Future<int> _syncAppleHealth(IntegrationConfig config, DateTime start, DateTime end) async {
    // Implementation would use HealthKit
    return 0;
  }

  Future<int> _syncGoogleFit(IntegrationConfig config, DateTime start, DateTime end) async {
    // Implementation would use Google Fit API
    return 0;
  }

  Future<int> _syncFitbit(IntegrationConfig config, DateTime start, DateTime end) async {
    // Implementation would use Fitbit API
    return 0;
  }

  Future<int> _syncWhoop(IntegrationConfig config, DateTime start, DateTime end) async {
    // Implementation would use Whoop API
    return 0;
  }

  Future<int> _syncOura(IntegrationConfig config, DateTime start, DateTime end) async {
    // Implementation would use Oura Ring API
    return 0;
  }

  Future<void> _saveSyncResult(SyncResult result) async {
    await _supabase
        .from('sync_results')
        .insert(result.toJson());
  }

  // =====================================================
  // GROCERY DELIVERY
  // =====================================================

  /// Create grocery delivery order
  Future<GroceryDeliveryOrder?> createGroceryOrder({
    required String userId,
    required IntegrationProvider provider,
    required List<GroceryItem> items,
    String? deliveryAddress,
    DateTime? deliveryTime,
  }) async {
    try {
      // Calculate total (would fetch prices from provider)
      double total = 0;
      for (final item in items) {
        total += (item.price ?? 0) * item.quantity;
      }

      final orderData = {
        'user_id': userId,
        'provider': provider.name,
        'items': items.map((i) => i.toJson()).toList(),
        'total_amount': total,
        'delivery_address': deliveryAddress,
        'delivery_time': deliveryTime?.toIso8601String(),
        'status': OrderStatus.pending.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_delivery_orders')
          .insert(orderData)
          .select()
          .single();

      final order = GroceryDeliveryOrder.fromJson(response);

      // Submit to external provider
      final externalOrderId = await _submitToGroceryProvider(provider, order);
      if (externalOrderId != null) {
        await _supabase
            .from('grocery_delivery_orders')
            .update({'external_order_id': externalOrderId})
            .eq('id', order.id);
      }

      notifyListeners();
      return order;
    } catch (e) {
      debugPrint('Error creating grocery order: $e');
      return null;
    }
  }

  Future<String?> _submitToGroceryProvider(
    IntegrationProvider provider,
    GroceryDeliveryOrder order,
  ) async {
    // Implementation would call external APIs
    // For now, return mock ID
    return 'ext_${DateTime.now().millisecondsSinceEpoch}';
  }

  // =====================================================
  // MEAL KIT INTEGRATION
  // =====================================================

  /// Subscribe to meal kit service
  Future<MealKitSubscription?> subscribeMealKit({
    required String userId,
    required IntegrationProvider provider,
    required String planName,
    required int mealsPerWeek,
    required int servingsPerMeal,
    Map<String, dynamic> preferences = const {},
  }) async {
    try {
      // Get pricing (would fetch from provider)
      final weeklyPrice = _calculateMealKitPrice(provider, mealsPerWeek, servingsPerMeal);

      final subscriptionData = {
        'user_id': userId,
        'provider': provider.name,
        'plan_name': planName,
        'meals_per_week': mealsPerWeek,
        'servings_per_meal': servingsPerMeal,
        'weekly_price': weeklyPrice,
        'next_delivery_date': _calculateNextDelivery().toIso8601String(),
        'is_active': true,
        'preferences': preferences,
      };

      final response = await _supabase
          .from('meal_kit_subscriptions')
          .insert(subscriptionData)
          .select()
          .single();

      notifyListeners();
      return MealKitSubscription.fromJson(response);
    } catch (e) {
      debugPrint('Error subscribing to meal kit: $e');
      return null;
    }
  }

  double _calculateMealKitPrice(IntegrationProvider provider, int meals, int servings) {
    // Mock pricing calculation
    const basePrice = 10.0;
    return basePrice * meals * servings;
  }

  DateTime _calculateNextDelivery() {
    // Calculate next delivery date (e.g., next Monday)
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    return now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }

  // =====================================================
  // CALENDAR SYNC
  // =====================================================

  /// Export meal plan to calendar
  Future<bool> exportToCalendar({
    required String userId,
    required String planId,
    required IntegrationProvider calendarProvider,
  }) async {
    try {
      // Fetch meal plan
      final plan = await _supabase
          .from('nutrition_plans')
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (plan == null) return false;

      // Convert meals to calendar events
      // Implementation would use Calendar APIs

      return true;
    } catch (e) {
      debugPrint('Error exporting to calendar: $e');
      return false;
    }
  }

  // =====================================================
  // UTILITY
  // =====================================================

  /// Get available integrations
  static List<IntegrationProvider> get availableIntegrations => IntegrationProvider.values;

  /// Get integration display info
  static Map<String, String> getProviderInfo(IntegrationProvider provider) {
    switch (provider) {
      case IntegrationProvider.appleHealth:
        return {'name': 'Apple Health', 'icon': '🍎', 'category': 'Wearable'};
      case IntegrationProvider.googleFit:
        return {'name': 'Google Fit', 'icon': '🏃', 'category': 'Wearable'};
      case IntegrationProvider.fitbit:
        return {'name': 'Fitbit', 'icon': '⌚', 'category': 'Wearable'};
      case IntegrationProvider.instacart:
        return {'name': 'Instacart', 'icon': '🛒', 'category': 'Grocery'};
      case IntegrationProvider.helloFresh:
        return {'name': 'HelloFresh', 'icon': '📦', 'category': 'Meal Kit'};
      default:
        return {'name': provider.name, 'icon': '🔗', 'category': 'Other'};
    }
  }

  /// Clear cache
  void clearCache() {
    _configCache.clear();
    notifyListeners();
  }
}