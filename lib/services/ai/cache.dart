import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ai_client.dart';
import 'pii_sanitizer.dart';

// ---------------------------------------------------------------------------
// BRAIN integration point
// ---------------------------------------------------------------------------

/// Abstract LLM client interface.
///
/// Currently backed by [_AiClientAdapter] wrapping [AIClient] (OpenRouter).
/// When BRAIN lands, swap the default with one call at app start-up:
///
/// ```dart
/// AiCacheService.configure(client: BrainClient.instance);
/// ```
abstract class AiBrainClient {
  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? options,
  });
}

class _AiClientAdapter implements AiBrainClient {
  final _inner = AIClient();

  @override
  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? options,
  }) =>
      _inner.chat(model: model, messages: messages, options: options);
}

// ---------------------------------------------------------------------------
// Cache service
// ---------------------------------------------------------------------------

/// AiCacheService — 3-layer AI response cache wrapping [AiBrainClient].
///
/// Read order: in-memory hot → SharedPreferences (offline) → Supabase (canonical).
/// Write order: all three layers on a cache miss.
///
/// Responses containing user-specific data (e.g. "your weight is X") are
/// never stored — only template-shaped responses are cached.
///
/// Telemetry is scaffolded via [_trackEvent]; wire to PostHog when ANALYTICA
/// adds the SDK.
class AiCacheService {
  AiCacheService._();
  static final AiCacheService instance = AiCacheService._();

  // Lazy default: only constructed on the first chat() call so that
  // tests can access [instance] without requiring Supabase initialization.
  AiBrainClient? _brainClient;
  AiBrainClient get _client => _brainClient ??= _AiClientAdapter();

  final _hot = <String, _HotEntry>{};

  static const String _localKeyPrefix = 'thrift_ai_cache_';
  static const String _supabaseTable = 'ai_cache';
  static const int _hotMaxEntries = 200;

  // Per-task TTL config (THRIFT spec).
  static const Map<String, Duration> _taskTtl = {
    'programGeneration':    Duration(days: 7),
    'workout.suggest':      Duration(days: 7),
    'workout.deload':       Duration(days: 7),
    'workout.deload_week':  Duration(days: 7),
    'workout.weakpoint':    Duration(days: 7),
    'workout.full_week':    Duration(days: 7),
    'workout.single_day':   Duration(days: 7),
    'workout.alternatives': Duration(days: 7),
    'workout.autofill':     Duration(days: 7),
    'workout.progression':  Duration(days: 7),
    'workout.balance':      Duration(days: 7),
    'workout.supersets':    Duration(days: 7),
    'workout.duration':     Duration(days: 7),
    'smartReply':           Duration(hours: 24),
    'messaging.reply':      Duration(hours: 24),
    'vision':               Duration(days: 14),
    'food_vision':          Duration(days: 14),
    'translation':          Duration(days: 30),
    'messaging.translate':  Duration(days: 30),
    'summary':              Duration(days: 7),
    'notes.summarize':      Duration(days: 7),
    'messaging.summarize':  Duration(days: 7),
    'calendar.tagger':      Duration(days: 7),
    'calendar.time':        Duration(days: 7),
  };

