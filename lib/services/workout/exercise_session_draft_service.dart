// lib/services/workout/exercise_session_draft_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseSessionDraftService {
  static final ExerciseSessionDraftService instance = ExerciseSessionDraftService._();
  ExerciseSessionDraftService._();

  String _key(String clientId, String exerciseKey, DateTime day) {
    final d = DateTime(day.year, day.month, day.day).toIso8601String();
    return 'exdraft::$clientId::$exerciseKey::$d';
    // stores a JSON with { "text": "...", "createdAt": isoString }
  }

  Future<void> save({
    required String clientId,
    required String exerciseKey,
    required DateTime day,
    required String text,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({'text': text, 'createdAt': DateTime.now().toIso8601String()});
    await prefs.setString(_key(clientId, exerciseKey, day), payload);
  }

  Future<String?> load({
    required String clientId,
    required String exerciseKey,
    required DateTime day,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(clientId, exerciseKey, day));
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (j['text'] as String?) ?? '';
    } catch (_) {
      return null;
    }
  }

  Future<void> clear({
    required String clientId,
    required String exerciseKey,
    required DateTime day,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(clientId, exerciseKey, day));
  }
}
