import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart' as health_pkg;
import 'package:uuid/uuid.dart';

/// Health platform providers
enum HealthProvider {
  healthkit,
  healthconnect,
  googlefit,
  hms,
}

/// Health data types
enum HealthDataType {
  steps,
  distance,
  calories,
  heartRate,
  sleep,
  weight,
  bodyFat,
  bloodPressure,
  bloodGlucose,
}

/// Health sample data model
class HealthSample {
  final String id;
  final String userId;
  final HealthDataType type;
  final double? value;
  final String? unit;
  final DateTime measuredAt;
  final String? source;
  final Map<String, dynamic>? meta;

  HealthSample({
    required this.id,
    required this.userId,
    required this.type,
    this.value,
    this.unit,
    required this.measuredAt,
    this.source,
    this.meta,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'measured_at': measuredAt.toIso8601String(),
      'source': source,
      'meta': meta ?? {},
    };
  }

  factory HealthSample.fromJson(Map<String, dynamic> json) {
    return HealthSample(
      id: json['id'],
      userId: json['user_id'],
      type: HealthDataType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HealthDataType.steps,
      ),
      value: json['value']?.toDouble(),
      unit: json['unit'],
      measuredAt: DateTime.parse(json['measured_at']),
      source: json['source'],
      meta: json['meta'],
    );
  }
}

/// Health workout data model
class HealthWorkout {
  final String id;
  final String userId;
  final String sport;
  final DateTime startAt;
  final DateTime? endAt;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? avgHeartRate;
  final double? calories;
  final String? source;
  final Map<String, dynamic>? meta;

  HealthWorkout({
    required this.id,
    required this.userId,
    required this.sport,
    required this.startAt,
    this.endAt,
    this.durationSeconds,
    this.distanceMeters,
    this.avgHeartRate,
    this.calories,
    this.source,
    this.meta,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sport': sport,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'duration_s': durationSeconds,
      'distance_m': distanceMeters,
      'avg_hr': avgHeartRate,
      'kcal': calories,
      'source': source,
      'meta': meta ?? {},
    };
  }

  factory HealthWorkout.fromJson(Map<String, dynamic> json) {
    return HealthWorkout(
      id: json['id'],
      userId: json['user_id'],
      sport: json['sport'],
      startAt: DateTime.parse(json['start_at']),
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
      durationSeconds: json['duration_s'],
      distanceMeters: json['distance_m']?.toDouble(),
      avgHeartRate: json['avg_hr']?.toDouble(),
      calories: json['kcal']?.toDouble(),
      source: json['source'],
      meta: json['meta'],
    );
  }
}

/// Sleep segment data model
class SleepSegment {
  final String id;
  final String userId;
  final DateTime startAt;
  final DateTime? endAt;
  final String? stage;
  final String? source;
  final Map<String, dynamic>? meta;

  SleepSegment({
    required this.id,
    required this.userId,
    required this.startAt,
    this.endAt,
    this.stage,
    this.source,
    this.meta,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'stage': stage,
      'source': source,
      'meta': meta ?? {},
    };
  }

  factory SleepSegment.fromJson(Map<String, dynamic> json) {
    return SleepSegment(
      id: json['id'],
      userId: json['user_id'],
      startAt: DateTime.parse(json['start_at']),
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
      stage: json['stage'],
      source: json['source'],
      meta: json['meta'],
    );
  }
}

/// Health source connection model
class HealthSource {
  final String id;
  final String userId;
  final HealthProvider provider;
  final Map<String, dynamic> scopes;
  final DateTime? lastSyncAt;
  final Map<String, dynamic> cursor;
  final DateTime createdAt;

