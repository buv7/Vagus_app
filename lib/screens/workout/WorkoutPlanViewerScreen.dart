import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // [tutorialLink]

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
      print("📦 Loaded plans: ${_plans.map((p) => p['id']).toList()}");
    } catch (e) {
      setState(() {
        _error = '❌ Failed to load data.';
        _loading = false;
      });
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
                pw.Text('Week ${weekIndex + 1}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
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
      appBar: AppBar(
        title: const Text('📋 Workout Viewer'),
        actions: [
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

            // Week tags (chips) + dropdown
            _buildWeekChips(),
            const SizedBox(height: 8),
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
              final chipBg = Theme.of(context).colorScheme.primary.withOpacity(0.12);
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

              // exercises
              ...exercises
                  .where((ex) =>
                  (ex['name'] ?? '').toString().toLowerCase().contains(_searchTerm))
                  .map((ex) {
                final e = Map<String, dynamic>.from(ex);
                final exAttachments = List<Map<String, dynamic>>.from(e['attachments'] ?? []);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(e['name'] ?? 'Unnamed Exercise')),
                          // [tutorialLink] show link icon when tutorialLink exists
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
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Couldn't open link")),
                                      );
                                    }
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Couldn't open link")),
                                    );
                                  }
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
                          if ((e['notes'] ?? '').toString().isNotEmpty)
                            Text('📝 Notes: ${e['notes']}'),
                          if ((e['tonnage'] ?? '').toString().isNotEmpty)
                            Text('💪 Tonnage: ${e['tonnage']}'),
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
              }).toList(),

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
                }).toList(),
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
      appBar: AppBar(
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
