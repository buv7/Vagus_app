import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/admin/admin_incident_service.dart';
import '../../models/admin/incident_models.dart';

class AdminTriageRulesScreen extends StatefulWidget {
  const AdminTriageRulesScreen({super.key});

  @override
  State<AdminTriageRulesScreen> createState() => _AdminTriageRulesScreenState();
}

class _AdminTriageRulesScreenState extends State<AdminTriageRulesScreen> {
  final _svc = AdminIncidentService.instance;
  List<TriageRule> _rules = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final r = await _svc.listRules();
    if (!mounted) return;
    setState(() => _rules = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto-Triage Rules')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewRule,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _rules.length,
        itemBuilder: (_, i) {
          final r = _rules[i];
          return Card(
            child: ListTile(
              leading: Icon(
                r.enabled ? Icons.toggle_on : Icons.toggle_off,
                color: r.enabled ? Colors.green : Colors.grey,
              ),
              title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                'Include: ${r.includeTags.join(', ')}  •  Exclude: ${r.excludeTags.join(', ')}  •  Actions: ${r.actions.map((e) => e.name).join(', ')}',
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (v) => v == 'edit' ? _openEditRule(r) : _deleteRule(r),
              ),
              onTap: () => _openEditRule(r),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteRule(TriageRule r) async {
    await _svc.deleteRule(r.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rule deleted')));
  }

  Future<void> _openNewRule() async => _openEditRule(const TriageRule(id: '', name: 'New rule', enabled: true));

  Future<void> _openEditRule(TriageRule r) async {
    final nameCtrl = TextEditingController(text: r.name);
    final incCtrl = TextEditingController(text: r.includeTags.join(','));
    final excCtrl = TextEditingController(text: r.excludeTags.join(','));
    bool enabled = r.enabled;
    final pickedActions = Set<TriageAction>.from(r.actions);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  value: enabled,
                  onChanged: (v) => enabled = v,
                  title: const Text('Enabled'),
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Rule name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: incCtrl,
                  decoration: const InputDecoration(labelText: 'Include tags (comma separated)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: excCtrl,
                  decoration: const InputDecoration(labelText: 'Exclude tags (comma separated)'),
                ),
                const SizedBox(height: 12),
                const Text('Actions', style: TextStyle(fontWeight: FontWeight.w700)),
                Wrap(
                  spacing: 8,
                  children: TriageAction.values.map((a) {
                    final sel = pickedActions.contains(a);
                    return FilterChip(
                      label: Text(a.name),
                      selected: sel,
                      onSelected: (v) {
                        if (v) {
                          pickedActions.add(a);
                        } else {
                          pickedActions.remove(a);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(c).pop(true),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true || !mounted) return;
    final rule = TriageRule(
      id: r.id.isEmpty ? 'rule-${DateTime.now().millisecondsSinceEpoch}' : r.id,
      name: nameCtrl.text.trim().isEmpty ? 'Rule' : nameCtrl.text.trim(),
      enabled: enabled,
      includeTags: incCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      excludeTags: excCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      actions: pickedActions.toList(),
    );
    await _svc.upsertRule(rule);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rule saved')));
  }
}
