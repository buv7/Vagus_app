import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/screens/notes/coach_note_screen.dart';
import 'package:vagus_app/widgets/notes/note_card.dart';
import 'package:vagus_app/theme/design_tokens.dart';

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
    unawaited(_fetchNotes());
  }

  void _openNote(Map<String, dynamic>? note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachNoteScreen(existingNote: note),
      ),
    );

    if (result == true) {
      unawaited(_fetchNotes());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
        foregroundColor: isDark ? Colors.white : DesignTokens.textColor(context),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.note_alt,
                color: DesignTokens.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Your Notes',
              style: TextStyle(
                color: isDark ? Colors.white : DesignTokens.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context)),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: DesignTokens.accentBlue))
          : _filteredNotes.isEmpty
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                    : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark 
                      ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                      : DesignTokens.borderColor(context),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.note_add,
                        size: 48,
                        color: DesignTokens.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notes found.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : DesignTokens.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to create your first note',
                      style: TextStyle(
                        color: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              DesignTokens.accentBlue.withValues(alpha: 0.3),
              DesignTokens.accentBlue.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: DesignTokens.accentBlue.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openNote(null),
                borderRadius: BorderRadius.circular(28),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkBackground : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.filter_list,
                            color: DesignTokens.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Filter Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : DesignTokens.textColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark 
                                ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                                : DesignTokens.borderColor(context),
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              'Has Attachments',
                              style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                            ),
                            value: _showOnlyWithAttachments,
                            activeColor: DesignTokens.accentBlue,
                            checkColor: Colors.white,
                            onChanged: (value) {
                              setState(() {
                                _showOnlyWithAttachments = value ?? false;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark 
                                ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                                : DesignTokens.borderColor(context),
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              'Has Versions',
                              style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                            ),
                            value: _showOnlyWithVersions,
                            activeColor: DesignTokens.accentBlue,
                            checkColor: Colors.white,
                            onChanged: (value) {
                              setState(() {
                                _showOnlyWithVersions = value ?? false;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.2) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _showOnlyWithAttachments = false;
                                    _showOnlyWithVersions = false;
                                  });
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Clear Filters',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : DesignTokens.accentBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: DesignTokens.accentBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Close',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
