import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health/health.dart' as h;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum WearableProvider {
  appleHealth,
  healthConnect,
  garmin,
  whoop,
  oura,
}

extension WearableProviderExt on WearableProvider {
  String get id {
    switch (this) {
      case WearableProvider.appleHealth:
        return 'apple_health';
      case WearableProvider.healthConnect:
        return 'google_health_connect';
      case WearableProvider.garmin:
        return 'garmin';
      case WearableProvider.whoop:
        return 'whoop';
      case WearableProvider.oura:
        return 'oura';
    }
  }

  String get displayName {
    switch (this) {
      case WearableProvider.appleHealth:
        return 'Apple Health';
      case WearableProvider.healthConnect:
        return 'Google Health Connect';
      case WearableProvider.garmin:
        return 'Garmin Connect';
      case WearableProvider.whoop:
        return 'WHOOP';
      case WearableProvider.oura:
        return 'Oura Ring';
    }
  }

  /// Free tier = device-native (no OAuth). Pro+ = cloud OAuth provider.
  bool get requiresPro {
    switch (this) {
      case WearableProvider.appleHealth:
      case WearableProvider.healthConnect:
        return false;
      case WearableProvider.garmin:
      case WearableProvider.whoop:
      case WearableProvider.oura:
        return true;
    }
  }

