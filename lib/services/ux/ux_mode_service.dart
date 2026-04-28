import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The three interface complexity tiers.
/// Ordering matters: simple < default_ < insane (use .index for comparison).
enum UxMode { simple, default_, insane }

extension UxModeOps on UxMode {
  bool operator >=(UxMode other) => index >= other.index;
  bool operator <=(UxMode other) => index <= other.index;
  bool operator >(UxMode other) => index > other.index;
  bool operator <(UxMode other) => index < other.index;

  String get label {
    switch (this) {
      case UxMode.simple:
        return 'Simple';
      case UxMode.default_:
        return 'Default';
      case UxMode.insane:
        return 'Insane';
    }
  }

  String get description {
    switch (this) {
      case UxMode.simple:
        return 'Essential tiles only — great for new users';
      case UxMode.default_:
        return 'Full feature set, standard layout';
      case UxMode.insane:
        return 'Dense power-user layout with all expert metrics';
    }
  }
}

/// Core service for the adaptive UX engine.
///
/// Responsibilities:
/// - Accumulate foreground usage hours via session start/end calls.
/// - Compute the auto mode from usage hours (Simple/Default/Insane).
/// - Persist a user override in the user_settings table.
/// - Detect demotion eligibility (30 days without advanced feature use).
/// - Sync usage hours to Supabase so the server can see them too.
class UxModeService {
  static final UxModeService instance = UxModeService._();
  UxModeService._();

  // SharedPreferences keys
  static const String _kUsageHours = 'ux_usage_hours';
  static const String _kSessionStartMs = 'ux_session_start_ms';
  static const String _kPromotionSeenAt = 'ux_promotion_seen_at';

  // Thresholds
  static const double simpleToDefaultHours = 5.0;
  static const double defaultToInsaneHours = 50.0;
  static const int demotionDays = 30;

  final _supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Mode resolution
  // ---------------------------------------------------------------------------

  /// Returns the resolved mode tuple for the current user.
  Future<({UxMode effective, UxMode auto, UxMode? override})> loadMode() async {
    final hours = await getUsageHours();
    final auto = computeAutoMode(hours);
    final override = await _loadOverride();
    return (effective: override ?? auto, auto: auto, override: override);
  }

  UxMode computeAutoMode(double hours) {
    if (hours >= defaultToInsaneHours) return UxMode.insane;
    if (hours >= simpleToDefaultHours) return UxMode.default_;
    return UxMode.simple;
  }

  // ---------------------------------------------------------------------------
  // Usage hour tracking
  // ---------------------------------------------------------------------------

  Future<double> getUsageHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kUsageHours) ?? 0.0;
  }

  /// Override usage hours (useful for QA / debug).
  Future<void> setUsageHoursForTesting(double hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kUsageHours, hours);
    await _syncHoursToSupabase(hours);
  }

  Future<void> onSessionStart() async {
    final prefs = await SharedPreferences.getInstance();
    // Only record start if there isn't one already (resume vs cold start).
    if (!prefs.containsKey(_kSessionStartMs)) {
      await prefs.setInt(
        _kSessionStartMs,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Called when the app goes to background or closes.
  /// Returns the new cumulative usage hours.
  Future<double> onSessionEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_kSessionStartMs);
    if (startMs == null) return await getUsageHours();

    final elapsedH =
        (DateTime.now().millisecondsSinceEpoch - startMs) / 3_600_000.0;
    final current = prefs.getDouble(_kUsageHours) ?? 0.0;
    final newTotal = current + elapsedH;

    await prefs.setDouble(_kUsageHours, newTotal);
    await prefs.remove(_kSessionStartMs);
    unawaited(_syncHoursToSupabase(newTotal));

    return newTotal;
  }

  // ---------------------------------------------------------------------------
  // Override persistence
  // ---------------------------------------------------------------------------

  Future<void> saveOverride(UxMode? mode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('user_settings').upsert({
        'user_id': user.id,
        'ux_mode_override': mode?.name,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('UxModeService: failed to save override: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Advanced-feature demotion tracking
  // ---------------------------------------------------------------------------

  Future<void> recordAdvancedFeatureUse() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('user_settings').upsert({
        'user_id': user.id,
        'ux_last_advanced_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('UxModeService: failed to record advanced use: $e');
    }
  }

  Future<bool> shouldSuggestDemotion(UxMode currentMode) async {
    if (currentMode < UxMode.insane) return false;
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    try {
      final row = await _supabase
          .from('user_settings')
          .select('ux_last_advanced_at')
          .eq('user_id', user.id)
          .maybeSingle();
      final raw = row?['ux_last_advanced_at'] as String?;
      if (raw == null) return false;
      final daysSince = DateTime.now().difference(DateTime.parse(raw)).inDays;
      return daysSince >= demotionDays;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Promotion snooze tracking (stored locally — only presentational)
  // ---------------------------------------------------------------------------

  Future<bool> hasSeenPromotion(UxMode fromMode, UxMode toMode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_kPromotionSeenAt}_${fromMode.name}_${toMode.name}';
    return prefs.containsKey(key);
  }

  Future<void> markPromotionSeen(UxMode fromMode, UxMode toMode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_kPromotionSeenAt}_${fromMode.name}_${toMode.name}';
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<UxMode?> _loadOverride() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final row = await _supabase
          .from('user_settings')
          .select('ux_mode_override')
          .eq('user_id', user.id)
          .maybeSingle();
      final raw = row?['ux_mode_override'] as String?;
      if (raw == null) return null;
      return UxMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => UxMode.default_,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncHoursToSupabase(double hours) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('user_settings').upsert({
        'user_id': user.id,
        'ux_usage_hours': hours,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('UxModeService: failed to sync hours: $e');
    }
  }
}
