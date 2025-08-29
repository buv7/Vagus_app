import 'package:flutter/material.dart';

class ExerciseSearchFilterSheet extends StatefulWidget {
  const ExerciseSearchFilterSheet({super.key});

  @override
  State<ExerciseSearchFilterSheet> createState() => _ExerciseSearchFilterSheetState();
}

class _ExerciseSearchFilterSheetState extends State<ExerciseSearchFilterSheet> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _muscleFilters = {};
  final Set<String> _equipmentFilters = {};
  final Set<String> _tagFilters = {};
  final Set<String> _favorites = {};

  final List<String> _catalog = const [
    'Bench Press', 'Incline Bench Press', 'Dumbbell Flyes', 'Push-ups',
    'Back Squat', 'Front Squat', 'Deadlift', 'Romanian Deadlift', 'Lunge', 'Leg Press', 'Calf Raise',
    'Overhead Press', 'Lateral Raise', 'Rear Delt Fly', 'Barbell Row', 'Dumbbell Row', 'Pull-up', 'Chin-up', 'Lat Pulldown',
    'Bicep Curl', 'Hammer Curl', 'Tricep Dip', 'Tricep Extension', 'Plank', 'Crunch',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Iterable<String> _deriveMuscles(String name) {
    final n = name.toLowerCase();
    final s = <String>{};
    if (n.contains('bench') || n.contains('push')) s.addAll(['Chest', 'Triceps']);
    if (n.contains('squat') || n.contains('lunge') || n.contains('leg')) s.addAll(['Quads', 'Glutes']);
    if (n.contains('deadlift') || n.contains('row') || n.contains('pull')) s.addAll(['Back', 'Biceps']);
    if (n.contains('press') || n.contains('raise') || n.contains('ohp')) s.add('Shoulders');
    if (n.contains('calf')) s.add('Calves');
    if (n.contains('plank') || n.contains('crunch')) s.add('Core');
    return s;
  }

  Iterable<String> _deriveEquipment(String name) {
    final n = name.toLowerCase();
    if (n.contains('dumbbell')) return const ['Dumbbell'];
    if (n.contains('barbell')) return const ['Barbell'];
    if (n.contains('machine') || n.contains('pulldown') || n.contains('press')) return const ['Machine'];
    if (n.contains('push-up') || n.contains('push up') || n.contains('pull-up') || n.contains('pull up') || n.contains('plank') || n.contains('crunch')) {
      return const ['Bodyweight'];
    }
    return const [];
  }

  List<String> _filtered() {
    final q = _search.text.trim().toLowerCase();
    return _catalog.where((name) {
      if (q.isNotEmpty && !name.toLowerCase().contains(q)) return false;
      if (_muscleFilters.isNotEmpty && _muscleFilters.intersection(_deriveMuscles(name).toSet()).isEmpty) {
        return false;
      }
      if (_equipmentFilters.isNotEmpty && _equipmentFilters.intersection(_deriveEquipment(name).toSet()).isEmpty) {
        return false;
      }
      if (_tagFilters.isNotEmpty) {
        // No explicit tags in catalog; simulate by reusing muscles as tags
        if (_tagFilters.intersection(_deriveMuscles(name).toSet()).isEmpty) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final muscles = const ['Chest', 'Back', 'Quads', 'Glutes', 'Hamstrings', 'Shoulders', 'Biceps', 'Triceps', 'Calves', 'Core'];
    final equipment = const ['Barbell', 'Dumbbell', 'Machine', 'Bodyweight'];

    final results = _filtered();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Filter Exercises', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search by name',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            const Text('Muscles'),
            Wrap(
              spacing: 8,
              children: muscles.map((m) => FilterChip(
                label: Text(m),
                selected: _muscleFilters.contains(m),
                onSelected: (s) => setState(() {
                  if (s) {
                    _muscleFilters.add(m);
                  } else {
                    _muscleFilters.remove(m);
                  }
                }),
              )).toList(),
            ),
            const SizedBox(height: 8),
            const Text('Equipment'),
            Wrap(
              spacing: 8,
              children: equipment.map((e) => FilterChip(
                label: Text(e),
                selected: _equipmentFilters.contains(e),
                onSelected: (s) => setState(() {
                  if (s) {
                    _equipmentFilters.add(e);
                  } else {
                    _equipmentFilters.remove(e);
                  }
                }),
              )).toList(),
            ),
            const SizedBox(height: 8),
            const Text('Results'),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final name = results[i];
                  final fav = _favorites.contains(name);
                  return ListTile(
                    title: Text(name),
                    subtitle: Text([
                      ..._deriveMuscles(name),
                      ..._deriveEquipment(name),
                    ].join(' • ')),
                    trailing: IconButton(
                      icon: Icon(fav ? Icons.star : Icons.star_border),
                      color: fav ? Colors.amber : null,
                      onPressed: () => setState(() {
                        if (fav) {
                          _favorites.remove(name);
                        } else {
                          _favorites.add(name);
                        }
                      }),
                    ),
                    onTap: () => Navigator.pop(context, name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


