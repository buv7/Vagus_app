import 'package:flutter/material.dart';
import '../../models/workout/fatigue_models.dart';

class SessionModeSelector extends StatelessWidget {
  final TransformationMode value;
  final ValueChanged<TransformationMode> onChanged;

  const SessionModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.tune),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Session Mode',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            DropdownButton<TransformationMode>(
              value: value,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: TransformationMode.values.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m.label()),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
