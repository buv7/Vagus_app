import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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

/// HealthKit adapter (iOS stub)
class HealthKitAdapter implements HealthAdapter {
  @override
  bool get isSupported => false; // Stub until package approved
  
  @override
  String get platformName => 'HealthKit';
  
  @override
  List<HealthDataType> get availableDataTypes => [];
  
  @override
  Future<bool> connect() async {
    debugPrint('HealthKit: connect() - stubbed');
    return false;
  }
  
  @override
  Future<void> disconnect() async {
    debugPrint('HealthKit: disconnect() - stubbed');
  }
  
  @override
  Future<bool> isConnected() async {
    debugPrint('HealthKit: isConnected() - stubbed');
    return false;
  }
  
  @override
  Future<Map<String, bool>> requestPermissions() async {
    debugPrint('HealthKit: requestPermissions() - stubbed');
    return {};
  }
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) async {
    debugPrint('HealthKit: getSamples() - stubbed');
    return [];
  }
  
  @override
  Future<List<HealthWorkout>> getWorkouts({
    required int days,
  }) async {
    debugPrint('HealthKit: getWorkouts() - stubbed');
    return [];
  }
  
  @override
  Future<List<SleepSegment>> getSleepData({
    required int days,
  }) async {
    debugPrint('HealthKit: getSleepData() - stubbed');
    return [];
  }
}

/// Health Connect adapter (Android stub)
class HealthConnectAdapter implements HealthAdapter {
  @override
  bool get isSupported => false; // Stub until package approved
  
  @override
  String get platformName => 'Health Connect';
  
  @override
  List<HealthDataType> get availableDataTypes => [];
  
  @override
  Future<bool> connect() async {
    debugPrint('HealthConnect: connect() - stubbed');
    return false;
  }
  
  @override
  Future<void> disconnect() async {
    debugPrint('HealthConnect: disconnect() - stubbed');
  }
  
  @override
  Future<bool> isConnected() async {
    debugPrint('HealthConnect: isConnected() - stubbed');
    return false;
  }
  
  @override
  Future<Map<String, bool>> requestPermissions() async {
    debugPrint('HealthConnect: requestPermissions() - stubbed');
    return {};
  }
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) async {
    debugPrint('HealthConnect: getSamples() - stubbed');
    return [];
  }
  
  @override
  Future<List<HealthWorkout>> getWorkouts({
    required int days,
  }) async {
    debugPrint('HealthConnect: getWorkouts() - stubbed');
    return [];
  }
  
  @override
  Future<List<SleepSegment>> getSleepData({
    required int days,
  }) async {
    debugPrint('HealthConnect: getSleepData() - stubbed');
    return [];
  }
}

/// Google Fit adapter (Android stub)
class GoogleFitAdapter implements HealthAdapter {
  @override
  bool get isSupported => false; // Stub until package approved
  
  @override
  String get platformName => 'Google Fit';
  
  @override
  List<HealthDataType> get availableDataTypes => [];
  
  @override
  Future<bool> connect() async {
    debugPrint('GoogleFit: connect() - stubbed');
    return false;
  }
  
  @override
  Future<void> disconnect() async {
    debugPrint('GoogleFit: disconnect() - stubbed');
  }
  
  @override
  Future<bool> isConnected() async {
    debugPrint('GoogleFit: isConnected() - stubbed');
    return false;
  }
  
  @override
  Future<Map<String, bool>> requestPermissions() async {
    debugPrint('GoogleFit: requestPermissions() - stubbed');
    return {};
  }
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) async {
    debugPrint('GoogleFit: getSamples() - stubbed');
    return [];
  }
  
  @override
  Future<List<HealthWorkout>> getWorkouts({
    required int days,
  }) async {
    debugPrint('GoogleFit: getWorkouts() - stubbed');
    return [];
  }
  
  @override
  Future<List<SleepSegment>> getSleepData({
    required int days,
  }) async {
    debugPrint('GoogleFit: getSleepData() - stubbed');
    return [];
  }
}

/// HMS adapter (Huawei stub)
class HMSAdapter implements HealthAdapter {
  @override
  bool get isSupported => false; // Stub until package approved
  
  @override
  String get platformName => 'HMS Health';
  
  @override
  List<HealthDataType> get availableDataTypes => [];
  
  @override
  Future<bool> connect() async {
    debugPrint('HMS: connect() - stubbed');
    return false;
  }
  
  @override
  Future<void> disconnect() async {
    debugPrint('HMS: disconnect() - stubbed');
  }
  
  @override
  Future<bool> isConnected() async {
    debugPrint('HMS: isConnected() - stubbed');
    return false;
  }
  
  @override
  Future<Map<String, bool>> requestPermissions() async {
    debugPrint('HMS: requestPermissions() - stubbed');
    return {};
  }
  
  @override
  Future<List<HealthSample>> getSamples({
    required HealthDataType type,
    required int days,
  }) async {
    debugPrint('HMS: getSamples() - stubbed');
    return [];
  }
  
  @override
  Future<List<HealthWorkout>> getWorkouts({
    required int days,
  }) async {
    debugPrint('HMS: getWorkouts() - stubbed');
    return [];
  }
  
  @override
  Future<List<SleepSegment>> getSleepData({
    required int days,
  }) async {
    debugPrint('HMS: getSleepData() - stubbed');
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

  /// Sync delta changes
  Future<void> syncDelta() async {
    try {
      final sources = await getConnectedSources();
      
      for (final source in sources) {
        // TODO: Implement delta sync logic when adapters are real
        debugPrint('Delta sync for ${source.provider} - stubbed');
      }
    } catch (e) {
      debugPrint('Error during delta sync: $e');
    }
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

