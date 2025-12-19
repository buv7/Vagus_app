// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/workout/workout_plan.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// Detailed Weekly Volume Screen
/// Shows comprehensive volume analytics with charts and detailed breakdowns
class WeeklyVolumeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> analytics;
  final int weekNumber;
  final int totalWeeks;
  final String? planName;
  final WorkoutWeek? weekData;
  final WorkoutPlan? plan; // For week comparison

  const WeeklyVolumeDetailScreen({
    super.key,
    required this.analytics,
    required this.weekNumber,
    required this.totalWeeks,
    this.planName,
    this.weekData,
    this.plan,
  });

  @override
  State<WeeklyVolumeDetailScreen> createState() =>
      _WeeklyVolumeDetailScreenState();
}

class _WeeklyVolumeDetailScreenState extends State<WeeklyVolumeDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedDayIndex; // For expandable day details
  Map<String, dynamic>? _previousWeekAnalytics;
  Map<String, dynamic>? _nextWeekAnalytics;
  List<double> _weeklyVolumes = []; // For trend chart
  late int _currentWeekNumber;
  Map<String, dynamic>? _currentAnalytics; // Cached analytics for current week
  
  // Sorting & Filtering state
  String _daySortOrder = 'default'; // 'default', 'volume_high', 'volume_low'
  bool _showEmptyDays = true;
  Set<String> _selectedMuscleGroups = {}; // Empty = show all
  
  // Animation & Loading
  bool _isLoadingWeek = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Performance: Memoization cache
  final Map<String, Map<String, dynamic>> _analyticsCache = {};
  List<Map<String, dynamic>>? _cachedSortedDays;
  String? _lastSortKey; // Cache key for sorted days
  Map<String, double>? _cachedFilteredMuscleGroups;
  String? _lastFilterKey; // Cache key for filtered muscle groups

  @override
  void initState() {
    super.initState();
    _currentWeekNumber = widget.weekNumber;
    _initializeAnimations();
    _calculateWeekComparisons();
    _loadCurrentWeekAnalytics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  void _loadCurrentWeekAnalytics() {
    if (widget.plan == null) {
      _currentAnalytics = widget.analytics;
      return;
    }

    final weekIndex = _currentWeekNumber - 1;
    if (weekIndex >= 0 && weekIndex < widget.plan!.weeks.length) {
      // Check cache first
      final cacheKey = 'week_${_currentWeekNumber}_${widget.plan!.id ?? "default"}';
      if (_analyticsCache.containsKey(cacheKey)) {
        _currentAnalytics = _analyticsCache[cacheKey];
        return;
      }

      // Calculate and cache
      final week = widget.plan!.weeks[weekIndex];
      _currentAnalytics = _calculateAnalyticsForWeekFull(week);
      _analyticsCache[cacheKey] = _currentAnalytics!;
    } else {
      _currentAnalytics = widget.analytics;
    }
  }

  void _navigateToWeek(int weekNumber) {
    if (weekNumber < 1 || weekNumber > widget.totalWeeks) return;
    if (weekNumber == _currentWeekNumber) return;

    setState(() {
      _isLoadingWeek = true;
      _currentWeekNumber = weekNumber;
      _selectedDayIndex = null; // Reset expanded day
      _cachedSortedDays = null; // Clear cache
      _lastSortKey = null;
      _cachedFilteredMuscleGroups = null;
      _lastFilterKey = null;
    });

    // Animate out
    _animationController.reverse().then((_) {
      if (!mounted) return;
      _loadCurrentWeekAnalytics();
      _calculateWeekComparisons();
      
      // Animate in
      if (mounted) {
        setState(() {
          _isLoadingWeek = false;
        });
        _animationController.forward();
      }
    });
  }

  void _calculateWeekComparisons() {
    if (widget.plan == null) return;

    // Calculate analytics for all weeks for trend chart
    _weeklyVolumes = [];
    for (int i = 0; i < widget.plan!.weeks.length; i++) {
      final weekAnalytics = _calculateAnalyticsForWeek(widget.plan!.weeks[i]);
      _weeklyVolumes.add(weekAnalytics['totalVolume'] as double? ?? 0.0);
    }

    // Calculate previous week analytics
    if (_currentWeekNumber > 1) {
      final prevWeekIndex = _currentWeekNumber - 2;
      if (prevWeekIndex >= 0 && prevWeekIndex < widget.plan!.weeks.length) {
        _previousWeekAnalytics = _calculateAnalyticsForWeekFull(
          widget.plan!.weeks[prevWeekIndex],
        );
      } else {
        _previousWeekAnalytics = null;
      }
    } else {
      _previousWeekAnalytics = null;
    }

    // Calculate next week analytics
    if (_currentWeekNumber < widget.totalWeeks) {
      final nextWeekIndex = _currentWeekNumber;
      if (nextWeekIndex < widget.plan!.weeks.length) {
        _nextWeekAnalytics = _calculateAnalyticsForWeekFull(
          widget.plan!.weeks[nextWeekIndex],
        );
      } else {
        _nextWeekAnalytics = null;
      }
    } else {
      _nextWeekAnalytics = null;
    }
  }

  Map<String, dynamic> _calculateAnalyticsForWeekFull(WorkoutWeek week) {
    // Full calculation with all details (similar to original analytics calculation)
    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;
    int totalMinutes = 0;
    int activeDays = 0;
    final Map<String, double> muscleGroupVolumes = {};
    final List<double> dailyVolumes = [];
    final List<Map<String, dynamic>> dailyDetails = [];

    for (final day in week.days) {
      double dayVolume = 0;
      int daySets = 0;
      int dayReps = 0;
      final List<Map<String, dynamic>> dayExercises = [];

      for (final exercise in day.exercises) {
        final volume = exercise.calculateVolume();
        if (volume != null) {
          dayVolume += volume;
          totalVolume += volume;
        }

        if (exercise.sets != null) {
          daySets += exercise.sets!;
          totalSets += exercise.sets!;
        }

        final repsNumeric = exercise.getRepsNumeric();
        if (repsNumeric != null && exercise.sets != null) {
          final exerciseReps = repsNumeric * exercise.sets!;
          dayReps += exerciseReps;
          totalReps += exerciseReps;
        }

        dayExercises.add({
          'name': exercise.name,
          'sets': exercise.sets,
          'reps': exercise.reps,
          'volume': volume ?? 0.0,
        });

        // Extract muscle groups
        final muscleGroups = _extractMuscleGroups(exercise.name);
        if (muscleGroups.isEmpty) {
          muscleGroupVolumes['Other'] =
              (muscleGroupVolumes['Other'] ?? 0.0) + (volume ?? 0.0);
        } else {
          for (final muscle in muscleGroups) {
            muscleGroupVolumes[muscle] =
                (muscleGroupVolumes[muscle] ?? 0.0) + (volume ?? 0.0);
          }
        }
      }

      dailyVolumes.add(dayVolume);
      dailyDetails.add({
        'exercises': dayExercises,
        'sets': daySets,
        'reps': dayReps,
        'volume': dayVolume,
        'duration': _estimateDayDuration(day),
      });

      if (day.exercises.isNotEmpty || day.cardioSessions.isNotEmpty) {
        activeDays++;
        totalMinutes += _estimateDayDuration(day);
      }
    }

    return {
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'totalMinutes': totalMinutes,
      'activeDays': activeDays,
      'muscleGroupVolumes': muscleGroupVolumes,
      'dailyVolumes': dailyVolumes,
      'dailyDetails': dailyDetails,
    };
  }

  int _estimateDayDuration(WorkoutDay day) {
    int duration = 0;
    for (final exercise in day.exercises) {
      if (exercise.sets != null) {
        duration += exercise.sets! * 2; // ~2 min per set
      }
    }
    for (final cardio in day.cardioSessions) {
      if (cardio.durationMinutes != null) {
        duration += cardio.durationMinutes!;
      }
    }
    return duration;
  }

  List<String> _extractMuscleGroups(String exerciseName) {
    final name = exerciseName.toLowerCase();
    final Set<String> muscles = {};

    if (name.contains('bench')) muscles.addAll(['Chest', 'Triceps', 'Shoulders']);
    if (name.contains('squat')) muscles.addAll(['Quads', 'Glutes', 'Hamstrings', 'Core']);
    if (name.contains('deadlift')) muscles.addAll(['Back', 'Glutes', 'Hamstrings']);
    if (name.contains('row')) muscles.addAll(['Back', 'Biceps']);
    if (name.contains('pull-up') || name.contains('pull up') || name.contains('chin')) {
      muscles.addAll(['Back', 'Biceps']);
    }
    if (name.contains('press') && !name.contains('bench')) {
      muscles.addAll(['Shoulders', 'Chest', 'Triceps']);
    }
    if (name.contains('overhead') || name.contains('ohp')) muscles.add('Shoulders');
    if (name.contains('lunge')) muscles.addAll(['Quads', 'Glutes']);
    if (name.contains('calf')) muscles.add('Calves');
    if (name.contains('curl')) muscles.add('Biceps');
    if (name.contains('extension') && name.contains('tricep')) muscles.add('Triceps');
    if (name.contains('dip')) muscles.add('Triceps');
    if (name.contains('crunch') || name.contains('plank') || name.contains('sit-up')) {
      muscles.add('Core');
    }
    if (name.contains('lat pulldown') || name.contains('pulldown')) {
      muscles.addAll(['Back', 'Biceps']);
    }
    if (name.contains('fly')) muscles.add('Chest');
    if (name.contains('shoulder') || name.contains('deltoid')) muscles.add('Shoulders');
    if (name.contains('leg press')) muscles.addAll(['Quads', 'Glutes']);
    if (name.contains('hamstring') || name.contains('leg curl')) muscles.add('Hamstrings');
    if (name.contains('quad') || name.contains('leg extension')) muscles.add('Quads');
    if (name.contains('glute')) muscles.add('Glutes');
    if (name.contains('back') && !name.contains('deadlift')) muscles.add('Back');
    if (name.contains('chest')) muscles.add('Chest');
    if (name.contains('tricep')) muscles.add('Triceps');
    if (name.contains('bicep')) muscles.add('Biceps');

    return muscles.toList();
  }

  Map<String, dynamic> _calculateAnalyticsForWeek(WorkoutWeek week) {
    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;
    int totalMinutes = 0;
    int activeDays = 0;

    for (final day in week.days) {
      int daySets = 0;

      for (final exercise in day.exercises) {
        final volume = exercise.calculateVolume();
        if (volume != null) {
          totalVolume += volume;
        }

        if (exercise.sets != null) {
          daySets += exercise.sets!;
          totalSets += exercise.sets!;
        }

        final repsNumeric = exercise.getRepsNumeric();
        if (repsNumeric != null && exercise.sets != null) {
          totalReps += repsNumeric * exercise.sets!;
        }
      }

      if (day.exercises.isNotEmpty || day.cardioSessions.isNotEmpty) {
        activeDays++;
        // Estimate duration (simplified)
        totalMinutes += (daySets * 2); // ~2 min per set
      }
    }

    return {
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'totalMinutes': totalMinutes,
      'activeDays': activeDays,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Use current analytics if available, otherwise fall back to widget analytics
    final analytics = _currentAnalytics ?? widget.analytics;

    final dailyVolumes = analytics['dailyVolumes'] as List<double>? ?? [];
    final totalVolume = analytics['totalVolume'] as double? ?? 0.0;
    final totalSets = analytics['totalSets'] as int? ?? 0;
    final totalReps = analytics['totalReps'] as int? ?? 0;
    final totalMinutes = analytics['totalMinutes'] as int? ?? 0;
    final activeDays = analytics['activeDays'] as int? ?? 0;
    final muscleGroupVolumes =
        analytics['muscleGroupVolumes'] as Map<String, double>? ?? {};
    final dailyDetails =
        analytics['dailyDetails'] as List<Map<String, dynamic>>? ?? [];

    // Get current week data
    final currentWeekData =
        widget.plan != null &&
                _currentWeekNumber >= 1 &&
                _currentWeekNumber <= widget.plan!.weeks.length
            ? widget.plan!.weeks[_currentWeekNumber - 1]
            : widget.weekData;

    final avgVolumePerDay =
        activeDays > 0 ? totalVolume / activeDays : 0.0;
    final maxVolume = dailyVolumes.isNotEmpty
        ? dailyVolumes.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final minVolume =
        dailyVolumes.isNotEmpty && dailyVolumes.any((v) => v > 0)
            ? dailyVolumes
                .where((v) => v > 0)
                .reduce((a, b) => a < b ? a : b)
            : 0.0;

    // Check if this is an empty week
    final isEmptyWeek =
        totalVolume == 0 && totalSets == 0 && activeDays == 0;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _isLoadingWeek
                  ? _buildLoadingState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: isEmptyWeek
                            ? _buildEmptyWeekState()
                            : Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Total Volume Hero Card with Comparison
                                  _buildTotalVolumeCard(
                                    totalVolume,
                                    previousVolume:
                                        _previousWeekAnalytics?[
                                                'totalVolume']
                                            as double?,
                                    nextVolume:
                                        _nextWeekAnalytics?[
                                                'totalVolume']
                                            as double?,
                                  ),

                                  const SizedBox(height: 16),

                                  // Week Comparison Card
                                  if (_previousWeekAnalytics != null ||
                                      _nextWeekAnalytics != null)
                                    _buildWeekComparisonCard(),

                                  const SizedBox(height: 16),

                                  // Trend Chart (if multiple weeks available)
                                  if (_weeklyVolumes.length > 1)
                                    RepaintBoundary(
                                      child: _buildTrendChart(),
                                    ),

                                  const SizedBox(height: 16),

                                  // Summary Metrics
                                  _buildSummaryMetricsCard(
                                    avgVolumePerDay,
                                    totalSets,
                                    totalReps,
                                    totalMinutes,
                                    activeDays,
                                    maxVolume,
                                    minVolume,
                                  ),

                                  const SizedBox(height: 16),

                                  // Daily Volume Chart (wrapped in RepaintBoundary for performance)
                                  if (dailyVolumes.isNotEmpty &&
                                      dailyVolumes.any((v) => v > 0))
                                    RepaintBoundary(
                                      child: _buildDailyVolumeChart(
                                          dailyVolumes),
                                    )
                                  else
                                    _buildEmptyDailyChartState(),

                                  const SizedBox(height: 16),

                                  // Daily Breakdown with Sorting
                                  if (dailyVolumes.isNotEmpty &&
                                      dailyDetails.isNotEmpty) ...[
                                    _buildDailyBreakdownHeader(
                                        totalVolume),
                                    const SizedBox(height: 12),
                                    _buildDailyBreakdown(
                                      dailyVolumes,
                                      dailyDetails,
                                      totalVolume,
                                    ),
                                  ] else
                                    _buildEmptyDailyBreakdownState(),

                                  const SizedBox(height: 16),

                                  // Volume Recommendations Card
                                  if (muscleGroupVolumes
                                          .isNotEmpty &&
                                      totalVolume > 0)
                                    _buildVolumeRecommendationsCard(
                                        muscleGroupVolumes,
                                        totalVolume)
                                  else
                                    _buildEmptyRecommendationsState(),

                                  const SizedBox(height: 16),

                                  // Muscle Group Distribution with Filtering (wrapped for performance)
                                  if (muscleGroupVolumes
                                          .isNotEmpty &&
                                      totalVolume > 0) ...[
                                    _buildMuscleGroupHeader(
                                        muscleGroupVolumes),
                                    const SizedBox(height: 12),
                                    RepaintBoundary(
                                      child: _buildMuscleGroupChart(
                                          muscleGroupVolumes,
                                          totalVolume),
                                    ),
                                    const SizedBox(height: 16),
                                    RepaintBoundary(
                                      child: _buildMuscleGroupCard(
                                          muscleGroupVolumes,
                                          totalVolume),
                                    ),
                                  ] else
                                    _buildEmptyMuscleGroupState(),

                                  const SizedBox(height: 16),

                                  // Exercise-Level Details (if available)
                                  if (currentWeekData != null &&
                                      currentWeekData.days.any((d) =>
                                          d.exercises.isNotEmpty))
                                    _buildExerciseDetails(
                                        currentWeekData)
                                  else if (currentWeekData != null)
                                    _buildEmptyExerciseDetailsState(),
                                ],
                              ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canGoPrevious = _currentWeekNumber > 1;
    final canGoNext = _currentWeekNumber < widget.totalWeeks;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.glassBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          // Share/Export button
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _showShareOptions(),
            tooltip: 'Share',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Volume Details',
                  style: DesignTokens.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Previous Week Button
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: canGoPrevious ? Colors.white : Colors.white38,
                      ),
                      onPressed: canGoPrevious
                          ? () => _navigateToWeek(_currentWeekNumber - 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                      tooltip: 'Previous Week',
                    ),
                    
                    // Week Selector
                    GestureDetector(
                      onTap: () => _showWeekSelector(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: DesignTokens.accentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Week $_currentWeekNumber',
                              style: DesignTokens.bodyMedium.copyWith(
                                color: DesignTokens.accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              color: DesignTokens.accentGreen,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Text(
                      ' of ${widget.totalWeeks}',
                      style: DesignTokens.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    
                    // Next Week Button
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: canGoNext ? Colors.white : Colors.white38,
                      ),
                      onPressed: canGoNext
                          ? () => _navigateToWeek(_currentWeekNumber + 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                      tooltip: 'Next Week',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWeekSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Week',
              style: DesignTokens.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                widget.totalWeeks,
                (index) {
                  final weekNumber = index + 1;
                  final isSelected = weekNumber == _currentWeekNumber;
                  return GestureDetector(
                    onTap: () {
                      _navigateToWeek(weekNumber);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DesignTokens.accentGreen
                            : DesignTokens.primaryDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? DesignTokens.accentGreen
                              : DesignTokens.glassBorder,
                        ),
                      ),
                      child: Text(
                        'Week $weekNumber',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: isSelected
                              ? AppTheme.primaryDark
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalVolumeCard(
    double totalVolume, {
    double? previousVolume,
    double? nextVolume,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentGreen.withValues(alpha: 0.2),
            DesignTokens.accentBlue.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total Weekly Volume',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatVolume(totalVolume),
            style: DesignTokens.displayMedium.copyWith(
              color: DesignTokens.accentGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Comparison indicators
          if (previousVolume != null || nextVolume != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (previousVolume != null)
                  _buildComparisonBadge(
                    'vs Prev',
                    previousVolume,
                    totalVolume,
                    isPrevious: true,
                  ),
                if (previousVolume != null && nextVolume != null)
                  const SizedBox(width: 12),
                if (nextVolume != null)
                  _buildComparisonBadge(
                    'vs Next',
                    nextVolume,
                    totalVolume,
                    isPrevious: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetricsCard(
    double avgVolumePerDay,
    int totalSets,
    int totalReps,
    int totalMinutes,
    int activeDays,
    double maxVolume,
    double minVolume,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary Metrics',
            style: DesignTokens.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricChip(
                'Avg per Day',
                _formatVolume(avgVolumePerDay),
                Icons.trending_up,
                DesignTokens.accentBlue,
              ),
              _buildMetricChip(
                'Total Sets',
                totalSets.toString(),
                Icons.format_list_numbered,
                DesignTokens.accentOrange,
              ),
              _buildMetricChip(
                'Total Reps',
                totalReps.toString(),
                Icons.repeat,
                DesignTokens.accentPurple,
              ),
              _buildMetricChip(
                'Total Time',
                '$totalMinutes min',
                Icons.access_time,
                DesignTokens.accentPink,
              ),
              _buildMetricChip(
                'Active Days',
                '$activeDays days',
                Icons.calendar_today,
                DesignTokens.accentTeal,
              ),
              if (maxVolume > 0)
                _buildMetricChip(
                  'Peak Day',
                  _formatVolume(maxVolume),
                  Icons.arrow_upward,
                  DesignTokens.accentGreen,
                ),
              if (minVolume > 0 && minVolume != maxVolume)
                _buildMetricChip(
                  'Lowest Day',
                  _formatVolume(minVolume),
                  Icons.arrow_downward,
                  Colors.orange,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: DesignTokens.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: DesignTokens.labelSmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyVolumeChart(List<double> dailyVolumes) {
    final maxVolume = dailyVolumes.reduce((a, b) => a > b ? a : b);
    if (maxVolume <= 0) return const SizedBox.shrink();

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Volume Distribution',
            style: DesignTokens.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVolume * 1.1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipBgColor: AppTheme.cardBackground,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayIndex = group.x.toInt();
                      final volume = rod.toY;
                      return BarTooltipItem(
                        '${dayNames[dayIndex]}\n${_formatVolume(volume)}',
                        DesignTokens.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _formatVolumeCompact(value),
                          style: DesignTokens.labelSmall.copyWith(
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dayIndex = value.toInt();
                        if (dayIndex < 0 || dayIndex >= dayNames.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayNames[dayIndex],
                            style: DesignTokens.labelSmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: DesignTokens.glassBorder,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: List.generate(
                  dailyVolumes.length,
                  (index) {
                    final volume = dailyVolumes[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: volume,
                          color: DesignTokens.accentGreen,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdownHeader(double totalVolume) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Daily Breakdown',
              style: DesignTokens.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.sort,
              color: Colors.white70,
              size: 20,
            ),
            tooltip: 'Sort options',
            onSelected: (value) {
              setState(() {
                _daySortOrder = value;
                _clearFilterCaches(); // Clear cache when sort changes
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'default',
                child: Row(
                  children: [
                    Icon(
                      _daySortOrder == 'default'
                          ? Icons.check
                          : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Default order'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'volume_high',
                child: Row(
                  children: [
                    Icon(
                      _daySortOrder == 'volume_high'
                          ? Icons.check
                          : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Highest volume first'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'volume_low',
                child: Row(
                  children: [
                    Icon(
                      _daySortOrder == 'volume_low'
                          ? Icons.check
                          : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Lowest volume first'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Toggle empty days
          IconButton(
            icon: Icon(
              _showEmptyDays ? Icons.visibility : Icons.visibility_off,
              color: _showEmptyDays ? DesignTokens.accentGreen : Colors.white38,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showEmptyDays = !_showEmptyDays;
                _clearFilterCaches(); // Clear cache when filter changes
              });
            },
            tooltip: _showEmptyDays ? 'Hide empty days' : 'Show empty days',
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown(
    List<double> dailyVolumes,
    List<Map<String, dynamic>> dailyDetails,
    double totalVolume,
  ) {
    // Memoization: Check cache
    final sortKey = '${_daySortOrder}_${_showEmptyDays}_${dailyVolumes.length}_${dailyVolumes.hashCode}';
    List<Map<String, dynamic>> filteredDaysList;
    
    if (_lastSortKey == sortKey && _cachedSortedDays != null) {
      // Use cached result
      filteredDaysList = _cachedSortedDays!;
    } else {
      // Recalculate
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];

      // Create indexed list for sorting
      final indexedDays = dailyVolumes.asMap().entries.map((entry) {
        return MapEntry(entry.key, {
          'index': entry.key,
          'name': dayNames[entry.key],
          'volume': entry.value,
          'details': entry.key < dailyDetails.length ? dailyDetails[entry.key] : null,
        });
      }).toList();

      // Apply sorting
      if (_daySortOrder == 'volume_high') {
        indexedDays.sort((a, b) => (b.value['volume'] as double).compareTo(a.value['volume'] as double));
      } else if (_daySortOrder == 'volume_low') {
        indexedDays.sort((a, b) => (a.value['volume'] as double).compareTo(b.value['volume'] as double));
      }

      // Filter empty days if needed
      final filteredDaysMap = _showEmptyDays
          ? indexedDays
          : indexedDays.where((day) => (day.value['volume'] as double) > 0).toList();

      // Cache result
      filteredDaysList = filteredDaysMap.map((e) => e.value as Map<String, dynamic>).toList();
      _cachedSortedDays = filteredDaysList;
      _lastSortKey = sortKey;
    }

    final filteredDaysData = filteredDaysList;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filteredDaysData.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No days to display',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            )
          else
            ...filteredDaysData.map((dayEntry) {
              final dayIndex = dayEntry['index'] as int;
              final dayName = dayEntry['name'] as String;
              final volume = dayEntry['volume'] as double;
              final dayDetail = dayEntry['details'] as Map<String, dynamic>?;
              final percentage = totalVolume > 0 ? (volume / totalVolume) * 100 : 0.0;
              final isExpanded = _selectedDayIndex == dayIndex.toString();

              return _buildDayCard(
                dayName,
                volume,
                percentage,
                isExpanded,
                dayDetail,
                dayIndex,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDayCard(
    String dayName,
    double volume,
    double percentage,
    bool isExpanded,
    Map<String, dynamic>? dayDetail,
    int dayIndex,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.primaryDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpanded
              ? DesignTokens.accentGreen
              : DesignTokens.glassBorder,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: DesignTokens.accentGreen.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Day Header (always visible)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: dayDetail != null
                  ? () {
                      setState(() {
                        _selectedDayIndex =
                            isExpanded ? null : dayIndex.toString();
                      });
                    }
                  : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: DesignTokens.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatVolume(volume),
                              style: DesignTokens.titleSmall.copyWith(
                                color: DesignTokens.accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.accentGreen
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: DesignTokens.labelSmall.copyWith(
                                  color: DesignTokens.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Progress Bar
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: DesignTokens.glassBorder,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: DesignTokens.accentGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (dayDetail != null) ...[
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.expand_more,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
              ),
            ),
          ),
          // Expanded Details with Animation
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: dayDetail != null
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryDark,
                      border: Border(
                        top: BorderSide(color: DesignTokens.glassBorder),
                      ),
                    ),
                    child: _buildDayDetails(dayDetail),
                  )
                : const SizedBox.shrink(),
            crossFadeState: isExpanded && dayDetail != null
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetails(Map<String, dynamic> dayDetail) {
    final exercises = dayDetail['exercises'] as List<dynamic>? ?? [];
    final sets = dayDetail['sets'] as int? ?? 0;
    final reps = dayDetail['reps'] as int? ?? 0;
    final duration = dayDetail['duration'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDetailStat('Sets', sets.toString(), Icons.format_list_numbered),
            _buildDetailStat('Reps', reps.toString(), Icons.repeat),
            _buildDetailStat('Time', '$duration min', Icons.access_time),
          ],
        ),
        if (exercises.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(color: DesignTokens.glassBorder),
          const SizedBox(height: 8),
          Text(
            'Exercises (${exercises.length})',
            style: DesignTokens.labelMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          ...exercises.map((ex) {
            final name = ex['name']?.toString() ?? 'Unknown';
            final exSets = ex['sets']?.toString() ?? '0';
            final exReps = ex['reps']?.toString() ?? '-';
            final exVolume = ex['volume'] as double? ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: DesignTokens.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '$exSets × $exReps',
                    style: DesignTokens.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatVolumeCompact(exVolume),
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: DesignTokens.accentGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: DesignTokens.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: DesignTokens.labelSmall.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupHeader(Map<String, double> muscleGroupVolumes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Muscle Group Distribution',
              style: DesignTokens.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Filter button
          IconButton(
            icon: Icon(
              _selectedMuscleGroups.isEmpty ? Icons.filter_list : Icons.filter_list_off,
              color: _selectedMuscleGroups.isEmpty ? Colors.white70 : DesignTokens.accentOrange,
              size: 20,
            ),
            onPressed: () => _showMuscleGroupFilter(muscleGroupVolumes),
            tooltip: 'Filter muscle groups',
          ),
        ],
      ),
    );
  }

  void _showMuscleGroupFilter(Map<String, double> muscleGroupVolumes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter Muscle Groups',
                    style: DesignTokens.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_selectedMuscleGroups.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedMuscleGroups.clear();
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: DesignTokens.accentOrange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedMuscleGroups.isEmpty
                  ? 'Showing all muscle groups'
                  : 'Showing ${_selectedMuscleGroups.length} of ${muscleGroupVolumes.length} groups',
              style: DesignTokens.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscleGroupVolumes.keys.map((group) {
                final isSelected = _selectedMuscleGroups.isEmpty ||
                    _selectedMuscleGroups.contains(group);
                return FilterChip(
                  selected: isSelected,
                  label: Text(group),
                  onSelected: (selected) {
                    setState(() {
                      if (_selectedMuscleGroups.isEmpty) {
                        // Initialize with all groups except the one being deselected
                        _selectedMuscleGroups = muscleGroupVolumes.keys
                            .where((g) => g != group)
                            .toSet();
                      } else if (selected) {
                        _selectedMuscleGroups.remove(group);
                        if (_selectedMuscleGroups.isEmpty) {
                          // If all are selected, clear selection (show all)
                          _selectedMuscleGroups = {};
                        }
                      } else {
                        _selectedMuscleGroups.add(group);
                      }
                      _clearFilterCaches(); // Clear cache when filter changes
                    });
                    Navigator.pop(context);
                  },
                  selectedColor: DesignTokens.accentGreen.withValues(alpha: 0.3),
                  checkmarkColor: DesignTokens.accentGreen,
                  labelStyle: DesignTokens.bodySmall.copyWith(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupChart(
    Map<String, double> muscleGroupVolumes,
    double totalVolume,
  ) {
    // Use cached filtered result if available (same filter as card)
    final filterKey = _selectedMuscleGroups.isEmpty
        ? 'all_${muscleGroupVolumes.length}'
        : 'filtered_${_selectedMuscleGroups.length}_${muscleGroupVolumes.length}';
    
    Map<String, double> filtered;
    if (_lastFilterKey == filterKey && _cachedFilteredMuscleGroups != null) {
      filtered = _cachedFilteredMuscleGroups!;
    } else {
      // Apply filter
      filtered = _selectedMuscleGroups.isEmpty
          ? muscleGroupVolumes
          : Map.fromEntries(
              muscleGroupVolumes.entries
                  .where((e) => !_selectedMuscleGroups.contains(e.key)),
            );
      // Cache result
      _cachedFilteredMuscleGroups = Map<String, double>.from(filtered);
      _lastFilterKey = filterKey;
    }

    final sorted = filtered.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGroups = sorted.take(6).toList(); // Top 6 for chart readability

    if (topGroups.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Group Distribution',
            style: DesignTokens.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: List.generate(
                  topGroups.length,
                  (index) {
                    final entry = topGroups[index];
                    final percentage = (entry.value / totalVolume) * 100;
                    final colors = [
                      DesignTokens.accentGreen,
                      DesignTokens.accentBlue,
                      DesignTokens.accentPurple,
                      DesignTokens.accentOrange,
                      DesignTokens.accentPink,
                      DesignTokens.accentTeal,
                    ];
                    
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: colors[index % colors.length],
                      radius: 80,
                      titleStyle: DesignTokens.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Can add interaction here if needed
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(
              topGroups.length,
              (index) {
                final entry = topGroups[index];
                final colors = [
                  DesignTokens.accentGreen,
                  DesignTokens.accentBlue,
                  DesignTokens.accentPurple,
                  DesignTokens.accentOrange,
                  DesignTokens.accentPink,
                  DesignTokens.accentTeal,
                ];
                final color = colors[index % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: DesignTokens.labelSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupCard(
    Map<String, double> muscleGroupVolumes,
    double totalVolume,
  ) {
    // Memoization: Check cache
    final filterKey = _selectedMuscleGroups.isEmpty
        ? 'all_${muscleGroupVolumes.length}'
        : 'filtered_${_selectedMuscleGroups.length}_${muscleGroupVolumes.length}';
    
    Map<String, double> filtered;
    if (_lastFilterKey == filterKey && _cachedFilteredMuscleGroups != null) {
      filtered = _cachedFilteredMuscleGroups!;
    } else {
      // Apply filter
      filtered = _selectedMuscleGroups.isEmpty
          ? muscleGroupVolumes
          : Map.fromEntries(
              muscleGroupVolumes.entries
                  .where((e) => !_selectedMuscleGroups.contains(e.key)),
            );
      // Cache result
      _cachedFilteredMuscleGroups = Map<String, double>.from(filtered);
      _lastFilterKey = filterKey;
    }

    final sorted = filtered.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume by Muscle Group',
            style: DesignTokens.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.map((entry) {
            final percentage = (entry.value / totalVolume) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatVolume(entry.value),
                            style: DesignTokens.bodyMedium.copyWith(
                              color: DesignTokens.accentGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.accentBlue
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: DesignTokens.labelSmall.copyWith(
                                color: DesignTokens.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: DesignTokens.glassBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: DesignTokens.accentBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExerciseDetails(WorkoutWeek week) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercise Details',
            style: DesignTokens.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...week.days.asMap().entries.map((dayEntry) {
            final dayIndex = dayEntry.key;
            final day = dayEntry.value;

            if (day.exercises.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.primaryDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.label.isNotEmpty ? day.label : 'Day ${dayIndex + 1}',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...day.exercises.map((exercise) {
                    final volume = exercise.calculateVolume() ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: DesignTokens.bodySmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (exercise.sets != null)
                            Text(
                              '${exercise.sets} sets',
                              style: DesignTokens.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          if (exercise.reps != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              exercise.reps!,
                              style: DesignTokens.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Text(
                            volume > 0 ? _formatVolumeCompact(volume) : '-',
                            style: DesignTokens.bodySmall.copyWith(
                              color: DesignTokens.accentGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k kg';
    }
    return '${volume.toStringAsFixed(0)} kg';
  }

  String _formatVolumeCompact(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }

  Widget _buildComparisonBadge(
    String label,
    double compareVolume,
    double currentVolume, {
    required bool isPrevious,
  }) {
    final difference = currentVolume - compareVolume;
    final percentageChange = compareVolume > 0
        ? (difference / compareVolume * 100)
        : 0.0;
    final isPositive = difference > 0;
    final isNeutral = difference.abs() < 50; // Less than 50kg difference = neutral

    Color color;
    IconData icon;
    if (isNeutral) {
      color = Colors.white70;
      icon = Icons.remove;
    } else if (isPositive) {
      color = DesignTokens.accentGreen;
      icon = isPrevious ? Icons.trending_up : Icons.arrow_upward;
    } else {
      color = Colors.orange;
      icon = isPrevious ? Icons.trending_down : Icons.arrow_downward;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$label: ${isNeutral ? "~" : isPositive ? "+" : ""}${percentageChange.abs().toStringAsFixed(1)}%',
            style: DesignTokens.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekComparisonCard() {
    final currentVolume = widget.analytics['totalVolume'] as double? ?? 0.0;
    final currentSets = widget.analytics['totalSets'] as int? ?? 0;
    final currentDays = widget.analytics['activeDays'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: DesignTokens.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Week Comparison',
                style: DesignTokens.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_previousWeekAnalytics != null) ...[
            _buildComparisonRow(
              'Previous Week',
              _previousWeekAnalytics!,
              currentVolume,
              currentSets,
              currentDays,
            ),
            if (_nextWeekAnalytics != null) const SizedBox(height: 12),
          ],
          if (_nextWeekAnalytics != null)
            _buildComparisonRow(
              'Next Week',
              _nextWeekAnalytics!,
              currentVolume,
              currentSets,
              currentDays,
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    Map<String, dynamic> compareData,
    double currentVolume,
    int currentSets,
    int currentDays,
  ) {
    final compareVolume = compareData['totalVolume'] as double? ?? 0.0;
    final compareSets = compareData['totalSets'] as int? ?? 0;
    final compareDays = compareData['activeDays'] as int? ?? 0;

    final volumeChange = currentVolume - compareVolume;
    final volumePercent = compareVolume > 0
        ? (volumeChange / compareVolume * 100)
        : 0.0;
    final setsChange = currentSets - compareSets;
    final daysChange = currentDays - compareDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DesignTokens.labelMedium.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildComparisonMetric(
                'Volume',
                _formatVolume(compareVolume),
                volumeChange,
                volumePercent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildComparisonMetric(
                'Sets',
                compareSets.toString(),
                setsChange.toDouble(),
                compareSets > 0 ? (setsChange / compareSets * 100) : 0.0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildComparisonMetric(
                'Days',
                compareDays.toString(),
                daysChange.toDouble(),
                compareDays > 0 ? (daysChange / compareDays * 100) : 0.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonMetric(
    String label,
    String value,
    double change,
    double percentChange,
  ) {
    final isPositive = change > 0;
    final isNeutral = change.abs() < 1;
    final color = isNeutral
        ? Colors.white70
        : (isPositive ? DesignTokens.accentGreen : Colors.orange);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DesignTokens.primaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DesignTokens.labelSmall.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isNeutral) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '${isPositive ? "+" : ""}${percentChange.toStringAsFixed(1)}%',
                  style: DesignTokens.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_weeklyVolumes.isEmpty || _weeklyVolumes.length < 2) {
      return const SizedBox.shrink();
    }

    final maxVolume = _weeklyVolumes.reduce((a, b) => a > b ? a : b);
    if (maxVolume <= 0) return const SizedBox.shrink();

    final currentWeekIndex = widget.weekNumber - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: DesignTokens.accentPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Volume Trend (All Weeks)',
                style: DesignTokens.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: DesignTokens.glassBorder,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _formatVolumeCompact(value),
                          style: DesignTokens.labelSmall.copyWith(
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final weekIndex = value.toInt();
                        if (weekIndex < 0 ||
                            weekIndex >= _weeklyVolumes.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'W${weekIndex + 1}',
                            style: DesignTokens.labelSmall.copyWith(
                              color: weekIndex == currentWeekIndex
                                  ? DesignTokens.accentGreen
                                  : Colors.white70,
                              fontWeight: weekIndex == currentWeekIndex
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _weeklyVolumes.length,
                      (index) => FlSpot(index.toDouble(), _weeklyVolumes[index]),
                    ),
                    isCurved: true,
                    color: DesignTokens.accentGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: index == currentWeekIndex ? 6 : 4,
                          color: index == currentWeekIndex
                              ? DesignTokens.accentGreen
                              : Colors.white70,
                          strokeWidth: 2,
                          strokeColor: AppTheme.primaryDark,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: DesignTokens.accentGreen.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.cardBackground,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Week ${spot.x.toInt() + 1}\n${_formatVolume(spot.y)}',
                          DesignTokens.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeRecommendationsCard(
    Map<String, double> muscleGroupVolumes,
    double totalVolume,
  ) {
    final recommendations = <Map<String, dynamic>>[];
    final balances = _calculateBalanceMetrics(muscleGroupVolumes, totalVolume);

    // Push/Pull Balance Analysis
    final pushPullRatio = balances['pushPullRatio'] as double;
    final pushPullStatus = _getBalanceStatus(pushPullRatio, targetRatio: 1.0, tolerance: 0.3);
    if (pushPullStatus != 'balanced') {
      recommendations.add({
        'type': 'push_pull',
        'title': 'Push/Pull Balance',
        'status': pushPullStatus,
        'ratio': pushPullRatio,
        'message': pushPullRatio > 1.3
            ? 'Push volume is ${(pushPullRatio * 100).toStringAsFixed(0)}% of pull volume. Consider adding more pulling exercises.'
            : 'Pull volume is ${((1 / pushPullRatio) * 100).toStringAsFixed(0)}% of push volume. Consider adding more pushing exercises.',
        'icon': pushPullStatus == 'over' ? Icons.trending_up : Icons.trending_down,
        'color': pushPullStatus == 'over' ? Colors.orange : DesignTokens.accentBlue,
      });
    } else {
      recommendations.add({
        'type': 'push_pull',
        'title': 'Push/Pull Balance',
        'status': 'balanced',
        'ratio': pushPullRatio,
        'message': 'Excellent balance between push and pull exercises.',
        'icon': Icons.check_circle,
        'color': DesignTokens.accentGreen,
      });
    }

    // Upper/Lower Balance Analysis
    final upperLowerRatio = balances['upperLowerRatio'] as double;
    final upperLowerStatus = _getBalanceStatus(upperLowerRatio, targetRatio: 1.0, tolerance: 0.5);
    if (upperLowerStatus != 'balanced') {
      recommendations.add({
        'type': 'upper_lower',
        'title': 'Upper/Lower Balance',
        'status': upperLowerStatus,
        'ratio': upperLowerRatio,
        'message': upperLowerRatio > 1.5
            ? 'Upper body volume is ${(upperLowerRatio * 100).toStringAsFixed(0)}% of lower body. Consider adding more leg exercises.'
            : 'Lower body volume is ${((1 / upperLowerRatio) * 100).toStringAsFixed(0)}% of upper body. Consider adding more upper body exercises.',
        'icon': upperLowerStatus == 'over' ? Icons.trending_up : Icons.trending_down,
        'color': upperLowerStatus == 'over' ? Colors.orange : DesignTokens.accentPurple,
      });
    } else {
      recommendations.add({
        'type': 'upper_lower',
        'title': 'Upper/Lower Balance',
        'status': 'balanced',
        'ratio': upperLowerRatio,
        'message': 'Well-balanced upper and lower body training.',
        'icon': Icons.check_circle,
        'color': DesignTokens.accentGreen,
      });
    }

    // Muscle Group Distribution Analysis
    final overdeveloped = balances['overdeveloped'] as List<String>;
    final underdeveloped = balances['underdeveloped'] as List<String>;

    if (overdeveloped.isNotEmpty) {
      recommendations.add({
        'type': 'overdeveloped',
        'title': 'Overdeveloped Muscle Groups',
        'status': 'warning',
        'message': '${overdeveloped.join(', ')} ${overdeveloped.length == 1 ? 'is' : 'are'} receiving high volume (>25%). Consider reducing to prevent imbalance.',
        'icon': Icons.warning,
        'color': Colors.orange,
        'muscleGroups': overdeveloped,
      });
    }

    if (underdeveloped.isNotEmpty) {
      recommendations.add({
        'type': 'underdeveloped',
        'title': 'Underdeveloped Muscle Groups',
        'status': 'warning',
        'message': 'Consider increasing volume for: ${underdeveloped.join(', ')} (<5% of total volume).',
        'icon': Icons.info,
        'color': DesignTokens.accentBlue,
        'muscleGroups': underdeveloped,
      });
    }

    if (recommendations.isEmpty || recommendations.every((r) => r['status'] == 'balanced')) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.accentGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: DesignTokens.accentGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excellent Balance',
                    style: DesignTokens.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your workout plan shows great balance across all muscle groups!',
                    style: DesignTokens.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: DesignTokens.accentOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Volume Recommendations',
                style: DesignTokens.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateBalanceMetrics(
    Map<String, double> muscleGroupVolumes,
    double totalVolume,
  ) {
    // Categorize muscle groups
    final pushGroups = ['Chest', 'Shoulders', 'Triceps'];
    final pullGroups = ['Back', 'Biceps'];
    final lowerGroups = ['Quads', 'Glutes', 'Hamstrings', 'Calves'];
    final coreGroups = ['Core'];

    // Calculate volumes by category
    double pushVolume = 0;
    double pullVolume = 0;
    double upperVolume = 0;
    double lowerVolume = 0;

    for (final entry in muscleGroupVolumes.entries) {
      final group = entry.key;
      final volume = entry.value;

      if (pushGroups.contains(group)) {
        pushVolume += volume;
        upperVolume += volume;
      } else if (pullGroups.contains(group)) {
        pullVolume += volume;
        upperVolume += volume;
      } else if (lowerGroups.contains(group)) {
        lowerVolume += volume;
      }
      if (!pushGroups.contains(group) &&
          !pullGroups.contains(group) &&
          !lowerGroups.contains(group) &&
          !coreGroups.contains(group)) {
        // Try to categorize "Other" groups by keyword
        final lower = group.toLowerCase();
        if (lower.contains('leg') ||
            lower.contains('quad') ||
            lower.contains('hamstring') ||
            lower.contains('glute') ||
            lower.contains('calf')) {
          lowerVolume += volume;
        } else {
          upperVolume += volume;
        }
      }
    }

    // Calculate ratios
    final pushPullRatio = pullVolume > 0 ? pushVolume / pullVolume : 0.0;
    final upperLowerRatio = lowerVolume > 0 ? upperVolume / lowerVolume : 0.0;

    // Find over/underdeveloped groups
    final overdeveloped = <String>[];
    final underdeveloped = <String>[];

    for (final entry in muscleGroupVolumes.entries) {
      final percentage = (entry.value / totalVolume) * 100;
      if (percentage > 25) {
        overdeveloped.add(entry.key);
      } else if (percentage < 5 && entry.value > 0) {
        underdeveloped.add(entry.key);
      }
    }

    return {
      'pushPullRatio': pushPullRatio,
      'upperLowerRatio': upperLowerRatio,
      'pushVolume': pushVolume,
      'pullVolume': pullVolume,
      'upperVolume': upperVolume,
      'lowerVolume': lowerVolume,
      'overdeveloped': overdeveloped,
      'underdeveloped': underdeveloped,
    };
  }

  String _getBalanceStatus(double ratio, {required double targetRatio, required double tolerance}) {
    final lowerBound = targetRatio - tolerance;
    final upperBound = targetRatio + tolerance;

    if (ratio >= lowerBound && ratio <= upperBound) {
      return 'balanced';
    } else if (ratio > upperBound) {
      return 'over';
    } else {
      return 'under';
    }
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    final status = recommendation['status'] as String;
    final color = recommendation['color'] as Color;
    final icon = recommendation['icon'] as IconData;
    final title = recommendation['title'] as String;
    final message = recommendation['message'] as String;
    final ratio = recommendation['ratio'] as double?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (ratio != null && status != 'balanced') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${ratio.toStringAsFixed(2)}:1',
                          style: DesignTokens.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: DesignTokens.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (recommendation['muscleGroups'] != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (recommendation['muscleGroups'] as List<String>)
                        .map((group) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.primaryDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                group,
                                style: DesignTokens.labelSmall.copyWith(
                                  color: color,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWeekState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: DesignTokens.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Workout Data for This Week',
              style: DesignTokens.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This week doesn\'t have any exercises or workout sessions yet.',
              style: DesignTokens.bodyMedium.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DesignTokens.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: DesignTokens.accentOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What to do next',
                        style: DesignTokens.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEmptyStateTip(
                    'Add exercises to your workout days',
                    'Tap on any day in your plan to add exercises',
                  ),
                  const SizedBox(height: 8),
                  _buildEmptyStateTip(
                    'This might be a rest week',
                    'Some programs include planned rest weeks for recovery',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateTip(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: DesignTokens.accentGreen,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DesignTokens.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: DesignTokens.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDailyChartState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: Colors.white38,
          ),
          const SizedBox(height: 16),
          Text(
            'No Daily Volume Data',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add exercises to your workout days to see volume distribution',
            style: DesignTokens.bodySmall.copyWith(
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDailyBreakdownState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            'No Daily Breakdown Available',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Once you add exercises to your workout days, you\'ll see a detailed breakdown here',
            style: DesignTokens.bodySmall.copyWith(
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendationsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 40,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            'Volume Recommendations',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add exercises to your workout plan to get personalized recommendations on push/pull balance, upper/lower balance, and muscle group distribution',
            style: DesignTokens.bodySmall.copyWith(
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMuscleGroupState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.radar_outlined,
            size: 40,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            'No Muscle Group Data',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Muscle group distribution will appear here once you add exercises to your workout plan',
            style: DesignTokens.bodySmall.copyWith(
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExerciseDetailsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 40,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            'No Exercise Details',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This week\'s days don\'t have any exercises yet. Start building your workout by adding exercises to each day',
            style: DesignTokens.bodySmall.copyWith(
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Weekly Volume',
              style: DesignTokens.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildShareOption(
              icon: Icons.text_fields,
              title: 'Share as Text',
              description: 'Share summary as formatted text',
              onTap: () {
                Navigator.pop(context);
                _shareAsText();
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              icon: Icons.image,
              title: 'Share as Image',
              description: 'Export as image (coming soon)',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Image export coming soon!'),
                    backgroundColor: DesignTokens.accentBlue,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              icon: Icons.description,
              title: 'Export as PDF',
              description: 'Generate PDF report (coming soon)',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('PDF export coming soon!'),
                    backgroundColor: DesignTokens.accentBlue,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: DesignTokens.accentBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: DesignTokens.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsText() async {
    try {
      final analytics = _currentAnalytics ?? widget.analytics;
      final totalVolume = analytics['totalVolume'] as double? ?? 0.0;
      final totalSets = analytics['totalSets'] as int? ?? 0;
      final totalReps = analytics['totalReps'] as int? ?? 0;
      final totalMinutes = analytics['totalMinutes'] as int? ?? 0;
      final activeDays = analytics['activeDays'] as int? ?? 0;
      final dailyVolumes = analytics['dailyVolumes'] as List<double>? ?? [];
      final muscleGroupVolumes = analytics['muscleGroupVolumes'] as Map<String, double>? ?? {};
      
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('📊 WEEKLY VOLUME SUMMARY');
      buffer.writeln('='.padRight(40, '='));
      buffer.writeln();
      
      if (widget.planName != null) {
        buffer.writeln('Plan: ${widget.planName}');
      }
      buffer.writeln('Week: $_currentWeekNumber of ${widget.totalWeeks}');
      buffer.writeln();
      buffer.writeln('-'.padRight(40, '-'));
      buffer.writeln();
      
      // Total Volume
      buffer.writeln('TOTAL WEEKLY VOLUME');
      buffer.writeln(_formatVolume(totalVolume));
      buffer.writeln();
      
      // Summary Metrics
      buffer.writeln('SUMMARY METRICS');
      buffer.writeln('Active Days: $activeDays');
      buffer.writeln('Total Sets: $totalSets');
      buffer.writeln('Total Reps: $totalReps');
      buffer.writeln('Total Time: $totalMinutes minutes');
      
      final avgVolumePerDay = activeDays > 0 ? totalVolume / activeDays : 0.0;
      buffer.writeln('Avg Volume/Day: ${_formatVolume(avgVolumePerDay)}');
      buffer.writeln();
      buffer.writeln('-'.padRight(40, '-'));
      buffer.writeln();
      
      // Daily Breakdown
      if (dailyVolumes.isNotEmpty) {
        buffer.writeln('DAILY BREAKDOWN');
        final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        for (int i = 0; i < dailyVolumes.length && i < dayNames.length; i++) {
          final volume = dailyVolumes[i];
          final percentage = totalVolume > 0 ? (volume / totalVolume * 100) : 0.0;
          buffer.writeln('${dayNames[i]}: ${_formatVolume(volume)} (${percentage.toStringAsFixed(1)}%)');
        }
        buffer.writeln();
        buffer.writeln('-'.padRight(40, '-'));
        buffer.writeln();
      }
      
      // Muscle Groups
      if (muscleGroupVolumes.isNotEmpty) {
        buffer.writeln('MUSCLE GROUP DISTRIBUTION');
        final sorted = muscleGroupVolumes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        for (final entry in sorted) {
          final percentage = (entry.value / totalVolume) * 100;
          buffer.writeln('${entry.key}: ${_formatVolume(entry.value)} (${percentage.toStringAsFixed(1)}%)');
        }
        buffer.writeln();
        buffer.writeln('-'.padRight(40, '-'));
        buffer.writeln();
      }
      
      // Recommendations Summary
      if (muscleGroupVolumes.isNotEmpty && totalVolume > 0) {
        final balances = _calculateBalanceMetrics(muscleGroupVolumes, totalVolume);
        final pushPullRatio = balances['pushPullRatio'] as double;
        final upperLowerRatio = balances['upperLowerRatio'] as double;
        
        buffer.writeln('BALANCE METRICS');
        buffer.writeln('Push/Pull Ratio: ${pushPullRatio.toStringAsFixed(2)}:1');
        buffer.writeln('Upper/Lower Ratio: ${upperLowerRatio.toStringAsFixed(2)}:1');
        buffer.writeln();
      }
      
      // Footer
      buffer.writeln('Generated by VAGUS App');
      buffer.writeln(DateTime.now().toString().split('.')[0]);
      
      await Share.share(
        buffer.toString(),
        subject: 'Weekly Volume Summary - Week $_currentWeekNumber',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to clear caches when filters change
  void _clearFilterCaches() {
    _cachedSortedDays = null;
    _lastSortKey = null;
    _cachedFilteredMuscleGroups = null;
    _lastFilterKey = null;
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accentGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading week data...',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
