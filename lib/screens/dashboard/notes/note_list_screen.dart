import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/screens/notes/coach_note_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  List<dynamic> _notes = [];

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
      appBar: AppBar(title: const Text("Your Notes")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(child: Text("No notes yet."))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final note = _notes[index];
          return ListTile(
            title: Text(note['note_text'] ?? 'No content'),
            subtitle: Text(
              note['reminder_date'] != null
                  ? "Reminder: ${note['reminder_date']}"
                  : "No reminder",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteNote(note['id']),
            ),
            onTap: () => _openNote(note),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNote(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
