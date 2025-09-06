// ignore_for_file: file_names
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/admin/admin_support_service.dart';

class AdminMacrosScreen extends StatefulWidget {
  const AdminMacrosScreen({super.key});
  @override
  State<AdminMacrosScreen> createState() => _AdminMacrosScreenState();
}

class _AdminMacrosScreenState extends State<AdminMacrosScreen> {
  final _svc = AdminSupportService.instance;
  List<Macro> _macros = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final m = await _svc.listMacros();
    if (!mounted) return;
    setState(()=> _macros = m);
  }

  Future<void> _edit(Macro? m) async {
    final id = m?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final title = TextEditingController(text: m?.title ?? '');
    final body = TextEditingController(text: m?.body ?? '');
    final tagsCtrl = TextEditingController(text: m==null ? '' : m.tags.join(', '));
    bool isPublic = m?.isPublic ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left:16,right:16, top:12, bottom: 12 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m==null ? 'Create Macro' : 'Edit Macro', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: body, maxLines: 5, decoration: const InputDecoration(labelText: 'Body / Reply')),
            const SizedBox(height: 8),
            TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (comma-separated)')),
            const SizedBox(height: 8),
            SwitchListTile(
              value: isPublic,
              onChanged: (v)=> setSheetState(()=> isPublic = v),
              title: const Text('Public'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final t = tagsCtrl.text.split(',').map((s)=> s.trim()).where((s)=> s.isNotEmpty).toList();
                  await _svc.upsertMacro(Macro(id:id, title:title.text.trim(), body: body.text.trim(), tags: t, isPublic: isPublic));
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
          ]),
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Macros & Canned Replies'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: ()=> _edit(null)),
      ]),
      body: ListView.separated(
        itemCount: _macros.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (_, i) {
          final m = _macros[i];
          return ListTile(
            title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(m.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: ()=> _edit(m)),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
                await _svc.deleteMacro(m.id);
                if (!context.mounted) return;
                unawaited(_load());
              }),
            ]),
          );
        },
      ),
    );
  }
}
