import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'note_file_picker.dart';
import 'note_reminder_setter.dart';
import 'smart_panel.dart';

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
  List<File> _attachments = [];
  List<String> _tags = [];
  Map<String, List<String>> _linkedPlanIds = {};
  bool _saving = false;

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
      final urls = List<String>.from(widget.existingNote!['attachments'] ?? []);
      _attachments = urls.map((url) => File(url)).toList();
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
        'attachments': _attachments.map((f) => f.path).toList(),
      };

      if (widget.existingNote != null) {
        await supabase.from('coach_notes').update(data).eq('id', widget.existingNote!['id']);
      } else {
        await supabase.from('coach_notes').insert(data);
      }

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

  void _pickFiles() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return NoteFilePicker(
          attachments: _attachments,
          onAdd: (file) {
            setState(() => _attachments.add(file));
            Navigator.pop(context);
          },
          onRemove: (file) {
            setState(() => _attachments.remove(file));
          },
          existingFiles: _attachments.map((f) => f.path).toList(),
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
      appBar: AppBar(
        title: Text(widget.existingNote == null ? "New Note" : "Edit Note"),
        actions: [
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
                hintText: "Note title (optional)",
                border: OutlineInputBorder(),
                labelText: "Title",
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
                  hintText: "Write your note...",
                  border: OutlineInputBorder(),
                  labelText: "Note",
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Tags section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tags:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: "Add a tag...",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTag,
                      child: const Text("Add"),
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
            SmartPanel(noteController: _bodyController),
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.alarm),
                  label: const Text("Set Reminder"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Attachments"),
                ),
              ],
            ),
            
            // Reminder display
            if (_reminderDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Reminder set for: ${_reminderDate!.toLocal()}"),
              ),
          ],
        ),
      ),
    );
  }
}
