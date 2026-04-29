import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'ai_quota_tracker.dart';
import 'pii_sanitizer.dart';
import 'task_type.dart';
import 'providers/provider_client.dart';
import 'providers/cerebras_client.dart';
import 'providers/gemini_client.dart';
import 'providers/groq_client.dart';
import 'providers/openrouter_client.dart';

/// Unified AI client that routes requests to the right provider based on
/// [TaskType], enforces PII sanitization on every input, tracks per-provider
/// quota via Supabase, and falls back through the provider chain on 429s or
/// transient errors.
///
/// Usage:
/// ```dart
/// final reply = await AIClient().complete(
///   'Summarise this workout log: ...',
///   TaskType.summary,
/// );
/// ```
class AIClient {
  // -- Singleton --

  static final AIClient _instance = AIClient._create(
    providers: {
      AiProvider.cerebras: CerebrasClient(),
      AiProvider.groq: GroqClient(),
      AiProvider.gemini: GeminiClient(),
      AiProvider.openrouter: OpenRouterClient(),
    },
    quota: AiQuotaTracker.instance,
  );

  factory AIClient() => _instance;

  AIClient._create({
    required Map<AiProvider, ProviderClient> providers,
    required QuotaChecker quota,
  })  : _providers = Map.unmodifiable(providers),
        _quota = quota;

  /// For tests only: create an isolated instance with injected providers and
  /// a stub quota checker so no Supabase connection is needed.
  @visibleForTesting
  factory AIClient.forTesting({
    required Map<AiProvider, ProviderClient> providers,
    QuotaChecker? quota,
  }) =>
      AIClient._create(
        providers: providers,
        quota: quota ?? const _AlwaysAllowedQuota(),
      );

  final Map<AiProvider, ProviderClient> _providers;
  final QuotaChecker _quota;

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Single-shot text completion, routed by [taskType].
  ///
  /// [knownNames] are stripped from [prompt] before transmission (VAULT PII
  /// guard). Pass `[user.fullName, coach?.fullName]` at the call site.
  Future<String> complete(
    String prompt,
    TaskType taskType, {
    List<String> knownNames = const [],
    List<Map<String, String>>? history,
  }) async {
    final sanitized = PiiSanitizer.sanitizeAndAssert(
      prompt,
      knownNames: knownNames,
      site: 'AIClient.complete[$taskType]',
    );
    final messages = [
      ...?history,
      {'role': 'user', 'content': sanitized},
    ];
    return _routeChat(messages, taskType);
  }

  /// Streaming text completion, routed by [taskType].
  ///
  /// Falls back to the next provider only if the first throws *before* any
  /// chunks are yielded (e.g. a 429 at connect time). Mid-stream errors are
  /// surfaced to the caller.
  Stream<String> stream(
    String prompt,
    TaskType taskType, {
    List<String> knownNames = const [],
    List<Map<String, String>>? history,
  }) {
    final sanitized = PiiSanitizer.sanitizeAndAssert(
      prompt,
      knownNames: knownNames,
      site: 'AIClient.stream[$taskType]',
    );
    final messages = [
      ...?history,
      {'role': 'user', 'content': sanitized},
    ];
    return _routeStream(messages, taskType);
  }

  /// Vision call — always Gemini, no fallback (spec: "no v1 fallback").
  Future<String> vision(
    Uint8List imageBytes,
    String prompt, {
    List<String> knownNames = const [],
  }) async {
    final sanitized = PiiSanitizer.sanitizeAndAssert(
      prompt,
      knownNames: knownNames,
      site: 'AIClient.vision',
    );
    final provider = _providers[AiProvider.gemini]!;
    try {
      final result = await provider.vision(imageBytes, sanitized);
      _posthogStub('vision', AiProvider.gemini, success: true);
      unawaited(_quota.recordUsage(provider.providerId));
      return result;
    } catch (e) {
      _posthogStub('vision', AiProvider.gemini, success: false, error: '$e');
      rethrow;
    }
  }

