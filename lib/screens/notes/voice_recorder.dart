import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VoiceRecorder extends StatelessWidget {
  final void Function(String transcribedText) onTranscription;

  const VoiceRecorder({super.key, required this.onTranscription});

  Future<void> _simulateTranscription(BuildContext context) async {
    // 📸 Simulate picking an audio file (later we'll do real mic recording)
    final picker = ImagePicker();
    final audio = await picker.pickVideo(source: ImageSource.gallery); // change later to audio

    if (audio == null) return;

    // 🧠 TODO: Upload audio to OpenRouter and transcribe
    await Future.delayed(const Duration(seconds: 2));

    // Simulated result:
    const simulatedText = "This is a simulated transcription result.";
    onTranscription(simulatedText);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voice transcribed and added.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.mic),
      label: const Text("Record Voice"),
      onPressed: () => _simulateTranscription(context),
    );
  }
}
