import 'package:flutter/material.dart';

class ExerciseEntryBlock extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final Function(List<Map<String, dynamic>>) onExercisesUpdated;

  const ExerciseEntryBlock({
    super.key,
    required this.exercises,
    required this.onExercisesUpdated,
  });

  @override
  State<ExerciseEntryBlock> createState() => _ExerciseEntryBlockState();
}

class _ExerciseEntryBlockState extends State<ExerciseEntryBlock> {
  List<Map<String, dynamic>> _localExercises = [];

  @override
  void initState() {
    super.initState();
    _localExercises = List.from(widget.exercises);
  }

  void _addExercise() {
    setState(() {
      _localExercises.add({
        'name': '',
        'sets': 3,
        'reps': 10,
        'rest': '60s',
        'notes': '',
        'percent1RM': 70,
        'tonnage': 0,
      });
    });
    widget.onExercisesUpdated(_localExercises);
  }

  void _removeExercise(int index) {
    setState(() {
      _localExercises.removeAt(index);
    });
    widget.onExercisesUpdated(_localExercises);
  }

  void _updateField(int index, String key, dynamic value) {
    setState(() {
      _localExercises[index][key] = value;
      // auto-calculate tonnage
      final sets = _localExercises[index]['sets'];
      final reps = _localExercises[index]['reps'];
      final weight = _localExercises[index]['percent1RM'];
      _localExercises[index]['tonnage'] = (sets * reps * weight).toInt();
    });
    widget.onExercisesUpdated(_localExercises);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _localExercises.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Exercise Name'),
                    onChanged: (val) => _updateField(i, 'name', val),
                    controller: TextEditingController(text: _localExercises[i]['name']),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Sets'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              _updateField(i, 'sets', int.tryParse(val) ?? 0),
                          controller: TextEditingController(
                              text: _localExercises[i]['sets'].toString()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Reps'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              _updateField(i, 'reps', int.tryParse(val) ?? 0),
                          controller: TextEditingController(
                              text: _localExercises[i]['reps'].toString()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: '%1RM'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              _updateField(i, 'percent1RM', int.tryParse(val) ?? 0),
                          controller: TextEditingController(
                              text: _localExercises[i]['percent1RM'].toString()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Rest (e.g., 90s)'),
                    onChanged: (val) => _updateField(i, 'rest', val),
                    controller: TextEditingController(text: _localExercises[i]['rest']),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Notes (e.g., RIR 2)'),
                    onChanged: (val) => _updateField(i, 'notes', val),
                    controller: TextEditingController(text: _localExercises[i]['notes']),
                  ),
                  const SizedBox(height: 4),
                  Text('Tonnage: ${_localExercises[i]['tonnage']}'),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeExercise(i),
                    ),
                  )
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _addExercise,
          icon: const Icon(Icons.add),
          label: const Text('Add Exercise'),
        )
      ],
    );
  }
}
