import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Daily request caps per provider (requests, not tokens, for simplicity).
/// Cerebras cap is in tokens; we track both but gate on requests here.
const Map<String, int> kDailyRequestLimits = {
  'cerebras': 1000000, // 1 M tokens/day — tracked as tokens; requests gate is liberal
  'groq': 14400,       // ~1 req/6 s burst average across 24 h
  'gemini': 1500,      // free tier
  'openrouter': 200,   // conservative for free models
};

/// Interface so tests can inject a no-op or controlled stub without Supabase.
abstract class QuotaChecker {
  Future<bool> hasCapacity(String provider);
  Future<void> recordUsage(String provider, {int tokens = 0, int requests = 1});
}

/// Production implementation — reads/writes `ai_quota_usage` via Supabase.
/// Uses `brain_upsert_quota` SECURITY DEFINER RPC for atomic increments.
class AiQuotaTracker implements QuotaChecker {
  static final AiQuotaTracker instance = AiQuotaTracker._();
  AiQuotaTracker._();

  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<bool> hasCapacity(String provider) async {
    try {
      final row = await _db
          .from('ai_quota_usage')
          .select('request_count')
          .eq('provider', provider)
          .eq('usage_date', _todayUtc())
          .maybeSingle();

      final count = (row?['request_count'] as num?)?.toInt() ?? 0;
      final limit = kDailyRequestLimits[provider] ?? 100;
      return count < limit;
    } catch (e) {
      // Fail open: quota check errors should never block the user.
      developer.log('QuotaChecker.hasCapacity error: $e', name: 'brain.quota');
      return true;
    }
  }

  @override
  Future<void> recordUsage(String provider, {int tokens = 0, int requests = 1}) async {
    try {
      await _db.rpc('brain_upsert_quota', params: {
        'p_provider': provider,
        'p_date': _todayUtc(),
        'p_tokens': tokens,
        'p_requests': requests,
      });
    } catch (e) {
      developer.log('QuotaChecker.recordUsage error: $e', name: 'brain.quota');
    }
  }

  String _todayUtc() {
    final d = DateTime.now().toUtc();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
