import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/feature_flags.dart';

class ViralAnalyticsService {
  ViralAnalyticsService._();
  static final ViralAnalyticsService I = ViralAnalyticsService._();

  final _db = Supabase.instance.client;

  /// Calculate daily metrics for a specific day
  Future<void> calculateDailyMetrics(DateTime day) async {
    try {
      final isEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.viralAnalytics);
      if (!isEnabled) return;

      final dayStr = DateTime(day.year, day.month, day.day).toIso8601String().substring(0, 10);

      // Get events for the day
      final events = await _db
          .from('viral_events')
          .select()
          .gte('created_at', '${dayStr}T00:00:00Z')
          .lt('created_at', '${day.add(const Duration(days: 1)).toIso8601String().substring(0, 10)}T00:00:00Z');

      final eventList = events as List;
      final totalUsers = (await _db.from('profiles').select('id').count()).count;

      // Calculate metrics
      final shares = eventList.where((e) => e['event_type'] == 'share').length;
      final referrals = eventList.where((e) => e['event_type'] == 'referral').length;
      final views = eventList.where((e) => e['event_type'] == 'view').length;
      final conversions = eventList.where((e) => e['event_type'] == 'conversion').length;

      // Calculate rates
      final sharesPerUser = totalUsers > 0 ? (shares / totalUsers).toStringAsFixed(4) : '0';
      final referralRate = totalUsers > 0 ? (referrals / totalUsers).toStringAsFixed(4) : '0';
      final conversionRate = referrals > 0 ? (conversions / referrals).toStringAsFixed(4) : '0';
      final viewsToShareRatio = views > 0 ? (shares / views).toStringAsFixed(4) : '0';

      // Upsert metrics
      await _upsertMetric(dayStr, 'shares_per_user', double.parse(sharesPerUser));
      await _upsertMetric(dayStr, 'referral_rate', double.parse(referralRate));
      await _upsertMetric(dayStr, 'conversion_rate', double.parse(conversionRate));
      await _upsertMetric(dayStr, 'views_to_share_ratio', double.parse(viewsToShareRatio));
    } catch (e) {
      debugPrint('Failed to calculate daily metrics: $e');
    }
  }

  /// Get trends for the last N days
  Future<List<Map<String, dynamic>>> getTrends({int days = 14}) async {
    try {
      final isEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.viralAnalytics);
      if (!isEnabled) return [];

      final cutoff = DateTime.now().subtract(Duration(days: days));
      final cutoffStr = cutoff.toIso8601String().substring(0, 10);

      final res = await _db
          .from('viral_analytics')
          .select()
          .gte('date', cutoffStr)
          .order('date', ascending: false);

      return (res as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to get trends: $e');
      return [];
    }
  }

  /// Log event from referral
  Future<void> logEventFromReferral({
    required String userId,
    required String referralCode,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final isEnabled = await FeatureFlags.instance.isEnabled(FeatureFlags.viralAnalytics);
      if (!isEnabled) return;

      await _db.from('viral_events').insert({
        'user_id': userId,
        'event_type': 'referral',
        'event_data': {
          'referral_code': referralCode,
          ...?additionalData,
        },
        'source': 'referral_attribution',
      });
    } catch (e) {
      debugPrint('Failed to log referral event: $e');
    }
  }

  /// Upsert a metric value
  Future<void> _upsertMetric(String date, String metricName, double value) async {
    try {
      await _db.from('viral_analytics').upsert({
        'date': date,
        'metric_name': metricName,
        'metric_value': value,
      }, onConflict: 'date,metric_name');
    } catch (e) {
      debugPrint('Failed to upsert metric: $e');
    }
  }
}
