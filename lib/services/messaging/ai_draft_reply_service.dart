import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

/// Service for generating AI-powered draft replies in messaging
class AIDraftReplyService {
  static final AIDraftReplyService _instance = AIDraftReplyService._internal();
  factory AIDraftReplyService() => _instance;
  AIDraftReplyService._internal();

  // Cache for draft replies per conversation
  final Map<String, _CachedDrafts> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 1);

  /// Gets AI draft replies for a conversation
  /// 
  /// [conversationId] - ID of the conversation
  /// [lastMessage] - The most recent message from the other party
  /// [role] - 'coach' or 'client' to determine response style
  Future<List<String>> getDraftReplies({
    required String conversationId,
    required String lastMessage,
    String role = 'coach',
  }) async {
    // Check cache first
    if (_cache.containsKey(conversationId) && _isCacheValid(conversationId)) {
      return _cache[conversationId]!.drafts;
    }

    try {
      // Get conversation context (last 3 messages)
      final context = await _getConversationContext(conversationId);
      
      // Try AI generation first, fallback to heuristics
      List<String> drafts;
      try {
        drafts = await _generateAIDrafts(lastMessage, context, role);
      } catch (e) {
        print('AIDraftReplyService: AI generation failed, using heuristics - $e');
        drafts = _generateHeuristicDrafts(lastMessage, role);
      }

      // Cache the results
      _cache[conversationId] = _CachedDrafts(
        drafts: drafts,
        timestamp: DateTime.now(),
      );

      return drafts;
    } catch (e) {
      print('AIDraftReplyService: Error generating drafts - $e');
      return _generateHeuristicDrafts(lastMessage, role);
    }
  }

  /// Gets conversation context (last 3 messages)
  Future<List<Map<String, dynamic>>> _getConversationContext(String conversationId) async {
    try {
      final response = await _sb
          .from('messages')
          .select('content, sender_id, created_at, sender_role')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(3);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      print('AIDraftReplyService: Error fetching conversation context - $e');
      return [];
    }
  }

  /// Generates AI-powered draft replies
  Future<List<String>> _generateAIDrafts(
    String lastMessage,
    List<Map<String, dynamic>> context,
    String role,
  ) async {
    // This is where you would integrate with your AI gateway
    // For now, we'll simulate AI responses based on message content
    
    final messageLower = lastMessage.toLowerCase();
    final drafts = <String>[];

    // Analyze message content and generate contextual responses
    if (messageLower.contains('workout') || messageLower.contains('training')) {
      if (role == 'coach') {
        drafts.addAll([
          "Great work on your training! How are you feeling?",
          "Let's adjust your next session based on your progress.",
          "Keep up the consistency - you're doing amazing!",
        ]);
      } else {
        drafts.addAll([
          "Thanks! I'm feeling strong today.",
          "The workout was challenging but I pushed through.",
          "I have some questions about my form.",
        ]);
      }
    } else if (messageLower.contains('nutrition') || messageLower.contains('diet') || messageLower.contains('food')) {
      if (role == 'coach') {
        drafts.addAll([
          "How's your nutrition tracking going?",
          "Remember to stay hydrated throughout the day.",
          "Let's review your meal plan for this week.",
        ]);
      } else {
        drafts.addAll([
          "I've been tracking my meals consistently.",
          "I'm struggling with meal prep this week.",
          "My energy levels have been great!",
        ]);
      }
    } else if (messageLower.contains('sleep') || messageLower.contains('rest')) {
      if (role == 'coach') {
        drafts.addAll([
          "Sleep is crucial for recovery. How many hours did you get?",
          "Let's work on improving your sleep routine.",
          "Quality rest will help your performance.",
        ]);
      } else {
        drafts.addAll([
          "I got 7 hours last night.",
          "I've been having trouble sleeping lately.",
          "My sleep has been much better this week.",
        ]);
      }
    } else if (messageLower.contains('pain') || messageLower.contains('hurt') || messageLower.contains('injury')) {
      if (role == 'coach') {
        drafts.addAll([
          "I'm concerned about that. Let's take it easy today.",
          "Please rest and let me know how you feel tomorrow.",
          "We should modify your training until this improves.",
        ]);
      } else {
        drafts.addAll([
          "I'll take it easy and rest today.",
          "It's not too bad, just a little sore.",
          "I think I need to see a doctor.",
        ]);
      }
    } else if (messageLower.contains('progress') || messageLower.contains('results')) {
      if (role == 'coach') {
        drafts.addAll([
          "Your progress has been incredible! Keep it up!",
          "I'm proud of your dedication and consistency.",
          "Let's celebrate this milestone together!",
        ]);
      } else {
        drafts.addAll([
          "Thank you! I'm really seeing the results.",
          "I'm excited to see what's next.",
          "I couldn't have done it without your guidance.",
        ]);
      }
    } else {
      // Generic responses based on role
      if (role == 'coach') {
        drafts.addAll([
          "Thanks for the update! How can I help?",
          "I appreciate you keeping me in the loop.",
          "Let's discuss this in more detail.",
        ]);
      } else {
        drafts.addAll([
          "Thanks for your support!",
          "I'll keep you updated on my progress.",
          "I have a question about my program.",
        ]);
      }
    }

    // Return 2-3 drafts, prioritizing the most relevant
    return drafts.take(3).toList();
  }

  /// Generates heuristic-based draft replies when AI is unavailable
  List<String> _generateHeuristicDrafts(String lastMessage, String role) {
    if (role == 'coach') {
      return [
        "Thanks for the update! How can I help?",
        "Great job this week! Keep up the consistency.",
        "Let's adjust your next session based on your progress.",
      ];
    } else {
      return [
        "Thanks for your support!",
        "I'll keep you updated on my progress.",
        "I have a question about my program.",
      ];
    }
  }

  /// Checks if cache is still valid
  bool _isCacheValid(String conversationId) {
    final cached = _cache[conversationId];
    if (cached == null) return false;
    return DateTime.now().difference(cached.timestamp) < _cacheExpiry;
  }

  /// Clears cache for a specific conversation
  void clearCache(String conversationId) {
    _cache.remove(conversationId);
  }

  /// Clears all cache
  void clearAllCache() {
    _cache.clear();
  }
}

/// Cached drafts data structure
class _CachedDrafts {
  final List<String> drafts;
  final DateTime timestamp;

  _CachedDrafts({
    required this.drafts,
    required this.timestamp,
  });
}
