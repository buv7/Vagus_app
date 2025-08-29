import 'dart:convert';

import 'ai_client.dart';
import 'ai_cache.dart';
import 'ai_usage_service.dart';
import 'rate_limiter.dart';
import 'model_registry.dart';
import '../billing/plan_access_manager.dart';

class WorkoutAI {
  static final AIClient _aiClient = AIClient();
  static final AICache _cache = AICache();
  static final AIUsageService _usageService = AIUsageService.instance;
  static final RateLimiter _rateLimiter = RateLimiter();
  static final ModelRegistry _modelRegistry = ModelRegistry();

  static Future<String> suggestProgression({required String planJson}) async {
    const task = 'workout.suggest';
    
    try {
      // AI gating check
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        return 'AI quota exceeded. Please upgrade your plan or try again later.';
      }

      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return 'Rate limit exceeded. Please wait a moment before trying again.';
      }
      
      if (!await _usageService.canMakeRequest('chat')) {
        return 'AI quota exceeded. Please upgrade your plan or try again later.';
      }

      // Check cache
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: planJson,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are a fitness coach AI. Analyze the workout plan and suggest specific progression strategies.
Focus on:
- Exercise selection improvements
- Weight/rep progression schemes
- Volume adjustments
- Recovery considerations
Keep suggestions practical and actionable.'''
        },
        {
          'role': 'user',
          'content': 'Analyze this workout plan and suggest progression strategies:\n\n$planJson'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response; // Error message from AI client
      }

      // Cache successful response
      _cache.set(cacheKey, response);
      
      // Increment usage
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return 'Unable to generate progression suggestions. Please try again.';
    }
  }

  static Future<String> deloadAdvice({
    required String planJson, 
    Map<String, dynamic>? fatigueSignals
  }) async {
    const task = 'workout.deload';
    
    try {
      // AI gating check
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        return 'AI quota exceeded. Please upgrade your plan or try again later.';
      }

      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return 'Rate limit exceeded. Please wait a moment before trying again.';
      }
      
      if (!await _usageService.canMakeRequest('chat')) {
        return 'AI quota exceeded. Please upgrade your plan or try again later.';
      }

      // Check cache
      final fatigueJson = fatigueSignals != null ? json.encode(fatigueSignals) : '';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: '$planJson$fatigueJson',
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);
      
      final fatigueContext = fatigueSignals != null 
        ? '\n\nFatigue signals: ${json.encode(fatigueSignals)}'
        : '';
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are a fitness coach AI. Analyze the workout plan and fatigue signals to provide deload advice.
Focus on:
- When to deload
- How to modify exercises
- Volume reduction strategies
- Recovery protocols
Provide specific, actionable deload recommendations.'''
        },
        {
          'role': 'user',
          'content': 'Analyze this workout plan and provide deload advice:\n\n$planJson$fatigueContext'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response; // Error message from AI client
      }

      // Cache successful response
      _cache.set(cacheKey, response);
      
      // Increment usage
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return 'Unable to generate deload advice. Please try again.';
    }
  }

  static Future<String> weakPointAnalysis({
    required String planJson, 
    List<String>? recentNotes
  }) async {
    const task = 'workout.weakpoint';
    
    try {
      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return 'Rate limit exceeded. Please wait a moment before trying again.';
      }
      
      if (!await _usageService.canMakeRequest('chat')) {
        return 'AI quota exceeded. Please upgrade your plan or try again later.';
      }

      // Check cache
      final notesJson = recentNotes != null ? json.encode(recentNotes) : '';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: '$planJson$notesJson',
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);
      
      final notesContext = recentNotes != null && recentNotes.isNotEmpty
        ? '\n\nRecent notes:\n${recentNotes.join('\n')}'
        : '';
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are a fitness coach AI. Analyze the workout plan and identify potential weak points.
Focus on:
- Muscle group imbalances
- Movement pattern deficiencies
- Recovery gaps
- Progression bottlenecks
Provide specific recommendations to address each weak point.'''
        },
        {
          'role': 'user',
          'content': 'Analyze this workout plan for weak points:\n\n$planJson$notesContext'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response; // Error message from AI client
      }

      // Cache successful response
      _cache.set(cacheKey, response);
      
      // Increment usage
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return 'Unable to analyze weak points. Please try again.';
    }
  }


}
