import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';

class SupportCannedRepliesScreen extends StatefulWidget {
  const SupportCannedRepliesScreen({super.key});

  @override
  State<SupportCannedRepliesScreen> createState() => _SupportCannedRepliesScreenState();
}

class _SupportCannedRepliesScreenState extends State<SupportCannedRepliesScreen> {
  final _svc = AdminSupportService.instance;
  List<Map<String,dynamic>> _items = const [];
  bool _loading = true;
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    final items = await _svc.listCannedRepliesRaw();
    if (!mounted) return;
    
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<Map<String,dynamic>> get _filteredItems {
    if (_q.text.isEmpty) return _items;
    final query = _q.text.toLowerCase();
    return _items.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final body = (item['body'] ?? '').toString().toLowerCase();
      final tags = (item['tags'] as List<dynamic>? ?? [])
          .map((t) => t.toString().toLowerCase())
          .join(' ');
      return title.contains(query) || body.contains(query) || tags.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canned Replies'),
        actions: [
          IconButton(
            onPressed: _create,
            icon: const Icon(Icons.add),
            tooltip: 'Create Reply',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _q,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Search by title, body, or tags...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(
                        child: Text('No canned replies found. Create your first one above.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final item = _filteredItems[i];
                          return Card(
                            child: ListTile(
                              title: Text(item['title'] ?? 'Untitled'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['body'] ?? 'No content',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if ((item['tags'] as List<dynamic>?)?.isNotEmpty == true)
                                    Wrap(
                                      spacing: 4,
                                      children: (item['tags'] as List<dynamic>)
                                          .map((tag) => _tag(tag.toString()))
                                          .toList(),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _edit(item),
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    onPressed: () => _delete(item),
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                              onTap: () => _view(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  static Widget _tag(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _create() async {
    await _editDialog();
  }

  Future<void> _edit(Map<String,dynamic> item) async {
    await _editDialog(existing: item);
  }

  Future<void> _view(Map<String,dynamic> item) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['title'] ?? 'Untitled'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item['body'] ?? 'No content'),
              if ((item['tags'] as List<dynamic>?)?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text(
                  'Tags:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: (item['tags'] as List<dynamic>)
                      .map((tag) => _tag(tag.toString()))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Map<String,dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: Text('Are you sure you want to delete "${item['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _svc.deleteCannedReply(item['id']);
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply deleted')),
        );
        unawaited(_load());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete reply')),
        );
      }
    }
  }

  Future<void> _editDialog({Map<String,dynamic>? existing}) async {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final bodyCtrl = TextEditingController(text: existing?['body'] ?? '');
    final tagsCtrl = TextEditingController(
      text: (existing?['tags'] as List<dynamic>?)?.join(', ') ?? '',
    );
    
    final result = await showDialog<Map<String,dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Create Reply' : 'Edit Reply'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Welcome Message',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter your canned reply content...',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'e.g., welcome, onboarding, faq (comma separated)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop({
              'title': titleCtrl.text.trim(),
              'body': bodyCtrl.text.trim(),
              'tags': tagsCtrl.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList(),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      bool success;
      if (existing == null) {
        final id = await _svc.createCannedReply(
          title: result['title'],
          body: result['body'],
          tags: result['tags'],
        );
        success = id != null;
      } else {
        success = await _svc.updateCannedReply(
          existing['id'],
          title: result['title'],
          body: result['body'],
          tags: result['tags'],
        );
      }

      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing == null ? 'Reply created' : 'Reply updated')),
        );
        unawaited(_load());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save reply')),
        );
      }
    }
  }
}
