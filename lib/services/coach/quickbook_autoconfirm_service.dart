import 'package:flutter/foundation.dart';
import '../../services/coach/calendar_quick_book_service.dart';
import '../../services/messages_service.dart';

/// Represents a proposed slot that can be auto-confirmed
class ProposedSlot {
  final String conversationId;
  final String clientId;
  final String coachId;
  final DateTime start;
  final Duration duration;
  final DateTime sentAt;
  
  ProposedSlot({
    required this.conversationId,
    required this.clientId,
    required this.coachId,
    required this.start,
    required this.duration,
    required this.sentAt,
  });
}

/// Result of an auto-confirmation attempt
class AutoConfirmResult {
  final bool ok;
  final String message;
  
  AutoConfirmResult(this.ok, this.message);
  
  static AutoConfirmResult success(String message) => AutoConfirmResult(true, message);
  static AutoConfirmResult failure(String message) => AutoConfirmResult(false, message);
}

/// Service for auto-confirming QuickBook proposals
class QuickBookAutoConfirmService {
  static final QuickBookAutoConfirmService instance = QuickBookAutoConfirmService._();
  QuickBookAutoConfirmService._();

  final List<ProposedSlot> _recent = [];
  final Duration _proposalTtl = const Duration(hours: 48);
  final MessagesService _messagesService = MessagesService();

  /// Tracks a new proposal for potential auto-confirmation
  void trackProposal(ProposedSlot proposal) {
    _prune();
    // Remove any existing proposal for this conversation (keep latest only)
    _recent.removeWhere((x) => x.conversationId == proposal.conversationId);
    _recent.add(proposal);
  }

  /// Finds the active proposal for a conversation
  ProposedSlot? findActiveProposal(String conversationId) {
    _prune();
    try {
      return _recent.lastWhere((x) => x.conversationId == conversationId);
    } catch (_) {
      return null;
    }
  }

  /// Removes expired proposals
  void _prune() {
    final cutoff = DateTime.now().subtract(_proposalTtl);
    _recent.removeWhere((x) => x.sentAt.isBefore(cutoff));
  }

  /// Checks if text is an affirmative response
  bool isAffirmative(String text) {
    final t = text.trim().toLowerCase();
    const yesList = [
      'yes', 'yep', 'yeah', 'sure', 'confirmed', 'sounds good', 'ok', 'okay', 'oke', 
      'cool', 'let\'s do it', 'lets do it', 'done', 'works', 'i agree', 'i confirm',
      'عندي موافق', 'موافق', 'تمام', 'اي', 'اوكي', // Arabic/Kurdish
      'perfect', 'great', 'excellent', 'sounds perfect', 'that works',
      'book it', 'schedule it', 'confirm', 'accepted', 'approved'
    ];
    return yesList.any((k) => t == k || t.contains(k));
  }

  /// Attempts to auto-confirm a proposal based on client reply
  Future<AutoConfirmResult> confirmIfEligible({
    required String conversationId,
    required String clientId,
    required String coachId,
    required String replyText,
  }) async {
    try {
      // Check if reply is affirmative
      if (!isAffirmative(replyText)) {
        return AutoConfirmResult.failure('Not affirmative.');
      }

      // Find active proposal for this conversation
      final proposal = findActiveProposal(conversationId);
      if (proposal == null) {
        return AutoConfirmResult.failure('No active proposal found.');
      }

      // Verify the proposal is still valid (not expired)
      if (proposal.sentAt.isBefore(DateTime.now().subtract(_proposalTtl))) {
        return AutoConfirmResult.failure('Proposal expired.');
      }

      // Attempt to create hold event
      final holdResult = await CalendarQuickBookService().createHoldEvent(
        clientId: clientId,
        slot: QuickBookSlot(proposal.start, proposal.duration),
      );

      // Send confirmation message
      final confirmationMessage = _buildConfirmationMessage(proposal, holdResult.ok);
      await _sendConfirmationMessage(conversationId, confirmationMessage);

      // Remove the proposal from tracking (it's been consumed)
      _recent.removeWhere((x) => x.conversationId == conversationId);

      return AutoConfirmResult.success('Auto-confirmed.');
    } catch (e) {
      debugPrint('QuickBookAutoConfirmService: Error confirming proposal - $e');
      return AutoConfirmResult.failure('Failed to confirm: $e');
    }
  }

  /// Builds the confirmation message
  String _buildConfirmationMessage(ProposedSlot proposal, bool holdCreated) {
    final formattedTime = _formatDateTime(proposal.start);
    final durationText = proposal.duration.inMinutes == 15 ? '15 min' : '${proposal.duration.inMinutes} min';
    
    var message = '✅ Confirmed: $formattedTime for $durationText.\n';
    
    if (holdCreated) {
      message += 'Calendar hold placed.';
    } else {
      message += 'Hold pending; we\'ll update your invite shortly.';
    }
    
    return message;
  }

  /// Sends confirmation message to the conversation
  Future<void> _sendConfirmationMessage(String conversationId, String message) async {
    try {
      await _messagesService.sendText(
        threadId: conversationId,
        text: message,
      );
    } catch (e) {
      debugPrint('QuickBookAutoConfirmService: Error sending confirmation message - $e');
      // Don't throw - confirmation should still succeed even if message fails
    }
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime dt) {
    final dow = _getDayOfWeek(dt.weekday);
    final year = dt.year;
    final month = _pad(dt.month);
    final day = _pad(dt.day);
    final hour = _pad(dt.hour);
    final minute = _pad(dt.minute);
    
    return '$dow $year-$month-$day $hour:$minute';
  }

  /// Gets day of week abbreviation
  String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Pads single digits with leading zero
  String _pad(int x) => x < 10 ? '0$x' : '$x';

  /// Gets all tracked proposals (for debugging)
  List<ProposedSlot> getAllProposals() {
    _prune();
    return List.from(_recent);
  }

  /// Clears all proposals (for testing)
  void clearAll() {
    _recent.clear();
  }

  /// Checks if a conversation has an active proposal
  bool hasActiveProposal(String conversationId) {
    return findActiveProposal(conversationId) != null;
  }

  /// Gets the count of active proposals
  int getActiveProposalCount() {
    _prune();
    return _recent.length;
  }

  /// Checks if a message is a QuickBook proposal
  bool isProposalMessage(String message) {
    return message.contains('📞 Quick call proposal:') || 
           message.contains('Quick call proposal');
  }

  /// Extracts proposal details from a message (if it's a proposal)
  ProposedSlot? extractProposalFromMessage({
    required String conversationId,
    required String clientId,
    required String coachId,
    required String message,
  }) {
    if (!isProposalMessage(message)) return null;
    
    // This is a simplified extraction - in a real implementation,
    // you might want to parse the actual time from the message
    final now = DateTime.now();
    final start = now.add(const Duration(hours: 1)); // Default to 1 hour from now
    final duration = const Duration(minutes: 15); // Default 15 minutes
    
    return ProposedSlot(
      conversationId: conversationId,
      clientId: clientId,
      coachId: coachId,
      start: start,
      duration: duration,
      sentAt: now,
    );
  }
}
