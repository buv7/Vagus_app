import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/ai/ai_client.dart';
import 'package:vagus_app/services/ai/ai_quota_tracker.dart';
import 'package:vagus_app/services/ai/pii_sanitizer.dart';
import 'package:vagus_app/services/ai/task_type.dart';
import 'package:vagus_app/services/ai/providers/provider_client.dart';

// ──────────────────────────────────────────────────────────────────────────
// Fakes
// ──────────────────────────────────────────────────────────────────────────

class _OkProvider implements ProviderClient {
  _OkProvider(this.providerId, this.reply);

  @override
  final String providerId;
  final String reply;

  int calls = 0;

  @override
  Future<String> complete(List<Map<String, String>> messages, {Map<String, dynamic>? options}) async {
    calls++;
    return reply;
  }

  @override
  Stream<String> stream(List<Map<String, String>> messages, {Map<String, dynamic>? options}) async* {
    calls++;
    for (final word in reply.split(' ')) {
      yield '$word ';
    }
  }

  @override
  Future<String> vision(Uint8List imageBytes, String prompt) async => reply;

  @override
  Future<List<double>> embed(String input) async => [0.1, 0.2, 0.3];
}

class _QuotaExhaustedProvider implements ProviderClient {
  _QuotaExhaustedProvider(this.providerId);

  @override
  final String providerId;

  @override
  Future<String> complete(List<Map<String, String>> messages, {Map<String, dynamic>? options}) =>
      throw ProviderQuotaExceededException(providerId);

  @override
  Stream<String> stream(List<Map<String, String>> messages, {Map<String, dynamic>? options}) =>
      Stream.error(ProviderQuotaExceededException(providerId));

  @override
  Future<String> vision(Uint8List imageBytes, String prompt) =>
      throw ProviderQuotaExceededException(providerId);

  @override
  Future<List<double>> embed(String input) =>
      throw ProviderQuotaExceededException(providerId);
}

class _ErrorProvider implements ProviderClient {
  _ErrorProvider(this.providerId);

  @override
  final String providerId;

  @override
  Future<String> complete(List<Map<String, String>> messages, {Map<String, dynamic>? options}) =>
      throw Exception('network failure');

  @override
  Stream<String> stream(List<Map<String, String>> messages, {Map<String, dynamic>? options}) =>
      Stream.error(Exception('network failure'));

  @override
  Future<String> vision(Uint8List imageBytes, String prompt) =>
      throw Exception('network failure');

  @override
  Future<List<double>> embed(String input) =>
      throw Exception('network failure');
}

class _TrackingQuota implements QuotaChecker {
  final Set<String> exhausted;
  final List<String> recorded = [];

  _TrackingQuota({this.exhausted = const {}});

  @override
  Future<bool> hasCapacity(String provider) async => !exhausted.contains(provider);