  HealthSource({
    required this.id,
    required this.userId,
    required this.provider,
    this.scopes = const {},
    this.lastSyncAt,
    this.cursor = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.name,
      'scopes': scopes,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'cursor': cursor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthSource.fromJson(Map<String, dynamic> json) {
    return HealthSource(
      id: json['id'],
      userId: json['user_id'],
      provider: HealthProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => HealthProvider.healthkit,
      ),
      scopes: json['scopes'] ?? {},
      lastSyncAt: json['last_sync_at'] != null ? DateTime.parse(json['last_sync_at']) : null,
      cursor: json['cursor'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Abstract health adapter interface
abstract class HealthAdapter {
  /// Check if this platform is supported
  bool get isSupported;
  
  /// Get platform name
  String get platformName;
  
  /// Get available data types
  List<HealthDataType> get availableDataTypes;
  
  /// Connect to the health platform
  Future<bool> connect();
  
  /// Disconnect from the health platform
  Future<void> disconnect();
  
  /// Check if connected
  Future<bool> isConnected();
  
  /// Request permissions
  Future<Map<String, bool>> requestPermissions();
  
  /// Get health data for the last N days
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  });
  
  /// Get workouts for the last N days
  Future<List<HealthWorkout>> getWorkouts({
    required int days,
  });
  
  /// Get sleep data for the last N days
  Future<List<SleepSegment>> getSleepData({
    required int days,
  });
}

/// Cross-platform health adapter using the health package
/// Works with Apple HealthKit (iOS) and Google Health Connect (Android)
class CrossPlatformHealthAdapter implements HealthAdapter {
  final health_pkg.Health _health = health_pkg.Health();
  bool _isAuthorized = false;
  final _uuid = const Uuid();
  
  @override
  bool get isSupported => Platform.isIOS || Platform.isAndroid;
  
  @override
  String get platformName => Platform.isIOS ? 'HealthKit' : 'Health Connect';
  
  @override
  List<HealthDataType> get availableDataTypes => [
    HealthDataType.steps,
    HealthDataType.distance,
    HealthDataType.calories,
    HealthDataType.heartRate,
    HealthDataType.sleep,
  ];
  
  /// Health data types to request from platform (using health package types)
  List<health_pkg.HealthDataType> get _platformDataTypes => [
    health_pkg.HealthDataType.STEPS,
    health_pkg.HealthDataType.DISTANCE_DELTA,
    health_pkg.HealthDataType.ACTIVE_ENERGY_BURNED,
    health_pkg.HealthDataType.HEART_RATE,
    health_pkg.HealthDataType.SLEEP_ASLEEP,
    health_pkg.HealthDataType.SLEEP_AWAKE,
    health_pkg.HealthDataType.SLEEP_DEEP,
    health_pkg.HealthDataType.SLEEP_LIGHT,
    health_pkg.HealthDataType.SLEEP_REM,
    health_pkg.HealthDataType.WORKOUT,
  ];
  
  @override
  Future<bool> connect() async {
    try {
      // Configure health package
      await _health.configure();
      
      // Request authorization
      final permissions = _platformDataTypes.map((t) => health_pkg.HealthDataAccess.READ).toList();
      final authorized = await _health.requestAuthorization(_platformDataTypes, permissions: permissions);
      
      _isAuthorized = authorized;
      debugPrint('$platformName: connect() - authorized: $authorized');
      return authorized;
    } catch (e) {
      debugPrint('$platformName: connect() error: $e');
      return false;
    }
  }
  
  @override
  Future<void> disconnect() async {
    _isAuthorized = false;
    debugPrint('$platformName: disconnect()');
  }
  
  @override
  Future<bool> isConnected() async {
    if (!_isAuthorized) return false;
    
    try {
      // Check if we still have permissions
      final hasPermissions = await _health.hasPermissions(_platformDataTypes);
      return hasPermissions ?? false;
    } catch (e) {
      debugPrint('$platformName: isConnected() error: $e');
      return false;
    }
  }
  
  @override
  Future<Map<String, bool>> requestPermissions() async {
    try {
      final permissions = _platformDataTypes.map((t) => health_pkg.HealthDataAccess.READ).toList();
      final authorized = await _health.requestAuthorization(_platformDataTypes, permissions: permissions);
      
      _isAuthorized = authorized;
      
      // Return permission status for each type
      final result = <String, bool>{};
      for (final type in _platformDataTypes) {
        result[type.name] = authorized;
      }
      return result;
    } catch (e) {
      debugPrint('$platformName: requestPermissions() error: $e');
      return {};
    }
  }
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) async {
    if (!_isAuthorized) {
      debugPrint('$platformName: getSamples() - not authorized');
      return [];
    }
    
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      
      // Map internal type to health package type
      final healthType = _mapToHealthDataType(type);
      if (healthType == null) return [];
      
      final dataPoints = await _health.getHealthDataFromTypes(
        types: [healthType],
        startTime: start,
        endTime: now,
      );
      
      // Remove duplicates
      final uniquePoints = _health.removeDuplicates(dataPoints);
      
      // Convert to our model
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      return uniquePoints.map((point) => _convertToHealthSample(point, userId, type)).toList();
    } catch (e) {
      debugPrint('$platformName: getSamples($type) error: $e');
      return [];
    }
  }
  
  @override
  Future<List<HealthWorkout>> getWorkouts({
    required int days,
  }) async {
    if (!_isAuthorized) {
      debugPrint('$platformName: getWorkouts() - not authorized');
      return [];
    }
    
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      
      final dataPoints = await _health.getHealthDataFromTypes(
        types: [health_pkg.HealthDataType.WORKOUT],
        startTime: start,
        endTime: now,
      );
      
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      
      return dataPoints.map((point) {
        final workoutValue = point.value;
        final duration = point.dateTo.difference(point.dateFrom).inSeconds;
        
        return HealthWorkout(
          id: _uuid.v4(),
          userId: userId,
          sport: workoutValue.toString(),
          startAt: point.dateFrom,
          endAt: point.dateTo,
          durationSeconds: duration,
          source: platformName.toLowerCase(),
          meta: {'source_id': point.uuid},
        );
      }).toList();
    } catch (e) {
      debugPrint('$platformName: getWorkouts() error: $e');
      return [];
    }
  }
  
