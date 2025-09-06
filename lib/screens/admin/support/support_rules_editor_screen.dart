// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';

class SupportRulesEditorScreen extends StatefulWidget {
  const SupportRulesEditorScreen({super.key});

  @override
  State<SupportRulesEditorScreen> createState() => _SupportRulesEditorScreenState();
}

class _SupportRulesEditorScreenState extends State<SupportRulesEditorScreen> {
  final _svc = AdminSupportService.instance;
  List<Map<String,dynamic>> _rules = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    final rules = await _svc.listAllRulesRaw();
    if (!mounted) return;
    
    setState(() {
      _rules = rules;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Triage Rules'),
        actions: [
          IconButton(
            onPressed: _createRuleDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create Rule',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? const Center(
                  child: Text('No rules configured. Create your first rule above.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = _rules[i];
                    return Card(
                      child: ListTile(
                        leading: _chip(r['priority'] ?? 'normal'),
                        title: Text(r['name'] ?? 'Unnamed Rule'),
                        subtitle: Text(r['description'] ?? 'No description'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _editRuleDialog(r),
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              onPressed: () => _deleteRule(r),
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  static Widget _chip(String t) {
    final color = switch (t.toLowerCase()) {
      'high' => Colors.red,
      'normal' => Colors.blue,
      'low' => Colors.grey,
      _ => Colors.blue,
    };
    return Chip(
      label: Text(t.toUpperCase()),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  Future<void> _createRuleDialog() async {
    await _ruleDialog();
  }

  Future<void> _editRuleDialog(Map<String,dynamic> r) async {
    await _ruleDialog(existing: r);
  }

  Future<void> _deleteRule(Map<String,dynamic> r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Are you sure you want to delete "${r['name']}"?'),
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
      final success = await _svc.deleteRule(r['id']);
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rule deleted')),
        );
        unawaited(_load());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete rule')),
        );
      }
    }
  }

  Future<void> _ruleDialog({Map<String,dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final priorityCtrl = TextEditingController(text: existing?['priority'] ?? 'normal');
    final conditionCtrl = TextEditingController(text: existing?['condition'] ?? '');
    final actionCtrl = TextEditingController(text: existing?['action'] ?? '');
    
    final result = await showDialog<Map<String,dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Create Rule' : 'Edit Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rule Name',
                  hintText: 'e.g., High Priority Bug',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What this rule does...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _dd(priorityCtrl, 'Priority', ['high', 'normal', 'low']),
              const SizedBox(height: 16),
              TextField(
                controller: conditionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Condition (SQL WHERE)',
                  hintText: 'e.g., priority = \'high\' AND category = \'bug\'',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: actionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  hintText: 'e.g., assign_to = \'support-team\'',
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
              'name': nameCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'priority': priorityCtrl.text.trim(),
              'condition': conditionCtrl.text.trim(),
              'action': actionCtrl.text.trim(),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      bool success;
      if (existing == null) {
        final id = await _svc.createRule(result);
        success = id != null;
      } else {
        success = await _svc.updateRule(existing['id'], result);
      }

      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing == null ? 'Rule created' : 'Rule updated')),
        );
        unawaited(_load());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save rule')),
        );
      }
    }
  }

  Widget _dd<T>(TextEditingController ctrl, String label, List<String?> items) {
    return DropdownButtonFormField<String>(
      value: ctrl.text.isEmpty ? null : ctrl.text,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item ?? ''),
      )).toList(),
      onChanged: (value) {
        if (value != null) ctrl.text = value;
      },
    );
  }
}
