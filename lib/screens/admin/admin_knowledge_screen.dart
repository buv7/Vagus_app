import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin/kb_models.dart';
import '../../services/admin/admin_knowledge_service.dart';

class AdminKnowledgeScreen extends StatefulWidget {
  const AdminKnowledgeScreen({super.key});

  @override
  State<AdminKnowledgeScreen> createState() => _AdminKnowledgeScreenState();
}

class _AdminKnowledgeScreenState extends State<AdminKnowledgeScreen> {
  final _svc = AdminKnowledgeService.instance;
  final _q = TextEditingController();
  List<KbArticle> _items = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _svc.search(q: _q.text.trim());
    if (!mounted) return;
    setState(() {
      _items = res;
      _loading = false;
    });
  }

  Future<void> _edit(KbArticle? a) async {
    final id = a?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final title = TextEditingController(text: a?.title ?? '');
    final body = TextEditingController(text: a?.body ?? '');
    final tags = TextEditingController(text: a == null ? '' : a.tags.join(', '));
    KbVisibility vis = a?.vis ?? KbVisibility.public;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              a == null ? 'Create Article' : 'Edit Article',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tags,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<KbVisibility>(
              value: vis,
              items: const [
                DropdownMenuItem(
                  value: KbVisibility.public,
                  child: Text('Public'),
                ),
                DropdownMenuItem(
                  value: KbVisibility.internal,
                  child: Text('Internal'),
                ),
              ],
              onChanged: (v) => vis = v ?? KbVisibility.public,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: body,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final art = KbArticle(
                    id: id,
                    title: title.text.trim(),
                    body: body.text,
                    tags: tags.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList(),
                    vis: vis,
                    updatedAt: DateTime.now(),
                    updatedBy: 'Admin',
                  );
                  await _svc.upsert(art);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            )
          ],
        ),
      ),
    );
    if (!mounted) return;
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _edit(null),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search articles…',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => unawaited(_load()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => unawaited(_load()),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final a = _items[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      a.vis == KbVisibility.public ? Icons.public : Icons.lock,
                    ),
                  ),
                  title: Text(
                    a.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${a.tags.join(", ")} • updated ${a.updatedAt}',
                  ),
                  onTap: () => _edit(a),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await _svc.remove(a.id);
                      if (!context.mounted) return;
                      unawaited(_load());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