  @override
  Future<List<SleepSegment>> getSleepData({
    required int days,
  }) async {
    if (!_isAuthorized) {
      debugPrint('$platformName: getSleepData() - not authorized');
      return [];
    }
    
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      
      final sleepTypes = [
        health_pkg.HealthDataType.SLEEP_ASLEEP,
        health_pkg.HealthDataType.SLEEP_AWAKE,
        health_pkg.HealthDataType.SLEEP_DEEP,
        health_pkg.HealthDataType.SLEEP_LIGHT,
        health_pkg.HealthDataType.SLEEP_REM,
      ];
      
      final dataPoints = await _health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: start,
        endTime: now,
      );
      
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      
      return dataPoints.map((point) {
        final stage = _mapSleepStage(point.type);
        
        return SleepSegment(
          id: _uuid.v4(),
          userId: userId,
          startAt: point.dateFrom,
          endAt: point.dateTo,
          stage: stage,
          source: platformName.toLowerCase(),
          meta: {'source_id': point.uuid},
        );
      }).toList();
    } catch (e) {
      debugPrint('$platformName: getSleepData() error: $e');
      return [];
    }
  }
  
  /// Map internal HealthDataType to health package HealthDataType
  health_pkg.HealthDataType? _mapToHealthDataType(HealthDataType type) {
    switch (type) {
      case HealthDataType.steps:
        return health_pkg.HealthDataType.STEPS;
      case HealthDataType.distance:
        return health_pkg.HealthDataType.DISTANCE_DELTA;
      case HealthDataType.calories:
        return health_pkg.HealthDataType.ACTIVE_ENERGY_BURNED;
      case HealthDataType.heartRate:
        return health_pkg.HealthDataType.HEART_RATE;
      case HealthDataType.sleep:
        return health_pkg.HealthDataType.SLEEP_ASLEEP;
      default:
        return null;
    }
  }
  
  /// Convert health package data point to our HealthSample model
  HealthSample _convertToHealthSample(health_pkg.HealthDataPoint point, String userId, HealthDataType type) {
    double? value;
    String? unit;
    
    final numValue = point.value;
    if (numValue is health_pkg.NumericHealthValue) {
      value = numValue.numericValue.toDouble();
    }
    
    // Map units
    switch (point.type) {
      case health_pkg.HealthDataType.STEPS:
        unit = 'count';
        break;
      case health_pkg.HealthDataType.DISTANCE_DELTA:
        unit = 'meters';
        break;
      case health_pkg.HealthDataType.ACTIVE_ENERGY_BURNED:
        unit = 'kcal';
        break;
      case health_pkg.HealthDataType.HEART_RATE:
        unit = 'bpm';
        break;
      default:
        unit = point.unit.name;
    }
    
    return HealthSample(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      value: value,
      unit: unit,
      measuredAt: point.dateFrom,
      source: platformName.toLowerCase(),
      meta: {'source_id': point.uuid},
    );
  }
  
  /// Map health package sleep type to stage string
  String? _mapSleepStage(health_pkg.HealthDataType type) {
    switch (type) {
      case health_pkg.HealthDataType.SLEEP_AWAKE:
        return 'awake';
      case health_pkg.HealthDataType.SLEEP_LIGHT:
        return 'light';
      case health_pkg.HealthDataType.SLEEP_DEEP:
        return 'deep';
      case health_pkg.HealthDataType.SLEEP_REM:
        return 'rem';
      case health_pkg.HealthDataType.SLEEP_ASLEEP:
        return 'light'; // Default to light if not specified
      default:
        return null;
    }
  }
}

