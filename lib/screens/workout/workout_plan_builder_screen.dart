import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  String _role = 'client';
  int _currentWeek = 0;
  bool _loading = true;
  String _error = '';
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    if (widget.planOverride != null) {
      _plan = Map<String, dynamic>.from(widget.planOverride!);
      _loading = false;
      _populatePlansForContext(); // ✅ load plans for dropdown even with planOverride
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      _role = profile['role'] ?? 'client';

      List<dynamic> plans;
      if (_role == 'coach') {
        plans = await supabase
            .from('workout_plans')
            .select()
            .eq('coach_id', user.id)
            .order('created_at', ascending: false);
      } else {
        plans = await supabase
            .from('workout_plans')
            .select()
            .eq('client_id', user.id)
            .order('created_at', ascending: false);
      }

      setState(() {
        _plans = plans.map((p) => Map<String, dynamic>.from(p)).toList();
        if (_plans.isNotEmpty) {
          _plan = _plans.first;
        }
        _loading = false;
      });

          debugPrint("📦 Loaded plans: ${_plans.map((p) => p['id']).toList()}");
    debugPrint("✅ Current selected: ${_plan?['id']}");
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
            .eq('coach_id', user.id)
            .order('created_at', ascending: false);
      } else {
        final clientId = (_plan?['client_id'] ?? user.id).toString();
        result = await supabase
            .from('workout_plans')
            .select()
            .eq('client_id', clientId)
            .order('created_at', ascending: false);
      }

      setState(() {
        _plans = result
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      });

              debugPrint('✅ Loaded ${_plans.length} plans for dropdown');
      } catch (e) {
        debugPrint('❌ Error loading plans for dropdown: $e');
    }
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text('Workout Plan: ${_plan?['name'] ?? 'Unnamed'}'),
            pw.SizedBox(height: 10),
            ...List.generate(_plan?['weeks'].length ?? 0, (weekIndex) {
              final week = _plan!['weeks'][weekIndex];
              return pw.Column(children: [
                pw.Text('Week ${weekIndex + 1}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...List.generate(week['days'].length, (dayIndex) {
                  final day = week['days'][dayIndex];
                  return pw.Column(children: [
                    pw.Text('Day: ${day['label'] ?? 'Day ${dayIndex + 1}'}'),
                    ...List.generate(day['exercises']?.length ?? 0, (i) {
                      final ex = day['exercises'][i];
                      return pw.Text('• ${ex['name']} - Sets: ${ex['sets']}, Reps: ${ex['reps']}, Rest: ${ex['rest']}');
                    })
                  ]);
                })
              ]);
            })
          ];
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
          )
        ],
      ),
      body: _plan == null
          ? Center(child: Text(_error))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _plan != null ? _plan!['id'].toString() : null,
              decoration: const InputDecoration(
                labelText: 'Select Plan',
                border: OutlineInputBorder(),
              ),
              items: _plans.map((plan) {
                return DropdownMenuItem<String>(
                  value: plan['id'].toString(),
                  child: Text(plan['name'] ?? 'Unnamed Plan'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final selected = _plans.firstWhere(
                        (p) => p['id'].toString() == val,
                    orElse: () => {},
                  );
                  setState(() => _plan = selected);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchTerm = val.toLowerCase()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _currentWeek,
              decoration: const InputDecoration(
                labelText: 'Select Week',
                border: OutlineInputBorder(),
              ),
              items: List.generate(_plan!['weeks'].length, (i) {
                return DropdownMenuItem(value: i, child: Text('Week ${i + 1}'));
              }),
              onChanged: (val) {
                if (val != null) setState(() => _currentWeek = val);
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildWeekView()),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    final weeks = List<Map<String, dynamic>>.from(_plan!['weeks']);
    final currentWeekData = weeks[_currentWeek];
    final days = List<Map<String, dynamic>>.from(currentWeekData['days']);

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final exercises = List<Map<String, dynamic>>.from(day['exercises'] ?? []);
        final attachments = List<Map<String, dynamic>>.from(day['attachments'] ?? []);
        final showDay = exercises.any((e) => (e['name'] ?? '').toString().toLowerCase().contains(_searchTerm));

        if (_searchTerm.isNotEmpty && !showDay) return const SizedBox();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            title: Text('📅 ${day['label'] ?? 'Day ${i + 1}'}'),
            children: [
              if (attachments.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: attachments.map((f) => AttachmentViewer(file: f)).toList(),
                ),
              ...exercises
                  .where((ex) => ex['name'].toString().toLowerCase().contains(_searchTerm))
                  .map((ex) {
                final exAttachments = List<Map<String, dynamic>>.from(ex['attachments'] ?? []);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(ex['name'] ?? 'Unnamed Exercise'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📊 Sets: ${ex['sets']}  Reps: ${ex['reps']}'),
                          Text('⏱️ Rest: ${ex['rest']} seconds'),
                          Text('🔥 %1RM: ${ex['percent1RM']}'),
                          if ((ex['notes'] ?? '').isNotEmpty) Text('📝 Notes: ${ex['notes']}'),
                          if ((ex['tonnage'] ?? '').toString().isNotEmpty) Text('💪 Tonnage: ${ex['tonnage']}'),
                        ],
                      ),
                    ),
                    if (exAttachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: exAttachments.map((f) => AttachmentViewer(file: f)).toList(),
                        ),
                      ),
                  ],
                );
              }),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  initialValue: day['clientComment'] ?? '',
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Leave a comment for this day',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => day['clientComment'] = val,
                ),
              )
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
    final url = file['url'] ?? '';
    final type = file['type'] ?? '';

    if (type.startsWith('image')) {
      return Image.network(url, height: 100);
    } else if (type.startsWith('video')) {
      return const Icon(Icons.videocam);
    } else if (type.startsWith('audio')) {
      return const Icon(Icons.audiotrack);
    } else if (type == 'application/pdf') {
      return const Row(children: [Icon(Icons.picture_as_pdf), Text('PDF')]);
    } else {
      return const Row(children: [Icon(Icons.insert_drive_file), Text('File')]);
    }
  }
}
