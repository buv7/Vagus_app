import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'iap_interface.dart';
import 'google_iap_service.dart';

/// Singleton factory that returns the correct [IapService] for the current
/// platform.  Call [IapServiceProvider.init] once during app startup (after
/// Supabase is initialised), then access [IapServiceProvider.instance]
/// anywhere.
///
/// Wiring in main.dart:
/// ```dart
/// await IapServiceProvider.init();
/// ```
class IapServiceProvider {
  IapServiceProvider._();

  static IapService? _instance;

  static IapService get instance {
    assert(_instance != null,
        'IapServiceProvider.init() must be called before accessing instance');
    return _instance!;
  }

  static Future<IapService> init() async {
    if (_instance != null) return _instance!;

    final supabase = Supabase.instance.client;

    final IapService service;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      service = GoogleIapService(supabase);
    } else {
      // iOS/macOS: IAP-APPLE will replace _NoOpIapService with AppleIapService
      // once that agent ships lib/services/iap/apple_iap_service.dart.
      service = _NoOpIapService();
    }

    await service.init();
    _instance = service;
    return service;
  }

  static Future<void> dispose() async {
    await _instance?.dispose();
    _instance = null;
  }
}

// ── Placeholder until IAP-APPLE ships apple_iap_service.dart ─────────────────

class _NoOpIapService implements IapService {
  final _ctrl = StreamController<SubscriptionState>.broadcast();

  @override
  Stream<SubscriptionState> get subscriptionStream => _ctrl.stream;

  @override
  Future<void> init() async {}

  @override
  Future<List<ProductDetails>> fetchProducts(List<String> productIds) async =>
      const [];

  @override
  Future<void> purchase(ProductDetails product) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<SubscriptionState> currentState() async => SubscriptionState.free;

  @override
  Future<void> dispose() async => _ctrl.close();
}
