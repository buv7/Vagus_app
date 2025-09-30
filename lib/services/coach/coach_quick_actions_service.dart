import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../messages_service.dart';

final _sb = Supabase.instance.client;

/// Result of a quick action operation
class QuickActionResult {
  final bool ok;
  final String message;
  
  QuickActionResult(this.ok, this.message);
  
  static QuickActionResult success(String message) => QuickActionResult(true, message);
  static QuickActionResult failure(String message) => QuickActionResult(false, message);
}

/// Service for coach quick actions and bulk operations
class CoachQuickActionsService {
  static final CoachQuickActionsService _instance = CoachQuickActionsService._internal();
  factory CoachQuickActionsService() => _instance;
  CoachQuickActionsService._internal();

  final MessagesService _messagesService = MessagesService();
  final Set<String> _reviewedClients = {};

  /// Sends a templated nudge message to a client
  Future<QuickActionResult> sendNudgeMessage({
    required String clientId,
    required String reason,
    String? customText,
  }) async {
    try {
      final message = customText ?? _getNudgeTemplate(reason);
      
      // Get or create thread
      final user = _sb.auth.currentUser;
      if (user == null) {
        return QuickActionResult.failure('Not authenticated');
      }

      final threadId = await _messagesService.ensureThread(
        coachId: user.id,
        clientId: clientId,
      );

      // Send message
      await _messagesService.sendText(
        threadId: threadId,
        text: message,
      );

      return QuickActionResult.success('Nudge sent successfully');
    } catch (e) {
      debugPrint('CoachQuickActionsService: Error sending nudge - $e');
      return QuickActionResult.failure('Failed to send nudge: $e');
    }
  }

  /// Creates a quick call proposal and posts to chat
  Future<QuickActionResult> proposeQuickCall({
    required String clientId,
    DateTime? when,
  }) async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        return QuickActionResult.failure('Not authenticated');
      }

      final threadId = await _messagesService.ensureThread(
        coachId: user.id,
        clientId: clientId,
      );

      // Default to next business day 10:00 if not specified
      final callTime = when ?? _getNextBusinessDay10AM();
      
      final message = _getQuickCallTemplate(callTime);

      await _messagesService.sendText(
        threadId: threadId,
        text: message,
      );

      return QuickActionResult.success('Quick call proposed');
    } catch (e) {
      debugPrint('CoachQuickActionsService: Error proposing quick call - $e');
      return QuickActionResult.failure('Failed to propose call: $e');
    }
  }

  /// Suggests a plan tweak and posts note to chat
  Future<QuickActionResult> suggestPlanTweak({
    required String clientId,
    required String tweak,
  }) async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        return QuickActionResult.failure('Not authenticated');
      }

      final threadId = await _messagesService.ensureThread(
        coachId: user.id,
        clientId: clientId,
      );

      final message = _getPlanTweakTemplate(tweak);

      await _messagesService.sendText(
        threadId: threadId,
        text: message,
      );

      return QuickActionResult.success('Plan tweak suggested');
    } catch (e) {
      debugPrint('CoachQuickActionsService: Error suggesting plan tweak - $e');
      return QuickActionResult.failure('Failed to suggest tweak: $e');
    }
  }

  /// Marks a client as reviewed (session-only)
  void markReviewed(String clientId) {
    _reviewedClients.add(clientId);
  }

  /// Checks if a client has been reviewed
  bool isReviewed(String clientId) {
    return _reviewedClients.contains(clientId);
  }

  /// Gets all reviewed client IDs
  Set<String> getReviewedClients() {
    return Set.from(_reviewedClients);
  }

  /// Clears reviewed clients (for new session)
  void clearReviewed() {
    _reviewedClients.clear();
  }

  /// Bulk send nudge messages
  Future<Map<String, QuickActionResult>> bulkSendNudge({
    required List<String> clientIds,
    required String reason,
  }) async {
    final results = <String, QuickActionResult>{};
    
    for (final clientId in clientIds) {
      final result = await sendNudgeMessage(
        clientId: clientId,
        reason: reason,
      );
      results[clientId] = result;
      
      // Small delay between messages to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return results;
  }

  /// Bulk propose quick calls
  Future<Map<String, QuickActionResult>> bulkProposeQuickCall({
    required List<String> clientIds,
  }) async {
    final results = <String, QuickActionResult>{};
    
    for (final clientId in clientIds) {
      final result = await proposeQuickCall(clientId: clientId);
      results[clientId] = result;
      
      // Small delay between messages
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return results;
  }

  /// Gets nudge template based on reason
  String _getNudgeTemplate(String reason) {
    switch (reason) {
      case 'low_sleep':
        return "Quick nudge on sleep — let's aim for 7–8h tonight. Short evening wind-down and screens off 60m before bed. How does that sound?";
      case 'low_steps':
        return 'Let\'s add two 10–15 min walks today to hit your step goal. Can you fit one after lunch and one this evening?';
      case 'missed_session':
        return 'Missed a session happens. Want a 15-min check-in to re-plan this week or prefer a light at-home session I can send?';
      case 'overdue_checkin':
        return 'Haven\'t seen a check-in this week — want to send quick photos + notes now, or book a 15-min catch-up?';
      case 'high_negative_net':
        return 'Energy deficit looks high recently. Any fatigue or appetite changes? We can add a refeed or adjust training.';
      default:
        return 'Quick check-in — how are things going? Let me know if you need any adjustments to your plan.';
    }
  }

  /// Gets quick call template
  String _getQuickCallTemplate(DateTime when) {
    final timeStr = _formatDateTime(when);
    return "📞 Quick call proposal: Let's chat for 15 minutes on $timeStr to discuss your progress. Does this time work for you?";
  }

  /// Gets plan tweak template
  String _getPlanTweakTemplate(String tweak) {
    switch (tweak) {
      case 'reduce_load_10':
        return '💡 Coach suggests: Let\'s reduce next session load by 10% to focus on form and recovery. How does that sound?';
      case 'add_walk_15':
        return '💡 Coach suggests: Add a 15-minute walk to your next session for extra cardio. Ready to try it?';
      case 'swap_rest_day':
        return '💡 Coach suggests: Let\'s swap your next session for a rest day to prioritize recovery. Sound good?';
      default:
        return '💡 Coach suggests: Let\'s make a small adjustment to your next session. I\'ll send details shortly.';
    }
  }

  /// Gets next business day at 10:00 AM
  DateTime _getNextBusinessDay10AM() {
    final now = DateTime.now();
    var nextDay = now.add(const Duration(days: 1));
    
    // Skip weekends (Saturday = 6, Sunday = 7)
    while (nextDay.weekday == 6 || nextDay.weekday == 7) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    
    return DateTime(nextDay.year, nextDay.month, nextDay.day, 10, 0);
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (target == today) {
      return 'today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (target == today.add(const Duration(days: 1))) {
      return 'tomorrow at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