  static const Duration _defaultTtl = Duration(hours: 24);

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Swap in BRAIN's client when it lands — one call, one config change.
  static void configure({required AiBrainClient client}) {
    instance._brainClient = client;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Cached [AiBrainClient.chat] call.
  ///
  /// Hashes (model + sanitized messages + temperature + systemMessage) to form
  /// the cache key. Returns the cached response when available and not stale;
  /// otherwise calls upstream and stores the result in all three layers.
  Future<String> chat({
    required String taskType,
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    String? systemMessage,
    Map<String, dynamic>? options,
  }) async {
    final sanitized = PiiSanitizer.sanitizeMessages(messages);
    final key = keyFor(
      model: model,
      messages: sanitized,
      temperature: temperature,
      systemMessage: systemMessage,
    );

    final cached = await _get(key, taskType);
    if (cached != null) {
      _trackEvent('cache_hit', taskType);
      return cached;
    }

    _trackEvent('cache_miss', taskType);

    final response = await _client.chat(
      model: model,
      messages: messages,
      options: options,
    );

    if (_isCacheable(response)) {
      await _put(
        key: key,
        taskType: taskType,
        model: model,
        response: response,
      );
    }

    return response;
  }

  /// Build the cache key for a (model, messages, temperature, systemMessage) tuple.
  static String keyFor({
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    String? systemMessage,
  }) {
    final canonical = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'system': systemMessage ?? '',
    });
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  /// Legacy helper — matches the signature used by existing [AICache] callers.
  ///
  /// Generates a key from a flat task+model+inputOrPrompt string so existing
  /// callers (WorkoutAI, MessagingAI, CalendarAI) benefit from Supabase
  /// persistence without refactoring their call sites.
  static String legacyKeyFor({
    required String task,
    required String model,
    required String inputOrPrompt,
  }) {
    final combined = '$task:$model:$inputOrPrompt';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  /// Read-only lookup. Returns null on miss or if the entry has expired.
  Future<String?> lookup(String key, String taskType) => _get(key, taskType);

  /// Store a pre-computed response under [key].
  ///
  /// Used by callers (e.g. WorkoutAI) that manage their own upstream calls but
  /// want Supabase persistence.
  Future<void> store({
    required String key,
    required String taskType,
    required String model,
    required String response,
  }) async {
    if (_isCacheable(response)) {
      await _put(key: key, taskType: taskType, model: model, response: response);
    }
  }

  /// Remove a specific entry from all three layers.
  ///
  /// Call this when a coach edits a generated program so the next request
  /// regenerates a fresh response.
  Future<void> invalidate(String key) async {
    _hot.remove(key);
    await _localRemove(key);
    await _supabaseDelete(key);
    developer.log('THRIFT invalidate $key', name: 'AiCacheService');
  }

  /// Pull non-expired entries from Supabase into SharedPreferences for offline use.
  ///
  /// Call on app start (DRIFTKIT can also call this to seed its local DB).
  Future<void> warmLocalCache() async {
    try {
      final rows = await Supabase.instance.client
          .from(_supabaseTable)
          .select('prompt_hash, response, expires_at, task_type')
          .gt('expires_at', DateTime.now().toIso8601String())
          .limit(500);

      final prefs = await SharedPreferences.getInstance();
      for (final row in rows as List) {
        final hash = row['prompt_hash'] as String;
        final expiresAt = DateTime.parse(row['expires_at'] as String);
        if (expiresAt.isAfter(DateTime.now())) {
          final entry = _LocalEntry(
            response: (row['response'] as Map<String, dynamic>)['text'] as String,
            expiresAt: expiresAt,
          );
          await prefs.setString(_localKeyPrefix + hash, jsonEncode(entry.toJson()));
        }
      }
      developer.log(
        'THRIFT warmed local cache from Supabase (${(rows as List).length} entries)',
        name: 'AiCacheService',
      );
    } catch (e) {
      developer.log('THRIFT warmLocalCache failed: $e', name: 'AiCacheService');
    }
  }

  /// Hit-rate stats for a task type, read from Supabase.
  Future<Map<String, dynamic>> hitRateStats(String taskType) async {
    try {
      final rows = await Supabase.instance.client
          .from(_supabaseTable)
          .select('hit_count')
          .eq('task_type', taskType)
          .gt('expires_at', DateTime.now().toIso8601String());

      int totalEntries = 0;
      int totalHits = 0;
      for (final row in rows as List) {
        totalEntries++;
        totalHits += (row['hit_count'] as int? ?? 0);
      }
      return {
        'task_type': taskType,
        'entries': totalEntries,
        'total_hits': totalHits,
        'avg_hits_per_entry': totalEntries == 0 ? 0.0 : totalHits / totalEntries,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // Test helpers
  // ---------------------------------------------------------------------------

  /// Seed the hot cache with a custom expiry — for unit tests only.
  @visibleForTesting
  void hotSeedForTest(String key, String response, DateTime expiresAt) {
    _hot[key] = _HotEntry(response: response, expiresAt: expiresAt);
  }

  // ---------------------------------------------------------------------------
  // Layer 1 — in-memory hot cache
  // ---------------------------------------------------------------------------

  String? _hotGet(String key) {
    final entry = _hot[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _hot.remove(key);
      return null;
    }
    return entry.response;
  }

  void _hotPut(String key, String response, DateTime expiresAt) {
    if (_hot.length >= _hotMaxEntries) _hotEvict();
    _hot[key] = _HotEntry(response: response, expiresAt: expiresAt);
  }

  void _hotEvict() {
    // Remove the 20 soonest-to-expire entries.
    final sorted = _hot.entries.toList()
      ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
    for (var i = 0; i < 20 && i < sorted.length; i++) {
      _hot.remove(sorted[i].key);
    }
  }

  // ---------------------------------------------------------------------------
  // Layer 2 — local (SharedPreferences)
  // ---------------------------------------------------------------------------

  Future<String?> _localGet(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKeyPrefix + key);
      if (raw == null) return null;
      final entry = _LocalEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().isAfter(entry.expiresAt)) {
        await prefs.remove(_localKeyPrefix + key);
        return null;
      }
      return entry.response;
    } catch (_) {
      return null;
    }
  }

  Future<void> _localPut(String key, String response, DateTime expiresAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = _LocalEntry(response: response, expiresAt: expiresAt);
      await prefs.setString(_localKeyPrefix + key, jsonEncode(entry.toJson()));
    } catch (_) {}
  }

