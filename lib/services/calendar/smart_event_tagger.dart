import '../ai/calendar_ai.dart';
import '../config/feature_flags.dart';
import '../core/logger.dart';

/// AI-powered event tag suggestions
///
/// Suggests contextual tags based on event title and notes
class SmartEventTagger {
  static final SmartEventTagger _instance = SmartEventTagger._internal();
  static SmartEventTagger get instance => _instance;
  SmartEventTagger._internal();

  final CalendarAI _calendarAI = CalendarAI.instance;

  /// Suggest tags for an event
  Future<List<String>> suggestTags(
    String title, 
    String? notes,
  ) async {
    try {
      // Check feature flag
      final enabled = await FeatureFlags.instance.isEnabled(
        FeatureFlags.calendarAI,
        defaultValue: false,
      );
      
      if (!enabled) {
        Logger.debug('Calendar AI disabled, returning empty tags');
        return [];
      }

      final combinedText = '${title.trim()}\n${(notes ?? '').trim()}';
      
      if (combinedText.trim().isEmpty) {
        return [];
      }

      final tags = await _calendarAI.suggestEventTags(combinedText);
      
      Logger.info('AI suggested tags', data: {
        'title': title,
        'tagCount': tags.length,
      });

      return tags;
    } catch (e, st) {
      Logger.error(
        'Failed to suggest event tags',
        error: e,
        stackTrace: st,
        data: {'title': title},
      );
      return _getFallbackTags(title, notes);
    }
  }

  /// Simple fallback tag suggestions without AI
  List<String> _getFallbackTags(String title, String? notes) {
    final tags = <String>[];
    final combined = '${title.toLowerCase()} ${(notes ?? '').toLowerCase()}';

    // Simple keyword matching
    if (combined.contains('workout') || combined.contains('training')) {
      tags.add('workout');
    }
    if (combined.contains('meeting') || combined.contains('call')) {
      tags.add('meeting');
    }
    if (combined.contains('session') || combined.contains('coaching')) {
      tags.add('coaching');
    }
    if (combined.contains('nutrition') || combined.contains('meal')) {
      tags.add('nutrition');
    }
    if (combined.contains('check-in') || combined.contains('checkin')) {
      tags.add('check-in');
    }

    return tags.take(3).toList();
  }

  /// Get popular tags from existing events (for autocomplete)
  Future<List<String>> getPopularTags({int limit = 10}) async {
    // This would query the database for most common tags
    // For now, return common tags
    return [
      'workout',
      'coaching',
      'meeting',
      'check-in',
      'nutrition',
      'planning',
      'assessment',
      'review',
      'consultation',
      'training',
    ];
  }
}

