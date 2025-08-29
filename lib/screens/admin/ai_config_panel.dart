import 'package:flutter/material.dart';
import '../../services/ai/model_registry.dart';
import 'global_settings_panel.dart';

class AIConfigPanel extends StatefulWidget {
  const AIConfigPanel({super.key});

  @override
  State<AIConfigPanel> createState() => _AIConfigPanelState();
}

class _AIConfigPanelState extends State<AIConfigPanel> {
  final ModelRegistry _modelRegistry = ModelRegistry();
  Map<String, String> _currentModels = {};
  Map<String, String> _environmentOverrides = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final tasks = _modelRegistry.availableTasks;
    final models = <String, String>{};
    final overrides = <String, String>{};

    for (final task in tasks) {
      models[task] = _modelRegistry.modelFor(task);
      
      // Check for environment overrides
      final overrideKey = _getOverrideKey(task);
      if (overrideKey != null) {
        final overrideValue = String.fromEnvironment(overrideKey, defaultValue: '');
        if (overrideValue.isNotEmpty) {
          overrides[task] = overrideValue;
        }
      }
    }

    setState(() {
      _currentModels = models;
      _environmentOverrides = overrides;
    });
  }

  String? _getOverrideKey(String task) {
    const overrideMap = {
      'notes.summarize': 'NOTES_SUMMARIZE_MODEL',
      'notes.tags': 'NOTES_TAGS_MODEL',
      'notes.dupdetect': 'NOTES_DUPDETECT_MODEL',
      'workout.suggest': 'WORKOUT_SUGGEST_MODEL',
      'workout.deload': 'WORKOUT_DELOAD_MODEL',
      'workout.weakpoint': 'WORKOUT_WEAKPOINT_MODEL',
      'calendar.tagger': 'CALENDAR_TAGGER_MODEL',
      'calendar.time': 'CALENDAR_TIME_MODEL',
      'messaging.reply': 'MESSAGING_REPLY_MODEL',
      'messaging.translate': 'MESSAGING_TRANSLATE_MODEL',
      'messaging.summarize': 'MESSAGING_SUMMARIZE_MODEL',
      'chat.default': 'CHAT_DEFAULT_MODEL',
      'embedding.default': 'EMBEDDING_DEFAULT_MODEL',
    };
    return overrideMap[task];
  }

  String _getTaskDisplayName(String task) {
    const displayNames = {
      'notes.summarize': 'Notes Summarization',
      'notes.tags': 'Notes Tagging',
      'notes.dupdetect': 'Notes Duplicate Detection',
      'workout.suggest': 'Workout Progression Suggestions',
      'workout.deload': 'Workout Deload Advice',
      'workout.weakpoint': 'Workout Weak Point Analysis',
      'calendar.tagger': 'Calendar Event Tagging',
      'calendar.time': 'Calendar Time Suggestions',
      'messaging.reply': 'Messaging Smart Replies',
      'messaging.translate': 'Messaging Translation',
      'messaging.summarize': 'Messaging Thread Summarization',
      'chat.default': 'Default Chat',
      'embedding.default': 'Default Embeddings',
    };
    return displayNames[task] ?? task;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalSettingsPanel()),
              );
            },
            tooltip: 'Global Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentConfig,
            tooltip: 'Refresh Configuration',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Model Configuration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This panel shows the current AI model assignments for different tasks. '
                    'Models can be overridden using dart-define flags.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildHelpSection(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Model assignments
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task → Model Assignments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._currentModels.entries.map((entry) => 
                    _buildModelAssignmentTile(entry.key, entry.value)
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Plan limits overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan Limits Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPlanLimitsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return const ExpansionTile(
      title: Text('How to Override Models'),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To override a model, use the --dart-define flag when building:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'flutter build apk --dart-define=NOTES_SUMMARIZE_MODEL=gpt-4o',
                style: TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Available models: gpt-4o, gpt-4o-mini, claude-3-5-sonnet, etc.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelAssignmentTile(String task, String model) {
    final hasOverride = _environmentOverrides.containsKey(task);
    final overrideKey = _getOverrideKey(task);
    
    return ListTile(
      title: Text(_getTaskDisplayName(task)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Model: $model'),
          if (hasOverride) ...[
            const SizedBox(height: 4),
            Text(
              'Override: ${_environmentOverrides[task]}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (overrideKey != null) ...[
            const SizedBox(height: 4),
            Text(
              'Flag: --dart-define=$overrideKey=<model>',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.blue,
              ),
            ),
          ],
        ],
      ),
      trailing: hasOverride 
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.info_outline, color: Colors.grey),
    );
  }

  Widget _buildPlanLimitsSection() {
    return Column(
      children: [
        _buildLimitTile('Free Plan', '100 requests/day', Colors.grey),
        _buildLimitTile('Basic Plan', '1,000 requests/day', Colors.blue),
        _buildLimitTile('Pro Plan', '10,000 requests/day', Colors.green),
        _buildLimitTile('Enterprise', 'Unlimited', Colors.purple),
        const SizedBox(height: 16),
        const Text(
          'Note: Limits are enforced per user and reset daily. '
          'Embedding requests count as 1 request each.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildLimitTile(String plan, String limit, Color color) {
    return ListTile(
      leading: Icon(Icons.star, color: color),
      title: Text(plan),
      trailing: Text(
        limit,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