  Future<void> _localRemove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localKeyPrefix + key);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Layer 3 — Supabase
  // ---------------------------------------------------------------------------

  Future<String?> _supabaseGet(String key) async {
    try {
      final rows = await Supabase.instance.client
          .from(_supabaseTable)
          .select('response, expires_at')
          .eq('prompt_hash', key)
          .gt('expires_at', DateTime.now().toIso8601String())
          .limit(1);

      if ((rows as List).isEmpty) return null;

      final row = rows.first;
      final responseMap = row['response'] as Map<String, dynamic>;
      final text = responseMap['text'] as String?;
      if (text == null) return null;

      final expiresAt = DateTime.parse(row['expires_at'] as String);

      // Promote to faster layers.
      _hotPut(key, text, expiresAt);
      await _localPut(key, text, expiresAt);

      // Fire-and-forget hit increment.
      _supabaseIncrementHit(key);

      return text;
    } catch (_) {
      return null;
    }
  }

  Future<void> _supabasePut({
    required String key,
    required String taskType,
    required String model,
    required String response,
    required DateTime expiresAt,
  }) async {
    try {
      await Supabase.instance.client.from(_supabaseTable).upsert({
        'prompt_hash': key,
        'model': model,
        'task_type': taskType,
        'response': {'text': response},
        'expires_at': expiresAt.toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _supabaseDelete(String key) async {
    try {
      await Supabase.instance.client
          .from(_supabaseTable)
          .delete()
          .eq('prompt_hash', key);
    } catch (_) {}
  }

  void _supabaseIncrementHit(String key) {
    unawaited(
      Supabase.instance.client
          .rpc('increment_cache_hit', params: {'p_hash': key})
          .then((_) {})
          .catchError((_) {}),
    );
  }

  // ---------------------------------------------------------------------------
  // Orchestration
  // ---------------------------------------------------------------------------

  Future<String?> _get(String key, String taskType) async {
    // L1: hot
    final hot = _hotGet(key);
    if (hot != null) return hot;

    // L2: local
    final local = await _localGet(key);
    if (local != null) {
      final ttl = _taskTtl[taskType] ?? _defaultTtl;
      _hotPut(key, local, DateTime.now().add(ttl));
      return local;
    }

    // L3: Supabase
    return _supabaseGet(key);
  }

  Future<void> _put({
    required String key,
    required String taskType,
    required String model,
    required String response,
  }) async {
    final ttl = _taskTtl[taskType] ?? _defaultTtl;
    final expiresAt = DateTime.now().add(ttl);

    _hotPut(key, response, expiresAt);
    await _localPut(key, response, expiresAt);
    await _supabasePut(
      key: key,
      taskType: taskType,
      model: model,
      response: response,
      expiresAt: expiresAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Guards
  // ---------------------------------------------------------------------------

  /// Returns false if the response contains user-specific data or error text.
  ///
  /// Template-shaped responses (general advice, translations, plans) are safe
  /// to cache across calls with identical inputs. Responses that echo personal
  /// measurements or names back to the user are not.
  static bool _isCacheable(String response) {
    if (response.isEmpty) return false;

    // Reject error/quota responses from AIClient.
    if (response.startsWith('Quota exceeded') ||
        response.startsWith('AI service') ||
        response.startsWith('Rate limit')) {
      return false;
    }

    // Reject if PiiSanitizer redaction markers appear in the OUTPUT.
    if (response.contains('[redacted-')) return false;

    // Reject responses that contain direct personal-measurement phrases.
    final userSpecific = RegExp(
      r'your\s+(weight|height|age|bmi|body\s+fat|waist|hip|name)\s+is\s+\d',
      caseSensitive: false,
    );
    if (userSpecific.hasMatch(response)) return false;

    return true;
  }

  // ---------------------------------------------------------------------------
  // Telemetry (scaffold — wire to PostHog when ANALYTICA adds posthog_flutter)
  // ---------------------------------------------------------------------------

  void _trackEvent(String event, String taskType) {
    if (kDebugMode) {
      developer.log('THRIFT $event task=$taskType', name: 'AiCacheService');
    }
    // TODO(THRIFT→ANALYTICA): replace stub with PostHog.capture when SDK lands.
    // PostHog.instance.capture(
    //   eventName: 'ai_cache_$event',
    //   properties: {'task_type': taskType},
    // );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _HotEntry {
  _HotEntry({required this.response, required this.expiresAt});
  final String response;
  final DateTime expiresAt;
}

class _LocalEntry {
  _LocalEntry({required this.response, required this.expiresAt});

  factory _LocalEntry.fromJson(Map<String, dynamic> json) => _LocalEntry(
        response: json['r'] as String,
        expiresAt: DateTime.parse(json['e'] as String),
      );

  final String response;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => {'r': response, 'e': expiresAt.toIso8601String()};
}
