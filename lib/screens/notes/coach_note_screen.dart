import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/branding/vagus_appbar.dart';
import 'note_reminder_setter.dart';
import 'smart_panel.dart';
// Note version viewer restored in Phase 2
import 'note_version_viewer.dart';
import 'voice_recorder.dart';
import '../../widgets/files/attach_to_note_button.dart';
import '../../services/ai/embedding_helper.dart';

class CoachNoteScreen extends StatefulWidget {
  final Map<String, dynamic>? existingNote;
  final String? clientId;

  const CoachNoteScreen({super.key, this.existingNote, this.clientId});

  @override
  State<CoachNoteScreen> createState() => _CoachNoteScreenState();
}

class _CoachNoteScreenState extends State<CoachNoteScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  DateTime? _reminderDate;
  List<Map<String, dynamic>> _attachments = [];
  List<String> _tags = [];
  Map<String, List<String>> _linkedPlanIds = {};
  bool _saving = false;
  int _currentVersion = 1;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!['title'] ?? '';
      _bodyController.text = widget.existingNote!['body'] ?? widget.existingNote!['note_text'] ?? '';
      if (widget.existingNote!['reminder_at'] != null) {
        _reminderDate = DateTime.tryParse(widget.existingNote!['reminder_at']);
      }
      final tags = (widget.existingNote!['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList();
      _tags = tags;
      final linkedPlans = widget.existingNote!['linked_plan_ids'] as Map<String, dynamic>? ?? {};
      _linkedPlanIds = linkedPlans.map((key, value) => MapEntry(
        key, 
        (value as List<dynamic>? ?? []).map((id) => id.toString()).toList()
      ));
      final attachments = widget.existingNote!['attachments'] as List<dynamic>? ?? [];
      _attachments = attachments.map((att) => Map<String, dynamic>.from(att)).toList();
      _currentVersion = widget.existingNote!['version'] ?? 1;
    }
  }

  Future<void> _saveNote() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note body is required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final data = {
        'coach_id': user.id,
        'client_id': widget.clientId,
        'title': title,
        'body': body,
        'tags': _tags,
        'linked_plan_ids': _linkedPlanIds,
        'reminder_at': _reminderDate?.toIso8601String(),
        'attachments': _attachments,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': user.id,
      };

      String noteId;
      if (widget.existingNote != null) {
        // Save current version before updating
        await _saveVersionSnapshot();
        
        // Increment version
        data['version'] = _currentVersion + 1;
        
        await supabase.from('coach_notes').update(data).eq('id', widget.existingNote!['id']);
        noteId = widget.existingNote!['id'];
        _currentVersion++;
      } else {
        final result = await supabase.from('coach_notes').insert(data).select('id').single();
        noteId = result['id'];
      }

      // Asynchronously update embedding (don't block the save)
      _updateNoteEmbedding(noteId, '$title $body');

      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Note saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to save note: $e')),
        );
      }
    }
  }

  Future<void> _saveVersionSnapshot() async {
    if (widget.existingNote == null) return;
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('coach_note_versions').insert({
        'note_id': widget.existingNote!['id'],
        'version_index': _currentVersion,
        'content': _bodyController.text.trim(),
        'metadata': {
          'title': _titleController.text.trim(),
          'tags': _tags,
          'linked_plan_ids': _linkedPlanIds,
          'attachments_summary': _getAttachmentsSummary(),
        },
        'created_by': user.id,
      });
    } catch (e) {
      // Log error but don't fail the save operation
      debugPrint('Failed to save version snapshot: $e');
    }
  }

  String _getAttachmentsSummary() {
    if (_attachments.isEmpty) return 'No attachments';
    return '${_attachments.length} attachment${_attachments.length == 1 ? '' : 's'}';
  }

  void _updateNoteEmbedding(String noteId, String content) {
    // Asynchronously update embedding without blocking the UI
    EmbeddingHelper().upsertNoteEmbedding(noteId, content).catchError((e) {
      // Silent failure - don't crash the app
      debugPrint('Failed to update note embedding: $e');
    });
  }

  void _openVersionHistory() {
    // Note version viewer restored in Phase 2
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteVersionViewer(
          noteId: widget.existingNote!['id'],
          noteTitle: widget.existingNote!['title'] ?? 'Untitled Note',
        ),
      ),
    );
  }

  void _pickReminder() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return NoteReminderSetter(
          initialDate: _reminderDate,
          onSet: (date) {
            setState(() => _reminderDate = date);
            Navigator.pop(context);
          },
        );
      },
    );
  }



  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VagusAppBar(
        title: Text(widget.existingNote == null ? 'New Note' : 'Edit Note'),
        actions: [
          if (widget.existingNote != null && _currentVersion > 1)
            TextButton.icon(
              onPressed: () => _openVersionHistory(),
              icon: const Icon(Icons.history, size: 16),
              label: Text('v$_currentVersion'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _saveNote,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Note title (optional)',
                border: OutlineInputBorder(),
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16),
            
            // Body field
            Expanded(
              child: TextField(
                controller: _bodyController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your note...',
                  border: OutlineInputBorder(),
                  labelText: 'Note',
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Tags section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: 'Add a tag...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTag,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _tags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                    )).toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // Smart panel
            SmartPanel(
              noteController: _bodyController,
              clientId: widget.clientId,
            ),
            const SizedBox(height: 12),
            
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.alarm),
                  label: const Text('Set Reminder'),
                ),
                VoiceRecorder(
                  onTranscription: (transcribedText) {
                    // Append to current cursor position in body
                    final currentText = _bodyController.text;
                    final selection = _bodyController.selection;
                    final newText = currentText.replaceRange(
                      selection.start,
                      selection.end,
                      transcribedText,
                    );
                    _bodyController.text = newText;
                    // Move cursor to end of inserted text
                    _bodyController.selection = TextSelection.collapsed(
                      offset: selection.start + transcribedText.length,
                    );
                  },
                  noteId: widget.existingNote?['id'],
                  clientId: widget.clientId,
                ),
              ],
            ),
            
            // Attachments section
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AttachToNoteButton(
                onFilesAttached: (attachments) {
                  setState(() {
                    _attachments = attachments;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File attached to note')),
                  );
                },
                existingAttachments: _attachments,
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
                },
              ),
            ),
            
            // Reminder display
            if (_reminderDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Reminder set for: ${_reminderDate!.toLocal()}'),
              ),
          ],
        ),
      ),
    );
  }
}
