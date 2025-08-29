import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/admin/admin_service.dart';

class GlobalSettingsPanel extends StatefulWidget {
  const GlobalSettingsPanel({super.key});

  @override
  State<GlobalSettingsPanel> createState() => _GlobalSettingsPanelState();
}

class _GlobalSettingsPanelState extends State<GlobalSettingsPanel> {
  final AdminService _adminService = AdminService.instance;
  
  Map<String, dynamic> _aiModels = {};
  Map<String, dynamic> _planLimits = {};
  Map<String, dynamic> _featureFlags = {};
  
  Map<String, dynamic> _originalAiModels = {};
  Map<String, dynamic> _originalPlanLimits = {};
  Map<String, dynamic> _originalFeatureFlags = {};
  
  bool _loading = true;
  bool _saving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
    });

    try {
      final aiModelsData = await _adminService.getAdminSetting('ai.models');
      final planLimitsData = await _adminService.getAdminSetting('plan.limits');
      final featureFlagsData = await _adminService.getAdminSetting('feature.flags');

      setState(() {
        _aiModels = Map<String, dynamic>.from(aiModelsData?['value'] ?? {});
        _planLimits = Map<String, dynamic>.from(planLimitsData?['value'] ?? {});
        _featureFlags = Map<String, dynamic>.from(featureFlagsData?['value'] ?? {});
        
        _originalAiModels = Map<String, dynamic>.from(_aiModels);
        _originalPlanLimits = Map<String, dynamic>.from(_planLimits);
        _originalFeatureFlags = Map<String, dynamic>.from(_featureFlags);
        
        _loading = false;
        _checkForChanges();
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  void _checkForChanges() {
    final hasChanges = !mapEquals(_aiModels, _originalAiModels) ||
                      !mapEquals(_planLimits, _originalPlanLimits) ||
                      !mapEquals(_featureFlags, _originalFeatureFlags);
    
    setState(() {
      _hasChanges = hasChanges;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _saving = true;
    });

    try {
      final aiSuccess = await _adminService.upsertAdminSetting('ai.models', _aiModels);
      final planSuccess = await _adminService.upsertAdminSetting('plan.limits', _planLimits);
      final flagsSuccess = await _adminService.upsertAdminSetting('feature.flags', _featureFlags);

      if (mounted) {
        if (aiSuccess && planSuccess && flagsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Settings saved successfully')),
          );
          
          // Update originals to reflect saved state
          setState(() {
            _originalAiModels = Map<String, dynamic>.from(_aiModels);
            _originalPlanLimits = Map<String, dynamic>.from(_planLimits);
            _originalFeatureFlags = Map<String, dynamic>.from(_featureFlags);
            _hasChanges = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Failed to save some settings')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  void _resetSettings() {
    setState(() {
      _aiModels = Map<String, dynamic>.from(_originalAiModels);
      _planLimits = Map<String, dynamic>.from(_originalPlanLimits);
      _featureFlags = Map<String, dynamic>.from(_originalFeatureFlags);
      _hasChanges = false;
    });
  }

  void _revertSettings() {
    _loadSettings();
  }

  Widget _buildAiModelsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🤖 AI Models',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Configure AI model assignments for different tasks',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._aiModels.entries.map((entry) => _buildModelSettingTile(entry.key, entry.value)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addNewModel(),
              icon: const Icon(Icons.add),
              label: const Text('Add Model'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSettingTile(String task, String model) {
    return ListTile(
      title: Text(_getTaskDisplayName(task)),
      subtitle: Text('Current: $model'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editModel(task, model),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _removeModel(task),
          ),
        ],
      ),
    );
  }

  String _getTaskDisplayName(String task) {
    const displayNames = {
      'notes.summarize': 'Notes Summarization',
      'notes.tags': 'Notes Tagging',
      'workout.suggest': 'Workout Suggestions',
      'calendar.tagger': 'Calendar Tagging',
      'messaging.reply': 'Messaging Replies',
      'chat.default': 'Default Chat',
      'embedding.default': 'Default Embeddings',
    };
    return displayNames[task] ?? task;
  }

  void _addNewModel() {
    final taskController = TextEditingController();
    final modelController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add AI Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taskController,
              decoration: const InputDecoration(
                labelText: 'Task (e.g., notes.summarize)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Model (e.g., gpt-4o)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final task = taskController.text.trim();
              final model = modelController.text.trim();
              if (task.isNotEmpty && model.isNotEmpty) {
                setState(() {
                  _aiModels[task] = model;
                  _checkForChanges();
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editModel(String task, String currentModel) {
    final modelController = TextEditingController(text: currentModel);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${_getTaskDisplayName(task)}'),
        content: TextField(
          controller: modelController,
          decoration: const InputDecoration(
            labelText: 'Model',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final model = modelController.text.trim();
              if (model.isNotEmpty) {
                setState(() {
                  _aiModels[task] = model;
                  _checkForChanges();
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeModel(String task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Model'),
        content: Text('Are you sure you want to remove the model for ${_getTaskDisplayName(task)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _aiModels.remove(task);
                _checkForChanges();
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanLimitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Plan Limits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Configure monthly AI call limits for different plans',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._planLimits.entries.map((entry) => _buildPlanLimitTile(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanLimitTile(String plan, dynamic limits) {
    final limitsMap = Map<String, dynamic>.from(limits);
    final monthlyCalls = limitsMap['monthly_ai_calls'] ?? 0;
    
    return ListTile(
      title: Text(plan.toUpperCase()),
      subtitle: Text('Monthly AI calls: $monthlyCalls'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _editPlanLimit(plan, monthlyCalls),
      ),
    );
  }

  void _editPlanLimit(String plan, int currentCalls) {
    final callsController = TextEditingController(text: currentCalls.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${plan.toUpperCase()} Limit'),
        content: TextField(
          controller: callsController,
          decoration: const InputDecoration(
            labelText: 'Monthly AI Calls',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final calls = int.tryParse(callsController.text.trim());
              if (calls != null && calls >= 0) {
                setState(() {
                  _planLimits[plan] = {'monthly_ai_calls': calls};
                  _checkForChanges();
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureFlagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚩 Feature Flags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enable or disable features globally',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._featureFlags.entries.map((entry) => _buildFeatureFlagTile(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureFlagTile(String flag, bool value) {
    return SwitchListTile(
      title: Text(_getFlagDisplayName(flag)),
      subtitle: Text(_getFlagDescription(flag)),
      value: value,
      onChanged: (newValue) {
        setState(() {
          _featureFlags[flag] = newValue;
          _checkForChanges();
        });
      },
    );
  }

  String _getFlagDisplayName(String flag) {
    const displayNames = {
      'enable_moderation': 'Content Moderation',
      'enable_analytics': 'Analytics',
      'enable_notifications': 'Notifications',
    };
    return displayNames[flag] ?? flag;
  }

  String _getFlagDescription(String flag) {
    const descriptions = {
      'enable_moderation': 'Enable AI-powered content moderation',
      'enable_analytics': 'Enable detailed analytics tracking',
      'enable_notifications': 'Enable push notifications',
    };
    return descriptions[flag] ?? 'No description available';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Global Settings'),
        actions: [
          if (_hasChanges) ...[
            TextButton(
              onPressed: _saving ? null : _saveSettings,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SAVE'),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Action buttons
                  if (_hasChanges)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _saveSettings,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save),
                                label: const Text('Save Changes'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _resetSettings,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _revertSettings,
                                icon: const Icon(Icons.undo),
                                label: const Text('Revert'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Settings sections
                  _buildAiModelsSection(),
                  const SizedBox(height: 16),
                  _buildPlanLimitsSection(),
                  const SizedBox(height: 16),
                  _buildFeatureFlagsSection(),
                ],
              ),
            ),
    );
  }
}
