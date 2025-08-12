import 'package:flutter/material.dart';
import 'dart:io';

class VoiceRecorder extends StatefulWidget {
  final Function(File audioFile) onVoiceRecorded;

  const VoiceRecorder({
    super.key,
    required this.onVoiceRecorded,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  bool _isRecording = false;
  int _recordingDuration = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Voice Message',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isRecording) ...[
                _buildRecordButton(),
                _buildPickAudioButton(),
              ] else ...[
                _buildStopButton(),
                _buildDurationDisplay(),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _startRecording,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.mic, color: Colors.red[700], size: 28),
          ),
          const SizedBox(height: 8),
          const Text(
            'Record',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPickAudioButton() {
    return GestureDetector(
      onTap: _pickAudioFile,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.audio_file, color: Colors.blue[700], size: 28),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick Audio',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: _stopRecording,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.stop, color: Colors.grey[700], size: 28),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stop',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationDisplay() {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Recording',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    // Simulate recording duration
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration++;
        });
        _startRecording();
      }
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });

    // For now, we'll simulate creating an audio file
    // In a real implementation, you'd save the actual recorded audio
    _simulateAudioFile();
  }

  void _pickAudioFile() async {
    // This would typically use file_picker to select an audio file
    // For now, we'll simulate it
    _simulateAudioFile();
  }

  void _simulateAudioFile() {
    // Simulate creating an audio file
    // In a real implementation, this would be the actual recorded audio file
    final tempFile = File('/tmp/simulated_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
    
    widget.onVoiceRecorded(tempFile);
    Navigator.pop(context);
  }
}