/// Legacy HealthKit adapter - now uses CrossPlatformHealthAdapter
class HealthKitAdapter implements HealthAdapter {
  final CrossPlatformHealthAdapter _crossPlatform = CrossPlatformHealthAdapter();
  
  @override
  bool get isSupported => Platform.isIOS;
  
  @override
  String get platformName => 'HealthKit';
  
  @override
  List<HealthDataType> get availableDataTypes => _crossPlatform.availableDataTypes;
  
  @override
  Future<bool> connect() => _crossPlatform.connect();
  
  @override
  Future<void> disconnect() => _crossPlatform.disconnect();
  
  @override
  Future<bool> isConnected() => _crossPlatform.isConnected();
  
  @override
  Future<Map<String, bool>> requestPermissions() => _crossPlatform.requestPermissions();
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) => _crossPlatform.getSamples(type: type, days: days);
  
  @override
  Future<List<HealthWorkout>> getWorkouts({required int days}) => _crossPlatform.getWorkouts(days: days);
  
  @override
  Future<List<SleepSegment>> getSleepData({required int days}) => _crossPlatform.getSleepData(days: days);
}

/// Health Connect adapter (Android) - uses CrossPlatformHealthAdapter
class HealthConnectAdapter implements HealthAdapter {
  final CrossPlatformHealthAdapter _crossPlatform = CrossPlatformHealthAdapter();
  
  @override
  bool get isSupported => Platform.isAndroid;
  
  @override
  String get platformName => 'Health Connect';
  
  @override
  List<HealthDataType> get availableDataTypes => _crossPlatform.availableDataTypes;
  
  @override
  Future<bool> connect() => _crossPlatform.connect();
  
  @override
  Future<void> disconnect() => _crossPlatform.disconnect();
  
  @override
  Future<bool> isConnected() => _crossPlatform.isConnected();
  
  @override
  Future<Map<String, bool>> requestPermissions() => _crossPlatform.requestPermissions();
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) => _crossPlatform.getSamples(type: type, days: days);
  
  @override
  Future<List<HealthWorkout>> getWorkouts({required int days}) => _crossPlatform.getWorkouts(days: days);
  
  @override
  Future<List<SleepSegment>> getSleepData({required int days}) => _crossPlatform.getSleepData(days: days);
}

/// Google Fit adapter (Android) - uses CrossPlatformHealthAdapter
/// Note: Google Fit is deprecated in favor of Health Connect on Android 14+
class GoogleFitAdapter implements HealthAdapter {
  final CrossPlatformHealthAdapter _crossPlatform = CrossPlatformHealthAdapter();
  
  @override
  bool get isSupported => Platform.isAndroid;
  
  @override
  String get platformName => 'Google Fit';
  
  @override
  List<HealthDataType> get availableDataTypes => _crossPlatform.availableDataTypes;
  
  @override
  Future<bool> connect() => _crossPlatform.connect();
  
  @override
  Future<void> disconnect() => _crossPlatform.disconnect();
  
  @override
  Future<bool> isConnected() => _crossPlatform.isConnected();
  
  @override
  Future<Map<String, bool>> requestPermissions() => _crossPlatform.requestPermissions();
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) => _crossPlatform.getSamples(type: type, days: days);
  
  @override
  Future<List<HealthWorkout>> getWorkouts({required int days}) => _crossPlatform.getWorkouts(days: days);
  
  @override
  Future<List<SleepSegment>> getSleepData({required int days}) => _crossPlatform.getSleepData(days: days);
}

/// HMS adapter (Huawei)
/// Note: HMS Health Kit requires Huawei Mobile Services, which may not be available on all devices
/// This adapter remains stubbed as it requires Huawei-specific SDK integration
class HMSAdapter implements HealthAdapter {
  @override
  bool get isSupported => false; // HMS requires Huawei-specific setup
  