  /// Whether this provider is available on the current OS.
  bool get isOsSupported {
    switch (this) {
      case WearableProvider.appleHealth:
        return Platform.isIOS;
      case WearableProvider.healthConnect:
        return Platform.isAndroid;
      case WearableProvider.garmin:
      case WearableProvider.whoop:
      case WearableProvider.oura:
        return true; // cloud — OS-agnostic once OAuth lands
    }
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class WearableDailySummary {
  final String source;
  final DateTime day;
  final int? steps;
  final int? restingHr;
  final double? hrvMs;
  final int? sleepMinutes;
  final int? activeKcal;
  final int? workoutsCount;
  final double? vo2max;

  const WearableDailySummary({
    required this.source,
    required this.day,
    this.steps,
    this.restingHr,
    this.hrvMs,
    this.sleepMinutes,
    this.activeKcal,
    this.workoutsCount,
    this.vo2max,
  });
}

// ---------------------------------------------------------------------------
// WearableService
// ---------------------------------------------------------------------------

class WearableService {
  WearableService._();
  static final WearableService instance = WearableService._();

  static const _syncIntervalHours = 4;
  static const _lastSyncKey = 'wearable_last_sync_epoch';
  static const _tokenPrefix = 'wearable_oauth_';

  final _supabase = Supabase.instance.client;
  final _health = h.Health();
  final _secureStorage = const FlutterSecureStorage();

  Timer? _syncTimer;

  // -------------------------------------------------------------------------
  // Initialisation
  // -------------------------------------------------------------------------

  /// Call on app launch. Kicks off background sync and schedules the timer.
  Future<void> init() async {
    await syncIfStale();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(hours: _syncIntervalHours),
      (_) => syncIfStale(),
    );
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // -------------------------------------------------------------------------
  // Connection management
  // -------------------------------------------------------------------------

  Future<bool> isConnected(WearableProvider provider) async {
    if (!provider.isOsSupported) return false;
    if (provider.requiresPro) {
      final token = await _secureStorage.read(key: '$_tokenPrefix${provider.id}');
      return token != null;
    }
    // Device-native: check permission status via the health package.
    return _hasHealthPermissions();
  }

  /// Connect a provider. Returns true on success.
  /// For cloud providers (Pro+) this is a placeholder — OAuth flow not yet
  /// implemented pending credentials. See escalation E-003.
  Future<bool> connect(WearableProvider provider) async {
    if (!provider.isOsSupported) return false;

    if (provider.requiresPro) {
      // OAuth approvals pending. UI shows "Coming Soon".
      // When credentials arrive: launch OAuth WebView → exchange code → store
      // token via _storeOAuthToken(provider, token).
      debugPrint('WearableService: ${provider.displayName} — OAuth not yet approved');
      return false;
    }

    // Device-native: request health permissions
    return _requestHealthPermissions();
  }

  Future<void> disconnect(WearableProvider provider) async {
    if (provider.requiresPro) {
      await _secureStorage.delete(key: '$_tokenPrefix${provider.id}');
    }
    // For device-native: revoke is done in OS settings; we just update Supabase.
    await _upsertSource(provider, connected: false);
  }

  // -------------------------------------------------------------------------
  // Sync
  // -------------------------------------------------------------------------

  /// Syncs if last sync was more than 4 hours ago.
  Future<void> syncIfStale() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEpoch = prefs.getInt(_lastSyncKey) ?? 0;
    final lastSync = DateTime.fromMillisecondsSinceEpoch(lastEpoch);
    if (DateTime.now().difference(lastSync).inHours < _syncIntervalHours) return;
    await syncAll();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Full sync across all connected device-native providers.
  Future<void> syncAll() async {
    if (_supabase.auth.currentUser == null) return;

    final authorized = await _hasHealthPermissions();
    if (!authorized) return;

    await _syncDeviceNative();
  }

  // -------------------------------------------------------------------------
  // Background sync — device-native (Apple Health / Health Connect)
  // -------------------------------------------------------------------------

  Future<void> _syncDeviceNative() async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();

    // Fetch the last 2 days to catch any late-arriving data points.
    final start = now.subtract(const Duration(days: 2));
    final source = Platform.isIOS ? 'apple_health' : 'google_health_connect';

    try {
      // --- Steps ---
      final steps = await _sumNumeric(h.HealthDataType.STEPS, start, now);

      // --- Resting HR ---
      final restingHr = await _avgNumeric(h.HealthDataType.RESTING_HEART_RATE, start, now);

      // --- HRV ---
      final hrv = await _avgNumeric(h.HealthDataType.HEART_RATE_VARIABILITY_RMSSD, start, now);

      // --- Sleep ---
      final sleepMinutes = await _sumSleepMinutes(start, now);

      // --- Active kcal ---
      final activeKcal = await _sumNumeric(h.HealthDataType.ACTIVE_ENERGY_BURNED, start, now);

      // --- Workouts ---
      final workouts = await _health.getHealthDataFromTypes(
        types: [h.HealthDataType.WORKOUT],
        startTime: start,
        endTime: now,
      );
      final workoutsCount = workouts.length;

      // VO2max: not available via health package v13; sourced from cloud providers (Garmin/Oura) in a future phase.
      const double? vo2max = null;

      // Upsert today's aggregate via server-side encrypted RPC
      await _supabase.rpc('wearable_upsert_daily', params: {
        'p_user_id': userId,
        'p_day': _dateStr(now),
        'p_source': source,
        'p_steps': steps?.toInt(),
        'p_resting_hr': restingHr?.toInt(),
        'p_hrv_ms': hrv?.toStringAsFixed(2),
        'p_sleep_minutes': sleepMinutes,
        'p_active_kcal': activeKcal?.toInt(),
        'p_workouts_count': workoutsCount,
        'p_vo2max': vo2max?.toStringAsFixed(1),
      });

      // Also update yesterday to catch late-arriving data
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStart = yesterday.subtract(const Duration(days: 1));

      final ySteps = await _sumNumeric(h.HealthDataType.STEPS, yesterdayStart, yesterday);
      final ySleep = await _sumSleepMinutes(yesterdayStart, yesterday);
      final yRestingHr = await _avgNumeric(h.HealthDataType.RESTING_HEART_RATE, yesterdayStart, yesterday);
      final yHrv = await _avgNumeric(h.HealthDataType.HEART_RATE_VARIABILITY_RMSSD, yesterdayStart, yesterday);
      final yActiveKcal = await _sumNumeric(h.HealthDataType.ACTIVE_ENERGY_BURNED, yesterdayStart, yesterday);
      await _supabase.rpc('wearable_upsert_daily', params: {
        'p_user_id': userId,
        'p_day': _dateStr(yesterday),
        'p_source': source,
        'p_steps': ySteps?.toInt(),
        'p_resting_hr': yRestingHr?.toInt(),
        'p_hrv_ms': yHrv?.toStringAsFixed(2),
        'p_sleep_minutes': ySleep,
        'p_active_kcal': yActiveKcal?.toInt(),
        'p_workouts_count': null,
        'p_vo2max': null,
      });

      await _upsertSource(
        Platform.isIOS ? WearableProvider.appleHealth : WearableProvider.healthConnect,
        connected: true,
      );

      // Audit: background sync — self-attributed, not a "human read"
      await _supabase.rpc('vault_audit_access', params: {
        'p_accessed_user_id': userId,
        'p_data_class': 'wearable',
        'p_action': 'write',
        'p_resource_table': 'wearable_daily',
        'p_justification': 'background_sync',
      });
    } catch (e) {
      debugPrint('WearableService._syncDeviceNative error: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Read — for UI
  // -------------------------------------------------------------------------

  /// Fetch today's summary for the current user. Triggers audit automatically
  /// via the wearable_read_daily RPC.
  Future<WearableDailySummary?> getTodaySummary() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final rows = await _supabase.rpc('wearable_read_daily', params: {
        'p_client_id': userId,
        'p_days': 1,
      }) as List<dynamic>;

      if (rows.isEmpty) return null;
      final row = rows.first as Map<String, dynamic>;

      return WearableDailySummary(
        source: row['source'] as String? ?? '',
        day: DateTime.tryParse(row['day'] as String? ?? '') ?? DateTime.now(),
        steps: row['steps'] as int?,
        restingHr: row['resting_hr'] as int?,
        sleepMinutes: row['sleep_minutes'] as int?,
        activeKcal: row['active_kcal'] as int?,
        workoutsCount: row['workouts_count'] as int?,
      );
    } catch (e) {
      debugPrint('WearableService.getTodaySummary error: $e');
      return null;
    }
  }

  /// Fetch recent summaries for a client (coach view). Emits audit row.
  Future<List<WearableDailySummary>> getClientSummaries({
    required String clientId,
    int days = 7,
    String? consentId,
  }) async {
    try {
      final rows = await _supabase.rpc('wearable_read_daily', params: {
        'p_client_id': clientId,
        'p_days': days,
        'p_consent_id': consentId,
      }) as List<dynamic>;

      return rows.map((r) {
        final row = r as Map<String, dynamic>;
        return WearableDailySummary(
          source: row['source'] as String? ?? '',
          day: DateTime.tryParse(row['day'] as String? ?? '') ?? DateTime.now(),
          steps: row['steps'] as int?,
          restingHr: row['resting_hr'] as int?,
          sleepMinutes: row['sleep_minutes'] as int?,
          activeKcal: row['active_kcal'] as int?,
          workoutsCount: row['workouts_count'] as int?,
        );
      }).toList();
    } catch (e) {
      debugPrint('WearableService.getClientSummaries error: $e');
      return [];
    }
  }

  /// Lists providers the current user has connected.
  Future<List<WearableProvider>> connectedProviders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _supabase
          .from('wearable_sources')
          .select('provider')
          .eq('user_id', userId) as List<dynamic>;

      final ids = rows.map((r) => (r as Map<String, dynamic>)['provider'] as String).toSet();
      return WearableProvider.values.where((p) => ids.contains(p.id)).toList();
    } catch (e) {
      debugPrint('WearableService.connectedProviders error: $e');
      return [];
    }
  }

