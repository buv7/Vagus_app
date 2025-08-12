import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NoteReminderSetter extends StatelessWidget {
  final DateTime? initialDate;
  final void Function(DateTime date) onSet;

  const NoteReminderSetter({
    super.key,
    required this.initialDate,
    required this.onSet,
  });

  void _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selected != null) {
      onSet(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = initialDate != null
        ? DateFormat.yMMMMd().format(initialDate!)
        : 'None';

    return Row(
      children: [
        const Icon(Icons.notifications),
        const SizedBox(width: 8),
        const Text("Reminder:"),
        const SizedBox(width: 8),
        Text(formatted, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton(
          onPressed: () => _pickDate(context),
          child: const Text("Set Date"),
        )
      ],
    );
  }
}
