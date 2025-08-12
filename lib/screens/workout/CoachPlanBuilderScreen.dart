import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class CoachPlanBuilderScreen extends StatefulWidget {
  const CoachPlanBuilderScreen({super.key});

  @override
  State<CoachPlanBuilderScreen> createState() => _CoachPlanBuilderScreenState();
}

class _CoachPlanBuilderScreenState extends State<CoachPlanBuilderScreen> {
  final supabase = Supabase.instance.client;

  String clientId = '';
  String planName = '';
  DateTime? startDate;
  int durationWeeks = 12;

  List<Map<String, dynamic>> clients = [];
  bool loadingClients = true;
  bool saving = false;
  String message = '';

  List<Map<String, dynamic>> weeks = [];
  
  // NEW: Superset/Circuit management
  Map<String, List<int>> selectedExercises = {}; // weekIndex_dayIndex -> [exerciseIndices]
  String? currentGroupType; // 'superset' or 'circuit'
  
  // NEW: AI suggestions cache
  Map<String, List<String>> aiSuggestionsCache = {};
  
  // NEW: Exercise history cache
  Map<String, List<Map<String, dynamic>>> exerciseHistoryCache = {};

  @override
  void initState() {
    super.initState();
    loadClients();
  }
  Future<void> loadClients() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('coach_clients')
        .select('client_id, profiles:client_id (id, name, email)')
        .eq('coach_id', user.id);

