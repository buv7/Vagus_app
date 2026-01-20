import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../services/workout/workout_knowledge_service.dart';
import '../../widgets/branding/vagus_appbar.dart';

/// Admin/Coach screen for managing workout knowledge base (exercises and intensifiers)
class WorkoutKnowledgeAdminScreen extends StatefulWidget {
  const WorkoutKnowledgeAdminScreen({super.key});

  @override
  State<WorkoutKnowledgeAdminScreen> createState() =>
      _WorkoutKnowledgeAdminScreenState();
}

class _WorkoutKnowledgeAdminScreenState
    extends State<WorkoutKnowledgeAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutKnowledgeService _service = WorkoutKnowledgeService.instance;

  // Exercises state
  List<Map<String, dynamic>> _exercises = [];
  bool _exercisesLoading = true;
  String _exerciseSearchQuery = '';

  // Intensifiers state
  List<Map<String, dynamic>> _intensifiers = [];
  bool _intensifiersLoading = true;
  String _intensifierSearchQuery = '';

  bool _isAdmin = false;
  int _regenLimit = 500; // Default limit for regeneration
  
  // Last regeneration stats
  DateTime? _lastRegenAt;
  Map<String, dynamic>? _lastRegenResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminStatus();
    _loadExercises();
    _loadIntensifiers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _service.isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  Future<void> _loadExercises({String? status}) async {
    if (!mounted) return;
    setState(() => _exercisesLoading = true);

    try {
      final exercises = await _service.searchExercises(
        query: _exerciseSearchQuery.isEmpty ? null : _exerciseSearchQuery,
        status: status ?? (_isAdmin ? null : 'approved'),
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _exercises = exercises;
          _exercisesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _exercisesLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load exercises: $e')),
        );
      }
    }
  }

  Future<void> _loadIntensifiers({String? status}) async {
    if (!mounted) return;
    setState(() => _intensifiersLoading = true);

    try {
      final intensifiers = await _service.searchIntensifiers(
        query: _intensifierSearchQuery.isEmpty ? null : _intensifierSearchQuery,
        status: status ?? (_isAdmin ? null : 'approved'),
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _intensifiers = intensifiers;
          _intensifiersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _intensifiersLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load intensifiers: $e')),
        );
      }
    }
  }

  Future<void> _showExerciseForm({Map<String, dynamic>? exercise}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ExerciseFormDialog(exercise: exercise),
    );

    if (result == true) {
      await _loadExercises();
    }
  }

  Future<void> _showIntensifierForm({Map<String, dynamic>? intensifier}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _IntensifierFormDialog(intensifier: intensifier),
    );

    if (result == true) {
      await _loadIntensifiers();
    }
  }

  Future<void> _updateStatus(
    String id,
    String newStatus,
    bool isExercise,
  ) async {
    try {
      if (isExercise) {
        await _service.updateExerciseStatus(id, newStatus);
      } else {
        await _service.updateIntensifierStatus(id, newStatus);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
        if (isExercise) {
          await _loadExercises();
        } else {
          await _loadIntensifiers();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VagusAppBar(
        title: Text('Workout Knowledge Base'),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.fitness_center), text: 'Exercises'),
              Tab(icon: Icon(Icons.trending_up), text: 'Intensifiers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExercisesTab(),
                _buildIntensifiersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showExerciseForm();
          } else {
            _showIntensifierForm();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _regenerateLinks() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin access required')),
      );
      return;
    }

    // Show confirmation dialog with limit picker
    int dialogLimit = _regenLimit;
    final confirm = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Regenerate Exercise-Intensifier Links'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select number of exercises to process:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 300, label: Text('300')),
                      ButtonSegment(value: 500, label: Text('500')),
                      ButtonSegment(value: 1000, label: Text('1000')),
                    ],
                    selected: {dialogLimit},
                    onSelectionChanged: (Set<int> newSelection) {
                      setDialogState(() {
                        dialogLimit = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => Text(
                      'This will add missing links for up to $dialogLimit exercises using heuristic rules.\n\n'
                      '• No links will be deleted\n'
                      '• No existing links will be updated\n'
                      '• Only new links will be added\n'
                      '• Safe to run multiple times',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {'limit': dialogLimit}),
                  child: const Text('Regenerate'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == null) return;
    
    final limit = confirm['limit'] as int? ?? _regenLimit;
    
    // Update stored limit
    setState(() {
      _regenLimit = limit;
    });

    // Show loading dialog
    if (!mounted) return;
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Regenerating links...'),
              ],
            ),
          ),
        ),
      ),
    ));

    try {
      final result = await _service.regenerateExerciseIntensifierLinks(limit: limit);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Store last run stats
      if (mounted) {
        setState(() {
          _lastRegenAt = DateTime.now();
          _lastRegenResult = result;
        });
      }

      // Show success dialog with results
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Links Regenerated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inserted links: ${result['inserted_links'] ?? 0}'),
              const SizedBox(height: 8),
              Text('Exercises considered: ${result['exercises_considered'] ?? 0}'),
              const SizedBox(height: 8),
              Text('Exercises affected: ${result['exercises_with_new_links'] ?? 0}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to regenerate links: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _importSeedExercises() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin access required')),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Seed Exercises'),
        content: const Text(
          'This will import 2000 exercises from the seed pack (EN).\n'
          'Each exercise includes dual tags: English + anatomical muscle names.\n\n'
          'Existing exercises will be updated only if fields are empty. '
          'This operation is safe to run multiple times.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show progress dialog
    if (!mounted) return;
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading seed file...'),
              ],
            ),
          ),
        ),
      ),
    ));

    try {
      // Load JSON asset
      final jsonString = await rootBundle.loadString(
        'assets/seeds/exercise_knowledge_seed_en.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);
      final List<Map<String, dynamic>> exercises = jsonData
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Import in batches
      int imported = 0;
      const batchSize = 200; // Process 200 exercises per batch
      
      // Show progress dialog
      if (!mounted) return;
      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Importing Exercises'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  // This will be updated via setState in StatefulBuilder
                  return const Text('Processing...');
                },
              ),
            ],
          ),
        ),
      ));

      try {
        for (int i = 0; i < exercises.length; i += batchSize) {
          if (!mounted) break;
          
          final batch = exercises.skip(i).take(batchSize).toList();
          final count = await _service.upsertExerciseKnowledgeBatch(batch);
          imported += count;
          
          debugPrint('📊 Progress: $imported / ${exercises.length}');
        }
      } finally {
        if (mounted) {
          Navigator.pop(context); // Close progress dialog
        }
      }

      // Reload exercises
      await _loadExercises();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Successfully imported $imported exercises'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close any open dialogs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to import: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildExercisesTab() {
    return Column(
      children: [
        // Search bar with import button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _exerciseSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _exerciseSearchQuery = '');
                              _loadExercises();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _exerciseSearchQuery = value);
                    _loadExercises();
                  },
                ),
              ),
              if (_isAdmin) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Import Seed (EN) — 2000',
                  onPressed: _importSeedExercises,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Regenerate Links (Top $_regenLimit)',
                  onPressed: _regenerateLinks,
                ),
              ],
            ],
          ),
        ),
        // Last run stats (if available)
        if (_isAdmin && _lastRegenAt != null && _lastRegenResult != null)
          _buildLastRegenStats(),
        // List
        Expanded(
          child: _exercisesLoading
              ? const Center(child: CircularProgressIndicator())
              : _exercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No exercises found'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showExerciseForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Exercise'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadExercises(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];
                          return _buildExerciseCard(exercise);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildIntensifiersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search intensifiers...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _intensifierSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _intensifierSearchQuery = '');
                        _loadIntensifiers();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() => _intensifierSearchQuery = value);
              _loadIntensifiers();
            },
          ),
        ),
        // List
        Expanded(
          child: _intensifiersLoading
              ? const Center(child: CircularProgressIndicator())
              : _intensifiers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.trending_up, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No intensifiers found'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showIntensifierForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Intensifier'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadIntensifiers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _intensifiers.length,
                        itemBuilder: (context, index) {
                          final intensifier = _intensifiers[index];
                          return _buildIntensifierCard(intensifier);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildLastRegenStats() {
    if (_lastRegenAt == null || _lastRegenResult == null) {
      return const SizedBox.shrink();
    }
    
    // Format time as HH:MM
    final h = _lastRegenAt!.hour.toString().padLeft(2, '0');
    final m = _lastRegenAt!.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';
    
    final insertedLinks = _lastRegenResult!['inserted_links'] ?? 0;
    final exercisesConsidered = _lastRegenResult!['exercises_considered'] ?? 0;
    final exercisesAffected = _lastRegenResult!['exercises_with_new_links'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last regen: $timeStr • Limit: $_regenLimit',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inserted: $insertedLinks • Considered: $exercisesConsidered • Affected: $exercisesAffected',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final status = exercise['status'] as String? ?? 'unknown';
    final primaryMuscles = (exercise['primary_muscles'] as List<dynamic>?) ?? [];
    final equipment = (exercise['equipment'] as List<dynamic>?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(exercise['name'] as String? ?? 'Unnamed'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise['short_desc'] != null) ...[
              const SizedBox(height: 4),
              Text(exercise['short_desc'] as String),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(status.toUpperCase()),
                  backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (primaryMuscles.isNotEmpty)
                  Chip(
                    label: Text(primaryMuscles.join(', ')),
                    avatar: const Icon(Icons.accessibility, size: 16),
                  ),
                if (equipment.isNotEmpty)
                  Chip(
                    label: Text(equipment.join(', ')),
                    avatar: const Icon(Icons.sports_gymnastics, size: 16),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (_isAdmin) ...[
              const PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Approve'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(Icons.close, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reject'),
                  ],
                ),
              ),
            ],
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showExerciseForm(exercise: exercise);
            } else if (value == 'approve') {
              _updateStatus(exercise['id'] as String, 'approved', true);
            } else if (value == 'reject') {
              _updateStatus(exercise['id'] as String, 'rejected', true);
            }
          },
        ),
      ),
    );
  }

  Widget _buildIntensifierCard(Map<String, dynamic> intensifier) {
    final status = intensifier['status'] as String? ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(intensifier['name'] as String? ?? 'Unnamed'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (intensifier['short_desc'] != null) ...[
              const SizedBox(height: 4),
              Text(intensifier['short_desc'] as String),
            ],
            const SizedBox(height: 8),
            Chip(
              label: Text(status.toUpperCase()),
              backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: _getStatusColor(status),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (_isAdmin) ...[
              const PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Approve'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(Icons.close, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reject'),
                  ],
                ),
              ),
            ],
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showIntensifierForm(intensifier: intensifier);
            } else if (value == 'approve') {
              _updateStatus(intensifier['id'] as String, 'approved', false);
            } else if (value == 'reject') {
              _updateStatus(intensifier['id'] as String, 'rejected', false);
            }
          },
        ),
      ),
    );
  }
}

