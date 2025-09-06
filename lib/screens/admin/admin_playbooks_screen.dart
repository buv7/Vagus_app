import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin/ticket_models.dart';
import '../../services/admin/admin_ticket_service.dart';

class AdminPlaybooksScreen extends StatefulWidget {
  const AdminPlaybooksScreen({super.key});

  @override
  State<AdminPlaybooksScreen> createState() => _AdminPlaybooksScreenState();
}

class _AdminPlaybooksScreenState extends State<AdminPlaybooksScreen> {
  final _svc = AdminTicketService.instance;
  List<Playbook> _items = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final p = await _svc.listPlaybooks();
    if (!mounted) return;
    setState(()=> _items = p);
  }

  Future<void> _edit(Playbook? p) async {
    final id = p?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final title = TextEditingController(text: p?.title ?? '');
    final tags = TextEditingController(text: p==null ? '' : p.tags.join(', '));
    final steps = List<PlayStep>.from(p?.steps ?? const []);

    Future<void> addStep() async {
      String kind = 'reply';
      final val = TextEditingController();
      await showDialog(
        context: context, 
        builder: (_)=> AlertDialog(
          title: const Text('Add Step'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: kind,
                items: const [
                  DropdownMenuItem(value:'reply', child: Text('Reply')),
                  DropdownMenuItem(value:'note', child: Text('Internal Note')),
                  DropdownMenuItem(value:'assign', child: Text('Assign Group')),
                  DropdownMenuItem(value:'tag', child: Text('Add Tag')),
                  DropdownMenuItem(value:'status', child: Text('Set Status')),
                  DropdownMenuItem(value:'macro', child: Text('Apply Macro')),
                ],
                onChanged: (v)=> kind = v ?? 'reply',
              ),
              TextField(
                controller: val, 
                decoration: const InputDecoration(labelText: 'Value')
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: ()=> Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            FilledButton(
              onPressed: (){
                steps.add(PlayStep(kind:kind, value:val.text.trim()));
                Navigator.pop(context);
              }, 
              child: const Text('Add')
            ),
          ],
        )
      );
      if (!mounted) return;
      setState((){});
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled:true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      builder: (_)=> Padding(
        padding: EdgeInsets.only(
          left:16,
          right:16, 
          top:12, 
          bottom:12 + MediaQuery.of(context).viewInsets.bottom
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p==null ? 'Create Playbook' : 'Edit Playbook', 
              style: const TextStyle(fontWeight: FontWeight.w800)
            ),
            const SizedBox(height: 8),
            TextField(
              controller: title, 
              decoration: const InputDecoration(labelText:'Title')
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tags, 
              decoration: const InputDecoration(labelText:'Tags (comma separated)')
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withValues(alpha:.08)),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Column(children: [
                for (var i=0;i<steps.length;i++)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha:.12),
                      child: const Icon(Icons.play_arrow)
                    ),
                    title: Text('${steps[i].kind} → ${steps[i].value}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline), 
                      onPressed: (){
                        steps.removeAt(i);
                        setState((){});
                      }
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: addStep, 
                    icon: const Icon(Icons.add), 
                    label: const Text('Add Step')
                  )
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final pb = Playbook(
                    id: id,
                    title: title.text.trim(),
                    steps: steps,
                    tags: tags.text.split(',').map((s)=> s.trim()).where((s)=> s.isNotEmpty).toList(),
                  );
                  await _svc.upsertPlaybook(pb);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              )
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
        title: const Text('Playbooks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add), 
            onPressed: ()=> _edit(null)
          ),
        ]
      ),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (_, i) {
          final p = _items[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withValues(alpha:.12),
              child: const Icon(Icons.auto_awesome)
            ),
            title: Text(
              p.title, 
              style: const TextStyle(fontWeight: FontWeight.w700)
            ),
            subtitle: Text('${p.steps.length} steps • ${p.tags.join(", ")}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined), 
                  onPressed: ()=> _edit(p)
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline), 
                  onPressed: () async {
                    await _svc.deletePlaybook(p.id);
                    if (!context.mounted) return;
                    unawaited(_load());
                  }
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
