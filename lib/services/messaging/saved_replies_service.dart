import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved reply model
class SavedReply {
  final String id;
  final String title;
  final String content;

  SavedReply({
    required this.id,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
  };

  factory SavedReply.fromJson(Map<String, dynamic> json) => SavedReply(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
  );
}

/// Service for managing saved replies
class SavedRepliesService {
  static final SavedRepliesService _instance = SavedRepliesService._internal();
  factory SavedRepliesService() => _instance;
  SavedRepliesService._internal();

  static const String _storageKey = 'coach_saved_replies';
  List<SavedReply>? _cachedReplies;

  /// Gets list of saved replies
  Future<List<SavedReply>> list() async {
    if (_cachedReplies != null) {
      return _cachedReplies!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _cachedReplies = jsonList.map((json) => SavedReply.fromJson(json)).toList();
      } else {
        // Initialize with default replies
        _cachedReplies = _getDefaultReplies();
        await _saveToStorage();
      }
      
      return _cachedReplies!;
    } catch (e) {
      print('SavedRepliesService: Error loading replies - $e');
      // Fallback to default replies
      _cachedReplies = _getDefaultReplies();
      return _cachedReplies!;
    }
  }

  /// Adds a new saved reply
  Future<void> add(SavedReply reply) async {
    final replies = await list();
    replies.add(reply);
    _cachedReplies = replies;
    await _saveToStorage();
  }

  /// Removes a saved reply by ID
  Future<void> remove(String id) async {
    final replies = await list();
    replies.removeWhere((reply) => reply.id == id);
    _cachedReplies = replies;
    await _saveToStorage();
  }

  /// Updates an existing saved reply
  Future<void> update(SavedReply updatedReply) async {
    final replies = await list();
    final index = replies.indexWhere((reply) => reply.id == updatedReply.id);
    if (index != -1) {
      replies[index] = updatedReply;
      _cachedReplies = replies;
      await _saveToStorage();
    }
  }

  /// Gets default saved replies
  List<SavedReply> _getDefaultReplies() {
    return [
      SavedReply(
        id: 'sleep_nudge',
        title: 'Sleep Nudge',
        content: "Quick nudge on sleep — let's aim for 7–8h tonight. Short evening wind-down and screens off 60m before bed. How does that sound?",
      ),
      SavedReply(
        id: 'steps_nudge',
        title: 'Steps Nudge',
        content: "Let's add two 10–15 min walks today to hit your step goal. Can you fit one after lunch and one this evening?",
      ),
      SavedReply(
        id: 'missed_session',
        title: 'Missed Session',
        content: "Missed a session happens. Want a 15-min check-in to re-plan this week or prefer a light at-home session I can send?",
      ),
      SavedReply(
        id: 'checkin_reminder',
        title: 'Check-in Reminder',
        content: "Haven't seen a check-in this week — want to send quick photos + notes now, or book a 15-min catch-up?",
      ),
      SavedReply(
        id: 'positive_reinforcement',
        title: 'Positive Reinforcement',
        content: "Great work this week! Your consistency is really paying off. Keep up the amazing progress!",
      ),
      SavedReply(
        id: 'energy_balance',
        title: 'Energy Balance',
        content: "Energy deficit looks high recently. Any fatigue or appetite changes? We can add a refeed or adjust training.",
      ),
      SavedReply(
        id: 'quick_checkin',
        title: 'Quick Check-in',
        content: "Quick check-in — how are things going? Let me know if you need any adjustments to your plan.",
      ),
      SavedReply(
        id: 'form_focus',
        title: 'Form Focus',
        content: "Let's focus on form in your next session. Quality over quantity — I'll send some technique tips.",
      ),
    ];
  }

  /// Saves replies to storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_cachedReplies!.map((reply) => reply.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('SavedRepliesService: Error saving replies - $e');
    }
  }

  /// Clears all saved replies (resets to defaults)
  Future<void> clearAll() async {
    _cachedReplies = _getDefaultReplies();
    await _saveToStorage();
  }

  /// Clears cache (forces reload from storage)
  void clearCache() {
    _cachedReplies = null;
  }
}
