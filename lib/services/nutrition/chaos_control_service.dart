import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/digestion_models.dart';
import 'dart:convert';

class ChaosControlService {
  ChaosControlService._();
  static final ChaosControlService I = ChaosControlService._();

  final _db = Supabase.instance.client;

  Future<String> enableMode({
    required String userId,
    required ChaosMode mode,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    String? nutritionPlanId,
    Map<String, dynamic>? adaptedMacros,
    String? notes,
  }) async {
    final res = await _db.from('travel_modes').insert({
      'user_id': userId,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate?.toIso8601String().substring(0, 10),
      'mode': mode.toDb(),
      'location': location,
      'nutrition_plan_id': nutritionPlanId,
      'adapted_macros': adaptedMacros != null ? jsonEncode(adaptedMacros) : null,
      'notes': notes,
    }).select('id').single();

    return res['id'] as String;
  }

  Future<TravelModeEntry?> getActiveMode({
    required String userId,
  }) async {
    final now = DateTime.now();
    final res = await _db
        .from('travel_modes')
        .select()
        .eq('user_id', userId)
        .lte('start_date', now.toIso8601String().substring(0, 10))
        .or('end_date.is.null,end_date.gte.${now.toIso8601String().substring(0, 10)}')
        .order('start_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;
    return TravelModeEntry.fromJson(res);
  }

  Future<void> endActiveMode({
    required String userId,
  }) async {
    final active = await getActiveMode(userId: userId);
    if (active == null) return;

    await _db
        .from('travel_modes')
        .update({'end_date': DateTime.now().toIso8601String().substring(0, 10)})
        .eq('id', active.id);
  }

  Future<ChaosControlSettings> getSettings({
    required String userId,
  }) async {
    final res = await _db
        .from('chaos_control_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) {
      // Create default settings
      final defaultSettings = ChaosControlSettings(
        id: 'temp',
        userId: userId,
        autoAdaptOnChaos: true,
        chaosDetectionEnabled: true,
        travelModeAutoEnable: true,
        createdAt: DateTime.now(),
      );
      await upsertSettings(defaultSettings);
      return getSettings(userId: userId);
    }

    return ChaosControlSettings.fromJson(res);
  }

  Future<void> upsertSettings(ChaosControlSettings settings) async {
    await _db.from('chaos_control_settings').upsert(
      settings.toInsertJson(),
      onConflict: 'user_id',
    );
  }

  Map<String, dynamic> adaptMacros({
    required Map<String, dynamic> baseMacros,
    required ChaosMode mode,
  }) {
    final adapted = Map<String, dynamic>.from(baseMacros);

    switch (mode) {
      case ChaosMode.travel:
        // Reduce precision, focus on protein
        if (adapted.containsKey('protein')) {
          adapted['protein'] = (adapted['protein'] as num) * 0.9; // 10% reduction
        }
        if (adapted.containsKey('carbs')) {
          adapted['carbs'] = (adapted['carbs'] as num) * 0.85; // 15% reduction
        }
        adapted['flexibility'] = 'high';
        break;

      case ChaosMode.chaos:
        // More flexible, maintain protein minimum
        if (adapted.containsKey('protein')) {
          final minProtein = (adapted['protein'] as num) * 0.8;
          adapted['protein_min'] = minProtein;
        }
        adapted['flexibility'] = 'very_high';
        break;

      case ChaosMode.restDay:
        // Slight reduction across the board
        adapted.forEach((key, value) {
          if (value is num && key != 'calories') {
            adapted[key] = value * 0.9;
          }
        });
        break;

      case ChaosMode.normal:
        // No changes
        break;
    }

    adapted['adapted_for'] = mode.toDb();
    adapted['adapted_at'] = DateTime.now().toIso8601String();

    return adapted;
  }
}