    setState(() {
      clients = (response as List)
          .map((row) {
        final profile = row['profiles'] as Map<String, dynamic>;
        return {
          'id': profile['id'], // ✅ this is important for matching client_id
          'name': profile['name'],
          'email': profile['email'],
        };
      })
          .toList();
      loadingClients = false;
    });
  }

  void addWeek() {
    setState(() {
      weeks.add({'days': []});
    });
  }

  void addDay(int weekIndex) {
    setState(() {
      weeks[weekIndex]['days'].add({
        'label': '',
        'exercises': [],
        'cardio': [], // NEW: Cardio section
        'clientComment': '',
        'attachments': []
      });
    });
  }

  // NEW: Enhanced addExercise with group support
  void addExercise(int weekIndex, int dayIndex) {
    setState(() {
      weeks[weekIndex]['days'][dayIndex]['exercises'].add({
        'name': '',
        'sets': 0,
        'reps': 0,
        'rest': '',
        'notes': '',
        'percent1RM': 0,
        'tonnage': 0,
        'attachments': [],
        // NEW: Group fields
        'groupId': null,
        'groupType': null,
        'weight': 0, // NEW: for %1RM calculation
        'RIR': 0, // NEW: Reps in Reserve
        'exerciseNote': '', // NEW: per-exercise notes
        'exerciseMedia': [], // NEW: per-exercise media
      });
    });
  }

  void removeWeek(int index) {
    setState(() => weeks.removeAt(index));
  }

  void removeDay(int weekIndex, int dayIndex) {
    setState(() => weeks[weekIndex]['days'].removeAt(dayIndex));
  }

  void removeExercise(int weekIndex, int dayIndex, int exIndex) {
    setState(() => weeks[weekIndex]['days'][dayIndex]['exercises'].removeAt(exIndex));
  }

  // NEW: Cardio management functions
  void addCardio(int weekIndex, int dayIndex) {
    setState(() {
      weeks[weekIndex]['days'][dayIndex]['cardio'].add({
        'machineType': 'Treadmill',
        'settings': {},
        'instructions': '',
      });
    });
  }

  void removeCardio(int weekIndex, int dayIndex, int cardioIndex) {
    setState(() => weeks[weekIndex]['days'][dayIndex]['cardio'].removeAt(cardioIndex));
  }

  void duplicateCardio(int weekIndex, int dayIndex, int cardioIndex) {
    final original = weeks[weekIndex]['days'][dayIndex]['cardio'][cardioIndex];
    setState(() {
      weeks[weekIndex]['days'][dayIndex]['cardio'].add({
        'machineType': original['machineType'],
        'settings': Map<String, dynamic>.from(original['settings']),
        'instructions': original['instructions'],
      });
    });
  }

  void updateCardio(int weekIndex, int dayIndex, int cardioIndex, String field, dynamic value) {
    setState(() {
      weeks[weekIndex]['days'][dayIndex]['cardio'][cardioIndex][field] = value;
    });
  }

  void updateCardioSetting(int weekIndex, int dayIndex, int cardioIndex, String settingKey, dynamic value) {
    setState(() {
      weeks[weekIndex]['days'][dayIndex]['cardio'][cardioIndex]['settings'][settingKey] = value;
    });
  }

  // NEW: Cardio drag and drop reordering
  void _reorderCardio(int weekIndex, int dayIndex, int oldIndex, int newIndex) {
    setState(() {
      final cardio = weeks[weekIndex]['days'][dayIndex]['cardio'];
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = cardio.removeAt(oldIndex);
      cardio.insert(newIndex, item);
    });
  }

  // NEW: Enhanced updateExercise with auto-calculations
  void updateExercise(int weekIndex, int dayIndex, int exIndex, String field, dynamic value) {
    setState(() {
      weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex][field] = value;

      final sets = (weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['sets'] ?? 0) as num;
      final reps = (weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['reps'] ?? 0) as num;
      final percent1RM = (weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['percent1RM'] ?? 0) as num;
      final tonnage = sets * reps * (percent1RM / 100);
      weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['tonnage'] = tonnage;
      
      // NEW: Auto-calculate %1RM if weight and reps are provided
      final weight = (weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['weight'] ?? 0) as num;
      if (weight > 0 && reps > 0) {
        final calculatedPercent1RM = _calculatePercent1RM(weight.toDouble(), reps.toInt());
        if (calculatedPercent1RM > 0) {
          weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['percent1RM'] = calculatedPercent1RM;
        }
      }
    });
  }

  // NEW: %1RM calculation using Epley formula
  double _calculatePercent1RM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    // Epley formula: 1RM = weight × (1 + reps/30)
    final oneRM = weight * (1 + reps / 30);
    return (weight / oneRM) * 100;
  }

  // NEW: RIR calculation based on perceived exertion
  double _calculateRIR(int reps, int perceivedExertion) {
    // Perceived exertion scale: 1-10, where 10 is maximum effort
    if (perceivedExertion >= 10) return 0; // No reps in reserve
    if (perceivedExertion <= 1) return reps * 0.8; // Many reps in reserve
    // Linear interpolation
    return reps * (1 - (perceivedExertion - 1) / 9);
  }

  // NEW: Helper function to get color for different group types
  Color _getGroupTypeColor(String? groupType) {
    switch (groupType) {
      case 'superset':
        return Colors.purple[50]!;
      case 'circuit':
        return Colors.orange[50]!;
      case 'drop_set':
        return Colors.red[50]!;
      case 'giant_set':
        return Colors.green[50]!;
      case 'top_set':
        return Colors.blue[50]!;
      case 'back_off_set':
        return Colors.indigo[50]!;
      case 'pyramid_set':
        return Colors.teal[50]!;
      default:
        return Colors.transparent;
    }
  }

  // NEW: Helper function to get header color for different group types
  Color _getGroupHeaderColor(String? groupType) {
    switch (groupType) {
      case 'superset':
        return Colors.purple[100]!;
      case 'circuit':
        return Colors.orange[100]!;
      case 'drop_set':
        return Colors.red[100]!;
      case 'giant_set':
        return Colors.green[100]!;
      case 'top_set':
        return Colors.blue[100]!;
      case 'back_off_set':
        return Colors.indigo[100]!;
      case 'pyramid_set':
        return Colors.teal[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  // NEW: Helper function to get icon for different group types
  IconData _getGroupTypeIcon(String? groupType) {
    switch (groupType) {
      case 'superset':
        return Icons.link;
      case 'circuit':
        return Icons.repeat;
      case 'drop_set':
        return Icons.trending_down;
      case 'giant_set':
        return Icons.fitness_center;
      case 'top_set':
        return Icons.trending_up;
      case 'back_off_set':
        return Icons.arrow_back;
      case 'pyramid_set':
        return Icons.change_history;
      default:
        return Icons.fitness_center;
    }
  }

  // NEW: Helper function to get display name for different group types
  String _getGroupTypeDisplayName(String? groupType) {
    switch (groupType) {
      case 'superset':
        return 'SUPERSET';
      case 'circuit':
        return 'CIRCUIT';
      case 'drop_set':
        return 'DROP SET';
      case 'giant_set':
        return 'GIANT SET';
      case 'top_set':
        return 'TOP SET';
      case 'back_off_set':
        return 'BACK-OFF SET';
      case 'pyramid_set':
        return 'PYRAMID SET';
      default:
        return 'COMBO SET';
    }
  }

  // NEW: Cardio machine types
  static const List<String> cardioMachineTypes = [
    'Treadmill',
    'Elliptical',
    'Stationary Bike',
    'Rowing Machine',
    'Stair Climber',
    'Spin Bike',
    'Arc Trainer',
    'SkiErg',
    'Other'
  ];

  // NEW: Get cardio machine settings based on machine type
  List<Map<String, dynamic>> _getCardioMachineSettings(String machineType) {
    switch (machineType) {
      case 'Treadmill':
        return [
          {'key': 'speed', 'label': 'Speed (km/h)', 'type': 'number'},
          {'key': 'incline', 'label': 'Incline (%)', 'type': 'number'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      case 'Elliptical':
        return [
          {'key': 'resistance', 'label': 'Resistance Level', 'type': 'number'},
          {'key': 'incline', 'label': 'Incline (%)', 'type': 'number'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      case 'Stationary Bike':
        return [
          {'key': 'resistance', 'label': 'Resistance Level', 'type': 'number'},
          {'key': 'cadence', 'label': 'Cadence (RPM)', 'type': 'number'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      case 'Rowing Machine':
        return [
          {'key': 'strokeRate', 'label': 'Stroke Rate (SPM)', 'type': 'number'},
          {'key': 'resistance', 'label': 'Resistance Level', 'type': 'number'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      case 'Stair Climber':
        return [
          {'key': 'stepRate', 'label': 'Step Rate (steps/min)', 'type': 'number'},
          {'key': 'level', 'label': 'Level', 'type': 'number'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      case 'Spin Bike':
        return [
          {'key': 'resistance', 'label': 'Resistance Level', 'type': 'number'},
          {'key': 'cadence', 'label': 'Cadence (RPM)', 'type': 'number'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      case 'Arc Trainer':
        return [
          {'key': 'resistance', 'label': 'Resistance Level', 'type': 'number'},
          {'key': 'incline', 'label': 'Incline (%)', 'type': 'number'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      case 'SkiErg':
        return [
          {'key': 'resistance', 'label': 'Resistance Level', 'type': 'number'},
          {'key': 'strokeRate', 'label': 'Stroke Rate (SPM)', 'type': 'number'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      case 'Other':
        return [
          {'key': 'instructions', 'label': 'Instructions', 'type': 'text'},
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
      default:
        return [
          {'key': 'duration', 'label': 'Duration (min)', 'type': 'number'},
        ];
    }
  }

  // NEW: Superset/Circuit management
  void toggleExerciseSelection(int weekIndex, int dayIndex, int exIndex) {
    final key = '${weekIndex}_${dayIndex}';
    setState(() {
      if (selectedExercises[key]?.contains(exIndex) == true) {
        selectedExercises[key]!.remove(exIndex);
        if (selectedExercises[key]!.isEmpty) {
          selectedExercises.remove(key);
        }
      } else {
        selectedExercises[key] ??= [];
        selectedExercises[key]!.add(exIndex);
      }
    });
  }

  void createSupersetOrCircuit(int weekIndex, int dayIndex, String groupType) {
    final key = '${weekIndex}_${dayIndex}';
    final selected = selectedExercises[key];
    if (selected == null || selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Select at least 2 exercises to create a $groupType')),
      );
      return;
    }

    final groupId = '${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      for (final exIndex in selected) {
        weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['groupId'] = groupId;
        weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['groupType'] = groupType;
      }
      selectedExercises.remove(key);
    });
  }

  void removeFromGroup(int weekIndex, int dayIndex, int exIndex) {
    setState(() {
      weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['groupId'] = null;
      weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['groupType'] = null;
    });
  }

  // NEW: AI exercise suggestions
  Future<List<String>> getAISuggestions(String muscleGroup) async {
    // Check cache first
    if (aiSuggestionsCache.containsKey(muscleGroup)) {
      return aiSuggestionsCache[muscleGroup]!;
    }

    // Simulated AI suggestions based on muscle group
    final suggestions = <String>[];
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        suggestions.addAll(['Bench Press', 'Push-ups', 'Dumbbell Flyes', 'Incline Press', 'Decline Press']);
        break;
      case 'back':
        suggestions.addAll(['Pull-ups', 'Rows', 'Deadlifts', 'Lat Pulldowns', 'Face Pulls']);
        break;
      case 'legs':
        suggestions.addAll(['Squats', 'Deadlifts', 'Lunges', 'Leg Press', 'Calf Raises']);
        break;
      case 'shoulders':
        suggestions.addAll(['Overhead Press', 'Lateral Raises', 'Front Raises', 'Rear Delt Flyes']);
        break;
      case 'arms':
        suggestions.addAll(['Bicep Curls', 'Tricep Dips', 'Hammer Curls', 'Skull Crushers']);
        break;
      default:
        suggestions.addAll(['Exercise 1', 'Exercise 2', 'Exercise 3']);
    }

    // Cache the results
    aiSuggestionsCache[muscleGroup] = suggestions;
    return suggestions;
  }

  // NEW: Exercise history
  Future<List<Map<String, dynamic>>> getExerciseHistory(String exerciseName) async {
    if (clientId.isEmpty) return [];
    
    final cacheKey = '${clientId}_$exerciseName';
    if (exerciseHistoryCache.containsKey(cacheKey)) {
      return exerciseHistoryCache[cacheKey]!;
    }

    try {
      // Simulated exercise history - in real app, query workout_logs table
      final history = [
        {
          'date': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
          'weight': 135,
          'reps': 8,
          'notes': 'Felt strong today'
        },
        {
          'date': DateTime.now().subtract(Duration(days: 14)).toIso8601String(),
          'weight': 130,
          'reps': 10,
          'notes': 'Good form'
        },
        {
          'date': DateTime.now().subtract(Duration(days: 21)).toIso8601String(),
          'weight': 125,
          'reps': 12,
          'notes': 'Tired from previous workout'
        },
        {
          'date': DateTime.now().subtract(Duration(days: 28)).toIso8601String(),
          'weight': 120,
          'reps': 10,
          'notes': 'First time trying this weight'
        },
      ];
      
      exerciseHistoryCache[cacheKey] = history;
      return history;
    } catch (e) {
      return [];
    }
  }

  // NEW: Per-exercise media upload
  Future<void> uploadExerciseMedia(int weekIndex, int dayIndex, int exIndex) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileExt = file.path.split('.').last;
      final fileName = 'exercise_media_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'exercise_media/$fileName';

      try {
        await supabase.storage.from('vagus-media').upload(filePath, file);
        final url = supabase.storage.from('vagus-media').getPublicUrl(filePath);

        setState(() {
          weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['exerciseMedia'].add({
            'url': url,
            'type': _getFileType(fileExt),
            'name': file.path.split('/').last,
          });
        });
      } catch (e) {
        setState(() {
          message = '❌ Upload failed: $e';
        });
      }
    }
  }

  // NEW: Edit exercise note
  void _editExerciseNote(int weekIndex, int dayIndex, int exIndex) {
    final current = (weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['exerciseNote'] ?? '').toString();
    final controller = TextEditingController(text: current);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exercise Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Add a note for this exercise',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              updateExercise(weekIndex, dayIndex, exIndex, 'exerciseNote', controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // NEW: Show AI suggestions modal
  void _showAISuggestions(int weekIndex, int dayIndex, int exIndex) async {
    final currentExercise = weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['name'] ?? '';
    
    // Extract muscle group from current exercise name or prompt user
    String muscleGroup = 'general';
    if (currentExercise.isNotEmpty) {
      if (currentExercise.toLowerCase().contains('bench') || currentExercise.toLowerCase().contains('push')) {
        muscleGroup = 'chest';
      } else if (currentExercise.toLowerCase().contains('pull') || currentExercise.toLowerCase().contains('row')) {
        muscleGroup = 'back';
      } else if (currentExercise.toLowerCase().contains('squat') || currentExercise.toLowerCase().contains('leg')) {
        muscleGroup = 'legs';
      } else if (currentExercise.toLowerCase().contains('press') || currentExercise.toLowerCase().contains('shoulder')) {
        muscleGroup = 'shoulders';
      } else if (currentExercise.toLowerCase().contains('curl') || currentExercise.toLowerCase().contains('arm')) {
        muscleGroup = 'arms';
      }
    }

    final suggestions = await getAISuggestions(muscleGroup);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 AI Exercise Suggestions'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(suggestions[index]),
                onTap: () {
                  updateExercise(weekIndex, dayIndex, exIndex, 'name', suggestions[index]);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // NEW: Show exercise history modal
  void _showExerciseHistory(int weekIndex, int dayIndex, int exIndex) async {
    final exerciseName = weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['name'] ?? '';
    if (exerciseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please enter an exercise name first')),
      );
      return;
    }

    final history = await getExerciseHistory(exerciseName);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 History: $exerciseName'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Text('No history found for this exercise')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final session = history[index];
                    return ListTile(
                      title: Text('${session['weight']} lbs × ${session['reps']} reps'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(session['date']))}'),
                          if ((session['notes'] ?? '').isNotEmpty)
                            Text('Notes: ${session['notes']}'),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // NEW: Drag and drop reordering
  void _reorderExercises(int weekIndex, int dayIndex, int oldIndex, int newIndex) {
    setState(() {
      final exercises = weeks[weekIndex]['days'][dayIndex]['exercises'];
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
    });
  }

  void _reorderDays(int weekIndex, int oldIndex, int newIndex) {
    setState(() {
      final days = weeks[weekIndex]['days'];
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = days.removeAt(oldIndex);
      days.insert(newIndex, item);
    });
  }

  void _reorderWeeks(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = weeks.removeAt(oldIndex);
      weeks.insert(newIndex, item);
    });
  }

  // [tutorialLink] dialog to insert/update exercise tutorial link
  void _editTutorialLink(int weekIndex, int dayIndex, int exIndex) {
    final current = (weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex]['tutorialLink'] ?? '').toString();
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert Tutorial Link'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL (e.g., https://youtube.com/...)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = controller.text.trim();
              // removal: empty input removes just this key
              if (raw.isEmpty) {
                setState(() {
                  weeks[weekIndex]['days'][dayIndex]['exercises'][exIndex].remove('tutorialLink');
                });
                Navigator.pop(context);
                return;
              }

              final normalized = _normalizeTutorialUrl(raw);
              if (normalized == null) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('❌ Invalid URL. Please enter an http(s) link.')),
                );
                return; // keep dialog open
              }

              updateExercise(weekIndex, dayIndex, exIndex, 'tutorialLink', normalized);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // [tutorialLink] normalize and validate http(s) URL; convert youtu.be to watch?v=
  String? _normalizeTutorialUrl(String input) {
    var value = input.trim();
    // Prepend https:// if missing scheme
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    Uri? uri;
    try {
      uri = Uri.tryParse(value);
    } catch (_) {
      return null;
    }
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || (uri.host.isEmpty)) {
      return null;
    }
    // Convert youtu.be/<id>?t=.. to https://www.youtube.com/watch?v=<id>&t=..
    if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      final t = uri.queryParameters['t'];
      final qp = <String, String>{'v': id, if (t != null && t.isNotEmpty) 't': t};
      uri = Uri(
        scheme: uri.scheme,
        host: 'www.youtube.com',
        path: '/watch',
        queryParameters: qp,
      );
      return uri.toString();
    }
    return uri.toString();
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  String _getFileType(String ext) {
    final extLower = ext.toLowerCase();
    if (['png', 'jpg', 'jpeg', 'gif'].contains(extLower)) return 'image';
    if (['mp4', 'mov', 'webm'].contains(extLower)) return 'video';
    if (['mp3', 'wav', 'm4a'].contains(extLower)) return 'audio';
    if (extLower == 'pdf') return 'application/pdf';
    return 'file';
  }

  Future<void> uploadAttachment(int weekIndex, int dayIndex) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'coach_plans/$fileName';

      try {
        await supabase.storage.from('vagus-media').upload(filePath, file);
        final url = supabase.storage.from('vagus-media').getPublicUrl(filePath);

        setState(() {
          weeks[weekIndex]['days'][dayIndex]['attachments'].add({
            'url': url,
            'type': _getFileType(fileExt),
            'name': file.path.split('/').last,
            'pinned': false
          });
        });
      } catch (e) {
        setState(() {
          message = '❌ Upload failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalTonnage = 0;
    int totalWeeks = weeks.length;
    int totalDays = 0;
    int totalExercises = 0;

    for (var week in weeks) {
      for (var day in week['days']) {
        totalDays++;
        totalExercises += (day['exercises'] as List).length;
        for (var ex in day['exercises']) {
          totalTonnage += (ex['tonnage'] ?? 0).toDouble();
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Coach Plan Builder')),
      body: loadingClients
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            /// CLIENT
            DropdownButtonFormField<String>(
              value: clientId.isEmpty ? null : clientId,
              decoration: const InputDecoration(labelText: 'Select Client'),
              items: clients.map<DropdownMenuItem<String>>((c) {
                return DropdownMenuItem<String>(
                  value: c['id'] as String,
                  child: Text('${c['name'] ?? 'No Name'} (${c['email']})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => clientId = val ?? ''),
            ),
            const SizedBox(height: 12),

            /// PLAN INFO
            TextField(
              decoration: const InputDecoration(labelText: 'Plan Name'),
              onChanged: (val) => setState(() => planName = val),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: pickStartDate,
              child: AbsorbPointer(
                child: TextField(
                  controller: TextEditingController(
                    text: startDate == null ? '' : DateFormat('yyyy-MM-dd').format(startDate!),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: durationWeeks,
              decoration: const InputDecoration(labelText: 'Duration (weeks)'),
              items: List.generate(24, (i) => i + 1)
                  .map((w) => DropdownMenuItem<int>(
                value: w,
                child: Text('$w'),
              ))
                  .toList(),
              onChanged: (val) => setState(() => durationWeeks = val ?? 12),
            ),

            const SizedBox(height: 20),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '📊 Plan Summary → Weeks: $totalWeeks | Days: $totalDays | Exercises: $totalExercises | Tonnage: ${totalTonnage.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: addWeek,
              icon: const Icon(Icons.add),
              label: const Text('Add Week'),
            ),
            const SizedBox(height: 12),

            /// WEEKS UI - Enhanced with drag and drop
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weeks.length,
              onReorder: _reorderWeeks,
              itemBuilder: (context, weekIndex) {
                final week = weeks[weekIndex];

                return Card(
                  key: ValueKey('week_$weekIndex'),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.drag_handle, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('📅 Week ${weekIndex + 1}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => removeWeek(weekIndex),
                            )
                          ],
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          onPressed: () => addDay(weekIndex),
                          icon: const Icon(Icons.calendar_view_day),
                          label: const Text('Add Day'),
                        ),
                        const SizedBox(height: 10),

                        /// DAYS UI - Enhanced with drag and drop
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: week['days'].length,
                          onReorder: (oldIndex, newIndex) => _reorderDays(weekIndex, oldIndex, newIndex),
                          itemBuilder: (context, dayIndex) {
                            final day = week['days'][dayIndex];

                            double dayTonnage = 0;
                            int sets = 0;

                            for (var ex in day['exercises']) {
                              sets += (ex['sets'] as num).toInt();
                              dayTonnage += (ex['tonnage'] ?? 0).toDouble();
                            }

                            final intensity = dayTonnage < 2000
                                ? 'low'
                                : dayTonnage < 8000
                                ? 'moderate'
                                : 'high';

                            return Container(
                              key: ValueKey('day_${weekIndex}_$dayIndex'),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[50],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.drag_handle, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextField(
                                                  decoration: const InputDecoration(labelText: 'Day Label'),
                                                  onChanged: (val) => setState(() => day['label'] = val),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.orange),
                                          onPressed: () => removeDay(weekIndex, dayIndex),
                                        ),
                                      ],
                                    ),
                                    Text('💪 Total Sets: $sets | Tonnage: ${dayTonnage.toStringAsFixed(0)} | Intensity: $intensity'),
                                    const Divider(),

                                    // NEW: Combo Set controls
                                    if (selectedExercises['${weekIndex}_$dayIndex']?.isNotEmpty == true)
                                      Card(
                                        color: Colors.blue[50],
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            children: [
                                              Text('Selected: ${selectedExercises['${weekIndex}_$dayIndex']!.length} exercises'),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () => createSupersetOrCircuit(weekIndex, dayIndex, 'superset'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.purple[100],
                                                      foregroundColor: Colors.purple[900],
                                                    ),
                                                    child: const Text('Superset'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => createSupersetOrCircuit(weekIndex, dayIndex, 'circuit'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.orange[100],
                                                      foregroundColor: Colors.orange[900],
                                                    ),
                                                    child: const Text('Circuit'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => createSupersetOrCircuit(weekIndex, dayIndex, 'drop_set'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red[100],
                                                      foregroundColor: Colors.red[900],
                                                    ),
                                                    child: const Text('Drop Set'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => createSupersetOrCircuit(weekIndex, dayIndex, 'giant_set'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green[100],
                                                      foregroundColor: Colors.green[900],
                                                    ),
                                                    child: const Text('Giant Set'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => createSupersetOrCircuit(weekIndex, dayIndex, 'top_set'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.blue[100],
                                                      foregroundColor: Colors.blue[900],
                                                    ),
                                                    child: const Text('Top Set'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => createSupersetOrCircuit(weekIndex, dayIndex, 'back_off_set'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.indigo[100],
                                                      foregroundColor: Colors.indigo[900],
                                                    ),
                                                    child: const Text('Back-off Set'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => createSupersetOrCircuit(weekIndex, dayIndex, 'pyramid_set'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.teal[100],
                                                      foregroundColor: Colors.teal[900],
                                                    ),
                                                    child: const Text('Pyramid Set'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    /// EXERCISES - Enhanced with all new features
                                    ReorderableListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: day['exercises'].length,
                                      onReorder: (oldIndex, newIndex) => _reorderExercises(weekIndex, dayIndex, oldIndex, newIndex),
                                      itemBuilder: (context, exIndex) {
                                        final ex = day['exercises'][exIndex];
                                        final isSelected = selectedExercises['${weekIndex}_$dayIndex']?.contains(exIndex) == true;
                                        final groupId = ex['groupId'];
                                        final groupType = ex['groupType'];

                                        return Card(
                                          key: ValueKey('exercise_${weekIndex}_${dayIndex}_$exIndex'),
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          color: groupId != null ? _getGroupTypeColor(groupType) : null,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              children: [
                                                // Group header if part of combo set
                                                if (groupId != null)
                                                  Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: _getGroupHeaderColor(groupType),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          _getGroupTypeIcon(groupType),
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          _getGroupTypeDisplayName(groupType),
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                        ),
                                                        const Spacer(),
                                                        IconButton(
                                                          icon: const Icon(Icons.close, size: 16),
                                                          onPressed: () => removeFromGroup(weekIndex, dayIndex, exIndex),
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                
                                                Row(
                                                  children: [
                                                    const Icon(Icons.drag_handle, color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextField(
                                                              decoration: const InputDecoration(labelText: 'Exercise Name'),
                                                              onChanged: (val) => updateExercise(weekIndex, dayIndex, exIndex, 'name', val),
                                                            ),
                                                          ),
                                                          // NEW: AI suggestions button
                                                          IconButton(
                                                            tooltip: 'AI Suggestions',
                                                            icon: const Icon(Icons.auto_awesome),
                                                            onPressed: () => _showAISuggestions(weekIndex, dayIndex, exIndex),
                                                          ),
                                                          // NEW: Exercise history button
                                                          IconButton(
                                                            tooltip: 'Exercise History',
                                                            icon: const Icon(Icons.history),
                                                            onPressed: () => _showExerciseHistory(weekIndex, dayIndex, exIndex),
                                                          ),
                                                          // NEW: Exercise note button
                                                          IconButton(
                                                            tooltip: 'Exercise Note',
                                                            icon: const Icon(Icons.note),
                                                            onPressed: () => _editExerciseNote(weekIndex, dayIndex, exIndex),
                                                          ),
                                                          // NEW: Superset/Circuit selection checkbox
                                                          Checkbox(
                                                            value: isSelected,
                                                            onChanged: (value) => toggleExerciseSelection(weekIndex, dayIndex, exIndex),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: TextField(
                                                        decoration: const InputDecoration(labelText: 'Sets'),
                                                        keyboardType: TextInputType.number,
                                                        onChanged: (val) => updateExercise(weekIndex, dayIndex, exIndex, 'sets', int.tryParse(val) ?? 0),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: TextField(
                                                        decoration: const InputDecoration(labelText: 'Reps'),
                                                        keyboardType: TextInputType.number,
                                                        onChanged: (val) => updateExercise(weekIndex, dayIndex, exIndex, 'reps', int.tryParse(val) ?? 0),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: TextField(
                                                        decoration: const InputDecoration(labelText: 'Weight (lbs)'),
                                                        keyboardType: TextInputType.number,
                                                        onChanged: (val) => updateExercise(weekIndex, dayIndex, exIndex, 'weight', double.tryParse(val) ?? 0),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: TextField(
                                                        decoration: const InputDecoration(labelText: '%1RM'),
                                                        keyboardType: TextInputType.number,
                                                        onChanged: (val) => updateExercise(weekIndex, dayIndex, exIndex, 'percent1RM', double.tryParse(val) ?? 0),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: TextField(
                                                        decoration: const InputDecoration(labelText: 'RIR'),
                                                        keyboardType: TextInputType.number,
                                                        onChanged: (val) => updateExercise(weekIndex, dayIndex, exIndex, 'RIR', double.tryParse(val) ?? 0),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: TextField(
                                                        decoration: const InputDecoration(labelText: 'Rest'),
                                                        onChanged: (val) => updateExercise(weekIndex, dayIndex, exIndex, 'rest', val),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                
                                                TextField(
                                                  decoration: const InputDecoration(labelText: 'Notes'),
                                                  style: const TextStyle(color: Colors.black),
                                                  cursorColor: Colors.deepPurple,
                                                  onChanged: (val) => updateExercise(weekIndex, dayIndex, exIndex, 'notes', val),
                                                ),
                                                
                                                // NEW: Display calculated values
                                                Row(
                                                  children: [
                                                    Text('🏋️ Tonnage: ${ex['tonnage'].toStringAsFixed(2)}'),
                                                    const SizedBox(width: 16),
                                                    if (ex['percent1RM'] > 0)
                                                      Text('📊 %1RM: ${ex['percent1RM'].toStringAsFixed(1)}%'),
                                                    const SizedBox(width: 16),
                                                    if (ex['RIR'] > 0)
                                                      Text('💪 RIR: ${ex['RIR'].toStringAsFixed(1)}'),
                                                  ],
                                                ),
                                                
                                                // NEW: Display exercise note if exists
                                                if ((ex['exerciseNote'] ?? '').isNotEmpty)
                                                  Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.all(8),
                                                    margin: const EdgeInsets.only(top: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.yellow[50],
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.yellow[200]!),
                                                    ),
                                                    child: Text(
                                                      '📝 ${ex['exerciseNote']}',
                                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                                    ),
                                                  ),
                                                
                                                // NEW: Display exercise media if exists
                                                if ((ex['exerciseMedia'] as List).isNotEmpty)
                                                  Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.all(8),
                                                    margin: const EdgeInsets.only(top: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[50],
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('📎 Exercise Media:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                        ...(ex['exerciseMedia'] as List).map((media) => ListTile(
                                                          leading: Icon(
                                                            media['type'].toString().startsWith('image')
                                                                ? Icons.image
                                                                : media['type'].toString().startsWith('video')
                                                                ? Icons.videocam
                                                                : Icons.insert_drive_file,
                                                          ),
                                                          title: Text(media['name'] ?? ''),
                                                          trailing: IconButton(
                                                            icon: const Icon(Icons.delete),
                                                            onPressed: () => setState(() => ex['exerciseMedia'].remove(media)),
                                                          ),
                                                        )),
                                                      ],
                                                    ),
                                                  ),
                                                
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    // NEW: Exercise media upload button
                                                    IconButton(
                                                      tooltip: 'Upload Exercise Media',
                                                      icon: const Icon(Icons.attach_file),
                                                      onPressed: () => uploadExerciseMedia(weekIndex, dayIndex, exIndex),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Insert Tutorial Link',
                                                      icon: const Icon(Icons.ondemand_video),
                                                      onPressed: () => _editTutorialLink(weekIndex, dayIndex, exIndex),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () => removeExercise(weekIndex, dayIndex, exIndex),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    /// Add EX
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () => addExercise(weekIndex, dayIndex),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Exercise'),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    /// CARDIO SECTION
                                    const Divider(),
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_run, color: Colors.green),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Cardio',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    /// Cardio entries
                                    ReorderableListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: (day['cardio'] as List).length,
                                      onReorder: (oldIndex, newIndex) => _reorderCardio(weekIndex, dayIndex, oldIndex, newIndex),
                                      itemBuilder: (context, cardioIndex) {
                                        final cardio = day['cardio'][cardioIndex];
                                        final machineType = cardio['machineType'] ?? 'Treadmill';
                                        final settings = cardio['settings'] ?? {};
                                        final instructions = cardio['instructions'] ?? '';

                                        return Card(
                                          key: ValueKey('cardio_${weekIndex}_${dayIndex}_$cardioIndex'),
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          color: Colors.green[50],
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.drag_handle, color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: DropdownButtonFormField<String>(
                                                        value: machineType,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Cardio Machine',
                                                          border: OutlineInputBorder(),
                                                        ),
                                                        items: cardioMachineTypes.map<DropdownMenuItem<String>>((type) {
                                                          return DropdownMenuItem<String>(
                                                            value: type,
                                                            child: Text(type),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          if (value != null) {
                                                            updateCardio(weekIndex, dayIndex, cardioIndex, 'machineType', value);
                                                            // Clear old settings when machine type changes
                                                            updateCardio(weekIndex, dayIndex, cardioIndex, 'settings', {});
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),

                                                // Machine-specific settings
                                                ..._getCardioMachineSettings(machineType).map((setting) {
                                                  final key = setting['key'] as String;
                                                  final label = setting['label'] as String;
                                                  final type = setting['type'] as String;
                                                  final value = settings[key]?.toString() ?? '';

                                                  if (type == 'text') {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 8),
                                                      child: TextField(
                                                        decoration: InputDecoration(
                                                          labelText: label,
                                                          border: const OutlineInputBorder(),
                                                        ),
                                                        onChanged: (val) => updateCardioSetting(weekIndex, dayIndex, cardioIndex, key, val),
                                                      ),
                                                    );
                                                  } else {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 8),
                                                      child: TextField(
                                                        decoration: InputDecoration(
                                                          labelText: label,
                                                          border: const OutlineInputBorder(),
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                        onChanged: (val) {
                                                          final numValue = double.tryParse(val);
                                                          if (numValue != null) {
                                                            updateCardioSetting(weekIndex, dayIndex, cardioIndex, key, numValue);
                                                          }
                                                        },
                                                      ),
                                                    );
                                                  }
                                                }).toList(),

                                                // Coach instructions
                                                TextField(
                                                  decoration: const InputDecoration(
                                                    labelText: 'Coach Instructions',
                                                    border: OutlineInputBorder(),
                                                    hintText: 'e.g., Maintain HR 130-140 bpm',
                                                  ),
                                                  maxLines: 2,
                                                  onChanged: (val) => updateCardio(weekIndex, dayIndex, cardioIndex, 'instructions', val),
                                                ),

                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Duplicate Cardio',
                                                      icon: const Icon(Icons.copy),
                                                      onPressed: () => duplicateCardio(weekIndex, dayIndex, cardioIndex),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () => removeCardio(weekIndex, dayIndex, cardioIndex),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    /// Add Cardio
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () => addCardio(weekIndex, dayIndex),
                                        icon: const Icon(Icons.add, color: Colors.green),
                                        label: const Text('Add Cardio', style: TextStyle(color: Colors.green)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[50],
                                          side: BorderSide(color: Colors.green[300]!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    /// Attachments
                                    ElevatedButton.icon(
                                      onPressed: () => uploadAttachment(weekIndex, dayIndex),
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Upload File'),
                                    ),
                                    const SizedBox(height: 6),
                                    ...List<Map<String, dynamic>>.from(day['attachments']).asMap().entries.map((entry) {
                                      final file = entry.value;
                                      return ListTile(
                                        title: Text(file['name'] ?? ''),
                                        subtitle: Text(file['type']),
                                        leading: Icon(
                                          file['type'].toString().startsWith('image')
                                              ? Icons.image
                                              : file['type'].toString().startsWith('video')
                                              ? Icons.videocam
                                              : file['type'].toString().startsWith('audio')
                                              ? Icons.audiotrack
                                              : Icons.insert_drive_file,
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => setState(() => day['attachments'].remove(file)),
                                        ),
                                      );
                                    }),

                                    const SizedBox(height: 10),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Client Comment',
                                        border: OutlineInputBorder(),
                                      ),
                                      style: const TextStyle(color: Colors.black),
                                      cursorColor: Colors.deepPurple,
                                      maxLines: 2,
                                      onChanged: (val) => setState(() => day['clientComment'] = val),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saving ? null : savePlan,
                icon: saving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  saving ? 'Saving...' : 'Save Plan to Supabase',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: saving ? Colors.grey : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> savePlan() async {
    if (clientId.isEmpty || planName.isEmpty || startDate == null || durationWeeks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ All fields are required!')),
      );
      return;
    }

    // NEW: Validate cardio entries
    for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      for (int dayIndex = 0; dayIndex < weeks[weekIndex]['days'].length; dayIndex++) {
        final day = weeks[weekIndex]['days'][dayIndex];
        final cardio = day['cardio'] as List;
        
        for (int cardioIndex = 0; cardioIndex < cardio.length; cardioIndex++) {
          final cardioEntry = cardio[cardioIndex];
          final machineType = cardioEntry['machineType'] ?? '';
          final settings = cardioEntry['settings'] ?? {};
          
          if (machineType.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Please select a cardio machine for entry ${cardioIndex + 1} in Week ${weekIndex + 1}, Day ${dayIndex + 1}')),
            );
            return;
          }
          
          // Check if duration is set (required for all machines)
          if (settings['duration'] == null || settings['duration'] <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Please set duration for ${machineType} in Week ${weekIndex + 1}, Day ${dayIndex + 1}')),
            );
            return;
          }
        }
      }
    }

    setState(() {
      saving = true;
      message = '';
    });

    try {
      final user = supabase.auth.currentUser;
      await supabase.from('workout_plans').insert({
        'client_id': clientId,
        'created_by': user!.id,
        'name': planName,
        'start_date': startDate!.toIso8601String(),
        'duration_weeks': durationWeeks,
        'weeks': weeks,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showSavedConfirmationModal(); // ✅ confirmation wedge
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save: $e')),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  void _showSavedConfirmationModal() {
    final client = clients.firstWhere((c) => c['id'] == clientId, orElse: () => {'name': 'Unknown'});
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 Plan Saved Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧍 Client: ${client['name']}'),
            Text('📋 Plan: $planName'),
            Text('📆 Duration: $durationWeeks weeks'),
            Text('🏁 Starts: ${DateFormat('yyyy-MM-dd').format(startDate!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close modal
              setState(() {
                // Reset form for new plan
                weeks = [];
                planName = '';
                clientId = '';
                startDate = null;
                durationWeeks = 12;
              });
            },
            child: const Text('✅ OK – Add New Plan'),
          )
        ],
      ),
    );
  }
}
