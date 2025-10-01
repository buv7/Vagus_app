import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout/workout_plan.dart';
import '../../models/workout/exercise.dart';
import '../../models/workout/cardio_session.dart';
// TODO: PDF export temporarily disabled due to Windows path resolution issue
// import '../../models/workout/workout_summary.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:intl/intl.dart';
import 'dart:io';

/// Comprehensive workout service for managing workout plans, exercises, and tracking
class WorkoutService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // CORE CRUD OPERATIONS
  // =====================================================

  /// Create a new workout plan
  Future<String> createPlan(WorkoutPlan plan) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Insert the main plan
      final planResponse = await _supabase
          .from('workout_plans')
          .insert({
        'coach_id': plan.coachId,
        'client_id': plan.clientId,
        'name': plan.name,
        'description': plan.description,
        'duration_weeks': plan.durationWeeks,
        'start_date': plan.startDate?.toIso8601String().split('T')[0],
        'created_by': user.id,
        'is_template': plan.isTemplate,
        'template_category': plan.templateCategory,
        'ai_generated': plan.aiGenerated,
        'unseen_update': plan.unseenUpdate,
        'metadata': plan.metadata,
      })
          .select()
          .single();

      final planId = planResponse['id'].toString();

      // Insert weeks, days, and exercises
      for (final week in plan.weeks) {
        final weekResponse = await _supabase
            .from('workout_plan_weeks')
            .insert({
          'plan_id': planId,
          'week_number': week.weekNumber,
          'notes': week.notes,
          'attachments': week.attachments,
        })
            .select()
            .single();

        final weekId = weekResponse['id'].toString();

        for (final day in week.days) {
          final dayResponse = await _supabase
              .from('workout_plan_days')
              .insert({
            'week_id': weekId,
            'day_number': day.dayNumber,
            'label': day.label,
            'client_comment': day.clientComment,
            'attachments': day.attachments,
          })
              .select()
              .single();

          final dayId = dayResponse['id'].toString();

          // Insert exercises
          if (day.exercises.isNotEmpty) {
            final exerciseData = day.exercises
                .map((ex) => ex.copyWith(dayId: dayId).toMap())
                .toList();
            await _supabase.from('workout_exercises').insert(exerciseData);
          }

          // Insert cardio sessions
          if (day.cardioSessions.isNotEmpty) {
            final cardioData = day.cardioSessions
                .map((cardio) => cardio.copyWith(dayId: dayId).toMap())
                .toList();
            await _supabase.from('workout_cardio').insert(cardioData);
          }
        }
      }

      debugPrint('✅ Created workout plan: $planId');
      return planId;
    } catch (e) {
      debugPrint('❌ Failed to create workout plan: $e');
      throw Exception('Failed to create workout plan: $e');
    }
  }

  /// Update an existing workout plan
  Future<void> updatePlan(WorkoutPlan plan) async {
    if (plan.id == null) {
      throw Exception('Cannot update plan without ID');
    }

    try {
      // Update main plan
      await _supabase.from('workout_plans').update({
        'name': plan.name,
        'description': plan.description,
        'duration_weeks': plan.durationWeeks,
        'start_date': plan.startDate?.toIso8601String().split('T')[0],
        'is_template': plan.isTemplate,
        'template_category': plan.templateCategory,
        'unseen_update': plan.unseenUpdate,
        'metadata': plan.metadata,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', plan.id!);

      // For full update, delete and recreate weeks/days/exercises
      // This is simpler than trying to diff and update incrementally
      await _supabase
          .from('workout_plan_weeks')
          .delete()
          .eq('plan_id', plan.id!);

      // Recreate the structure
      for (final week in plan.weeks) {
        final weekResponse = await _supabase
            .from('workout_plan_weeks')
            .insert({
          'plan_id': plan.id,
          'week_number': week.weekNumber,
          'notes': week.notes,
          'attachments': week.attachments,
        })
            .select()
            .single();

        final weekId = weekResponse['id'].toString();

        for (final day in week.days) {
          final dayResponse = await _supabase
              .from('workout_plan_days')
              .insert({
            'week_id': weekId,
            'day_number': day.dayNumber,
            'label': day.label,
            'client_comment': day.clientComment,
            'attachments': day.attachments,
          })
              .select()
              .single();

          final dayId = dayResponse['id'].toString();

          // Insert exercises
          if (day.exercises.isNotEmpty) {
            final exerciseData = day.exercises
                .map((ex) => ex.copyWith(dayId: dayId).toMap())
                .toList();
            await _supabase.from('workout_exercises').insert(exerciseData);
          }

          // Insert cardio sessions
          if (day.cardioSessions.isNotEmpty) {
            final cardioData = day.cardioSessions
                .map((cardio) => cardio.copyWith(dayId: dayId).toMap())
                .toList();
            await _supabase.from('workout_cardio').insert(cardioData);
          }
        }
      }

      debugPrint('✅ Updated workout plan: ${plan.id}');
    } catch (e) {
      debugPrint('❌ Failed to update workout plan: $e');
      throw Exception('Failed to update workout plan: $e');
    }
  }

  /// Delete a workout plan
  Future<void> deletePlan(String planId) async {
    try {
      await _supabase.from('workout_plans').delete().eq('id', planId);
      debugPrint('✅ Deleted workout plan: $planId');
    } catch (e) {
      debugPrint('❌ Failed to delete workout plan: $e');
      throw Exception('Failed to delete workout plan: $e');
    }
  }

  /// Fetch a specific workout plan by ID
  Future<WorkoutPlan?> fetchPlan(String planId) async {
    try {
      // Fetch main plan
      final planResponse = await _supabase
          .from('workout_plans')
          .select()
          .eq('id', planId)
          .single();

      // Fetch weeks
      final weeksResponse = await _supabase
          .from('workout_plan_weeks')
          .select()
          .eq('plan_id', planId)
          .order('week_number');

      final weeks = <WorkoutWeek>[];

      for (final weekData in weeksResponse as List<dynamic>) {
        final weekId = weekData['id'].toString();

        // Fetch days for this week
        final daysResponse = await _supabase
            .from('workout_plan_days')
            .select()
            .eq('week_id', weekId)
            .order('day_number');

        final days = <WorkoutDay>[];

        for (final dayData in daysResponse as List<dynamic>) {
          final dayId = dayData['id'].toString();

          // Fetch exercises for this day
          final exercisesResponse = await _supabase
              .from('workout_exercises')
              .select()
              .eq('day_id', dayId)
              .order('order_index');

          final exercises = (exercisesResponse as List<dynamic>)
              .map((ex) => Exercise.fromMap(ex as Map<String, dynamic>))
              .toList();

          // Fetch cardio for this day
          final cardioResponse = await _supabase
              .from('workout_cardio')
              .select()
              .eq('day_id', dayId)
              .order('order_index');

          final cardioSessions = (cardioResponse as List<dynamic>)
              .map((cardio) =>
              CardioSession.fromMap(cardio as Map<String, dynamic>))
              .toList();

          days.add(WorkoutDay(
            id: dayId,
            weekId: weekId,
            dayNumber: dayData['day_number'] as int,
            label: dayData['label']?.toString() ?? '',
            clientComment: dayData['client_comment']?.toString(),
            attachments: (dayData['attachments'] as List<dynamic>?)
                ?.map((a) => a.toString())
                .toList() ??
                [],
            createdAt: DateTime.tryParse(dayData['created_at']?.toString() ?? '') ??
                DateTime.now(),
            updatedAt: DateTime.tryParse(dayData['updated_at']?.toString() ?? '') ??
                DateTime.now(),
            exercises: exercises,
            cardioSessions: cardioSessions,
          ));
        }

        weeks.add(WorkoutWeek(
          id: weekId,
          planId: planId,
          weekNumber: weekData['week_number'] as int,
          notes: weekData['notes']?.toString(),
          attachments: (weekData['attachments'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
              [],
          createdAt: DateTime.tryParse(weekData['created_at']?.toString() ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(weekData['updated_at']?.toString() ?? '') ??
              DateTime.now(),
          days: days,
        ));
      }

      return WorkoutPlan(
        id: planId,
        coachId: planResponse['coach_id']?.toString() ?? '',
        clientId: planResponse['client_id']?.toString() ?? '',
        name: planResponse['name']?.toString() ?? '',
        description: planResponse['description']?.toString(),
        durationWeeks: planResponse['duration_weeks'] as int? ?? 1,
        startDate: planResponse['start_date'] != null
            ? DateTime.tryParse(planResponse['start_date'].toString())
            : null,
        createdAt: DateTime.tryParse(planResponse['created_at']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(planResponse['updated_at']?.toString() ?? '') ??
            DateTime.now(),
        createdBy: planResponse['created_by']?.toString() ?? '',
        isTemplate: planResponse['is_template'] as bool? ?? false,
        templateCategory: planResponse['template_category']?.toString(),
        aiGenerated: planResponse['ai_generated'] as bool? ?? false,
        unseenUpdate: planResponse['unseen_update'] as bool? ?? false,
        isArchived: planResponse['is_archived'] as bool? ?? false,
        metadata: Map<String, dynamic>.from(
            planResponse['metadata'] as Map? ?? {}),
        versionNumber: planResponse['version_number'] as int? ?? 1,
        weeks: weeks,
      );
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null;
      }
      debugPrint('❌ Failed to fetch workout plan: $e');
      throw Exception('Failed to fetch workout plan: $e');
    }
  }

  /// Fetch all workout plans for a specific coach
  Future<List<WorkoutPlan>> fetchPlansByCoach(String coachId) async {
    try {
      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('coach_id', coachId)
          .order('created_at', ascending: false);

      final plans = <WorkoutPlan>[];
      for (final planData in response as List<dynamic>) {
        final plan = await fetchPlan(planData['id'].toString());
        if (plan != null) {
          plans.add(plan);
        }
      }

      return plans;
    } catch (e) {
      debugPrint('❌ Failed to fetch coach plans: $e');
      throw Exception('Failed to fetch coach plans: $e');
    }
  }

  /// Fetch all workout plans for a specific client
  Future<List<WorkoutPlan>> fetchPlansByClient(String clientId) async {
    try {
      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      final plans = <WorkoutPlan>[];
      for (final planData in response as List<dynamic>) {
        final plan = await fetchPlan(planData['id'].toString());
        if (plan != null) {
          plans.add(plan);
        }
      }

      return plans;
    } catch (e) {
      debugPrint('❌ Failed to fetch client plans: $e');
      throw Exception('Failed to fetch client plans: $e');
    }
  }

  /// Duplicate a workout plan for a different client
  Future<void> duplicatePlan(WorkoutPlan plan, String targetClientId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final duplicatedPlan = plan.copyWith(
        id: null, // New plan, no ID
        clientId: targetClientId,
        name: '${plan.name} (Copy)',
        createdBy: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        unseenUpdate: true, // Notify the new client
        versionNumber: 1,
      );

      await createPlan(duplicatedPlan);
      debugPrint('✅ Duplicated workout plan for client: $targetClientId');
    } catch (e) {
      debugPrint('❌ Failed to duplicate plan: $e');
      throw Exception('Failed to duplicate plan: $e');
    }
  }

  // =====================================================
  // VERSION MANAGEMENT
  // =====================================================

  /// Create a version snapshot of a workout plan
  Future<void> createPlanVersion(String planId) async {
    try {
      final plan = await fetchPlan(planId);
      if (plan == null) throw Exception('Plan not found');

      final user = _supabase.auth.currentUser;

      await _supabase.from('workout_plan_versions').insert({
        'plan_id': planId,
        'version_number': plan.versionNumber,
        'snapshot': plan.toMap(),
        'changed_by': user?.id,
        'change_description': 'Version ${plan.versionNumber} snapshot',
      });

      // Increment version number in main plan
      await _supabase
          .from('workout_plans')
          .update({'version_number': plan.versionNumber + 1}).eq('id', planId);

      debugPrint('✅ Created version ${plan.versionNumber} for plan: $planId');
    } catch (e) {
      debugPrint('❌ Failed to create plan version: $e');
      throw Exception('Failed to create plan version: $e');
    }
  }

  /// Fetch all versions of a workout plan
  Future<List<WorkoutPlanVersion>> fetchPlanVersions(String planId) async {
    try {
      final response = await _supabase
          .from('workout_plan_versions')
          .select()
          .eq('plan_id', planId)
          .order('version_number', ascending: false);

      return (response as List<dynamic>)
          .map((version) =>
          WorkoutPlanVersion.fromMap(version as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch plan versions: $e');
      throw Exception('Failed to fetch plan versions: $e');
    }
  }

  /// Revert a workout plan to a specific version
  Future<void> revertToVersion(String planId, int versionNumber) async {
    try {
      // Fetch the version snapshot
      final versionResponse = await _supabase
          .from('workout_plan_versions')
          .select()
          .eq('plan_id', planId)
          .eq('version_number', versionNumber)
          .single();

      final snapshot = versionResponse['snapshot'] as Map<String, dynamic>;

      // Reconstruct the plan from snapshot
      final plan = WorkoutPlan.fromMap(snapshot);

      // Update the current plan with the snapshot data
      await updatePlan(plan.copyWith(
        id: planId,
        updatedAt: DateTime.now(),
        unseenUpdate: true,
      ));

      debugPrint(
          '✅ Reverted plan $planId to version $versionNumber');
    } catch (e) {
      debugPrint('❌ Failed to revert to version: $e');
      throw Exception('Failed to revert to version: $e');
    }
  }

  // =====================================================
  // EXERCISE HISTORY TRACKING
  // =====================================================

  /// Record exercise completion by client
  Future<void> recordExerciseCompletion({
    required String clientId,
    required String exerciseId,
    required int completedSets,
    required String completedReps,
    required double weightUsed,
    int? rirActual,
    String? notes,
    int? formRating,
    int? difficultyRating,
  }) async {
    try {
      // Calculate estimated 1RM
      final repsNumeric = _extractFirstNumber(completedReps);
      final estimated1RM =
      repsNumeric != null ? _calculate1RM(weightUsed, repsNumeric) : null;

      // Calculate volume
      final volume = repsNumeric != null
          ? completedSets * repsNumeric * weightUsed
          : null;

      await _supabase.from('exercise_history').insert({
        'client_id': clientId,
        'exercise_id': exerciseId,
        'completed_sets': completedSets,
        'completed_reps': completedReps,
        'weight_used': weightUsed,
        'rir_actual': rirActual,
        'notes': notes,
        'form_rating': formRating,
        'difficulty_rating': difficultyRating,
        'estimated_1rm': estimated1RM,
        'volume': volume,
        'completed_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Recorded exercise completion for client: $clientId');
    } catch (e) {
      debugPrint('❌ Failed to record exercise completion: $e');
      throw Exception('Failed to record exercise completion: $e');
    }
  }

  /// Fetch exercise history for a specific client and exercise
  Future<List<ExerciseHistoryEntry>> fetchExerciseHistory(
      String clientId,
      String exerciseName,
      ) async {
    try {
      // Get exercise IDs matching the name
      final exercisesResponse = await _supabase
          .from('workout_exercises')
          .select('id')
          .eq('name', exerciseName);

      if ((exercisesResponse as List).isEmpty) {
        return [];
      }

      final exerciseIds =
      exercisesResponse.map((e) => e['id'].toString()).toList();

      // Fetch history for these exercises
      final historyResponse = await _supabase
          .from('exercise_history')
          .select()
          .eq('client_id', clientId)
          .inFilter('exercise_id', exerciseIds)
          .order('completed_at', ascending: false);

      return (historyResponse as List<dynamic>)
          .map((entry) =>
          ExerciseHistoryEntry.fromMap(entry as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch exercise history: $e');
      throw Exception('Failed to fetch exercise history: $e');
    }
  }

  /// Analyze progress trend from exercise history
  ProgressAnalysis analyzeProgressTrend(
      List<ExerciseHistoryEntry> historyEntries) {
    if (historyEntries.isEmpty) {
      return ProgressAnalysis(
        trend: ProgressTrend.noData,
        averageVolume: 0,
        volumeChange: 0,
        strengthGain: 0,
        consistency: 0,
      );
    }

    // Sort by date (oldest first)
    final sorted = List<ExerciseHistoryEntry>.from(historyEntries)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    // Calculate metrics
    final totalVolume =
        sorted.fold<double>(0, (sum, entry) => sum + (entry.volume ?? 0));
    final averageVolume = totalVolume / sorted.length;

    // Compare first and last entry
    final first = sorted.first;
    final last = sorted.last;

    final volumeChange = (last.volume ?? 0) - (first.volume ?? 0);
    final strengthGain = (last.estimated1RM ?? 0) - (first.estimated1RM ?? 0);

    // Determine trend
    ProgressTrend trend;
    if (volumeChange > 0 && strengthGain > 0) {
      trend = ProgressTrend.improving;
    } else if (volumeChange < 0 || strengthGain < 0) {
      trend = ProgressTrend.declining;
    } else {
      trend = ProgressTrend.maintaining;
    }

    // Calculate consistency (% of expected sessions)
    final daysBetween = last.completedAt.difference(first.completedAt).inDays;
    final expectedSessions = (daysBetween / 7).ceil() * 2; // Assume 2x per week
    final consistency = (sorted.length / expectedSessions * 100).clamp(0, 100);

    return ProgressAnalysis(
      trend: trend,
      averageVolume: averageVolume,
      volumeChange: volumeChange,
      strengthGain: strengthGain,
      consistency: consistency.toDouble(),
    );
  }

  // =====================================================
  // CLIENT INTERACTION
  // =====================================================

  /// Update client comment on a specific day
  Future<void> updateDayComment(
      String planId,
      int weekNumber,
      int dayNumber,
      String comment,
      ) async {
    try {
      final plan = await fetchPlan(planId);
      if (plan == null) throw Exception('Plan not found');

      final week = plan.getWeek(weekNumber);
      if (week == null) throw Exception('Week not found');

      if (dayNumber < 1 || dayNumber > week.days.length) {
        throw Exception('Invalid day number');
      }

      final day = week.days[dayNumber - 1];
      if (day.id == null) throw Exception('Day ID not found');

      await _supabase
          .from('workout_plan_days')
          .update({'client_comment': comment}).eq('id', day.id!);

      debugPrint('✅ Updated day comment');
    } catch (e) {
      debugPrint('❌ Failed to update day comment: $e');
      throw Exception('Failed to update day comment: $e');
    }
  }

  /// Mark workout plan as seen by client
  Future<void> markPlanSeen(String planId) async {
    try {
      await _supabase
          .from('workout_plans')
          .update({'unseen_update': false}).eq('id', planId);

      debugPrint('✅ Marked plan as seen: $planId');
    } catch (e) {
      debugPrint('❌ Failed to mark plan as seen: $e');
      throw Exception('Failed to mark plan as seen: $e');
    }
  }

  /// Upload exercise video/media
  Future<String> uploadExerciseMedia(
      String planId,
      String exerciseId,
      File mediaFile,
      ) async {
    try {
      final fileName =
          'workout_media/${planId}_${exerciseId}_${DateTime.now().millisecondsSinceEpoch}_${mediaFile.path.split('/').last}';

      await _supabase.storage.from('workout-media').upload(
        fileName,
        mediaFile,
      );

      final publicUrl =
      _supabase.storage.from('workout-media').getPublicUrl(fileName);

      debugPrint('✅ Uploaded exercise media: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Failed to upload exercise media: $e');
      throw Exception('Failed to upload exercise media: $e');
    }
  }

  // =====================================================
  // PDF EXPORT
  // =====================================================

  /// Export workout plan to PDF
  /// TODO: Temporarily disabled due to Windows path resolution issue with PDF package
  /*
  Future<void> exportWorkoutPlanToPdf(
      WorkoutPlan plan,
      String coachName,
      String clientName,
      ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => [
            // Header
            _buildPdfHeader(plan, coachName, clientName),
            pw.SizedBox(height: 20),

            // Plan Overview
            _buildPlanOverview(plan),
            pw.SizedBox(height: 20),

            // Weekly Calendar
            _buildWeeklyCalendar(plan),
            pw.SizedBox(height: 20),

            // Detailed Workout Days
            ...plan.weeks.expand((week) => [
              _buildWeekSection(week, plan),
              pw.SizedBox(height: 15),
            ]),

            // Summary Statistics
            _buildSummaryStatistics(plan),

            // Footer
            pw.SizedBox(height: 30),
            _buildPdfFooter(),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Workout_Plan_${plan.name.replaceAll(' ', '_')}.pdf',
      );

      debugPrint('✅ Exported workout plan to PDF');
    } catch (e) {
      debugPrint('❌ Failed to export PDF: $e');
      throw Exception('Failed to export PDF: $e');
    }
  }

  // PDF Helper Methods
  pw.Widget _buildPdfHeader(
      WorkoutPlan plan, String coachName, String clientName) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WORKOUT PLAN',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                plan.name,
                style: const pw.TextStyle(fontSize: 16),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                DateFormat('MMM dd, yyyy').format(plan.createdAt),
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Coach: $coachName',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Client: $clientName',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPlanOverview(WorkoutPlan plan) {
    final summary = plan.getPlanSummary();
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Plan Overview',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Duration', '${plan.durationWeeks} weeks'),
              _buildInfoItem('Training Days',
                  '${summary.totalTrainingDays} / ${plan.durationWeeks * 7}'),
              _buildInfoItem('Total Volume',
                  '${(summary.totalVolume / 1000).toStringAsFixed(1)}k kg'),
              _buildInfoItem('Unique Exercises',
                  '${plan.getUniqueExerciseNames().length}'),
            ],
          ),
          if (plan.description != null) ...[
            pw.SizedBox(height: 10),
            pw.Text('Description: ${plan.description}',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildWeeklyCalendar(WorkoutPlan plan) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Weekly Calendar',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...plan.weeks.map((week) => _buildWeekCalendarRow(week)),
        ],
      ),
    );
  }

  pw.Widget _buildWeekCalendarRow(WorkoutWeek week) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 60,
            child: pw.Text(
              'Week ${week.weekNumber}',
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          ...week.days.map((day) => pw.Container(
            width: 70,
            height: 30,
            margin: const pw.EdgeInsets.only(right: 5),
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              color: day.isRestDay ? PdfColors.grey200 : PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              day.label,
              style: const pw.TextStyle(fontSize: 8),
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
            ),
          )),
        ],
      ),
    );
  }

  pw.Widget _buildWeekSection(WorkoutWeek week, WorkoutPlan plan) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          child: pw.Text(
            'Week ${week.weekNumber}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        ...week.days.map((day) => _buildDaySection(day)),
      ],
    );
  }

  pw.Widget _buildDaySection(WorkoutDay day) {
    if (day.isRestDay) {
      return pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 5),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          '${day.label} - REST DAY',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            day.label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),

          // Exercises
          if (day.exercises.isNotEmpty) ...[
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Exercise', isHeader: true),
                    _buildTableCell('Sets', isHeader: true),
                    _buildTableCell('Reps', isHeader: true),
                    _buildTableCell('Rest', isHeader: true),
                    _buildTableCell('Notes', isHeader: true),
                  ],
                ),
                // Exercise rows
                ...day.exercises.map((exercise) => pw.TableRow(
                  children: [
                    _buildTableCell(exercise.name),
                    _buildTableCell(exercise.sets?.toString() ?? '-'),
                    _buildTableCell(exercise.reps ?? '-'),
                    _buildTableCell(
                        exercise.rest != null ? '${exercise.rest}s' : '-'),
                    _buildTableCell(
                      exercise.getIntensityDisplay().isNotEmpty
                          ? exercise.getIntensityDisplay()
                          : (exercise.notes ?? '-'),
                      fontSize: 8,
                    ),
                  ],
                )),
              ],
            ),
          ],

          // Cardio
          if (day.cardioSessions.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Cardio',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            ...day.cardioSessions.map((cardio) => pw.Text(
              '• ${cardio.getDisplaySummary()}',
              style: const pw.TextStyle(fontSize: 9),
            )),
          ],

          // Summary
          pw.SizedBox(height: 8),
          pw.Text(
            'Estimated Duration: ${day.getDaySummary().getDurationDisplay()}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text,
      {bool isHeader = false, double fontSize = 9}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryStatistics(WorkoutPlan plan) {
    final summary = plan.getPlanSummary();
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Program Statistics',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Total Volume',
                  '${(summary.totalVolume / 1000).toStringAsFixed(1)}k kg'),
              _buildStatBox('Training Days', '${summary.totalTrainingDays}'),
              _buildStatBox('Avg Weekly Volume',
                  '${(summary.averageWeeklyVolume / 1000).toStringAsFixed(1)}k kg'),
              _buildStatBox('Unique Exercises',
                  '${plan.getUniqueExerciseNames().length}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Generated by VAGUS App - ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
  */

  // =====================================================
  // ANALYTICS
  // =====================================================

  /// Calculate weekly volume metrics
  VolumeMetrics calculateWeeklyVolume(WorkoutPlan plan, int weekNumber) {
    final week = plan.getWeek(weekNumber);
    if (week == null) {
      return VolumeMetrics(
        totalVolume: 0,
        totalSets: 0,
        totalReps: 0,
        averageIntensity: 0,
      );
    }

    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;
    int exerciseCount = 0;

    for (final day in week.days) {
      for (final exercise in day.exercises) {
        final volume = exercise.calculateVolume();
        if (volume != null) {
          totalVolume += volume;
        }

        if (exercise.sets != null) {
          totalSets += exercise.sets!;
        }

        final repsNumeric = exercise.getRepsNumeric();
        if (repsNumeric != null && exercise.sets != null) {
          totalReps += repsNumeric * exercise.sets!;
        }

        exerciseCount++;
      }
    }

    final averageIntensity =
    exerciseCount > 0 ? totalVolume / exerciseCount : 0;

    return VolumeMetrics(
      totalVolume: totalVolume,
      totalSets: totalSets,
      totalReps: totalReps,
      averageIntensity: averageIntensity.toDouble(),
    );
  }

  /// Estimate total duration of workout plan
  Duration estimateTotalDuration(WorkoutPlan plan) {
    int totalMinutes = 0;

    for (final week in plan.weeks) {
      for (final day in week.days) {
        final summary = day.getDaySummary();
        totalMinutes += summary.estimatedDuration;
      }
    }

    return Duration(minutes: totalMinutes);
  }

  /// Analyze muscle group balance across the plan
  BalanceReport analyzeMuscleGroupBalance(WorkoutPlan plan) {
    final muscleGroupCounts = <String, int>{};
    final muscleGroupVolume = <String, double>{};

    // Common muscle groups
    final muscleGroups = [
      'chest',
      'back',
      'shoulders',
      'biceps',
      'triceps',
      'legs',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'abs',
      'core'
    ];

    for (final week in plan.weeks) {
      for (final day in week.days) {
        for (final exercise in day.exercises) {
          // Simple keyword matching for muscle groups
          for (final group in muscleGroups) {
            if (exercise.name.toLowerCase().contains(group)) {
              muscleGroupCounts[group] = (muscleGroupCounts[group] ?? 0) + 1;

              final volume = exercise.calculateVolume() ?? 0;
              muscleGroupVolume[group] =
                  (muscleGroupVolume[group] ?? 0) + volume;
            }
          }
        }
      }
    }

    // Generate recommendations
    final recommendations = <String>[];

    // Check push/pull balance
    final pushVolume = (muscleGroupVolume['chest'] ?? 0) +
        (muscleGroupVolume['shoulders'] ?? 0) +
        (muscleGroupVolume['triceps'] ?? 0);
    final pullVolume = (muscleGroupVolume['back'] ?? 0) +
        (muscleGroupVolume['biceps'] ?? 0);

    if (pushVolume > pullVolume * 1.3) {
      recommendations
          .add('Consider adding more pulling exercises to balance push/pull ratio');
    } else if (pullVolume > pushVolume * 1.3) {
      recommendations
          .add('Consider adding more pushing exercises to balance push/pull ratio');
    }

    // Check leg training
    final legVolume = (muscleGroupVolume['legs'] ?? 0) +
        (muscleGroupVolume['quads'] ?? 0) +
        (muscleGroupVolume['hamstrings'] ?? 0);
    final upperVolume = pushVolume + pullVolume;

    if (legVolume < upperVolume * 0.5) {
      recommendations.add('Leg training volume is low compared to upper body');
    }

    // Calculate overall balance score (0-10)
    final totalExercises = muscleGroupCounts.values.fold(0, (a, b) => a + b);
    final variance = _calculateVariance(
        muscleGroupCounts.values.map((v) => v.toDouble()).toList());
    final balanceScore = (10 - (variance / totalExercises * 10)).clamp(0, 10);

    return BalanceReport(
      muscleGroupCounts: muscleGroupCounts,
      muscleGroupVolume: muscleGroupVolume,
      recommendations: recommendations,
      balanceScore: balanceScore.toDouble(),
    );
  }

  /// Suggest rest days based on volume and recovery needs
  List<int> suggestRestDays(WorkoutPlan plan) {
    final restDays = <int>[];
    int consecutiveTrainingDays = 0;

    for (int weekIndex = 0; weekIndex < plan.weeks.length; weekIndex++) {
      final week = plan.weeks[weekIndex];

      for (int dayIndex = 0; dayIndex < week.days.length; dayIndex++) {
        final day = week.days[dayIndex];
        final globalDayIndex = weekIndex * 7 + dayIndex;

        if (day.isRestDay) {
          consecutiveTrainingDays = 0;
        } else {
          consecutiveTrainingDays++;

          // Suggest rest after 3-4 consecutive training days
          if (consecutiveTrainingDays >= 4) {
            restDays.add(globalDayIndex + 1); // Suggest next day as rest
            consecutiveTrainingDays = 0;
          }

          // Suggest rest if volume is very high
          final summary = day.getDaySummary();
          if (summary.totalVolume > 5000) {
            // Arbitrary threshold
            restDays.add(globalDayIndex + 1);
            consecutiveTrainingDays = 0;
          }
        }
      }
    }

    return restDays;
  }

  // =====================================================
  // TEMPLATE MANAGEMENT
  // =====================================================

  /// Save workout plan as a template
  Future<String> saveAsTemplate(WorkoutPlan plan,
      {String? category}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final templatePlan = plan.copyWith(
        id: null, // New template, no ID
        clientId: user.id, // Templates owned by coach
        name: '${plan.name} (Template)',
        isTemplate: true,
        templateCategory: category ?? 'custom',
        createdBy: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        unseenUpdate: false,
      );

      final templateId = await createPlan(templatePlan);
      debugPrint('✅ Saved as template: $templateId');
      return templateId;
    } catch (e) {
      debugPrint('❌ Failed to save as template: $e');
      throw Exception('Failed to save as template: $e');
    }
  }

  /// Fetch all templates created by a coach
  Future<List<WorkoutPlan>> fetchTemplates(String coachId) async {
    try {
      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('created_by', coachId)
          .eq('is_template', true)
          .order('created_at', ascending: false);

      final templates = <WorkoutPlan>[];
      for (final templateData in response as List<dynamic>) {
        final template = await fetchPlan(templateData['id'].toString());
        if (template != null) {
          templates.add(template);
        }
      }

      return templates;
    } catch (e) {
      debugPrint('❌ Failed to fetch templates: $e');
      throw Exception('Failed to fetch templates: $e');
    }
  }

  /// Apply a template to a client
  Future<WorkoutPlan> applyTemplate(String templateId,
      String clientId) async {
    try {
      final template = await fetchPlan(templateId);
      if (template == null) throw Exception('Template not found');

      if (!template.isTemplate) {
        throw Exception('Plan is not a template');
      }

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final appliedPlan = template.copyWith(
        id: null, // New plan, no ID
        clientId: clientId,
        name: template.name.replaceAll(' (Template)', ''),
        isTemplate: false,
        createdBy: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        unseenUpdate: true,
        versionNumber: 1,
      );

      final planId = await createPlan(appliedPlan);
      final createdPlan = await fetchPlan(planId);

      if (createdPlan == null) {
        throw Exception('Failed to fetch created plan');
      }

      debugPrint('✅ Applied template to client: $clientId');
      return createdPlan;
    } catch (e) {
      debugPrint('❌ Failed to apply template: $e');
      throw Exception('Failed to apply template: $e');
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  double? _calculate1RM(double weight, int reps) {
    if (reps < 1 || reps > 15) return null;
    if (reps == 1) return weight;

    // Epley formula: 1RM = weight × (1 + reps / 30)
    return weight * (1 + reps / 30.0);
  }

  int? _extractFirstNumber(String text) {
    final match = RegExp(r'^\d+').firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }
}

// =====================================================
// DATA MODELS
// =====================================================

class WorkoutPlanVersion {
  final String id;
  final String planId;
  final int versionNumber;
  final Map<String, dynamic> snapshot;
  final String? changedBy;
  final String? changeDescription;
  final DateTime createdAt;

  WorkoutPlanVersion({
    required this.id,
    required this.planId,
    required this.versionNumber,
    required this.snapshot,
    this.changedBy,
    this.changeDescription,
    required this.createdAt,
  });

  factory WorkoutPlanVersion.fromMap(Map<String, dynamic> map) {
    return WorkoutPlanVersion(
      id: map['id']?.toString() ?? '',
      planId: map['plan_id']?.toString() ?? '',
      versionNumber: map['version_number'] as int? ?? 1,
      snapshot: Map<String, dynamic>.from(map['snapshot'] as Map? ?? {}),
      changedBy: map['changed_by']?.toString(),
      changeDescription: map['change_description']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ExerciseHistoryEntry {
  final String id;
  final String clientId;
  final String exerciseId;
  final int completedSets;
  final String completedReps;
  final double weightUsed;
  final int? rirActual;
  final String? notes;
  final int? formRating;
  final int? difficultyRating;
  final double? estimated1RM;
  final double? volume;
  final DateTime completedAt;

  ExerciseHistoryEntry({
    required this.id,
    required this.clientId,
    required this.exerciseId,
    required this.completedSets,
    required this.completedReps,
    required this.weightUsed,
    this.rirActual,
    this.notes,
    this.formRating,
    this.difficultyRating,
    this.estimated1RM,
    this.volume,
    required this.completedAt,
  });

  factory ExerciseHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ExerciseHistoryEntry(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      exerciseId: map['exercise_id']?.toString() ?? '',
      completedSets: map['completed_sets'] as int? ?? 0,
      completedReps: map['completed_reps']?.toString() ?? '',
      weightUsed: (map['weight_used'] as num?)?.toDouble() ?? 0,
      rirActual: map['rir_actual'] as int?,
      notes: map['notes']?.toString(),
      formRating: map['form_rating'] as int?,
      difficultyRating: map['difficulty_rating'] as int?,
      estimated1RM: (map['estimated_1rm'] as num?)?.toDouble(),
      volume: (map['volume'] as num?)?.toDouble(),
      completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

enum ProgressTrend { improving, maintaining, declining, noData }

class ProgressAnalysis {
  final ProgressTrend trend;
  final double averageVolume;
  final double volumeChange;
  final double strengthGain;
  final double consistency;

  ProgressAnalysis({
    required this.trend,
    required this.averageVolume,
    required this.volumeChange,
    required this.strengthGain,
    required this.consistency,
  });
}

class VolumeMetrics {
  final double totalVolume;
  final int totalSets;
  final int totalReps;
  final double averageIntensity;

  VolumeMetrics({
    required this.totalVolume,
    required this.totalSets,
    required this.totalReps,
    required this.averageIntensity,
  });
}

class BalanceReport {
  final Map<String, int> muscleGroupCounts;
  final Map<String, double> muscleGroupVolume;
  final List<String> recommendations;
  final double balanceScore;

  BalanceReport({
    required this.muscleGroupCounts,
    required this.muscleGroupVolume,
    required this.recommendations,
    required this.balanceScore,
  });
}