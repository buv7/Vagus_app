import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ai/transcription_ai.dart';
import 'package:uuid/uuid.dart';

class VoiceRecorder extends StatefulWidget {
  final void Function(String transcribedText) onTranscription;
  final String? noteId;
  final String? clientId;

  const VoiceRecorder({
    super.key, 
    required this.onTranscription,
    this.noteId,
    this.clientId,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final TranscriptionAI _transcriptionAI = TranscriptionAI();
  final Uuid _uuid = const Uuid();
  bool _isProcessing = false;

  Future<void> _recordAndTranscribe(BuildContext context) async {
    try {
      setState(() => _isProcessing = true);

      // Pick audio file (simulating recording for now)
      final picker = ImagePicker();
      final audio = await picker.pickVideo(source: ImageSource.gallery); // TODO: Change to audio picker

      if (audio == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Show processing indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing audio...')),
        );
      }

      // Upload to Supabase Storage
      if (kDebugMode) {
        debugPrint('VoiceRecorder: Starting audio upload...');
      }
      final storagePath = await _uploadAudioToStorage(audio);
      if (kDebugMode) {
        debugPrint('VoiceRecorder: Upload successful - path: $storagePath');
      }
      
      // Transcribe using AI service
      if (kDebugMode) {
        debugPrint('VoiceRecorder: Starting transcription...');
      }
      final transcribedText = await _transcriptionAI.transcribeAudio(
        storagePath: storagePath,
        languageHint: 'en', // Default to English
      );
      if (kDebugMode) {
        debugPrint('VoiceRecorder: Transcription successful - length: ${transcribedText.length} chars');
      }

      // Insert transcribed text into note
      widget.onTranscription(transcribedText);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Transcribed: ${transcribedText.length} characters'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('VoiceRecorder: Error - $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Transcription failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<String> _uploadAudioToStorage(XFile audioFile) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileExt = audioFile.path.split('.').last;
    final fileName = '${_uuid.v4()}.$fileExt';
    
    // Create storage path: notes/{userId}/{noteId}/audio/{timestamp}.{ext}
    final noteId = widget.noteId ?? 'temp';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'notes/${user.id}/$noteId/audio/${timestamp}_$fileName';

    try {
      // Upload file to storage
      await supabase.storage
          .from('vagus-media')
          .upload(storagePath, File(audioFile.path));

      return storagePath;
    } catch (e) {
      throw Exception('Failed to upload audio file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _isProcessing 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.mic),
      label: Text(_isProcessing ? 'Processing...' : 'Record Voice'),
      onPressed: _isProcessing ? null : () => _recordAndTranscribe(context),
    );
  }
}
