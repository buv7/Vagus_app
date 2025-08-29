import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notes/coach_note_screen.dart';
import '../../widgets/notes/note_card.dart';

class CoachNotesScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const CoachNotesScreen({super.key, required this.client});

  @override
  State<CoachNotesScreen> createState() => _CoachNotesScreenState();
}

class _CoachNotesScreenState extends State<CoachNotesScreen> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _notes = [];
  String _searchQuery = '';
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('coach_notes')
          .select()
          .eq('coach_id', user.id)
          .eq('client_id', widget.client['id'])
          .order('created_at', ascending: false);

      setState(() {
        _notes = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: $e')),
        );
      }
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      await supabase.from('coach_notes').delete().eq('id', id);
      await _fetchNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Note deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to delete note: $e')),
        );
      }
    }
  }

  void _openNote(Map<String, dynamic>? note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachNoteScreen(
          existingNote: note,
          clientId: widget.client['id'],
        ),
      ),
    );

    if (result == true) {
      await _fetchNotes();
    }
  }

  List<Map<String, dynamic>> get _filteredNotes {
    return _notes.where((note) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final title = (note['title'] ?? '').toString().toLowerCase();
        final body = (note['body'] ?? '').toString().toLowerCase();
        final tags = (note['tags'] as List<dynamic>? ?? [])
            .map((tag) => tag.toString().toLowerCase())
            .join(' ');
        
        if (!title.contains(searchLower) && 
            !body.contains(searchLower) && 
            !tags.contains(searchLower)) {
          return false;
        }
      }

      // Tag filter
      if (_selectedTags.isNotEmpty) {
        final noteTags = (note['tags'] as List<dynamic>? ?? [])
            .map((tag) => tag.toString())
            .toList();
        
        if (!_selectedTags.any((tag) => noteTags.contains(tag))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<String> get _allTags {
    final Set<String> tags = {};
    for (final note in _notes) {
      final noteTags = (note['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList();
      tags.addAll(noteTags);
    }
    return tags.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final clientName = widget.client['name'] ?? 'Unknown Client';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('📝 Notes for $clientName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tags filter
          if (_allTags.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by tags:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          
          // Notes list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? const Center(
                        child: Text(
                          'No notes found',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNote(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Notes'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by title, content, or tags...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
