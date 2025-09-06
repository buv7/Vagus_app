import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart'; // [tutorialLink]
import '../../components/workout/week_progress_ring.dart';
import '../../components/workout/volume_summary_card.dart';
import '../../components/workout/rest_timer.dart';
import '../../services/workout/workout_metrics_service.dart';
import '../../services/share/share_card_service.dart';
import '../../screens/share/share_picker.dart';
import '../../services/ocr/ocr_cardio_service.dart';
import '../../services/health/health_service.dart';
import '../../services/music/music_service.dart';
import '../../models/music/music_models.dart';
import '../../widgets/music/music_play_button.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../widgets/workout/exercise_detail_sheet.dart';

// Safe image handling helpers
bool _isValidHttpUrl(String? url) {
  if (url == null) return false;
  final u = url.trim();
  return u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'));
}

Widget _imagePlaceholder({double? w, double? h}) {
  return Container(
    width: w,
    height: h,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.image_not_supported),
  );
}

Widget safeNetImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (_isValidHttpUrl(url)) {
    return Image.network(
      url!.trim(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _imagePlaceholder(w: width, h: height),
    );
  }
  return _imagePlaceholder(w: width, h: height);
}

class WorkoutPlanViewerScreen extends StatefulWidget {
  final Map<String, dynamic>? planOverride;

  const WorkoutPlanViewerScreen({super.key, this.planOverride});

  @override
  State<WorkoutPlanViewerScreen> createState() => _WorkoutPlanViewerScreenState();
}

