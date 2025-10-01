import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/workout_plan.dart';
import '../../models/workout/exercise.dart';
import '../../models/workout/cardio_session.dart';
import '../../services/workout/workout_service.dart';
import '../../services/ai/ai_usage_service.dart';
import 'widgets/workout_session_manager.dart';
import 'widgets/exercise_completion_widget.dart';
import 'widgets/rest_timer_widget.dart';
import 'widgets/progress_chart_widget.dart';
// import 'widgets/exercise_demo_player.dart'; // Not yet implemented
// import 'widgets/muscle_activation_visual.dart'; // Not yet implemented
import 'package:intl/intl.dart';

/// Enhanced Workout Plan Viewer with session mode, progress tracking, and offline support
class WorkoutPlanViewerScreen extends StatefulWidget {
  final String? planId;
  final WorkoutPlan? planOverride; // For offline/preview

  const WorkoutPlanViewerScreen({
    super.key,
    this.planId,
    this.planOverride,
  });

  @override
  State<WorkoutPlanViewerScreen> createState() =>
      _WorkoutPlanViewerScreenState();
}

class _WorkoutPlanViewerScreenState extends State<WorkoutPlanViewerScreen>
    with TickerProviderStateMixin {
  // Services
  final WorkoutService _workoutService = WorkoutService();
  final AIUsageService _aiUsageService = AIUsageService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  bool _loading = true;
  WorkoutPlan? _currentPlan;
  String? _errorMessage;

  // Navigation
  int _currentWeekIndex = 0;
  int _currentDayIndex = 0;
  TabController? _weekTabController;
  PageController? _dayPageController;

  // Session mode
  bool _isSessionActive = false;
  WorkoutSessionManager? _sessionManager;
  DateTime? _sessionStartTime;

  // AI Usage
  Map<String, dynamic>? _aiUsage;

  // Exercise completion tracking
  final Map<String, ExerciseCompletionData> _completedExercises = {};

  // Rest timer
  RestTimerController? _restTimerController;

  // Offline support
  bool _isOffline = false;
  Timer? _syncTimer;

  // View mode
  ViewMode _viewMode = ViewMode.overview;

  @override
  void initState() {
    super.initState();
    _initialize();
    _startSyncTimer();
  }

  @override
  void dispose() {
    _weekTabController?.dispose();
    _dayPageController?.dispose();
    _syncTimer?.cancel();
    // _sessionManager does not have a dispose method
    _restTimerController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _loading = true);

    try {
      await Future.wait([
        _loadPlan(),
        _loadAIUsage(),
        _loadCompletionData(),
      ]);

      _initializeControllers();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load workout plan: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPlan() async {
    if (widget.planOverride != null) {
      setState(() => _currentPlan = widget.planOverride);
      return;
    }

    if (widget.planId == null) {
      throw Exception('No plan ID provided');
    }

    try {
      final plan = await _workoutService.fetchPlan(widget.planId!);
      if (plan != null) {
        setState(() => _currentPlan = plan);

        // Mark as seen
        if (plan.unseenUpdate) {
          await _workoutService.markPlanSeen(widget.planId!);
        }
      } else {
        throw Exception('Plan not found');
      }
    } catch (e) {
      debugPrint('❌ Failed to load plan: $e');
      rethrow;
    }
  }

  Future<void> _loadAIUsage() async {
    try {
      final usage = await _aiUsageService.getCurrentUsage();
      setState(() => _aiUsage = usage);
    } catch (e) {
      debugPrint('❌ Failed to load AI usage: $e');
    }
  }

  Future<void> _loadCompletionData() async {
    // TODO: Load from local storage or database
    // For now, initialize empty
  }

  void _initializeControllers() {
    if (_currentPlan == null) return;

    _weekTabController = TabController(
      length: _currentPlan!.weeks.length,
      vsync: this,
      initialIndex: _currentWeekIndex,
    );

    _weekTabController!.addListener(() {
      if (_weekTabController!.indexIsChanging) {
        setState(() {
          _currentWeekIndex = _weekTabController!.index;
          _currentDayIndex = 0;
        });
      }
    });

    _dayPageController = PageController(initialPage: _currentDayIndex);
    _restTimerController = RestTimerController();
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _syncData();
    });
  }

  Future<void> _syncData() async {
    if (_isOffline) return;

    try {
      // Sync completion data to server
      for (final entry in _completedExercises.entries) {
        final data = entry.value;
        if (!data.synced) {
          await _workoutService.recordExerciseCompletion(
            clientId: _supabase.auth.currentUser!.id,
            exerciseId: data.exerciseId,
            completedSets: data.completedSets,
            completedReps: data.completedReps,
            weightUsed: data.weightUsed,
            rirActual: data.rpeRating,
            notes: data.notes,
            formRating: data.formRating,
            difficultyRating: data.difficultyRating,
          );

          setState(() {
            _completedExercises[entry.key] =
                data.copyWith(synced: true);
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
      setState(() => _isOffline = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initialize,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPlan == null) {
      return const Scaffold(
        body: Center(child: Text('No workout plan available')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_currentPlan!.name),
          if (_isSessionActive)
            Text(
              'Session: ${_getSessionDuration()}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      actions: [
        // Offline indicator
        if (_isOffline)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.cloud_off, color: Colors.orange),
          ),

        // View mode toggle
        IconButton(
          icon: Icon(_viewMode == ViewMode.overview
              ? Icons.view_list
              : Icons.dashboard),
          onPressed: () {
            setState(() {
              _viewMode = _viewMode == ViewMode.overview
                  ? ViewMode.session
                  : ViewMode.overview;
            });
          },
          tooltip: 'Toggle view mode',
        ),

        // More options
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export_pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text('Export as PDF'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('View History'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            // AI Usage Meter (compact)
            _buildAIUsageMeter(),

            // Week tabs
            _buildWeekTabs(),

            // Day carousel indicators
            _buildDayIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildAIUsageMeter() {
    if (_aiUsage == null) return const SizedBox.shrink();

    final used = _aiUsage!['requests_this_month'] ?? 0;
    final limit = _aiUsage!['monthly_limit'] ?? 100;
    final percentage = (used / limit * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.psychology, size: 16),
          const SizedBox(width: 8),
          Text('AI: $used/$limit', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              color: percentage > 80 ? Colors.orange : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTabs() {
    return TabBar(
      controller: _weekTabController,
      isScrollable: true,
      tabs: List.generate(
        _currentPlan!.weeks.length,
            (index) => Tab(
          text: 'Week ${index + 1}',
          icon: _getWeekCompletionIcon(index),
        ),
      ),
    );
  }

  Widget _buildDayIndicators() {
    if (_currentPlan!.weeks.isEmpty) return const SizedBox.shrink();

    final currentWeek = _currentPlan!.weeks[_currentWeekIndex];

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: currentWeek.days.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentDayIndex;
          final day = currentWeek.days[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _currentDayIndex = index);
                _dayPageController?.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      day.label.isEmpty ? 'Day ${index + 1}' : day.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    if (_isDayCompleted(_currentWeekIndex, index))
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_viewMode == ViewMode.session && _isSessionActive) {
      return _buildSessionMode();
    }

    return _buildOverviewMode();
  }

  Widget _buildOverviewMode() {
    final currentWeek = _currentPlan!.weeks[_currentWeekIndex];

    return PageView.builder(
      controller: _dayPageController,
      itemCount: currentWeek.days.length,
      onPageChanged: (index) {
        setState(() => _currentDayIndex = index);
      },
      itemBuilder: (context, index) {
        final day = currentWeek.days[index];
        return _buildDayContent(day);
      },
    );
  }

  Widget _buildDayContent(WorkoutDay day) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day summary card
          _buildDaySummaryCard(day),

          const SizedBox(height: 16),

          // Muscle activation visual (not yet implemented)
          // if (day.exercises.isNotEmpty) ...[
          //   MuscleActivationVisual(exercises: day.exercises),
          //   const SizedBox(height: 16),
          // ],

          // Exercises
          if (day.exercises.isNotEmpty) ...[
            const Text(
              'Exercises',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...day.exercises.map((exercise) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExerciseCompletionWidget(
                  exercise: exercise,
                  completionData: _getCompletionData(exercise),
                  onComplete: () => _handleExerciseComplete(exercise, _getCompletionData(exercise) ?? ExerciseCompletionData.initial(exercise)),
                  onDataChanged: (data) => _updateCompletionData(exercise, data),
                  onPlayDemo: () => _showExerciseDemo(exercise),
                  onViewHistory: () => _showExerciseHistory(exercise),
                  onRequestSubstitution: () =>
                      _requestSubstitution(exercise),
                  isSessionActive: _isSessionActive,
                ),
              );
            }),
          ],

          // Cardio sessions
          if (day.cardioSessions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Cardio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...day.cardioSessions.map((cardio) => Card(
              child: ListTile(
                leading: const Icon(Icons.directions_run),
                title: Text(cardio.machineType?.displayName ?? 'Cardio'),
                subtitle: Text(cardio.getDisplaySummary()),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _startCardioSession(cardio),
                ),
              ),
            )),
          ],

          // Day notes section
          const SizedBox(height: 24),
          _buildDayNotesSection(day),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildDaySummaryCard(WorkoutDay day) {
    final summary = day.getDaySummary();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isDayCompleted(_currentWeekIndex, _currentDayIndex))
                  const Chip(
                    label: Text('Completed'),
                    avatar: Icon(Icons.check, size: 16),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  Icons.fitness_center,
                  '${day.exercises.length}',
                  'Exercises',
                ),
                _buildSummaryItem(
                  Icons.schedule,
                  summary.getDurationDisplay(),
                  'Duration',
                ),
                _buildSummaryItem(
                  Icons.trending_up,
                  summary.getVolumeDisplay(),
                  'Volume',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDayNotesSection(WorkoutDay day) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: day.clientComment),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add notes about this workout...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _updateDayComment(day, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionMode() {
    // TODO: Implement full session mode UI
    return const Center(
      child: Text('Session Mode - Coming Soon'),
    );
  }

  Widget _buildBottomBar() {
    if (_isSessionActive) {
      return _buildSessionBottomBar();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous day button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _canGoPrevious() ? _goToPreviousDay : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          ),

          const SizedBox(width: 16),

          // Next day button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _canGoNext() ? _goToNextDay : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Current exercise info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise ${(_sessionManager?.currentExerciseIndex ?? 0) + 1}/${_sessionManager?.day.exercises.length ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _sessionManager?.getCurrentExercise()?.name ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // End session button
          ElevatedButton(
            onPressed: _endSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_isSessionActive) return null;

    final currentDay = _currentPlan!.weeks[_currentWeekIndex].days[_currentDayIndex];

    if (currentDay.isRestDay) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: _startSession,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Workout'),
      backgroundColor: Colors.green,
    );
  }

  // Helper methods

  Icon _getWeekCompletionIcon(int weekIndex) {
    // TODO: Calculate actual completion percentage
    return const Icon(Icons.fitness_center, size: 16);
  }

  bool _isDayCompleted(int weekIndex, int dayIndex) {
    // TODO: Check if all exercises in day are completed
    return false;
  }

  ExerciseCompletionData? _getCompletionData(Exercise exercise) {
    if (exercise.id == null) return null;
    return _completedExercises[exercise.id];
  }

  void _handleExerciseComplete(
      Exercise exercise, ExerciseCompletionData data) {
    setState(() {
      if (exercise.id != null) {
        _completedExercises[exercise.id!] = data;
      }
    });

    // Trigger sync
    _syncData();
  }

  void _updateCompletionData(Exercise exercise, ExerciseCompletionData data) {
    setState(() {
      if (exercise.id != null) {
        _completedExercises[exercise.id!] = data;
      }
    });
  }

  void _showExerciseDemo(Exercise exercise) {
    // TODO: Implement exercise demo player
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo player for ${exercise.name} - coming soon!'),
      ),
    );
  }

  void _showExerciseHistory(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ProgressChartWidget(
          exerciseName: exercise.name,
          clientId: _supabase.auth.currentUser?.id ?? '',
        ),
      ),
    );
  }

  void _requestSubstitution(Exercise exercise) {
    // TODO: Implement exercise substitution request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Substitution request sent for ${exercise.name}'),
      ),
    );
  }

  void _startCardioSession(CardioSession cardio) {
    // TODO: Implement cardio session mode
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cardio.machineType?.displayName ?? 'Cardio'),
        content: Text(cardio.getDisplaySummary()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start cardio timer
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDayComment(WorkoutDay day, String comment) async {
    if (_currentPlan?.id == null) return;

    try {
      await _workoutService.updateDayComment(
        _currentPlan!.id!,
        _currentWeekIndex + 1,
        _currentDayIndex + 1,
        comment,
      );
    } catch (e) {
      debugPrint('❌ Failed to update comment: $e');
    }
  }

  void _startSession() {
    final currentDay =
    _currentPlan!.weeks[_currentWeekIndex].days[_currentDayIndex];

    setState(() {
      _isSessionActive = true;
      _sessionStartTime = DateTime.now();
      _sessionManager = WorkoutSessionManager(
        day: currentDay,
        onExerciseComplete: (exerciseId, data) {
          // Find the exercise by ID and call the handler
          final exercise = currentDay.exercises.firstWhere(
            (e) => e.id == exerciseId,
            orElse: () => currentDay.exercises.first,
          );
          _handleExerciseComplete(exercise, data);
        },
        onSessionComplete: _endSession,
      );
    });
  }

  void _endSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Workout Session?'),
        content: Text(
            'You\'ve been working out for ${_getSessionDuration()}. End session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isSessionActive = false;
                // _sessionManager does not have a dispose method
                _sessionManager = null;
                _sessionStartTime = null;
              });
              Navigator.pop(context);
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  String _getSessionDuration() {
    if (_sessionStartTime == null) return '0:00';

    final duration = DateTime.now().difference(_sessionStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool _canGoPrevious() {
    return _currentDayIndex > 0 ||
        (_currentWeekIndex > 0 && _currentDayIndex == 0);
  }

  bool _canGoNext() {
    final currentWeek = _currentPlan!.weeks[_currentWeekIndex];
    return _currentDayIndex < currentWeek.days.length - 1 ||
        _currentWeekIndex < _currentPlan!.weeks.length - 1;
  }

  void _goToPreviousDay() {
    if (_currentDayIndex > 0) {
      setState(() => _currentDayIndex--);
      _dayPageController?.animateToPage(
        _currentDayIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentWeekIndex > 0) {
      setState(() {
        _currentWeekIndex--;
        _currentDayIndex =
            _currentPlan!.weeks[_currentWeekIndex].days.length - 1;
      });
      _weekTabController?.animateTo(_currentWeekIndex);
    }
  }

  void _goToNextDay() {
    final currentWeek = _currentPlan!.weeks[_currentWeekIndex];

    if (_currentDayIndex < currentWeek.days.length - 1) {
      setState(() => _currentDayIndex++);
      _dayPageController?.animateToPage(
        _currentDayIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentWeekIndex < _currentPlan!.weeks.length - 1) {
      setState(() {
        _currentWeekIndex++;
        _currentDayIndex = 0;
      });
      _weekTabController?.animateTo(_currentWeekIndex);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_pdf':
        _exportToPdf();
        break;
      case 'share':
        _sharePlan();
        break;
      case 'history':
        _showHistory();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  Future<void> _exportToPdf() async {
    if (_currentPlan == null) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get user profile for names
      final profile = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .single();

      // TODO: PDF export temporarily disabled due to Windows path resolution issue
      // await _workoutService.exportWorkoutPlanToPdf(
      //   _currentPlan!,
      //   'Coach', // TODO: Get actual coach name
      //   profile['name'] ?? 'Client',
      // );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF export temporarily disabled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e')),
      );
    }
  }

  void _sharePlan() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _showHistory() {
    // TODO: Navigate to workout history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History view coming soon')),
    );
  }

  void _showSettings() {
    // TODO: Show settings dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Viewer Settings'),
        content: const Text('Settings options coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Enums and helper classes

enum ViewMode {
  overview,
  session,
}

// ExerciseCompletionData is defined in widgets/exercise_completion_widget.dart

class RestTimerController {
  // TODO: Implement rest timer controller
  void dispose() {}
}