  @override
  String get platformName => 'HMS Health';
  
  @override
  List<HealthDataType> get availableDataTypes => [];
  
  @override
  Future<bool> connect() async {
    debugPrint('HMS: connect() - HMS Health requires Huawei-specific integration');
    return false;
  }
  
  @override
  Future<void> disconnect() async {
    debugPrint('HMS: disconnect()');
  }
  
  @override
  Future<bool> isConnected() async {
    return false;
  }
  
  @override
  Future<Map<String, bool>> requestPermissions() async {
    return {};
  }
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) async {
    return [];
  }
  
  @override
  Future<List<HealthWorkout>> getWorkouts({
    required int days,
  }) async {
    return [];
  }
  
  @override
  Future<List<SleepSegment>> getSleepData({
    required int days,
  }) async {
    return [];
  }
}

/// Main health service
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Adapters
  final HealthKitAdapter _healthKit = HealthKitAdapter();
  final HealthConnectAdapter _healthConnect = HealthConnectAdapter();
  final GoogleFitAdapter _googleFit = GoogleFitAdapter();
  final HMSAdapter _hms = HMSAdapter();

  /// Get adapter for a specific provider
  HealthAdapter getAdapter(HealthProvider provider) {
    switch (provider) {
      case HealthProvider.healthkit:
        return _healthKit;
      case HealthProvider.healthconnect:
        return _healthConnect;
      case HealthProvider.googlefit:
        return _googleFit;
      case HealthProvider.hms:
        return _hms;
    }
  }

  /// Connect to a health platform
  Future<bool> connect(HealthProvider provider) async {
    try {
      final adapter = getAdapter(provider);
      if (!adapter.isSupported) {
        debugPrint('${adapter.platformName} is not supported on this platform');
        return false;
      }
      
      final connected = await adapter.connect();
      if (connected) {
        await _saveHealthSource(provider);
      }
      return connected;
    } catch (e) {
      debugPrint('Error connecting to $provider: $e');
      return false;
    }
  }

  /// Disconnect from a health platform
  Future<void> disconnect(HealthProvider provider) async {
    try {
      final adapter = getAdapter(provider);
      await adapter.disconnect();
      await _removeHealthSource(provider);
    } catch (e) {
      debugPrint('Error disconnecting from $provider: $e');
    }
  }

  /// Initial import of health data
  Future<void> initialImport({int days = 30}) async {
    try {
      final sources = await getConnectedSources();
      
      for (final source in sources) {
        final adapter = getAdapter(source.provider);
        
        // Import samples
        for (final type in adapter.availableDataTypes) {
          final samples = await adapter.getSamples(type: type, days: days);
          await _saveSamples(samples);
        }
        
        // Import workouts
        final workouts = await adapter.getWorkouts(days: days);
        await _saveWorkouts(workouts);
        
        // Import sleep data
        final sleepData = await adapter.getSleepData(days: days);
        await _saveSleepSegments(sleepData);
      }
    } catch (e) {
      debugPrint('Error during initial import: $e');
    }
  }

  /// Sync delta changes - fetches recent data from health platforms
  Future<void> syncDelta() async {
    try {
      final sources = await getConnectedSources();
      
      for (final source in sources) {
        final adapter = getAdapter(source.provider);
        
        // Sync last 1 day of data for quick updates
        for (final type in adapter.availableDataTypes) {
          final samples = await adapter.getSamples(type: type, days: 1);
          await _saveSamples(samples);
        }
        
        // Sync today's workouts
        final workouts = await adapter.getWorkouts(days: 1);
        await _saveWorkouts(workouts);
        
        debugPrint('Delta sync completed for ${source.provider}');
      }
    } catch (e) {
      debugPrint('Error during delta sync: $e');
    }
  }

  /// Sync today's data and return fresh summary
  /// This fetches data directly from the health platform for the current day
  Future<Map<String, dynamic>> syncAndGetTodaySummary() async {
    try {
      // Sync today's data first
      await syncDelta();
      
      // Then fetch from database
      final summary = await getDailySummary(DateTime.now());
      
      return summary ?? {
        'steps': 0,
        'active_kcal': 0,
        'exercise_minutes': 0,
        'stand_hours': 0,
        'distance_km': 0.0,
      };
    } catch (e) {
      debugPrint('Error syncing and getting today summary: $e');
      return {
        'steps': 0,
        'active_kcal': 0,
        'exercise_minutes': 0,
        'stand_hours': 0,
        'distance_km': 0.0,
      };
    }
  }

  /// Get the recommended health provider for the current platform
  HealthProvider? getRecommendedProvider() {
    if (Platform.isIOS) {
      return HealthProvider.healthkit;
    } else if (Platform.isAndroid) {
      return HealthProvider.healthconnect;
    }
    return null;
  }

  /// Quick connect to the recommended health platform
  Future<bool> quickConnect() async {
    final provider = getRecommendedProvider();
    if (provider == null) return false;
    return connect(provider);
  }

  /// Save health samples to database
  Future<void> saveSamples(List<HealthSample> samples) async {
    try {
      for (final sample in samples) {
        await _supabase
            .from('health_samples')
            .upsert(sample.toJson());
      }
    } catch (e) {
      debugPrint('Error saving samples: $e');
    }
  }

  /// Save health workouts to database
  Future<void> saveWorkouts(List<HealthWorkout> workouts) async {
    try {
      for (final workout in workouts) {
        await _supabase
            .from('health_workouts')
            .upsert(workout.toJson());
      }
    } catch (e) {
      debugPrint('Error saving workouts: $e');
    }
  }

  /// Save sleep segments to database
  Future<void> saveSleepSegments(List<SleepSegment> segments) async {
    try {
      for (final segment in segments) {
        await _supabase
            .from('sleep_segments')
            .upsert(segment.toJson());
      }
    } catch (e) {
      debugPrint('Error saving sleep segments: $e');
    }
  }

  /// Get daily health summary
  Future<Map<String, dynamic>?> getDailySummary(DateTime date) async {
    try {
      final response = await _supabase
          .from('health_daily_v')
          .select()
          .eq('date', date.toIso8601String().split('T')[0])
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error getting daily summary: $e');
      return null;
    }
  }

  /// Find overlapping watch workouts for OCR merge
  Future<HealthWorkout?> findOverlappingWatchWorkout({
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async {
    try {
      // Stub implementation - returns demo workout for testing merge feature
      debugPrint('findOverlappingWatchWorkout - stubbed, returning demo workout');
      
      // Return a demo workout that overlaps with the current time for testing
      final now = DateTime.now();
      if (now.isAfter(windowStart) && now.isBefore(windowEnd)) {
        return HealthWorkout(
          id: 'demo-overlap-${now.millisecondsSinceEpoch}',
          userId: _supabase.auth.currentUser?.id ?? 'demo-user',
          sport: 'Running',
          startAt: now.subtract(const Duration(minutes: 15)),
          endAt: now.add(const Duration(minutes: 15)),
          durationSeconds: 1800, // 30 minutes
          distanceMeters: 5000.0, // 5km
          avgHeartRate: 150.0,
          calories: 350.0,
          source: 'demo-watch',
          meta: {'demo': true},
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error finding overlapping workout: $e');
      return null;
    }
  }

  // Private helper methods
  
  Future<void> _saveHealthSource(HealthProvider provider) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      await _supabase
          .from('health_sources')
          .upsert({
            'user_id': userId,
            'provider': provider.name,
            'last_sync_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('Error saving health source: $e');
    }
  }
  
  Future<void> _removeHealthSource(HealthProvider provider) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      await _supabase
          .from('health_sources')
          .delete()
          .eq('user_id', userId)
          .eq('provider', provider.name);
    } catch (e) {
      debugPrint('Error removing health source: $e');
    }
  }
  
  Future<List<HealthSource>> getConnectedSources() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      
      final response = await _supabase
          .from('health_sources')
          .select()
          .eq('user_id', userId);
      
      return response.map((json) => HealthSource.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting connected sources: $e');
      return [];
    }
  }
  
  Future<void> _saveSamples(List<HealthSample> samples) async {
    await saveSamples(samples);
  }
  
  Future<void> _saveWorkouts(List<HealthWorkout> workouts) async {
    await saveWorkouts(workouts);
  }
  
  Future<void> _saveSleepSegments(List<SleepSegment> segments) async {
    await saveSleepSegments(segments);
  }
}