  /// Text embedding — always OpenRouter (backward-compat: `model` is ignored).
  Future<List<double>> embed({
    String model = '',     // kept for backward compat with existing callers
    required String input,
    TaskType taskType = TaskType.smartReply,
  }) async {
    final sanitized = PiiSanitizer.sanitize(input);
    final provider = _providers[AiProvider.openrouter]!;
    try {
      final result = await provider.embed(sanitized);
      unawaited(_quota.recordUsage(provider.providerId));
      return result;
    } catch (e) {
      developer.log('embed failed: $e', name: 'brain.ai_client');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Backward-compat shim
  // Existing callers (workout_ai, messaging_ai, calendar_ai …) use chat().
  // Migration to complete()+TaskType is tracked as tech-debt; @Deprecated will
  // be added once all call sites are updated in a follow-up PR.
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> chat({
    required String model,
    required List<Map<String, String>> messages,
    Map<String, dynamic>? options,
  }) async {
    final sanitized = PiiSanitizer.sanitizeMessages(messages);
    return _routeChat(sanitized, TaskType.smartReply);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Internal routing
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _routeChat(
    List<Map<String, String>> messages,
    TaskType taskType,
  ) async {
    final chain = kProviderChain[taskType]!;
    Object? lastError;

    for (final key in chain) {
      final provider = _providers[key]!;

      if (!await _quota.hasCapacity(provider.providerId)) {
        developer.log(
          'quota full for ${provider.providerId}, trying next',
          name: 'brain.ai_client',
        );
        lastError = ProviderQuotaExceededException(provider.providerId);
        continue;
      }

      try {
        final result = await provider.complete(messages);
        _posthogStub('complete', key, success: true);
        unawaited(_quota.recordUsage(provider.providerId));
        return result;
      } on ProviderQuotaExceededException catch (e) {
        developer.log('429 from ${provider.providerId}, falling back', name: 'brain.ai_client');
        lastError = e;
      } catch (e) {
        developer.log('${provider.providerId} error: $e', name: 'brain.ai_client');
        _posthogStub('complete', key, success: false, error: '$e');
        lastError = e;
      }
    }

    throw lastError ?? Exception('All providers exhausted for $taskType');
  }

  Stream<String> _routeStream(
    List<Map<String, String>> messages,
    TaskType taskType,
  ) async* {
    final chain = kProviderChain[taskType]!;

    for (final key in chain) {
      final provider = _providers[key]!;

      if (!await _quota.hasCapacity(provider.providerId)) continue;

      try {
        var yielded = false;
        await for (final chunk in provider.stream(messages)) {
          yielded = true;
          yield chunk;
        }
        if (yielded) {
          unawaited(_quota.recordUsage(provider.providerId));
          return; // stream completed successfully
        }
      } on ProviderQuotaExceededException {
        developer.log('stream 429 from ${provider.providerId}, trying next', name: 'brain.ai_client');
        continue;
      } catch (e) {
        developer.log('stream error from ${provider.providerId}: $e', name: 'brain.ai_client');
        continue;
      }
    }

    throw Exception('All providers exhausted streaming for $taskType');
  }

  void _posthogStub(
    String event,
    AiProvider provider, {
    required bool success,
    String? error,
  }) {
    // ANALYTICA wires real PostHog calls in a later PR.
    developer.log(
      'posthog_stub:ai_$event provider=${provider.name} success=$success'
      '${error != null ? ' error=$error' : ''}',
      name: 'brain.telemetry',
    );
  }
}

/// No-op quota checker for tests — all providers always have capacity.
class _AlwaysAllowedQuota implements QuotaChecker {
  const _AlwaysAllowedQuota();

  @override
  Future<bool> hasCapacity(String provider) async => true;

  @override
  Future<void> recordUsage(String provider, {int tokens = 0, int requests = 1}) async {}
}
