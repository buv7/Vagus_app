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

  /// Generate a full week workout plan based on targets and preferences
  static Future<String> generateFullWeek({
    required Map<String, dynamic> targets,
    required Map<String, dynamic> preferences,
    String locale = 'en',
  }) async {
    const task = 'workout.full_week';

    try {
      // AI gating check
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        return _localizeError('AI quota exceeded', locale);
      }

      // Rate limiting and quota check
      if (!await _rateLimiter.tryConsume(task)) {
        return _localizeError('Rate limit exceeded', locale);
      }

      if (!await _usageService.canMakeRequest('chat')) {
        return _localizeError('AI quota exceeded', locale);
      }

      // Check cache
      final inputData = json.encode({'targets': targets, 'preferences': preferences, 'locale': locale});
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt('full_week', locale),
        },
        {
          'role': 'user',
          'content': 'Generate a full week workout plan:\n\nTargets: ${json.encode(targets)}\n\nPreferences: ${json.encode(preferences)}'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response;
      }

      _cache.set(cacheKey, response);
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return _localizeError('Unable to generate workout', locale);
    }
  }

  /// Generate a single workout day
  static Future<String> generateWorkoutDay({
    required List<String> muscleGroups,
    required List<String> equipment,
    required int durationMinutes,
    required String intensity,
    String locale = 'en',
  }) async {
    const task = 'workout.single_day';

    try {
      // AI gating check
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        return _localizeError('AI quota exceeded', locale);
      }

      if (!await _rateLimiter.tryConsume(task)) {
        return _localizeError('Rate limit exceeded', locale);
      }

      if (!await _usageService.canMakeRequest('chat')) {
        return _localizeError('AI quota exceeded', locale);
      }

      final inputData = json.encode({
        'muscleGroups': muscleGroups,
        'equipment': equipment,
        'duration': durationMinutes,
        'intensity': intensity,
        'locale': locale,
      });

      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt('single_day', locale),
        },
        {
          'role': 'user',
          'content': '''Generate a workout day:
Muscle Groups: ${muscleGroups.join(', ')}
Equipment: ${equipment.join(', ')}
Duration: $durationMinutes minutes
Intensity: $intensity'''
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response;
      }

      _cache.set(cacheKey, response);
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return _localizeError('Unable to generate workout day', locale);
    }
  }

  /// Suggest exercise alternatives
  static Future<String> suggestExerciseAlternatives({
    required String exerciseName,
    required String reason,
    String locale = 'en',
  }) async {
    const task = 'workout.alternatives';

    try {
      if (!await _rateLimiter.tryConsume(task)) {
        return _localizeError('Rate limit exceeded', locale);
      }

      if (!await _usageService.canMakeRequest('chat')) {
        return _localizeError('AI quota exceeded', locale);
      }

      final inputData = '$exerciseName:$reason:$locale';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt('alternatives', locale),
        },
        {
          'role': 'user',
          'content': 'Suggest alternatives for "$exerciseName" because: $reason'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response;
      }

      _cache.set(cacheKey, response);
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return _localizeError('Unable to suggest alternatives', locale);
    }
  }

  /// Auto-fill exercise details (sets, reps, rest)
  static Future<String> autoFillExerciseDetails({
    required String exerciseName,
    required String goal,
    String locale = 'en',
  }) async {
    const task = 'workout.autofill';

    try {
      if (!await _rateLimiter.tryConsume(task)) {
        return _localizeError('Rate limit exceeded', locale);
      }

      if (!await _usageService.canMakeRequest('chat')) {
        return _localizeError('AI quota exceeded', locale);
      }

      final inputData = '$exerciseName:$goal:$locale';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt('autofill', locale),
        },
        {
          'role': 'user',
          'content': 'Provide sets, reps, and rest for "$exerciseName" with goal: $goal. Return as JSON: {"sets": X, "reps": "X-X", "rest": X}'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response;
      }

      _cache.set(cacheKey, response);
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return _localizeError('Unable to autofill exercise', locale);
    }
  }

  /// Generate progressive overload
  static Future<String> generateProgressiveOverload({
    required String currentWorkoutJson,
    required int weekNumber,
    String locale = 'en',
  }) async {
    const task = 'workout.progression';

    try {
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        return _localizeError('AI quota exceeded', locale);
      }

      if (!await _rateLimiter.tryConsume(task)) {
        return _localizeError('Rate limit exceeded', locale);
      }

      if (!await _usageService.canMakeRequest('chat')) {
        return _localizeError('AI quota exceeded', locale);
      }

      final inputData = '$currentWorkoutJson:week$weekNumber:$locale';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt('progression', locale),
        },
        {
          'role': 'user',
          'content': 'Apply progressive overload for week $weekNumber:\n\n$currentWorkoutJson'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response;
      }

      _cache.set(cacheKey, response);
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return _localizeError('Unable to generate progression', locale);
    }
  }

  /// Analyze workout balance
  static Future<String> analyzeWorkoutBalance({
    required String weekPlanJson,
    String locale = 'en',
  }) async {
    const task = 'workout.balance';

    try {
      if (!await _rateLimiter.tryConsume(task)) {
        return _localizeError('Rate limit exceeded', locale);
      }

      if (!await _usageService.canMakeRequest('chat')) {
        return _localizeError('AI quota exceeded', locale);
      }

      final inputData = '$weekPlanJson:$locale';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt('balance', locale),
        },
        {
          'role': 'user',
          'content': 'Analyze the balance and distribution of this week plan:\n\n$weekPlanJson'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response;
      }

      _cache.set(cacheKey, response);
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return _localizeError('Unable to analyze balance', locale);
    }
  }

  /// Suggest superset combinations
  static Future<String> suggestSupersetCombinations({
    required String exercisesJson,
    String locale = 'en',
  }) async {
    const task = 'workout.supersets';

    try {
      if (!await _rateLimiter.tryConsume(task)) {
        return _localizeError('Rate limit exceeded', locale);
      }

      if (!await _usageService.canMakeRequest('chat')) {
        return _localizeError('AI quota exceeded', locale);
      }

      final inputData = '$exercisesJson:$locale';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt('supersets', locale),
        },
        {
          'role': 'user',
          'content': 'Suggest intelligent superset pairings for these exercises:\n\n$exercisesJson'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response;
      }

      _cache.set(cacheKey, response);
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return _localizeError('Unable to suggest supersets', locale);
    }
  }

  /// Estimate workout duration
  static Future<String> estimateWorkoutDuration({
    required String exercisesJson,
    required String cardioJson,
    String locale = 'en',
  }) async {
    const task = 'workout.duration';

    try {
      // This is a quick calculation, no rate limiting needed
      final inputData = '$exercisesJson:$cardioJson:$locale';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': 'You are a fitness timing expert. Estimate workout duration based on exercises and cardio.',
        },
        {
          'role': 'user',
          'content': 'Estimate duration for:\nExercises: $exercisesJson\nCardio: $cardioJson'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      _cache.set(cacheKey, response);
      return response;
    } catch (e) {
      return _localizeError('Unable to estimate duration', locale);
    }
  }

  /// Calculate 1RM using Epley formula
  static double? calculate1RM({
    required double weight,
    required int reps,
  }) {
    if (reps < 1 || reps > 15) return null;
    if (reps == 1) return weight;

    // Epley formula: 1RM = weight × (1 + reps / 30)
    return weight * (1 + reps / 30.0);
  }

  /// Generate deload week (enhanced version of existing deloadAdvice)
  static Future<String> suggestDeloadWeek({
    required String previousWeeksJson,
    String locale = 'en',
  }) async {
    const task = 'workout.deload_week';

    try {
      final remaining = await PlanAccessManager.instance.remainingAICalls();
      if (remaining <= 0) {
        return _localizeError('AI quota exceeded', locale);
      }

      if (!await _rateLimiter.tryConsume(task)) {
        return _localizeError('Rate limit exceeded', locale);
      }

      if (!await _usageService.canMakeRequest('chat')) {
        return _localizeError('AI quota exceeded', locale);
      }

      final inputData = '$previousWeeksJson:$locale';
      final cacheKey = _cache.cacheKeyFor(
        task: task,
        model: _modelRegistry.modelFor(task),
        inputOrPrompt: inputData,
      );
      final cached = await _cache.get<String>(cacheKey);
      if (cached != null) return cached;

      final model = _modelRegistry.modelFor(task);

      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt('deload_week', locale),
        },
        {
          'role': 'user',
          'content': 'Generate a deload week based on these previous weeks:\n\n$previousWeeksJson'
        }
      ];

      final response = await _aiClient.chat(
        model: model,
        messages: messages,
      );

      if (response.startsWith('Quota exceeded') || response.startsWith('AI service')) {
        return response;
      }

      _cache.set(cacheKey, response);
      await _usageService.incrementUsage('chat', model);

      return response;
    } catch (e) {
      return _localizeError('Unable to generate deload week', locale);
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  static String _getSystemPrompt(String promptType, String locale) {
    final prompts = {
      'full_week': '''You are an expert fitness coach AI. Generate complete weekly workout plans.
${_getMenaContext(locale)}
Focus on:
- Balanced muscle group distribution
- Appropriate volume and intensity
- Progressive overload principles
- Recovery considerations
- Equipment availability
${_getRamadanContext(locale)}
Return structured workout plan in JSON format.''',

      'single_day': '''You are an expert fitness coach AI. Generate single workout days.
${_getMenaContext(locale)}
Focus on:
- Exercise selection for target muscle groups
- Appropriate sets, reps, and rest periods
- Time efficiency
- Equipment constraints
${_getRamadanContext(locale)}
Return workout in JSON format.''',

      'alternatives': '''You are an expert fitness coach AI. Suggest exercise alternatives.
${_getMenaContext(locale)}
Consider:
- Same muscle group targeting
- Equipment availability
- Difficulty level
- Movement patterns
Provide 3-5 alternatives with reasoning.''',

      'autofill': '''You are an expert fitness coach AI. Provide optimal sets, reps, and rest periods.
Base recommendations on:
- Training goal (strength/hypertrophy/endurance)
- Exercise type and complexity
- Training experience level
Return as JSON with sets, reps, rest, and optional tempo.''',

      'progression': '''You are an expert fitness coach AI. Apply progressive overload principles.
${_getMenaContext(locale)}
Progression strategies:
- Weight increases (2.5-5%)
- Rep increases (1-2 reps)
- Volume increases (additional sets)
- Intensity techniques
Return progressed workout in JSON format.''',

      'balance': '''You are an expert fitness coach AI. Analyze workout program balance.
${_getMenaContext(locale)}
Analyze:
- Muscle group frequency and volume
- Push/pull/legs distribution
- Movement pattern variety
- Recovery adequacy
Provide specific recommendations.''',

      'supersets': '''You are an expert fitness coach AI. Suggest superset combinations.
${_getMenaContext(locale)}
Consider:
- Antagonistic muscle pairings
- Non-competing movements
- Time efficiency
- Fatigue management
Provide reasoning for each pairing.''',

      'deload_week': '''You are an expert fitness coach AI. Generate recovery-focused deload weeks.
${_getMenaContext(locale)}
Deload principles:
- Reduce volume by 40-50%
- Reduce intensity by 20-30%
- Maintain movement patterns
- Focus on technique
${_getRamadanContext(locale)}
Return deload plan in JSON format.''',
    };

    return prompts[promptType] ?? 'You are an expert fitness coach AI.';
  }

  static String _getMenaContext(String locale) {
    if (locale == 'ar' || locale == 'ku') {
      return '''MENA Region Context:
- Consider common gym equipment in the region
- Account for cultural preferences
- Adapt exercise names to local terminology
- Consider heat and climate factors
''';
    }
    return '';
  }

  static String _getRamadanContext(String locale) {
    if (locale == 'ar' || locale == 'ku') {
      return '''Ramadan Considerations:
- If during Ramadan, suggest lower volume workouts
- Recommend training after Iftar
- Focus on maintenance rather than progression
- Emphasize hydration and recovery
''';
    }
    return '';
  }

  static String _localizeError(String error, String locale) {
    if (locale == 'ar') {
      final translations = {
        'AI quota exceeded': 'تم تجاوز حصة الذكاء الاصطناعي',
        'Rate limit exceeded': 'تم تجاوز حد المعدل',
        'Unable to generate workout': 'غير قادر على إنشاء التمرين',
        'Unable to generate workout day': 'غير قادر على إنشاء يوم التمرين',
        'Unable to suggest alternatives': 'غير قادر على اقتراح البدائل',
        'Unable to autofill exercise': 'غير قادر على ملء التمرين تلقائيًا',
        'Unable to generate progression': 'غير قادر على إنشاء التقدم',
        'Unable to analyze balance': 'غير قادر على تحليل التوازن',
        'Unable to suggest supersets': 'غير قادر على اقتراح السوبرسيت',
        'Unable to estimate duration': 'غير قادر على تقدير المدة',
        'Unable to generate deload week': 'غير قادر على إنشاء أسبوع التخفيف',
      };
      return translations[error] ?? error;
    } else if (locale == 'ku') {
      final translations = {
        'AI quota exceeded': 'سنووری AI تێپەڕیوە',
        'Rate limit exceeded': 'سنووری ڕێژە تێپەڕیوە',
        'Unable to generate workout': 'ناتوانێ ڕاهێنان دروست بکات',
      };
      return translations[error] ?? error;
    }
    return error;
  }
}
