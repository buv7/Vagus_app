import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin/ticket_models.dart';
import '../../services/admin/admin_ticket_service.dart';

class AdminEscalationMatrixScreen extends StatefulWidget {
  const AdminEscalationMatrixScreen({super.key});

  @override
  State<AdminEscalationMatrixScreen> createState() => _AdminEscalationMatrixScreenState();
}

class _AdminEscalationMatrixScreenState extends State<AdminEscalationMatrixScreen> {
  final _svc = AdminTicketService.instance;
  List<EscalationRule> _rules = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final r = await _svc.listRules();
    if (!mounted) return;
    setState(()=> _rules = r);
  }

  Future<void> _edit(EscalationRule? r) async {
    final id = r?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final name = TextEditingController(text: r?.name ?? '');
    final tags = TextEditingController(text: r==null ? '' : r.matchTags.join(', '));
    TicketPriority? minPri = r?.minPriority;
    Duration? frt = r?.maxFirstResponse;
    Duration? mttr = r?.maxResolution;
    final assignGroup = TextEditingController(text: r?.actionAssignGroup ?? '');
    final actTags = TextEditingController(text: r==null ? '' : r.actionAddTags.join(', '));
    TicketPriority? setPri = r?.actionSetPriority;
    bool notifySlack = r?.notifySlack ?? false;

    Duration? pickDuration(Duration? current) => current;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left:16,
          right:16, 
          top:12, 
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              r==null ? 'Create Rule' : 'Edit Rule', 
              style: const TextStyle(fontWeight: FontWeight.w800)
            ),
            const SizedBox(height: 8),
            TextField(
              controller: name, 
              decoration: const InputDecoration(labelText:'Name')
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tags, 
              decoration: const InputDecoration(labelText:'Match tags (comma separated)')
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TicketPriority?>(
              value: minPri,
              items: const [
                DropdownMenuItem(value:null, child: Text('Min Priority: Any')),
                DropdownMenuItem(value:TicketPriority.low, child: Text('Low')),
                DropdownMenuItem(value:TicketPriority.normal, child: Text('Normal')),
                DropdownMenuItem(value:TicketPriority.high, child: Text('High')),
                DropdownMenuItem(value:TicketPriority.urgent, child: Text('Urgent')),
              ],
              onChanged: (v)=> setState(()=> minPri = v),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('Max First Response: ${frt?.inMinutes ?? 0}m')),
              TextButton(
                onPressed: ()=> setState(()=> frt = pickDuration(frt) ?? const Duration(minutes: 30)), 
                child: const Text('Set 30m')
              ),
              TextButton(
                onPressed: ()=> setState(()=> frt = null), 
                child: const Text('Clear')
              ),
            ]),
            Row(children: [
              Expanded(child: Text('Max Resolution: ${mttr?.inHours ?? 0}h')),
              TextButton(
                onPressed: ()=> setState(()=> mttr = pickDuration(mttr) ?? const Duration(hours: 24)), 
                child: const Text('Set 24h')
              ),
              TextButton(
                onPressed: ()=> setState(()=> mttr = null), 
                child: const Text('Clear')
              ),
            ]),
            const Divider(height: 24),
            TextField(
              controller: assignGroup, 
              decoration: const InputDecoration(labelText:'Assign group (e.g., L2, Billing)')
            ),
            const SizedBox(height: 8),
            TextField(
              controller: actTags, 
              decoration: const InputDecoration(labelText:'Add tags (comma separated)')
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TicketPriority?>(
              value: setPri,
              items: const [
                DropdownMenuItem(value:null, child: Text('Set Priority: —')),
                DropdownMenuItem(value:TicketPriority.low, child: Text('Low')),
                DropdownMenuItem(value:TicketPriority.normal, child: Text('Normal')),
                DropdownMenuItem(value:TicketPriority.high, child: Text('High')),
                DropdownMenuItem(value:TicketPriority.urgent, child: Text('Urgent')),
              ],
              onChanged: (v)=> setState(()=> setPri = v),
            ),
            SwitchListTile(
              value: notifySlack, 
              onChanged:(v)=> setState(()=> notifySlack = v),
              title: const Text('Notify Slack (stub)')
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final r2 = EscalationRule(
                    id:id,
                    name:name.text.trim(),
                    matchTags: tags.text.split(',').map((s)=> s.trim()).where((s)=> s.isNotEmpty).toList(),
                    minPriority:minPri,
                    maxFirstResponse: frt,
                    maxResolution: mttr,
                    actionAssignGroup: assignGroup.text.trim(),
                    actionAddTags: actTags.text.split(',').map((s)=> s.trim()).where((s)=> s.isNotEmpty).toList(),
                    actionSetPriority:setPri,
                    notifySlack:notifySlack,
                  );
                  await _svc.upsertRule(r2);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
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
        title: const Text('Escalation Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add), 
            onPressed: ()=> _edit(null)
          ),
        ]
      ),
      body: ListView.separated(
        itemCount: _rules.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = _rules[i];
          return ListTile(
            title: Text(
              r.name, 
              style: const TextStyle(fontWeight: FontWeight.w700)
            ),
            subtitle: Text([
              if (r.matchTags.isNotEmpty) 'tags: ${r.matchTags.join(", ")}',
              if (r.minPriority!=null) 'minPrio: ${r.minPriority!.name}',
              if (r.maxFirstResponse!=null) 'frt<=${r.maxFirstResponse!.inMinutes}m',
              if (r.maxResolution!=null) 'mttr<=${r.maxResolution!.inHours}h',
              if (r.actionAssignGroup.isNotEmpty) 'assign:${r.actionAssignGroup}',
              if (r.actionAddTags.isNotEmpty) 'add:${r.actionAddTags.join(",")}',
              if (r.actionSetPriority!=null) 'set:${r.actionSetPriority!.name}',
              if (r.notifySlack) 'slack'
            ].join(' • ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined), 
                  onPressed: ()=> _edit(r)
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline), 
                  onPressed: () async {
                    await _svc.deleteRule(r.id);
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