class _WorkoutPlanViewerScreenState extends State<WorkoutPlanViewerScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _plan;
  List<Map<String, dynamic>> _plans = [];
  String? _selectedPlanId;

  String _role = 'client';
  int _currentWeek = 0;
  bool _loading = true;
  bool _saving = false;
  String _error = '';
  String _searchTerm = '';

  // In-session completion tracking (ephemeral)
  final Set<String> _completedSets = {};

  // Music integration
  final MusicService _musicService = MusicService();
  List<MusicLink> _musicLinks = [];
  UserMusicPrefs? _musicPrefs;
  final GlobalKey<MusicPlayButtonState> _musicPlayButtonKey = GlobalKey<MusicPlayButtonState>();

  // [comment-permission] only the plan owner (client) can edit comments
  bool get _canEditComments {
    final uid = supabase.auth.currentUser?.id;
    final planClientId = _plan?['client_id'] ?? _plan?['clientId'];
    return uid != null && planClientId != null && uid.toString() == planClientId.toString();
  }

  @override
  void initState() {
    super.initState();
    if (widget.planOverride != null) {
      _plan = Map<String, dynamic>.from(widget.planOverride!);
      _selectedPlanId = _plan?['id']?.toString();
      _loading = false;
      _populatePlansForContext();
      _loadMusicData();
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'No user.';
        _loading = false;
      });
      return;
    }

    try {
      // Get role
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      _role = (profile['role'] ?? 'client').toString();

      // Load plans:
      // - client: plans where client_id = me
      // - coach: plans where created_by = me (adjust if your column name differs)
      final List<dynamic> plans = _role == 'coach'
          ? await supabase
          .from('workout_plans')
          .select()
          .eq('created_by', user.id)
          .order('created_at', ascending: false)
          : await supabase
          .from('workout_plans')
          .select()
          .eq('client_id', user.id)
          .order('created_at', ascending: false);

      final typed = plans.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

      setState(() {
        _plans = typed;
        if (_plans.isNotEmpty) {
          _plan = _plans.first;
          _selectedPlanId = _plan!['id']?.toString();
          _currentWeek = 0;
        } else {
          _plan = null;
          _selectedPlanId = null;
          _error = 'No workout plans found.';
        }
        _loading = false;
      });

      // Debug
      // ignore: avoid_print
      debugPrint("📦 Loaded plans: ${_plans.map((p) => p['id']).toList()}");
      
      // Load music data after plan is loaded
      unawaited(_loadMusicData());
    } catch (e) {
      setState(() {
        _error = '❌ Failed to load data.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMusicData() async {
    if (_plan == null) return;
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load music preferences
      _musicPrefs = await _musicService.getPrefs(user.id);
      
      // Load music links for current week/day
      final weeks = List<Map<String, dynamic>>.from((_plan?['weeks'] as List<dynamic>?) ?? []);
      if (weeks.isNotEmpty && _currentWeek < weeks.length) {
        final days = List<Map<String, dynamic>>.from((weeks[_currentWeek]['days'] as List<dynamic>?) ?? []);
        if (days.isNotEmpty) {
          // Load music for first day of current week (or you could make this more specific)
          final musicLinks = await _musicService.getForPlanDay(
            planId: _plan!['id'],
            weekIdx: _currentWeek,
            dayIdx: 0,
          );
          
          setState(() {
            _musicLinks = musicLinks;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading music data: $e');
    }
  }

  Future<void> _populatePlansForContext() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Ensure role is known
      if (_role.isEmpty) {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        _role = (profile['role'] ?? 'client').toString();
      }

      List<dynamic> result;
      if (_role == 'coach') {
        result = await supabase
            .from('workout_plans')
            .select()
            .eq('created_by', user.id)
            .order('created_at', ascending: false);
      } else {
        final clientId = (_plan?['client_id'] ?? user.id).toString();
        result = await supabase
            .from('workout_plans')
            .select()
            .eq('client_id', clientId)
            .order('created_at', ascending: false);
      }

      final typed =
          result.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

      setState(() {
        _plans = typed;
        // Ensure the current plan is present in the list for the dropdown
        if (_plan != null &&
            _plans.every((p) => p['id'].toString() != _plan!['id'].toString())) {
          _plans = [Map<String, dynamic>.from(_plan!), ..._plans];
        }
      });
    } catch (e) {
      // Silently ignore to avoid blocking UI; dropdown will just be empty
    }
  }

  Future<void> _exportToPDF() async {
    if (_plan == null) return;

    final pdf = pw.Document();
    final weeks = List<Map<String, dynamic>>.from((_plan!['weeks'] as List<dynamic>?) ?? []);

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text('Workout Plan: ${_plan?['name'] ?? 'Unnamed'}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Created: ${(_plan?['created_at'] ?? '').toString()}'),
            pw.SizedBox(height: 12),
            ...List.generate(weeks.length, (weekIndex) {
              final week = Map<String, dynamic>.from(weeks[weekIndex]);
              final days = List<Map<String, dynamic>>.from((week['days'] as List<dynamic>?) ?? []);
              return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.SizedBox(height: 8),
                pw.Text('Week ${weekIndex + 1}${((week['label'] ?? '').toString().isNotEmpty) ? ' — ${week['label']}' : ''}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                if ((week['tags'] is List) && (week['tags'] as List).isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Wrap(
                      spacing: 6,
                      children: (week['tags'] as List<dynamic>?)
                          ?.map((t) => pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey300,
                                  borderRadius: pw.BorderRadius.circular(10),
                                ),
                                child: pw.Text(t.toString(), style: const pw.TextStyle(fontSize: 10)),
                              ))
                          .toList() ?? [],
                    ),
                  ),
                pw.SizedBox(height: 6),
                ...List.generate(days.length, (dayIndex) {
                  final day = Map<String, dynamic>.from(days[dayIndex]);
                  final exercises = List<Map<String, dynamic>>.from((day['exercises'] as List<dynamic>?) ?? []);
                  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.SizedBox(height: 4),
                    pw.Text('Day: ${day['label'] ?? 'Day ${dayIndex + 1}'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    if ((day['clientComment'] ?? '').toString().isNotEmpty)
                      pw.Text('Comment: ${day['clientComment']}'),
                    ...exercises.map((ex) {
                      final e = Map<String, dynamic>.from(ex);
                      return pw.Bullet(
                          text:
                          "${e['name'] ?? 'Exercise'} — Sets: ${e['sets'] ?? '-'}, Reps: ${e['reps'] ?? '-'}, Rest: ${e['rest'] ?? '-'}, %1RM: ${e['percent1RM'] ?? '-'}");
                    }),
                    pw.SizedBox(height: 6),
                    // Compact weekly volume summary
                    _pdfWeekSummaryTable(week: week),
                  ]);
                }),
              ]);
            })
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfWeekSummaryTable({required Map<String, dynamic> week}) {
    final plan = {'weeks': [week]};
    final summary = WorkoutMetricsService.weekVolumeSummary(plan, weekIndex: 0);
    if (summary.isEmpty) return pw.SizedBox.shrink();
    final rows = summary.entries
        .map((e) => {
              'muscle': e.key,
              'sets': (e.value['sets'] ?? 0).toString(),
              'reps': (e.value['reps'] ?? 0).toString(),
              'volume': (e.value['volume'] ?? 0).toString(),
            })
        .toList();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Volume Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Muscle')),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Sets')),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Reps')),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Volume')),
          ]),
          ...rows.map((r) => pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r['muscle']!)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r['sets']!)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r['reps']!)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(r['volume']!)),
              ])),
        ],
      ),
    ]);
  }

  Future<void> _saveCommentsToSupabase() async {
    if (_plan == null) return;
    // [comment-permission] block save if user cannot edit
    if (!_canEditComments) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Read-only: only the plan owner can save comments.')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final weeks = _plan!['weeks']; // already mutated in memory by text fields
      await supabase
          .from('workout_plans')
          .update({'weeks': weeks})
          .eq('id', _plan!['id']);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved comments ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save failed ❌')),
        );
      }
    }
  }

  void _onSelectPlan(String? id) {
    if (id == null) return;
    final found = _plans.firstWhere(
          (p) => p['id'].toString() == id,
      orElse: () => {},
    );
    if (found.isEmpty) return;

    setState(() {
      _selectedPlanId = id;
      _plan = Map<String, dynamic>.from(found);
      // [plan-selection] clamp week index to valid range
      final weeks = List<Map<String, dynamic>>.from((_plan?['weeks'] as List<dynamic>?) ?? []);
      final maxIndex = (weeks.isEmpty ? 1 : weeks.length) - 1;
      _currentWeek = _currentWeek.clamp(0, maxIndex);
      _searchTerm = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: VagusAppBar(
        title: const Text('📋 Workout Viewer'),
        actions: [
          // Cardio quick-log button
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _openCardioQuickLog,
            tooltip: '📸 Cardio',
          ),
          // Share button
          if (_plan != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _showShareOptions,
              tooltip: 'Share Workout',
            ),
          // [excel-edit] coach-only entry point to full plan editor
          if (_role == 'coach' && _plan != null)
            IconButton(
              icon: const Icon(Icons.table_chart),
              tooltip: 'Edit Full Plan',
              onPressed: _openExcelEditor,
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _plan == null ? null : _exportToPDF,
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: _plan == null
          ? Center(child: Text(_error.isEmpty ? 'No plan.' : _error))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Plan selector (past plans)
            DropdownButtonFormField<String>(
              value: _selectedPlanId,
              decoration: const InputDecoration(
                labelText: 'Select Plan',
                border: OutlineInputBorder(),
              ),
              items: _plans.map((p) {
                // [plan-selection] label uses name — startDate (fallbacks applied)
                final rawName = (p['name'] ?? '').toString();
                final displayName = rawName.isEmpty ? (p['id'] ?? '').toString() : rawName;
                final startDate = (p['start_date'] ?? p['startDate'] ?? p['created_at'] ?? '')
                    .toString();
                final label = startDate.isEmpty
                    ? displayName
                    : '$displayName — $startDate';
                return DropdownMenuItem<String>(
                  value: p['id'].toString(),
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: _onSelectPlan,
            ),
            const SizedBox(height: 12),

            // Search
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchTerm = val.toLowerCase()),
            ),
            const SizedBox(height: 12),

            // Week tags (chips) + dropdown + progress ring + label/tags
            _buildWeekHeader(),
            const SizedBox(height: 8),
            
            // Music play button
            if (_musicLinks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MusicPlayButton(
                  key: _musicPlayButtonKey,
                  musicLinks: _musicLinks,
                  defaultProvider: _musicPrefs?.defaultProvider,
                  autoOpen: _musicPrefs?.autoOpen ?? true,
                  onAutoOpenTriggered: () {
                    // Music auto-opened successfully
                  },
                ),
              ),
            DropdownButtonFormField<int>(
              value: _currentWeek,
              decoration: const InputDecoration(
                labelText: 'Select Week',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                List<Map<String, dynamic>>.from((_plan!['weeks'] as List<dynamic>?) ?? []).length,
                    (i) => DropdownMenuItem(value: i, child: Text('Week ${i + 1}')),
              ),
              onChanged: (val) {
                if (val != null) setState(() => _currentWeek = val);
              },
            ),
            const SizedBox(height: 12),

            // Week view
            Expanded(child: _buildWeekView()),

            // Save comments
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveCommentsToSupabase,
                icon: _saving
                    ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save comments'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [excel-edit] open full-screen excel-like editor
  void _openExcelEditor() {
    if (_plan == null) return;
    final weeks = List<Map<String, dynamic>>.from((_plan!['weeks'] as List<dynamic>?) ?? []);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ExcelPlanEditorScreen(
          weeks: weeks,
          onChange: (updatedWeeks) {
            setState(() {
              _plan!['weeks'] = updatedWeeks;
            });
          },
          onSave: _savePlanEditsToSupabase,
        ),
      ),
    );
  }

  // [excel-edit] save entire plan weeks to Supabase
  Future<void> _savePlanEditsToSupabase() async {
    if (_plan == null) return;
    setState(() => _saving = true);
    try {
      final weeks = _plan!['weeks'];
      await supabase
          .from('workout_plans')
          .update({'weeks': weeks})
          .eq('id', _plan!['id']);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan saved ✅')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save failed ❌')),
        );
      }
    }
  }

  // Share helper method
  void _showShareOptions() {
    if (_plan == null) return;
    
    final weeks = List<Map<String, dynamic>>.from((_plan!['weeks'] as List<dynamic>?) ?? []);
    if (weeks.isEmpty) return;
    
    final currentWeek = weeks[_currentWeek];
    final days = List<Map<String, dynamic>>.from((currentWeek['days'] as List<dynamic>?) ?? []);
    
    // Count total exercises
    int totalExercises = 0;
    for (final day in days) {
      final exercises = List<Map<String, dynamic>>.from((day['exercises'] as List<dynamic>?) ?? []);
      totalExercises += exercises.length;
    }
    
    final shareData = ShareDataModel(
      title: 'Workout Plan: ${_plan!['name'] ?? 'Week ${_currentWeek + 1}'}',
      subtitle: '${days.length} days, $totalExercises exercises',
      metrics: {
        'Days': days.length.toString(),
        'Exercises': totalExercises.toString(),
        'Week': '${_currentWeek + 1}',
      },
      date: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharePicker(data: shareData),
      ),
    );
  }

  // Cardio quick-log method
  void _openCardioQuickLog() async {
    try {
      final ocrService = OCRCardioService();
      
      // Capture image (stub for now)
      final imagePath = await ocrService.captureImage();
      if (imagePath == null) return;
      
      // Perform OCR (stub for now)
      final ocrText = await ocrService.performOCR(imagePath);
      if (ocrText == null) return;
      
      // Parse OCR text
      final workoutData = await ocrService.parseOCRText(ocrText);
      if (workoutData == null) return;
      
      // Show preview and save
      if (mounted) {
        _showCardioPreview(workoutData, imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing cardio: $e')),
        );
      }
    }
  }

  void _showCardioPreview(CardioWorkoutData workoutData, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📸 Cardio Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sport: ${workoutData.sport}'),
            if (workoutData.distance != null) 
              Text('Distance: ${workoutData.distance} ${workoutData.distanceUnit}'),
            if (workoutData.durationMinutes != null) 
              Text('Duration: ${workoutData.durationMinutes} minutes'),
            if (workoutData.calories != null) 
              Text('Calories: ${workoutData.calories}'),
            if (workoutData.avgHeartRate != null) 
              Text('Heart Rate: ${workoutData.avgHeartRate} bpm'),
            Text('Confidence: ${(workoutData.confidence * 100).toInt()}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveCardioWorkout(workoutData, imagePath),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCardioWorkout(CardioWorkoutData workoutData, String imagePath) async {
    try {
      final ocrService = OCRCardioService();
      
      // Save workout data
      await ocrService.saveWorkoutData(
        imagePath: imagePath,
        ocrText: 'Demo OCR text',
        parsedData: workoutData,
      );
      
      // Check for overlapping workouts
      final healthService = HealthService();
      final overlappingWorkout = await healthService.findOverlappingWatchWorkout(
        windowStart: DateTime.now().subtract(const Duration(minutes: 30)),
        windowEnd: DateTime.now().add(const Duration(minutes: 30)),
      );
      
      if (mounted) {
        Navigator.pop(context); // Close preview dialog
        
        if (overlappingWorkout != null) {
          _showMergeSuggestion(workoutData, overlappingWorkout);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Cardio workout saved!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout: $e')),
        );
      }
    }
  }

  void _showMergeSuggestion(CardioWorkoutData ocrData, HealthWorkout watchData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge Workouts?'),
        content: const Text(
          'We found a similar workout from your watch around the same time. '
          'Would you like to merge them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Separate'),
          ),
          ElevatedButton(
            onPressed: () => _acceptMerge(ocrData, watchData),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptMerge(CardioWorkoutData ocrData, HealthWorkout watchData) async {
    try {
      final ocrService = OCRCardioService();
      await ocrService.saveWorkoutData(
        imagePath: '',
        ocrText: 'Demo OCR text',
        parsedData: ocrData,
        workoutId: watchData.id,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close merge dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Workouts merged successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error merging workouts: $e')),
        );
      }
    }
  }

  Widget _buildWeekChips() {
    final weeks = List<Map<String, dynamic>>.from((_plan?['weeks'] as List<dynamic>?) ?? []);
    if (weeks.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: weeks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _currentWeek == index;
          return ChoiceChip(
            label: Text('Week ${index + 1}'),
            selected: selected,
            onSelected: (_) => setState(() => _currentWeek = index),
          );
        },
      ),
    );
  }

  Widget _buildWeekHeader() {
    final weeks = List<Map<String, dynamic>>.from((_plan?['weeks'] as List<dynamic>?) ?? []);
    if (weeks.isEmpty) return const SizedBox.shrink();
    final thisWeek = Map<String, dynamic>.from(weeks[_currentWeek]);
    final label = (thisWeek['label'] ?? '').toString();
    final tags = List<String>.from((thisWeek['tags'] as List<dynamic>?)?.map((e) => e.toString()) ?? const []);

    // Compute totals for progress
    int totalSets = 0;
    int completedSets = 0;
    final days = List<Map<String, dynamic>>.from((thisWeek['days'] as List<dynamic>?) ?? []);
    for (var di = 0; di < days.length; di++) {
      final exercises = List<Map<String, dynamic>>.from((days[di]['exercises'] as List<dynamic>?) ?? []);
      for (var ei = 0; ei < exercises.length; ei++) {
        final e = Map<String, dynamic>.from(exercises[ei]);
        final sets = int.tryParse((e['sets'] ?? 0).toString()) ?? 0;
        for (var si = 0; si < sets; si++) {
          totalSets += 1;
          final key = _setKey(_currentWeek, di, ei, si);
          if (_completedSets.contains(key)) completedSets += 1;
        }
      }
    }

    return Row(
      children: [
        Expanded(child: _buildWeekChips()),
        const SizedBox(width: 8),
        WeekProgressRing(completedSets: completedSets, totalSets: totalSets),
        const SizedBox(width: 8),
        if (label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        if (tags.isNotEmpty) ...[
          const SizedBox(width: 8),
          Wrap(
            spacing: 6,
            children: tags
                .map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))
                .toList(),
          ),
        ]
      ],
    );
  }

  String _setKey(int w, int d, int e, int s) => 'w$w-d$d-e$e-s$s';

  void _toggleSetDone({
    required int weekIndex,
    required int dayIndex,
    required int exerciseIndex,
    required int setIndex,
    required Map<String, dynamic> exercise,
  }) {
    final key = _setKey(weekIndex, dayIndex, exerciseIndex, setIndex);
    setState(() {
      if (_completedSets.contains(key)) {
        _completedSets.remove(key);
      } else {
        _completedSets.add(key);
      }
    });

    // Only trigger rest timer when newly completed
    if (_completedSets.contains(key)) {
      final seconds = _resolveRestSeconds(exercise);
      if (seconds != null && seconds > 0) {
        final nextHint = _nextSetHint(weekIndex, dayIndex, exerciseIndex, setIndex, exercise);
        _showRestTimer(seconds: seconds, nextHint: nextHint);
      }
      
      // Trigger music auto-open on first set completion
      if (_completedSets.length == 1) {
        _musicPlayButtonKey.currentState?.triggerAutoOpen();
      }
    }
  }

  int? _resolveRestSeconds(Map<String, dynamic> exercise) {
    // Priority: set['rest_seconds'] > exercise['rest_seconds'] > plan['defaults']['rest_seconds']
    // Current UI has not per-set object, so only exercise and plan defaults apply.
    final exRest = int.tryParse((exercise['rest_seconds'] ?? exercise['rest'] ?? '').toString());
    if (exRest != null && exRest > 0) return exRest;
    final defaults = Map<String, dynamic>.from((_plan?['defaults'] as Map<String, dynamic>?) ?? {});
    final planRest = int.tryParse((defaults['rest_seconds'] ?? '').toString());
    return planRest;
  }

  String? _nextSetHint(int w, int d, int e, int s, Map<String, dynamic> exercise) {
    final name = (exercise['name'] ?? 'Exercise').toString();
    final totalSets = int.tryParse((exercise['sets'] ?? 0).toString()) ?? 0;
    if (s + 1 < totalSets) {
      return 'Next: $name · Set ${s + 2}';
    }
    return 'Next: $name · Finish';
  }

  void _showRestTimer({required int seconds, String? nextHint}) {
    // Dismiss existing and show a new fresh one
    if (Navigator.canPop(context)) {
      // Attempt to close any open bottom sheet
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => RestTimer(
        seconds: seconds,
        nextHint: nextHint,
        autoStart: true,
        onFinish: () {
          if (Navigator.canPop(ctx)) Navigator.pop(ctx);
        },
        onCancel: () {},
      ),
    );
  }

  void _showExerciseDetailSheet({
    required Map<String, dynamic> exercise,
    required int dayIndex,
  }) {
    final groupExercises = _getGroupExercises(exercise, dayIndex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ExerciseDetailSheet(
          exercises: groupExercises,
          initialIndex: groupExercises.indexWhere((e) => identical(e, exercise)),
          roleContext: _role,
          onMarkDone: (ex) {
            // OPTIONAL: hook into your existing completion toggle if available.
            // Example: _toggleExerciseDone(dayIndex, ex);
            // Leave as is if not supported.
          },
          onAddNote: (ex, note) {
            // OPTIONAL: hook to your existing note mechanism per exercise.
            // Example: _saveExerciseNote(dayIndex, ex, note);
          },
          onAttachMedia: (ex) {
            // OPTIONAL: open your attachment flow here if you have one.
            // Example: _openAttachmentPickerForExercise(dayIndex, ex);
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getGroupExercises(Map<String, dynamic> exercise, int dayIndex) {
    try {
      final weeks = List<Map<String, dynamic>>.from((_plan?['weeks'] as List<dynamic>?) ?? []);
      if (weeks.isEmpty || _currentWeek >= weeks.length) return [exercise];
      
      final week = weeks[_currentWeek];
      final days = List<Map<String, dynamic>>.from((week['days'] as List<dynamic>?) ?? []);
      if (dayIndex >= days.length) return [exercise];
      
      final day = days[dayIndex];
      final List<dynamic> all = (day['exercises'] as List?) ?? const [];
      final groupId = exercise['groupId'];

      if (groupId == null) {
        // Not grouped: return just this exercise
        return [exercise];
      }
      final sameGroup = all.whereType<Map<String, dynamic>>().where((e) => e['groupId'] == groupId).toList();
      return sameGroup.isNotEmpty ? sameGroup : [exercise];
    } catch (_) {
      return [exercise];
    }
  }

  Widget _buildWeekView() {
    final weeks = List<Map<String, dynamic>>.from((_plan!['weeks'] as List<dynamic>?) ?? []);
    if (weeks.isEmpty) {
      return const Center(child: Text('No weeks in this plan.'));
    }
    final currentWeekData = Map<String, dynamic>.from(weeks[_currentWeek]);
    final days = List<Map<String, dynamic>>.from((currentWeekData['days'] as List<dynamic>?) ?? []);

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = Map<String, dynamic>.from(days[i]);
        final exercises = List<Map<String, dynamic>>.from((day['exercises'] as List<dynamic>?) ?? []);
        final attachments = List<Map<String, dynamic>>.from((day['attachments'] as List<dynamic>?) ?? []);

        final cardio = List<Map<String, dynamic>>.from((day['cardio'] as List<dynamic>?) ?? []);
        final showDay = _searchTerm.isEmpty
            ? true
            : exercises.any((e) => (e['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchTerm)) ||
            cardio.any((c) => (c['machineType'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchTerm));

        if (!showDay) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            // [day-tag] show a small calendar-style tag next to the day name when available
            title: Builder(builder: (context) {
              final tagText = (day['tag'] ?? '').toString().trim();
              final dayTitle = '📅 ${day['label'] ?? 'Day ${i + 1}'}';
              if (tagText.isEmpty) {
                return Text(dayTitle);
              }
              final chipBg = Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
              final chipFg = Theme.of(context).colorScheme.primary;
              return Row(
                children: [
                  Expanded(child: Text(dayTitle, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(tagText, style: TextStyle(color: chipFg, fontSize: 12)),
                  ),
                ],
              );
            }),
            childrenPadding: const EdgeInsets.only(bottom: 12),
            children: [
              if (attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: attachments.map((f) => AttachmentViewer(file: f)).toList(),
                  ),
                ),

              // Week volume summary at first day
              if (i == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: VolumeSummaryCard(plan: _plan ?? {}, weekIndex: _currentWeek, collapsedInitially: false),
                ),

              // exercises with per-set chips
              ...exercises
                  .where((ex) => (ex['name'] ?? '').toString().toLowerCase().contains(_searchTerm))
                  .map((ex) {
                final e = Map<String, dynamic>.from(ex);
                final exAttachments = List<Map<String, dynamic>>.from(e['attachments'] ?? []);
                final sets = int.tryParse((e['sets'] ?? 0).toString()) ?? 0;
                final exerciseIndex = exercises.indexOf(ex);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      onTap: () => _showExerciseDetailSheet(
                        exercise: e,
                        dayIndex: i,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(e['name'] ?? 'Unnamed Exercise')),
                          if (((e['tutorialLink'] ?? '').toString()).isNotEmpty)
                            IconButton(
                              tooltip: 'Open tutorial',
                              icon: const Icon(Icons.link),
                              onPressed: () async {
                                final url = Uri.tryParse((e['tutorialLink'] ?? '').toString());
                                if (url != null && await canLaunchUrl(url)) {
                                  try {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } catch (_) {
                                    if (!mounted || !context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Couldn't open link")),
                                    );
                                  }
                                } else {
                                  if (!mounted || !context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Couldn't open link")),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📊 Sets: ${e['sets'] ?? '-'}  Reps: ${e['reps'] ?? '-'}'),
                          Text('⏱️ Rest: ${e['rest'] ?? '-'}'),
                          Text('🔥 %1RM: ${e['percent1RM'] ?? '-'}'),
                          if ((e['notes'] ?? '').toString().isNotEmpty) Text('📝 Notes: ${e['notes']}'),
                          if ((e['tonnage'] ?? '').toString().isNotEmpty) Text('💪 Tonnage: ${e['tonnage']}'),
                          if (sets > 0) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: List.generate(sets, (si) {
                                final key = _setKey(_currentWeek, i, exerciseIndex, si);
                                final done = _completedSets.contains(key);
                                return ChoiceChip(
                                  label: Text('Set ${si + 1}'),
                                  selected: done,
                                  onSelected: (_) => _toggleSetDone(
                                    weekIndex: _currentWeek,
                                    dayIndex: i,
                                    exerciseIndex: exerciseIndex,
                                    setIndex: si,
                                    exercise: e,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (exAttachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: exAttachments.map((f) => AttachmentViewer(file: f)).toList(),
                        ),
                      ),
                  ],
                );
              }),

              // NEW: Cardio section
              if (cardio.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.directions_run, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cardio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                ...cardio.map((cardioEntry) {
                  final cardio = Map<String, dynamic>.from(cardioEntry);
                  final machineType = cardio['machineType'] ?? 'Unknown Machine';
                  final settings = Map<String, dynamic>.from(cardio['settings'] ?? {});
                  final instructions = cardio['instructions'] ?? '';

                  // Build settings display string
                  final settingsList = <String>[];
                  if (settings['speed'] != null) settingsList.add('Speed: ${settings['speed']} km/h');
                  if (settings['incline'] != null) settingsList.add('Incline: ${settings['incline']}%');
                  if (settings['resistance'] != null) settingsList.add('Resistance: ${settings['resistance']}');
                  if (settings['cadence'] != null) settingsList.add('Cadence: ${settings['cadence']} RPM');
                  if (settings['strokeRate'] != null) settingsList.add('Stroke Rate: ${settings['strokeRate']} SPM');
                  if (settings['stepRate'] != null) settingsList.add('Step Rate: ${settings['stepRate']} steps/min');
                  if (settings['level'] != null) settingsList.add('Level: ${settings['level']}');
                  if (settings['duration'] != null) settingsList.add('Duration: ${settings['duration']} min');
                  if (settings['instructions'] != null) settingsList.add('Instructions: ${settings['instructions']}');

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.directions_run, color: Colors.green),
                      title: Text(
                        machineType,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (settingsList.isNotEmpty)
                            Text(settingsList.join(' • ')),
                          if (instructions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '📝 $instructions',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              // comment box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextFormField(
                  initialValue: day['clientComment'] ?? '',
                  maxLines: 2,
                  // [comment-permission] allow edit only for plan owner (client)
                  enabled: _canEditComments,
                  decoration: InputDecoration(
                    labelText: 'Leave a comment for this day',
                    border: const OutlineInputBorder(),
                    helperText: _canEditComments ? null : 'Read-only (coach/admin view)',
                  ),
                  onChanged: (val) {
                    // mutate in-memory plan (so Save button persists)
                    final weeksMut = List<Map<String, dynamic>>.from((_plan!['weeks'] as List<dynamic>?) ?? []);
                    final thisWeek = Map<String, dynamic>.from(weeksMut[_currentWeek]);
                    final daysMut = List<Map<String, dynamic>>.from((thisWeek['days'] as List<dynamic>?) ?? []);
                    final dayMut = Map<String, dynamic>.from(daysMut[i]);
                    dayMut['clientComment'] = val;
                    daysMut[i] = dayMut;
                    thisWeek['days'] = daysMut;
                    weeksMut[_currentWeek] = thisWeek;
                    setState(() {
                      _plan!['weeks'] = weeksMut;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AttachmentViewer extends StatelessWidget {
  final Map<String, dynamic> file;

  const AttachmentViewer({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final url = (file['url'] ?? '').toString();
    final type = (file['type'] ?? '').toString();

    Widget iconWithLabel(IconData icon, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ]),
      );
    }

    if (type.startsWith('image')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: safeNetImage(url, height: 100, width: 100, fit: BoxFit.cover),
      );
    } else if (type.startsWith('video')) {
      return iconWithLabel(Icons.videocam, 'Video');
    } else if (type.startsWith('audio')) {
      return iconWithLabel(Icons.audiotrack, 'Audio');
    } else if (type == 'application/pdf') {
      return iconWithLabel(Icons.picture_as_pdf, 'PDF');
    } else {
      return iconWithLabel(Icons.insert_drive_file, 'File');
    }
  }
}

// [excel-edit] Full-screen, inline-edit table for all weeks/days/exercises
class _ExcelPlanEditorScreen extends StatefulWidget {
  final List<Map<String, dynamic>> weeks;
  final void Function(List<Map<String, dynamic>> updatedWeeks) onChange;
  final Future<void> Function() onSave;

  const _ExcelPlanEditorScreen({
    required this.weeks,
    required this.onChange,
    required this.onSave,
  });

  @override
  State<_ExcelPlanEditorScreen> createState() => _ExcelPlanEditorScreenState();
}

class _ExcelPlanEditorScreenState extends State<_ExcelPlanEditorScreen> {
  late List<Map<String, dynamic>> _weeks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weeks = widget.weeks.map((w) => Map<String, dynamic>.from(w)).toList();
  }

  void _updateCell({
    required int weekIndex,
    required int dayIndex,
    required int exerciseIndex,
    required String field,
    required String value,
  }) {
    final weeksMut = _weeks.map((w) => Map<String, dynamic>.from(w)).toList();
    final week = Map<String, dynamic>.from(weeksMut[weekIndex]);
    final days = List<Map<String, dynamic>>.from((week['days'] as List<dynamic>?) ?? []);
    final day = Map<String, dynamic>.from(days[dayIndex]);
    final exercises = List<Map<String, dynamic>>.from((day['exercises'] as List<dynamic>?) ?? []);
    final ex = Map<String, dynamic>.from(exercises[exerciseIndex]);
    ex[field] = value;
    exercises[exerciseIndex] = ex;
    day['exercises'] = exercises;
    days[dayIndex] = day;
    week['days'] = days;
    weeksMut[weekIndex] = week;
    setState(() => _weeks = weeksMut);
    widget.onChange(_weeks);
  }

  // [excel-tag] update day-level tag value
  void _updateDayTag({
    required int weekIndex,
    required int dayIndex,
    required String value,
  }) {
    final weeksMut = _weeks.map((w) => Map<String, dynamic>.from(w)).toList();
    final week = Map<String, dynamic>.from(weeksMut[weekIndex]);
    final days = List<Map<String, dynamic>>.from((week['days'] as List<dynamic>?) ?? []);
    final day = Map<String, dynamic>.from(days[dayIndex]);
    day['tag'] = value;
    days[dayIndex] = day;
    week['days'] = days;
    weeksMut[weekIndex] = week;
    setState(() => _weeks = weeksMut);
    widget.onChange(_weeks);
  }

  Widget _buildEditableCell({
    required String initial,
    required void Function(String) onChanged,
    double width = 140,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VagusAppBar(
        title: const Text('Edit Full Plan'),
        actions: [
          TextButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await widget.onSave();
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1100),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_weeks.length, (weekIndex) {
                  final week = Map<String, dynamic>.from(_weeks[weekIndex]);
                  final days = List<Map<String, dynamic>>.from((week['days'] as List<dynamic>?) ?? []);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Week ${weekIndex + 1}', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    // [excel-tag] insert Tag column after Day
                    columnWidths: const {
                      0: FixedColumnWidth(70),  // Week
                      1: FixedColumnWidth(140), // Day
                      2: FixedColumnWidth(120), // Tag
                      3: FixedColumnWidth(220), // Exercise
                      4: FixedColumnWidth(80),  // Sets
                      5: FixedColumnWidth(80),  // Reps
                      6: FixedColumnWidth(90),  // Rest
                      7: FixedColumnWidth(90),  // %1RM
                      8: FixedColumnWidth(110), // Tonnage
                      9: FixedColumnWidth(240), // Notes
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFF3F4F6)),
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text('Week')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Day')),
                          // [excel-tag]
                          Padding(padding: EdgeInsets.all(8), child: Text('Tag')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Exercise Name')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Sets')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Reps')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Rest')),
                          Padding(padding: EdgeInsets.all(8), child: Text('%1RM')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Tonnage')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Notes')),
                        ],
                      ),
                      ...List.generate(days.length, (dayIndex) {
                        final day = Map<String, dynamic>.from(days[dayIndex]);
                        final exercises = List<Map<String, dynamic>>.from((day['exercises'] as List<dynamic>?) ?? []);
                        if (exercises.isEmpty) {
                          return TableRow(children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text('${weekIndex + 1}')),
                            Padding(padding: const EdgeInsets.all(8), child: Text(day['label'] ?? 'Day ${dayIndex + 1}')),
                            // [excel-tag] Tag editor even if day has no exercises
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox(
                                width: 120,
                                child: TextFormField(
                                  initialValue: (day['tag'] ?? '').toString(),
                                  onChanged: (v) => _updateDayTag(
                                    weekIndex: weekIndex,
                                    dayIndex: dayIndex,
                                    value: v,
                                  ),
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                ),
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(8), child: Text('—')),
                            const Padding(padding: EdgeInsets.all(8), child: Text('')),
                            const Padding(padding: EdgeInsets.all(8), child: Text('')),
                            const Padding(padding: EdgeInsets.all(8), child: Text('')),
                            const Padding(padding: EdgeInsets.all(8), child: Text('')),
                            const Padding(padding: EdgeInsets.all(8), child: Text('')),
                            const Padding(padding: EdgeInsets.all(8), child: Text('')),
                          ]);
                        }
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text('${weekIndex + 1}')),
                            Padding(padding: const EdgeInsets.all(8), child: Text(day['label'] ?? 'Day ${dayIndex + 1}')),
                            // [excel-tag] Day tag editor
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox(
                                width: 120,
                                child: TextFormField(
                                  initialValue: (day['tag'] ?? '').toString(),
                                  onChanged: (v) => _updateDayTag(
                                    weekIndex: weekIndex,
                                    dayIndex: dayIndex,
                                    value: v,
                                  ),
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(exercises.length, (exerciseIndex) {
                                final e = Map<String, dynamic>.from(exercises[exerciseIndex]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildEditableCell(
                                    initial: (e['name'] ?? '').toString(),
                                    onChanged: (v) => _updateCell(
                                      weekIndex: weekIndex,
                                      dayIndex: dayIndex,
                                      exerciseIndex: exerciseIndex,
                                      field: 'name',
                                      value: v,
                                    ),
                                    width: 220,
                                  ),
                                );
                              }),
                            ),
                            Column(
                              children: List.generate(exercises.length, (exerciseIndex) {
                                final e = Map<String, dynamic>.from(exercises[exerciseIndex]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildEditableCell(
                                    initial: (e['sets'] ?? '').toString(),
                                    onChanged: (v) => _updateCell(
                                      weekIndex: weekIndex,
                                      dayIndex: dayIndex,
                                      exerciseIndex: exerciseIndex,
                                      field: 'sets',
                                      value: v,
                                    ),
                                    width: 80,
                                  ),
                                );
                              }),
                            ),
                            Column(
                              children: List.generate(exercises.length, (exerciseIndex) {
                                final e = Map<String, dynamic>.from(exercises[exerciseIndex]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildEditableCell(
                                    initial: (e['reps'] ?? '').toString(),
                                    onChanged: (v) => _updateCell(
                                      weekIndex: weekIndex,
                                      dayIndex: dayIndex,
                                      exerciseIndex: exerciseIndex,
                                      field: 'reps',
                                      value: v,
                                    ),
                                    width: 80,
                                  ),
                                );
                              }),
                            ),
                            Column(
                              children: List.generate(exercises.length, (exerciseIndex) {
                                final e = Map<String, dynamic>.from(exercises[exerciseIndex]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildEditableCell(
                                    initial: (e['rest'] ?? '').toString(),
                                    onChanged: (v) => _updateCell(
                                      weekIndex: weekIndex,
                                      dayIndex: dayIndex,
                                      exerciseIndex: exerciseIndex,
                                      field: 'rest',
                                      value: v,
                                    ),
                                    width: 90,
                                  ),
                                );
                              }),
                            ),
                            Column(
                              children: List.generate(exercises.length, (exerciseIndex) {
                                final e = Map<String, dynamic>.from(exercises[exerciseIndex]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildEditableCell(
                                    initial: (e['percent1RM'] ?? '').toString(),
                                    onChanged: (v) => _updateCell(
                                      weekIndex: weekIndex,
                                      dayIndex: dayIndex,
                                      exerciseIndex: exerciseIndex,
                                      field: 'percent1RM',
                                      value: v,
                                    ),
                                    width: 90,
                                  ),
                                );
                              }),
                            ),
                            Column(
                              children: List.generate(exercises.length, (exerciseIndex) {
                                final e = Map<String, dynamic>.from(exercises[exerciseIndex]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildEditableCell(
                                    initial: (e['tonnage'] ?? '').toString(),
                                    onChanged: (v) => _updateCell(
                                      weekIndex: weekIndex,
                                      dayIndex: dayIndex,
                                      exerciseIndex: exerciseIndex,
                                      field: 'tonnage',
                                      value: v,
                                    ),
                                    width: 110,
                                  ),
                                );
                              }),
                            ),
                            Column(
                              children: List.generate(exercises.length, (exerciseIndex) {
                                final e = Map<String, dynamic>.from(exercises[exerciseIndex]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: _buildEditableCell(
                                    initial: (e['notes'] ?? '').toString(),
                                    onChanged: (v) => _updateCell(
                                      weekIndex: weekIndex,
                                      dayIndex: dayIndex,
                                      exerciseIndex: exerciseIndex,
                                      field: 'notes',
                                      value: v,
                                    ),
                                    width: 240,
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      })
                    ],
                  ),
                ],
              );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }


}
