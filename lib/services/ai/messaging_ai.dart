import 'dart:convert';
import 'ai_client.dart';
import 'ai_cache.dart';
import 'ai_usage_service.dart';
import 'rate_limiter.dart';
import 'model_registry.dart';
import '../billing/plan_access_manager.dart';

class MessagingAI {
  static final AIClient _aiClient = AIClient();
  static final AICache _cache = AICache();
  static final AIUsageService _usageService = AIUsageService.instance;
  static final RateLimiter _rateLimiter = RateLimiter();
  static final ModelRegistry _modelRegistry = ModelRegistry();

  static Future<List<String>> smartReplies({
    required String lastMessage, 
    String? threadContext
  }) async {
    const task = 'messaging.reply';
    
    try {
      // AI gating check
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        return ['AI quota exceeded. Please upgrade your plan.'];
      }

      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return ['Rate limit exceeded. Please wait a moment.'];
      }
      
      if (!await _usageService.canMakeRequest('chat')) {
        return ['AI quota exceeded. Please upgrade your plan.'];
      }

      // Check cache
      final contextKey = threadContext ?? '';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: '$lastMessage$contextKey',
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
      
      final contextPrompt = threadContext != null && threadContext.isNotEmpty
        ? '\n\nThread context: $threadContext'
        : '';
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are a helpful AI assistant. Generate 3-5 concise, professional reply suggestions for the given message.
Keep replies:
- Under 50 words each
- Professional and helpful
- Varied in tone (supportive, informative, action-oriented)
- Relevant to the message content
Return only the reply text, one per line.'''
        },
        {
          'role': 'user',
          'content': 'Generate smart replies for this message:$contextPrompt\n\nMessage: $lastMessage'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return ['Unable to generate replies. Please try again.'];
      }

      // Parse response into list of replies
      final replies = response
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .take(5)
          .toList();

      if (replies.isEmpty) {
        return ['Thanks!', 'Got it.', 'I understand.'];
      }

      // Cache successful response
      _cache.set(cacheKey, json.encode(replies));
      
      // Increment usage
      await _usageService.incrementUsage('chat', model);

      return replies;
    } catch (e) {
      return ['Thanks!', 'Got it.', 'I understand.'];
    }
  }

  static Future<String> translate({
    required String text, 
    required String targetLang
  }) async {
    const task = 'messaging.translate';
    
    try {
      // Simple heuristic to avoid re-translating
      if (_isLikelySameLanguage(text, targetLang)) {
        return text; // Return original if likely same language
      }

      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return 'Rate limit exceeded. Please wait a moment.';
      }
      
      if (!await _usageService.canMakeRequest('chat')) {
        return 'AI quota exceeded. Please upgrade your plan.';
      }

      // Check cache
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: '$text$targetLang',
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are a translation assistant. Translate the given text to the specified language.
Return only the translated text, nothing else.
Maintain the original tone and meaning.'''
        },
        {
          'role': 'user',
          'content': 'Translate this text to $targetLang:\n\n$text'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return 'Translation unavailable. Please try again.';
      }

      // Cache successful response
      _cache.set(cacheKey, response);
      
      // Increment usage
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return 'Translation failed. Please try again.';
    }
  }

  static Future<String> summarizeThread({required String threadText}) async {
    const task = 'messaging.summarize';
    
    try {
      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return 'Rate limit exceeded. Please wait a moment.';
      }
      
      if (!await _usageService.canMakeRequest('chat')) {
        return 'AI quota exceeded. Please upgrade your plan.';
      }

      // Check cache
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: threadText,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      // Use notes.summarize model if available, otherwise fallback
      final model = _modelRegistry.modelFor('notes.summarize');
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are a summarization assistant. Create a concise summary of the conversation thread.
Focus on:
- Key points discussed
- Action items mentioned
- Important decisions made
Keep the summary under 100 words.'''
        },
        {
          'role': 'user',
          'content': 'Summarize this conversation thread:\n\n$threadText'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return 'Unable to summarize thread. Please try again.';
      }

      // Cache successful response
      _cache.set(cacheKey, response);
      
      // Increment usage
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return 'Unable to summarize thread. Please try again.';
    }
  }

  // Simple language detection heuristic
  static bool _isLikelySameLanguage(String text, String targetLang) {
    // Very basic heuristic - could be improved
    final commonEnglishWords = ['the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'];
    final commonSpanishWords = ['el', 'la', 'de', 'que', 'y', 'a', 'en', 'un', 'es', 'se', 'no', 'te'];
    final commonFrenchWords = ['le', 'la', 'de', 'et', 'à', 'en', 'un', 'est', 'il', 'ne', 'pas', 'vous'];
    
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final englishCount = words.where((w) => commonEnglishWords.contains(w)).length;
    final spanishCount = words.where((w) => commonSpanishWords.contains(w)).length;
    final frenchCount = words.where((w) => commonFrenchWords.contains(w)).length;
    
    if (targetLang.toLowerCase().contains('english') && englishCount > 2) return true;
    if (targetLang.toLowerCase().contains('spanish') && spanishCount > 2) return true;
    if (targetLang.toLowerCase().contains('french') && frenchCount > 2) return true;
    
    return false;
  }

}