// =====================================================
// FORM DIALOGS
// =====================================================

class _ExerciseFormDialog extends StatefulWidget {
  final Map<String, dynamic>? exercise;

  const _ExerciseFormDialog({this.exercise});

  @override
  State<_ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<_ExerciseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _howToController = TextEditingController();
  final _musclesController = TextEditingController(); // Comma-separated
  final _equipmentController = TextEditingController(); // Comma-separated
  String _status = 'pending';

  final WorkoutKnowledgeService _service = WorkoutKnowledgeService.instance;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!['name'] ?? '';
      _shortDescController.text = widget.exercise!['short_desc'] ?? '';
      _howToController.text = widget.exercise!['how_to'] ?? '';
      _musclesController.text =
          (widget.exercise!['primary_muscles'] as List<dynamic>?)?.join(', ') ?? '';
      _equipmentController.text =
          (widget.exercise!['equipment'] as List<dynamic>?)?.join(', ') ?? '';
      _status = widget.exercise!['status'] ?? 'pending';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _howToController.dispose();
    _musclesController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _service.isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final muscles = _musclesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final equipment = _equipmentController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final data = {
        'name': _nameController.text.trim(),
        'short_desc': _shortDescController.text.trim().isEmpty
            ? null
            : _shortDescController.text.trim(),
        'how_to': _howToController.text.trim().isEmpty
            ? null
            : _howToController.text.trim(),
        'primary_muscles': muscles,
        'equipment': equipment,
        'status': _status,
      };

