import 'dart:developer' as developer;

class ModelRegistry {
  static final ModelRegistry _instance = ModelRegistry._internal();
  factory ModelRegistry() => _instance;
  ModelRegistry._internal();

  // Task to model mappings with dart-define overrides
  static const Map<String, String> _taskModels = {
    'notes.summarize': 'gpt-4o-mini',
    'notes.tags': 'gpt-4o-mini',
    'notes.dupdetect': 'gpt-4o-mini',
    'workout.suggest': 'gpt-4o-mini',
    'workout.deload': 'gpt-4o-mini',
    'workout.weakpoint': 'gpt-4o-mini',
    'calendar.tagger': 'gpt-4o-mini',
    'calendar.time': 'gpt-4o-mini',
    'messaging.reply': 'gpt-4o-mini',
    'messaging.translate': 'gpt-4o-mini',
    'messaging.summarize': 'gpt-4o-mini',
    'chat.default': 'gpt-4o-mini',
    'embedding.default': 'text-embedding-3-large',
  };

  // Override mappings with dart-define if available
  static const Map<String, String> _overrides = {
    'NOTES_SUMMARIZE_MODEL': 'notes.summarize',
    'NOTES_TAGS_MODEL': 'notes.tags',
    'NOTES_DUPDETECT_MODEL': 'notes.dupdetect',
    'WORKOUT_SUGGEST_MODEL': 'workout.suggest',
    'WORKOUT_DELOAD_MODEL': 'workout.deload',
    'WORKOUT_WEAKPOINT_MODEL': 'workout.weakpoint',
    'CALENDAR_TAGGER_MODEL': 'calendar.tagger',
    'CALENDAR_TIME_MODEL': 'calendar.time',
    'MESSAGING_REPLY_MODEL': 'messaging.reply',
    'MESSAGING_TRANSLATE_MODEL': 'messaging.translate',
    'MESSAGING_SUMMARIZE_MODEL': 'messaging.summarize',
    'CHAT_DEFAULT_MODEL': 'chat.default',
    'EMBEDDING_DEFAULT_MODEL': 'embedding.default',
  };

  String modelFor(String task) {
    // Check for dart-define override first
    for (final entry in _overrides.entries) {
      final overrideValue = String.fromEnvironment(entry.key, defaultValue: '');
      if (overrideValue.isNotEmpty && entry.value == task) {
        return overrideValue;
      }
    }

    // Return default model for task
    return _taskModels[task] ?? 'gpt-4o-mini';
  }

  int embeddingDim(String model) {
    // Return 1536 for text-embedding-3-large, default to 1536 for unknown models
    if (model.contains('text-embedding-3-large') || model.contains('text-embedding-3-small')) {
      return 1536;
    }
    
    // Log warning for unknown models but return 1536 as fallback
    developer.log('Unknown embedding model: $model, using 1536 dimensions', name: 'ModelRegistry');
    return 1536;
  }

  // Helper to get all available tasks
  List<String> get availableTasks => _taskModels.keys.toList();

  // Helper to check if a task is supported
  bool isTaskSupported(String task) => _taskModels.containsKey(task);
}
