import 'dart:convert';
import 'ai_client.dart';
import 'ai_cache.dart';
import 'ai_usage_service.dart';
import 'rate_limiter.dart';
import 'model_registry.dart';
import '../billing/plan_access_manager.dart';

class CalendarAI {
  static final AIClient _aiClient = AIClient();
  static final AICache _cache = AICache();
  static final AIUsageService _usageService = AIUsageService.instance;
  static final RateLimiter _rateLimiter = RateLimiter();
  static final ModelRegistry _modelRegistry = ModelRegistry();

  static Future<List<String>> autoTags({
    required String title, 
    String? description
  }) async {
    const task = 'calendar.tagger';
    
    try {
      // AI gating check
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        return _getFallbackTags(title, description);
      }

      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return _getFallbackTags(title, description);
      }
      
      if (!await _usageService.canMakeRequest('chat')) {
        return _getFallbackTags(title, description);
      }

      // Check cache
      final descKey = description ?? '';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: '$title$descKey',
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) {
        try {
          return List<String>.from(json.decode(cached));
        } catch (e) {
          // Fall through to regenerate
        }
      }

      final model = _modelRegistry.modelFor(task);
      
      final descContext = description != null && description.isNotEmpty
        ? '\n\nDescription: $description'
        : '';
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are a calendar tagging assistant. Generate 3-8 relevant tags for the given event.
Focus on:
- Event type (meeting, workout, appointment, etc.)
- Priority level (urgent, important, routine)
- Category (work, personal, health, etc.)
- Time sensitivity (deadline, flexible, etc.)
Return only the tags, one per line, no numbering or formatting.'''
        },
        {
          'role': 'user',
          'content': 'Generate tags for this event:$descContext\n\nTitle: $title'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return _getFallbackTags(title, description);
      }

      // Parse response into list of tags
      final tags = response
          .split('\n')
          .map((line) => line.trim().replaceAll(RegExp(r'^[0-9\-\.\s]+'), '')) // Remove numbering
          .where((line) => line.isNotEmpty && line.length < 20) // Filter out empty or too long tags
          .take(8)
          .toList();

      if (tags.isEmpty) {
        return _getFallbackTags(title, description);
      }

      // Cache successful response
      _cache.set(cacheKey, json.encode(tags));
      
      // Increment usage
      await _usageService.incrementUsage('chat', model);

      return tags;
    } catch (e) {
      return _getFallbackTags(title, description);
    }
  }

  static Future<String> timeSuggestion({required String context}) async {
    const task = 'calendar.time';
    
    try {
      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return 'Unable to suggest time. Please try again.';
      }
      
      if (!await _usageService.canMakeRequest('chat')) {
        return 'AI quota exceeded. Please upgrade your plan.';
      }

      // Check cache
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: context,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      // Use a generic model for time suggestions
      final model = _modelRegistry.modelFor('chat.default');
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are a scheduling assistant. Suggest an appropriate time for the given context.
Consider:
- Event duration (suggest 1 hour if not specified)
- Time of day preferences
- Work hours (9 AM - 6 PM for business events)
- Availability patterns
Return only the suggested time in format: "Day, Time - End Time" (e.g., "Tomorrow, 2:00 PM - 3:00 PM")'''
        },
        {
          'role': 'user',
          'content': 'Suggest a time for: $context'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return 'Unable to suggest time. Please try again.';
      }

      // Cache successful response
      _cache.set(cacheKey, response);
      
      // Increment usage
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return 'Unable to suggest time. Please try again.';
    }
  }

  // Fallback tag generation using simple rules
  static List<String> _getFallbackTags(String title, String? description) {
    final tags = <String>[];
    final text = '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}';
    
    // Event type detection
    if (text.contains('meeting') || text.contains('call') || text.contains('zoom')) {
      tags.add('meeting');
    }
    if (text.contains('workout') || text.contains('exercise') || text.contains('gym')) {
      tags.add('workout');
    }
    if (text.contains('appointment') || text.contains('doctor') || text.contains('medical')) {
      tags.add('appointment');
    }
    if (text.contains('deadline') || text.contains('due') || text.contains('urgent')) {
      tags.add('urgent');
    }
    if (text.contains('review') || text.contains('check-in') || text.contains('progress')) {
      tags.add('review');
    }
    
    // Category detection
    if (text.contains('work') || text.contains('business') || text.contains('project')) {
      tags.add('work');
    }
    if (text.contains('personal') || text.contains('family') || text.contains('friend')) {
      tags.add('personal');
    }
    if (text.contains('health') || text.contains('fitness') || text.contains('nutrition')) {
      tags.add('health');
    }
    
    // Default tags if none detected
    if (tags.isEmpty) {
      tags.addAll(['event', 'scheduled']);
    }
    
    return tags.take(5).toList();
  }
}