      if (widget.exercise != null) {
        await _service.updateExercise(widget.exercise!['id'] as String, data);
      } else {
        await _service.createExercise(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.exercise != null ? 'Exercise updated' : 'Exercise created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise != null ? 'Edit Exercise' : 'Add Exercise'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shortDescController,
                  decoration: const InputDecoration(labelText: 'Short Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _howToController,
                  decoration: const InputDecoration(labelText: 'How To'),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _musclesController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Muscles (comma-separated)',
                    hintText: 'chest, triceps',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _equipmentController,
                  decoration: const InputDecoration(
                    labelText: 'Equipment (comma-separated)',
                    hintText: 'barbell, bench',
                  ),
                ),
                if (_isAdmin) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'pending'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _IntensifierFormDialog extends StatefulWidget {
  final Map<String, dynamic>? intensifier;

  const _IntensifierFormDialog({this.intensifier});

  @override
  State<_IntensifierFormDialog> createState() => _IntensifierFormDialogState();
}

class _IntensifierFormDialogState extends State<_IntensifierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _howToController = TextEditingController();
  String _status = 'pending';

  final WorkoutKnowledgeService _service = WorkoutKnowledgeService.instance;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    if (widget.intensifier != null) {
      _nameController.text = widget.intensifier!['name'] ?? '';
      _shortDescController.text = widget.intensifier!['short_desc'] ?? '';
      _howToController.text = widget.intensifier!['how_to'] ?? '';
      _status = widget.intensifier!['status'] ?? 'pending';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _howToController.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _service.isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'name': _nameController.text.trim(),
        'short_desc': _shortDescController.text.trim().isEmpty
            ? null
            : _shortDescController.text.trim(),
        'how_to': _howToController.text.trim().isEmpty
            ? null
            : _howToController.text.trim(),
        'status': _status,
      };

      if (widget.intensifier != null) {
        await _service.updateIntensifier(widget.intensifier!['id'] as String, data);
      } else {
        await _service.createIntensifier(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.intensifier != null ? 'Intensifier updated' : 'Intensifier created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.intensifier != null ? 'Edit Intensifier' : 'Add Intensifier'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shortDescController,
                  decoration: const InputDecoration(labelText: 'Short Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _howToController,
                  decoration: const InputDecoration(labelText: 'How To'),
                  maxLines: 4,
                ),
                if (_isAdmin) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'pending'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