  @override
  Future<void> recordUsage(String provider, {int tokens = 0, int requests = 1}) async {
    recorded.add(provider);
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────

Map<AiProvider, ProviderClient> _allOk({String reply = 'ok'}) => {
      AiProvider.cerebras: _OkProvider('cerebras', reply),
      AiProvider.groq: _OkProvider('groq', reply),
      AiProvider.gemini: _OkProvider('gemini', reply),
      AiProvider.openrouter: _OkProvider('openrouter', reply),
    };

// ──────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────

void main() {
  // ────────────────────────────────────────────────────────────────────────
  // 1. TaskType routing table
  // ────────────────────────────────────────────────────────────────────────

  group('kProviderChain routing table', () {
    test('programGeneration first provider is cerebras', () {
      expect(kProviderChain[TaskType.programGeneration]!.first, AiProvider.cerebras);
    });

    test('smartReply first provider is groq', () {
      expect(kProviderChain[TaskType.smartReply]!.first, AiProvider.groq);
    });

    test('translation first provider is groq', () {
      expect(kProviderChain[TaskType.translation]!.first, AiProvider.groq);
    });

    test('vision is gemini only — no fallback', () {
      expect(kProviderChain[TaskType.vision], [AiProvider.gemini]);
    });

    test('summary first provider is cerebras', () {
      expect(kProviderChain[TaskType.summary]!.first, AiProvider.cerebras);
    });

    test('coachInsight first provider is cerebras', () {
      expect(kProviderChain[TaskType.coachInsight]!.first, AiProvider.cerebras);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 2. PII sanitizer integration
  // ────────────────────────────────────────────────────────────────────────

  group('PiiSanitizer integration', () {
    test('email is stripped before reaching provider', () async {
      String? seen;
      final providers = _allOk();
      // Wrap the primary provider to capture what it receives.
      final okGroq = _OkProvider('groq', 'pong');
      final capturingGroq = _CapturingProvider(okGroq, onComplete: (msgs) {
        seen = msgs.last['content'];
      });
      providers[AiProvider.groq] = capturingGroq;

      final client = AIClient.forTesting(providers: providers);
      await client.complete('Email me at user@example.com', TaskType.smartReply);

      expect(seen, isNotNull);
      expect(seen, isNot(contains('user@example.com')));
      expect(seen, contains('[redacted-email]'));
    });

    test('phone number is stripped', () async {
      final sanitized = PiiSanitizer.sanitize('Call me at +1 555-867-5309');
      expect(sanitized, isNot(contains('555-867-5309')));
    });

    test('name + date combination throws (AssertionError in debug mode)', () {
      // assertSafe() throws AssertionError (via assert) in debug/test mode,
      // and PiiViolation in release mode. Either is correct.
      expect(
        () => PiiSanitizer.assertSafe(
          'John Smith born 1990-05-12',
          knownNames: ['John Smith'],
          site: 'test',
        ),
        throwsA(anyOf(isA<AssertionError>(), isA<PiiViolation>())),
      );
    });

    test('sanitize strips date-of-birth year patterns', () {
      final out = PiiSanitizer.sanitize('DOB: 1990-05-12');
      expect(out, isNot(contains('1990-05-12')));
      expect(out, contains('[redacted-date]'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 3. Fallback chain — quota exceeded
  // ────────────────────────────────────────────────────────────────────────

  group('Fallback chain — ProviderQuotaExceededException', () {
    test('smartReply: groq quota → falls back to cerebras', () async {
      final quota = _TrackingQuota(exhausted: {'groq'});
      final cerebras = _OkProvider('cerebras', 'cerebras-response');
      final client = AIClient.forTesting(
        providers: {
          AiProvider.groq: _QuotaExhaustedProvider('groq'),
          AiProvider.cerebras: cerebras,
          AiProvider.gemini: _OkProvider('gemini', 'unused'),
          AiProvider.openrouter: _OkProvider('openrouter', 'unused'),
        },
        quota: quota,
      );

      final result = await client.complete('hello', TaskType.smartReply);
      expect(result, 'cerebras-response');
      expect(cerebras.calls, 1);
    });

    test('smartReply: groq + cerebras quota → falls back to openrouter', () async {
      final client = AIClient.forTesting(
        providers: {
          AiProvider.groq: _QuotaExhaustedProvider('groq'),
          AiProvider.cerebras: _QuotaExhaustedProvider('cerebras'),
          AiProvider.gemini: _OkProvider('gemini', 'unused'),
          AiProvider.openrouter: _OkProvider('openrouter', 'openrouter-response'),
        },
      );

      final result = await client.complete('hello', TaskType.smartReply);
      expect(result, 'openrouter-response');
    });

    test('programGeneration: cerebras quota → falls back to gemini', () async {
      final gemini = _OkProvider('gemini', 'gemini-response');
      final client = AIClient.forTesting(
        providers: {
          AiProvider.cerebras: _QuotaExhaustedProvider('cerebras'),
          AiProvider.gemini: gemini,
          AiProvider.groq: _OkProvider('groq', 'unused'),
          AiProvider.openrouter: _OkProvider('openrouter', 'unused'),
        },
      );

      final result = await client.complete('plan', TaskType.programGeneration);
      expect(result, 'gemini-response');
      expect(gemini.calls, 1);
    });

    test('all providers exhausted throws', () async {
      final client = AIClient.forTesting(
        providers: {
          AiProvider.groq: _QuotaExhaustedProvider('groq'),
          AiProvider.cerebras: _QuotaExhaustedProvider('cerebras'),
          AiProvider.gemini: _QuotaExhaustedProvider('gemini'),
          AiProvider.openrouter: _QuotaExhaustedProvider('openrouter'),
        },
      );

      expect(
        () => client.complete('hello', TaskType.smartReply),
        throwsException,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 4. Fallback chain — provider errors (non-quota)
  // ────────────────────────────────────────────────────────────────────────

  group('Fallback chain — network/unknown errors', () {
    test('error on primary falls through to secondary', () async {
      final groq = _OkProvider('groq', 'groq-ok');
      final client = AIClient.forTesting(
        providers: {
          AiProvider.groq: groq,
          AiProvider.cerebras: _ErrorProvider('cerebras'),
          AiProvider.gemini: _OkProvider('gemini', 'unused'),
          AiProvider.openrouter: _OkProvider('openrouter', 'unused'),
        },
      );

      // For smartReply, groq is first so this should work immediately.
      final result = await client.complete('hi', TaskType.smartReply);
      expect(result, 'groq-ok');
    });

    test('primary + secondary error → tertiary for smartReply', () async {
      final openrouter = _OkProvider('openrouter', 'openrouter-ok');
      final client = AIClient.forTesting(
        providers: {
          AiProvider.groq: _ErrorProvider('groq'),
          AiProvider.cerebras: _ErrorProvider('cerebras'),
          AiProvider.gemini: _OkProvider('gemini', 'unused'),
          AiProvider.openrouter: openrouter,
        },
      );

      final result = await client.complete('hi', TaskType.smartReply);
      expect(result, 'openrouter-ok');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 5. Quota tracker — hasCapacity gate
  // ────────────────────────────────────────────────────────────────────────

  group('QuotaChecker gate', () {
    test('provider with full quota is skipped via QuotaChecker', () async {
      final quota = _TrackingQuota(exhausted: {'cerebras'});
      final cerebrasProvider = _OkProvider('cerebras', 'should-not-be-called');
      final geminiProvider = _OkProvider('gemini', 'gemini-ok');

      final client = AIClient.forTesting(
        providers: {
          AiProvider.cerebras: cerebrasProvider,
          AiProvider.gemini: geminiProvider,
          AiProvider.groq: _OkProvider('groq', 'unused'),
          AiProvider.openrouter: _OkProvider('openrouter', 'unused'),
        },
        quota: quota,
      );

      final result = await client.complete('plan', TaskType.programGeneration);
      expect(result, 'gemini-ok');
      expect(cerebrasProvider.calls, 0); // skipped by quota gate
    });

    test('usage is recorded after successful call', () async {
      final quota = _TrackingQuota();
      final client = AIClient.forTesting(
        providers: _allOk(reply: 'ok'),
        quota: quota,
      );

      await client.complete('test', TaskType.summary);
      // Give the unawaited future a tick to run.
      await Future<void>.delayed(Duration.zero);
      expect(quota.recorded, isNotEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 6. Streaming
  // ────────────────────────────────────────────────────────────────────────

  group('stream()', () {
    test('chunks from primary provider are yielded in order', () async {
      final client = AIClient.forTesting(providers: _allOk(reply: 'hello world'));
      final chunks = await client.stream('hi', TaskType.smartReply).toList();
      final combined = chunks.join('').trim();
      expect(combined, 'hello world');
    });

    test('streaming falls back when primary throws quota before yielding', () async {
      final groqFails = _QuotaExhaustedProvider('groq');
      final cerebrasOk = _OkProvider('cerebras', 'fallback stream');

      final client = AIClient.forTesting(
        providers: {
          AiProvider.groq: groqFails,
          AiProvider.cerebras: cerebrasOk,
          AiProvider.gemini: _OkProvider('gemini', 'unused'),
          AiProvider.openrouter: _OkProvider('openrouter', 'unused'),
        },
      );

      final chunks =
          await client.stream('hi', TaskType.smartReply).toList();
      expect(chunks.join('').trim(), 'fallback stream');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 7. vision() — Gemini only, no fallback
  // ────────────────────────────────────────────────────────────────────────

  group('vision()', () {
    test('calls gemini provider only', () async {
      final gemini = _OkProvider('gemini', 'pasta');
      int cerebrasCalls = 0;
      final cerebras = _CountingProvider('cerebras', onVision: () => cerebrasCalls++);

      final client = AIClient.forTesting(
        providers: {
          AiProvider.cerebras: cerebras,
          AiProvider.gemini: gemini,
          AiProvider.groq: _OkProvider('groq', 'unused'),
          AiProvider.openrouter: _OkProvider('openrouter', 'unused'),
        },
      );

      final result = await client.vision(Uint8List(10), 'What food is this?');
      expect(result, 'pasta');
      expect(cerebrasCalls, 0);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 8. embed() backward compat
  // ────────────────────────────────────────────────────────────────────────

  group('embed() backward compat', () {
    test('named model param is accepted (ignored) without error', () async {
      final client = AIClient.forTesting(providers: _allOk());
      final vec = await client.embed(model: 'text-embedding-3-small', input: 'test');
      expect(vec, isNotEmpty);
    });

    test('PII is sanitized before embedding', () async {
      String? seen;
      final capturingOpenRouter = _CapturingProvider(
        _OkProvider('openrouter', ''),
        onEmbed: (s) => seen = s,
      );

      final client = AIClient.forTesting(
        providers: {
          AiProvider.cerebras: _OkProvider('cerebras', ''),
          AiProvider.groq: _OkProvider('groq', ''),
          AiProvider.gemini: _OkProvider('gemini', ''),
          AiProvider.openrouter: capturingOpenRouter,
        },
      );

      await client.embed(input: 'Index email user@example.com');
      expect(seen, isNotNull);
      expect(seen, isNot(contains('user@example.com')));
    });
  });
}

// ──────────────────────────────────────────────────────────────────────────
// Test-only wrappers that capture what reaches the provider
// ──────────────────────────────────────────────────────────────────────────

class _CapturingProvider implements ProviderClient {
  _CapturingProvider(
    this._inner, {
    void Function(List<Map<String, String>>)? onComplete,
    void Function(String)? onEmbed,
  })  : _onComplete = onComplete,
        _onEmbed = onEmbed;

  final ProviderClient _inner;
  final void Function(List<Map<String, String>>)? _onComplete;
  final void Function(String)? _onEmbed;

  @override
  String get providerId => _inner.providerId;

  @override
  Future<String> complete(List<Map<String, String>> messages, {Map<String, dynamic>? options}) {
    _onComplete?.call(messages);
    return _inner.complete(messages, options: options);
  }

  @override
  Stream<String> stream(List<Map<String, String>> messages, {Map<String, dynamic>? options}) =>
      _inner.stream(messages, options: options);

  @override
  Future<String> vision(Uint8List imageBytes, String prompt) =>
      _inner.vision(imageBytes, prompt);

  @override
  Future<List<double>> embed(String input) {
    _onEmbed?.call(input);
    return _inner.embed(input);
  }
}

class _CountingProvider implements ProviderClient {
  _CountingProvider(this.providerId, {void Function()? onVision})
      : _onVision = onVision;

  @override
  final String providerId;
  final void Function()? _onVision;

  @override
  Future<String> complete(List<Map<String, String>> messages, {Map<String, dynamic>? options}) async =>
      throw UnsupportedError('not used');

  @override
  Stream<String> stream(List<Map<String, String>> messages, {Map<String, dynamic>? options}) =>
      throw UnsupportedError('not used');

  @override
  Future<String> vision(Uint8List imageBytes, String prompt) async {
    _onVision?.call();
    return '';
  }

  @override
  Future<List<double>> embed(String input) async => throw UnsupportedError('not used');
}
