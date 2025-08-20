import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NoteVersionViewer extends StatefulWidget {
  final String noteId;
  final String noteTitle;

  const NoteVersionViewer({
    super.key,
    required this.noteId,
    required this.noteTitle,
  });

  @override
  State<NoteVersionViewer> createState() => _NoteVersionViewerState();
}

class _NoteVersionViewerState extends State<NoteVersionViewer> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _versions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVersions();
  }

  Future<void> _fetchVersions() async {
    try {
      final response = await supabase
          .from('coach_note_versions')
          .select('*, profiles!coach_note_versions_created_by_fkey(name, email)')
          .eq('note_id', widget.noteId)
          .order('version_index', ascending: false);

      setState(() {
        _versions = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load versions: $e';
        _loading = false;
      });
    }
  }

  Future<void> _revertToVersion(Map<String, dynamic> version) async {
    try {
      // Get the current note to update it
      final noteResponse = await supabase
          .from('coach_notes')
          .select()
          .eq('id', widget.noteId)
          .single();

      final currentNote = noteResponse as Map<String, dynamic>;
      final currentVersion = currentNote['version'] ?? 1;

      // Create a new version with the current content before reverting
      await supabase.from('coach_note_versions').insert({
        'note_id': widget.noteId,
        'version_index': currentVersion,
        'content': currentNote['body'] ?? '',
        'metadata': {
          'title': currentNote['title'],
          'tags': currentNote['tags'] ?? [],
          'linked_plan_ids': currentNote['linked_plan_ids'] ?? {},
          'attachments_summary': _getAttachmentsSummary(currentNote['attachments'] ?? []),
        },
        'created_by': supabase.auth.currentUser!.id,
      });

      // Update the note with the reverted content
      final versionMetadata = version['metadata'] as Map<String, dynamic>? ?? {};
      
      await supabase.from('coach_notes').update({
        'body': version['content'],
        'title': versionMetadata['title'],
        'tags': versionMetadata['tags'] ?? [],
        'linked_plan_ids': versionMetadata['linked_plan_ids'] ?? {},
        'version': currentVersion + 1,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': supabase.auth.currentUser!.id,
      }).eq('id', widget.noteId);

      // Refresh the versions list
      await _fetchVersions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reverted to version ${version['version_index']}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate note was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to revert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getAttachmentsSummary(List<dynamic> attachments) {
    if (attachments.isEmpty) return 'No attachments';
    return '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}';
  }

  void _viewFullVersion(Map<String, dynamic> version) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Version ${version['version_index']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.parse(version['created_at']))}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    version['content'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _revertToVersion(version);
                    },
                    child: const Text('Revert to This Version'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Versions: ${widget.noteTitle}'),
        actions: [
          if (_versions.isNotEmpty)
            Text(
              '${_versions.length} version${_versions.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchVersions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _versions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No versions yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Versions will appear here when you edit the note',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _versions.length,
                      itemBuilder: (context, index) {
                        final version = _versions[index];
                        final createdAt = DateTime.parse(version['created_at']);
                        final author = version['profiles'] as Map<String, dynamic>?;
                        final authorName = author?['name'] ?? author?['email'] ?? 'Unknown';
                        final metadata = version['metadata'] as Map<String, dynamic>? ?? {};
                        final tags = metadata['tags'] as List<dynamic>? ?? [];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'v${version['version_index']}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMM dd, yyyy - HH:mm').format(createdAt),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'By: $authorName',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  version['content'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (tags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: tags.map((tag) => Chip(
                                      label: Text(
                                        tag.toString(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      backgroundColor: Colors.grey[100],
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    )).toList(),
                                  ),
                                ],
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'view':
                                    _viewFullVersion(version);
                                    break;
                                  case 'revert':
                                    _revertToVersion(version);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 8),
                                      Text('View Full'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'revert',
                                  child: Row(
                                    children: [
                                      Icon(Icons.restore),
                                      SizedBox(width: 8),
                                      Text('Revert to This Version'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
