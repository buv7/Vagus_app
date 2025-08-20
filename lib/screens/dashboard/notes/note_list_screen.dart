import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/screens/notes/coach_note_screen.dart';
import 'package:vagus_app/widgets/notes/note_card.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  List<dynamic> _notes = [];
  bool _showOnlyWithAttachments = false;
  bool _showOnlyWithVersions = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('coach_notes')
        .select()
        .eq('coach_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      _notes = response;
      _loading = false;
    });
  }

  List<dynamic> get _filteredNotes {
    return _notes.where((note) {
      if (_showOnlyWithAttachments) {
        final attachments = note['attachments'] as List<dynamic>? ?? [];
        if (attachments.isEmpty) return false;
      }
      
      if (_showOnlyWithVersions) {
        final version = note['version'] ?? 1;
        if (version <= 1) return false;
      }
      
      return true;
    }).toList();
  }

  Future<void> _deleteNote(String id) async {
    await supabase.from('coach_notes').delete().eq('id', id);
    _fetchNotes();
  }

  void _openNote(Map<String, dynamic>? note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachNoteScreen(existingNote: note),
      ),
    );

    if (result == true) {
      _fetchNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Notes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotes.isEmpty
          ? const Center(child: Text("No notes found."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NoteCard(
                    note: note,
                    onTap: () => _openNote(note),
                    onDelete: () => _deleteNote(note['id']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNote(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Has Attachments'),
              value: _showOnlyWithAttachments,
              onChanged: (value) {
                setState(() {
                  _showOnlyWithAttachments = value ?? false;
                });
                Navigator.pop(context);
              },
            ),
            CheckboxListTile(
              title: const Text('Has Versions'),
              value: _showOnlyWithVersions,
              onChanged: (value) {
                setState(() {
                  _showOnlyWithVersions = value ?? false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showOnlyWithAttachments = false;
                _showOnlyWithVersions = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear Filters'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
