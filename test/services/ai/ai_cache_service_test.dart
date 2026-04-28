import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vagus_app/services/ai/cache.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    // Reset SharedPreferences mock before each test for isolation.
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Key generation
  // ---------------------------------------------------------------------------

  group('AiCacheService.keyFor', () {
    test('produces a 64-char hex SHA-256 hash', () {
      final key = AiCacheService.keyFor(
        model: 'cerebras/llama-3.3-70b',
        messages: [
          {'role': 'user', 'content': 'Give me a push/pull/legs split'},
        ],
      );
      expect(key.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(key), isTrue);
    });

    test('is deterministic — same input always produces same key', () {
      final messages = [
        {'role': 'system', 'content': 'You are a fitness coach.'},
        {'role': 'user', 'content': 'Suggest a deload week'},
      ];
      final k1 = AiCacheService.keyFor(
        model: 'gpt-4o',
        messages: messages,
        temperature: 0.5,
        systemMessage: 'You are a fitness coach.',
      );
      final k2 = AiCacheService.keyFor(
        model: 'gpt-4o',
        messages: messages,
        temperature: 0.5,
        systemMessage: 'You are a fitness coach.',
      );
      expect(k1, equals(k2));
    });

    test('differs when model changes', () {
      final messages = [
        {'role': 'user', 'content': 'Hello'},
      ];
      final k1 = AiCacheService.keyFor(model: 'model-a', messages: messages);
      final k2 = AiCacheService.keyFor(model: 'model-b', messages: messages);
      expect(k1, isNot(equals(k2)));
    });
  });

  group('AiCacheService.legacyKeyFor', () {
    test('produces consistent hash for legacy callers', () {
      final k1 = AiCacheService.legacyKeyFor(
        task: 'programGeneration',
        model: 'gpt-4o',
        inputOrPrompt: 'hypertrophy 4 days barbell',
      );
      final k2 = AiCacheService.legacyKeyFor(
        task: 'programGeneration',
        model: 'gpt-4o',
        inputOrPrompt: 'hypertrophy 4 days barbell',
      );
      expect(k1, equals(k2));
      expect(k1.length, 64);
    });
  });

  // ---------------------------------------------------------------------------
  // Cache miss — fresh lookup returns null
  // ---------------------------------------------------------------------------

  group('cache miss', () {
    test('lookup returns null for an unknown key', () async {
      final key = AiCacheService.keyFor(
        model: 'gpt-4o',
        messages: [
          {'role': 'user', 'content': 'unique-${DateTime.now().microsecondsSinceEpoch}'},
        ],
      );
      final result = await AiCacheService.instance.lookup(key, 'smartReply');
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Cache hit — store then lookup returns the value
  // ---------------------------------------------------------------------------

  group('cache hit', () {
    test('lookup returns value after store', () async {
      const response = 'Here is your 7-day deload plan.';
      final key = AiCacheService.legacyKeyFor(
        task: 'programGeneration',
        model: 'gpt-4o',
        inputOrPrompt: 'deload-${DateTime.now().microsecondsSinceEpoch}',
      );

      await AiCacheService.instance.store(
        key: key,
        taskType: 'programGeneration',
        model: 'gpt-4o',
        response: response,
      );

      final result = await AiCacheService.instance.lookup(key, 'programGeneration');
      expect(result, equals(response));
    });

    test('lookup returns null after invalidation', () async {
      const response = 'Push day: bench, OHP, dips.';
      final key = AiCacheService.legacyKeyFor(
        task: 'workout.suggest',
        model: 'gpt-4o',
        inputOrPrompt: 'push-${DateTime.now().microsecondsSinceEpoch}',
      );

      await AiCacheService.instance.store(
        key: key,
        taskType: 'workout.suggest',
        model: 'gpt-4o',
        response: response,
      );

      // Verify it was stored.
      expect(
        await AiCacheService.instance.lookup(key, 'workout.suggest'),
        equals(response),
      );

      // Invalidate and verify it's gone.
      await AiCacheService.instance.invalidate(key);
      final afterInvalidate = await AiCacheService.instance.lookup(key, 'workout.suggest');
      expect(afterInvalidate, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Expiry — expired hot-cache entry is treated as a miss
  // ---------------------------------------------------------------------------

  group('expiry', () {
    test('hot-cache entry past its expiry is treated as a miss', () async {
      final key = AiCacheService.legacyKeyFor(
        task: 'smartReply',
        model: 'gpt-4o',
        inputOrPrompt: 'stale-${DateTime.now().microsecondsSinceEpoch}',
      );
      const staleResponse = 'This reply has expired.';

      // Seed an entry that already expired one second ago.
      AiCacheService.instance.hotSeedForTest(
        key,
        staleResponse,
        DateTime.now().subtract(const Duration(seconds: 1)),
      );

      // The hot-cache read should evict it and return null.
      // SharedPreferences is empty (mock) and Supabase is absent in tests,
      // so all layers return null.
      final result = await AiCacheService.instance.lookup(key, 'smartReply');
      expect(result, isNull);
    });

    test('hot-cache entry before expiry is still returned', () async {
      final key = AiCacheService.legacyKeyFor(
        task: 'translation',
        model: 'gpt-4o',
        inputOrPrompt: 'fresh-${DateTime.now().microsecondsSinceEpoch}',
      );
      const freshResponse = 'مرحبا بالعالم';

      // Seed an entry that expires one hour from now.
      AiCacheService.instance.hotSeedForTest(
        key,
        freshResponse,
        DateTime.now().add(const Duration(hours: 1)),
      );

      final result = await AiCacheService.instance.lookup(key, 'translation');
      expect(result, equals(freshResponse));
    });
  });

  // ---------------------------------------------------------------------------
  // Cacheability guard
  // ---------------------------------------------------------------------------

  group('uncacheable responses are not stored', () {
    test('error responses are not stored', () async {
      const errorResponse = 'Quota exceeded. Please upgrade your plan.';
      final key = AiCacheService.legacyKeyFor(
        task: 'smartReply',
        model: 'gpt-4o',
        inputOrPrompt: 'quota-${DateTime.now().microsecondsSinceEpoch}',
      );

      // store() should silently drop uncacheable content.
      await AiCacheService.instance.store(
        key: key,
        taskType: 'smartReply',
        model: 'gpt-4o',
        response: errorResponse,
      );

      final result = await AiCacheService.instance.lookup(key, 'smartReply');
      expect(result, isNull);
    });

    test('PII-redacted responses are not stored', () async {
      const piiResponse = 'Hello [redacted-name], your weight is 80kg.';
      final key = AiCacheService.legacyKeyFor(
        task: 'smartReply',
        model: 'gpt-4o',
        inputOrPrompt: 'pii-${DateTime.now().microsecondsSinceEpoch}',
      );

      await AiCacheService.instance.store(
        key: key,
        taskType: 'smartReply',
        model: 'gpt-4o',
        response: piiResponse,
      );

      final result = await AiCacheService.instance.lookup(key, 'smartReply');
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // BRAIN client swap — configure() is one call
  // ---------------------------------------------------------------------------

  group('BRAIN client interface', () {
    test('configure() swaps the underlying client', () {
      final fake = _FakeBrainClient();
      // Should not throw — verifies the configure API exists and is callable.
      expect(() => AiCacheService.configure(client: fake), returnsNormally);
      // Restore default so other tests are unaffected.
      AiCacheService.configure(client: _DefaultClientRestorer());
    });
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _FakeBrainClient implements AiBrainClient {
  @override
  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? options,
  }) async =>
      'fake response';
}

/// Restores the default adapter after a configure() call in tests.
class _DefaultClientRestorer implements AiBrainClient {
  @override
  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? options,
  }) async =>
      'AI service not configured. Please contact support.';
}
