// lib/services/settings/user_prefs_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../workout/exercise_local_log_service.dart';

/// Service for managing user preferences for workout popout defaults
/// and per-exercise sticky choices
class UserPrefsService {
  static final UserPrefsService instance = UserPrefsService._();
  UserPrefsService._();

  SharedPreferences? _prefs;
  final ValueNotifier<int> _prefsVersion = ValueNotifier<int>(0);

  /// Initialize the service and load preferences
  Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
  }

  /// Notifier for preference changes
  ValueNotifier<int> get prefsVersion => _prefsVersion;

  /// Increment version to notify listeners
  void _notifyChange() {
    _prefsVersion.value++;
  }

  // Global defaults
  bool get hapticsEnabled {
    return _prefs?.getBool('prefs::hapticsEnabled') ?? true;
  }

  Future<void> setHapticsEnabled(bool value) async {
    await _prefs?.setBool('prefs::hapticsEnabled', value);
    _notifyChange();
  }

  bool get tempoCuesEnabled {
    return _prefs?.getBool('prefs::tempoCuesEnabled') ?? true;
  }

  Future<void> setTempoCuesEnabled(bool value) async {
    await _prefs?.setBool('prefs::tempoCuesEnabled', value);
    _notifyChange();
  }

  bool get autoAdvanceSupersets {
    return _prefs?.getBool('prefs::autoAdvanceSupersets') ?? true;
  }

  Future<void> setAutoAdvanceSupersets(bool value) async {
    await _prefs?.setBool('prefs::autoAdvanceSupersets', value);
    _notifyChange();
  }

  String get defaultUnit {
    return _prefs?.getString('prefs::defaultUnit') ?? 'kg';
  }

  Future<void> setDefaultUnit(String value) async {
    if (value == 'kg' || value == 'lb') {
      await _prefs?.setString('prefs::defaultUnit', value);
      _notifyChange();
    }
  }

  bool get showQuickNoteCard {
    return _prefs?.getBool('prefs::showQuickNoteCard') ?? true;
  }

  Future<void> setShowQuickNoteCard(bool value) async {
    await _prefs?.setBool('prefs::showQuickNoteCard', value);
    _notifyChange();
  }

  bool get showWorkingSetsFirst {
    return _prefs?.getBool('prefs::showWorkingSetsFirst') ?? true;
  }

  Future<void> setShowWorkingSetsFirst(bool value) async {
    await _prefs?.setBool('prefs::showWorkingSetsFirst', value);
    _notifyChange();
  }

  // Feature flags for coach UI simplification
  bool get showAIInsights {
    return _prefs?.getBool('prefs::showAIInsights') ?? true;
  }

  Future<void> setShowAIInsights(bool value) async {
    await _prefs?.setBool('prefs::showAIInsights', value);
    _notifyChange();
  }

  bool get showMiniDayCards {
    return _prefs?.getBool('prefs::showMiniDayCards') ?? true;
  }

  Future<void> setShowMiniDayCards(bool value) async {
    await _prefs?.setBool('prefs::showMiniDayCards', value);
    _notifyChange();
  }

  // Per-exercise sticky preferences
  Map<String, dynamic> getStickyFor(String exerciseKey) {
    try {
      final jsonString = _prefs?.getString('prefs::sticky::$exerciseKey');
      if (jsonString == null || jsonString.isEmpty) return {};
      
      final Map<String, dynamic> sticky = jsonDecode(jsonString);
      return _validateStickySchema(sticky);
    } catch (e) {
      debugPrint('Error loading sticky for $exerciseKey: $e');
      return {};
    }
  }

  Future<void> setStickyFor(String exerciseKey, Map<String, dynamic> json) async {
    try {
      // Validate and normalize the sticky data
      final normalized = _normalizeStickyData(json);
      
      // Check size limits
      final jsonString = jsonEncode(normalized);
      if (jsonString.length > 1536) { // 1.5KB limit
        debugPrint('Sticky data too large for $exerciseKey, skipping save');
        return;
      }

      await _prefs?.setString('prefs::sticky::$exerciseKey', jsonString);
      _notifyChange();
    } catch (e) {
      debugPrint('Error saving sticky for $exerciseKey: $e');
    }
  }

  /// Validate sticky schema and return only valid fields
  Map<String, dynamic> _validateStickySchema(Map<String, dynamic> sticky) {
    final valid = <String, dynamic>{};
    
    // Unit validation
    if (sticky['unit'] == 'kg' || sticky['unit'] == 'lb') {
      valid['unit'] = sticky['unit'];
    }
    
    // Bar weight validation
    if (sticky['barWeight'] is num) {
      final weight = (sticky['barWeight'] as num).toDouble();
      if (weight > 0 && weight <= 1000) {
        valid['barWeight'] = weight;
      }
    }
    
    // Set type validation
    if (sticky['setType'] is String) {
      final setTypeStr = sticky['setType'] as String;
      try {
        final setType = SetType.values.firstWhere((e) => e.name == setTypeStr);
        valid['setType'] = setTypeStr;
        
        // Advanced set type fields
        if (setType == SetType.drop) {
          if (sticky['dropWeights'] is List) {
            final weights = (sticky['dropWeights'] as List)
                .map((e) => (e as num?)?.toDouble())
                .where((e) => e != null && e > 0)
                .cast<double>()
                .take(4)
                .toList();
            if (weights.isNotEmpty) valid['dropWeights'] = weights;
          }
          if (sticky['dropPercents'] is List) {
            final percents = (sticky['dropPercents'] as List)
                .map((e) => (e as num?)?.toDouble())
                .where((e) => e != null && e < 0)
                .cast<double>()
                .take(4)
                .toList();
            if (percents.isNotEmpty) valid['dropPercents'] = percents;
          }
        } else if (setType == SetType.restPause) {
          if (sticky['rpBursts'] is List) {
            final bursts = (sticky['rpBursts'] as List)
                .map((e) => (e as num?)?.toInt())
                .where((e) => e != null && e > 0)
                .cast<int>()
                .toList();
            if (bursts.isNotEmpty) valid['rpBursts'] = bursts;
          }
          if (sticky['rpRestSec'] is num) {
            final restSec = (sticky['rpRestSec'] as num).toInt().clamp(5, 60);
            valid['rpRestSec'] = restSec;
          }
        } else if (setType == SetType.cluster) {
          if (sticky['clusterSize'] is num) {
            final size = (sticky['clusterSize'] as num).toInt().clamp(2, 6);
            valid['clusterSize'] = size;
          }
          if (sticky['clusterRestSec'] is num) {
            final restSec = (sticky['clusterRestSec'] as num).toInt().clamp(5, 60);
            valid['clusterRestSec'] = restSec;
          }
          if (sticky['clusterTotalReps'] is num) {
            final totalReps = (sticky['clusterTotalReps'] as num).toInt().clamp(6, 50);
            valid['clusterTotalReps'] = totalReps;
          }
        }
      } catch (_) {
        // Invalid setType, ignore
      }
    }
    
    return valid;
  }

  /// Normalize sticky data before saving
  Map<String, dynamic> _normalizeStickyData(Map<String, dynamic> json) {
    final normalized = <String, dynamic>{};
    
    // Only include valid keys
    final validKeys = {
      'unit', 'barWeight', 'setType', 'dropWeights', 'dropPercents',
      'rpBursts', 'rpRestSec', 'clusterSize', 'clusterRestSec', 'clusterTotalReps'
    };
    
    for (final key in validKeys) {
      if (json.containsKey(key) && json[key] != null) {
        normalized[key] = json[key];
      }
    }
    
    return normalized;
  }

  /// Clear all sticky preferences (for testing/debugging)
  Future<void> clearAllSticky() async {
    final keys = _prefs?.getKeys() ?? {};
    final stickyKeys = keys.where((key) => key.startsWith('prefs::sticky::'));
    
    for (final key in stickyKeys) {
      await _prefs?.remove(key);
    }
    _notifyChange();
  }

  /// Get total preferences size (for monitoring)
  int getTotalPrefsSize() {
    final keys = _prefs?.getKeys() ?? {};
    int totalSize = 0;
    
    for (final key in keys) {
      if (key.startsWith('prefs::')) {
        final value = _prefs?.getString(key) ?? '';
        totalSize += key.length + value.length;
      }
    }
    
    return totalSize;
  }
}
