import 'package:flutter/material.dart';

class SmartPanel extends StatelessWidget {
  final TextEditingController noteController;

  const SmartPanel({super.key, required this.noteController});

  void _runAction(BuildContext context, String type) async {
    final currentText = noteController.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note is empty.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Running AI: $type... (simulated)")),
    );

    await Future.delayed(const Duration(seconds: 2));

    switch (type) {
      case 'Improve':
        noteController.text = "🧠 [Improved] $currentText";
        break;
      case 'Summarize':
        noteController.text += "\n\n• Summary: [Simulated bullet summary]";
        break;
      case 'Tags':
        noteController.text += "\n\n🏷 Tags: mindset, recovery";
        break;
      case 'Rewrite Tone':
        noteController.text = "[Friendly Tone]: $currentText";
        break;
      case 'Follow-Up':
        noteController.text += "\n\n📌 Follow-up: Discuss client mindset tomorrow";
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          onPressed: () => _runAction(context, 'Improve'),
          child: const Text("✨ Improve"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Summarize'),
          child: const Text("📄 Summarize"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Tags'),
          child: const Text("🏷 Smart Tags"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Rewrite Tone'),
          child: const Text("🎭 Rewrite Tone"),
        ),
        ElevatedButton(
          onPressed: () => _runAction(context, 'Follow-Up'),
          child: const Text("📌 Follow-Up Suggestion"),
        ),
      ],
    );
  }
}