  // -------------------------------------------------------------------------
  // health package helpers
  // -------------------------------------------------------------------------

  static const _readTypes = [
    h.HealthDataType.STEPS,
    h.HealthDataType.ACTIVE_ENERGY_BURNED,
    h.HealthDataType.HEART_RATE,
    h.HealthDataType.RESTING_HEART_RATE,
    h.HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    h.HealthDataType.SLEEP_ASLEEP,
    h.HealthDataType.SLEEP_AWAKE,
    h.HealthDataType.SLEEP_DEEP,
    h.HealthDataType.SLEEP_LIGHT,
    h.HealthDataType.SLEEP_REM,
    h.HealthDataType.WORKOUT,
    h.HealthDataType.WEIGHT,
    h.HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  Future<bool> _requestHealthPermissions() async {
    try {
      await _health.configure();
      final perms = _readTypes.map((_) => h.HealthDataAccess.READ).toList();
      final granted = await _health.requestAuthorization(_readTypes, permissions: perms);
      if (granted) {
        await _upsertSource(
          Platform.isIOS ? WearableProvider.appleHealth : WearableProvider.healthConnect,
          connected: true,
        );
      }
      return granted;
    } catch (e) {
      debugPrint('WearableService._requestHealthPermissions error: $e');
      return false;
    }
  }

  Future<bool> _hasHealthPermissions() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    try {
      final has = await _health.hasPermissions(_readTypes);
      return has ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<double?> _sumNumeric(h.HealthDataType type, DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: start,
        endTime: end,
      );
      if (points.isEmpty) return null;
      double sum = 0;
      for (final p in points) {
        final v = p.value;
        if (v is h.NumericHealthValue) sum += v.numericValue.toDouble();
      }
      return sum;
    } catch (_) {
      return null;
    }
  }

  Future<double?> _avgNumeric(h.HealthDataType type, DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: start,
        endTime: end,
      );
      if (points.isEmpty) return null;
      final vals = points
          .map((p) => p.value)
          .whereType<h.NumericHealthValue>()
          .map((v) => v.numericValue.toDouble())
          .toList();
      if (vals.isEmpty) return null;
      return vals.reduce((a, b) => a + b) / vals.length;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _sumSleepMinutes(DateTime start, DateTime end) async {
    try {
      final sleepTypes = [
        h.HealthDataType.SLEEP_ASLEEP,
        h.HealthDataType.SLEEP_DEEP,
        h.HealthDataType.SLEEP_LIGHT,
        h.HealthDataType.SLEEP_REM,
      ];
      final points = await _health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: start,
        endTime: end,
      );
      if (points.isEmpty) return null;
      int totalMinutes = 0;
      for (final p in points) {
        totalMinutes += p.dateTo.difference(p.dateFrom).inMinutes;
      }
      return totalMinutes;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Supabase helpers
  // -------------------------------------------------------------------------

  Future<void> _upsertSource(WearableProvider provider, {required bool connected}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (connected) {
        await _supabase.from('wearable_sources').upsert({
          'user_id': userId,
          'provider': provider.id,
          'last_sync_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,provider');
      } else {
        await _supabase
            .from('wearable_sources')
            .delete()
            .eq('user_id', userId)
            .eq('provider', provider.id);
      }
    } catch (e) {
      debugPrint('WearableService._upsertSource error: $e');
    }
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
