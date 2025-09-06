import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';

class SupportSlaEditorScreen extends StatefulWidget {
  const SupportSlaEditorScreen({super.key});

  @override
  State<SupportSlaEditorScreen> createState() => _SupportSlaEditorScreenState();
}

class _SupportSlaEditorScreenState extends State<SupportSlaEditorScreen> {
  final _svc = AdminSupportService.instance;
  final _priorities = const ['urgent', 'high', 'normal', 'low'];
  final Map<String, TextEditingController> _first = {};
  final Map<String, TextEditingController> _resol = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    for (final p in _priorities) {
      _first[p] = TextEditingController();
      _resol[p] = TextEditingController();
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final ctrl in _first.values) ctrl.dispose();
    for (final ctrl in _resol.values) ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    final policies = await _svc.fetchSlaPolicies();
    if (!mounted) return;
    
    for (final p in policies.values) {
      _first[p.priority]?.text = p.firstResponseMins.toString();
      _resol[p.priority]?.text = p.resolutionMins.toString();
    }
    
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SLA Policies'),
        actions: [
          IconButton(
            onPressed: _saveAll,
            icon: const Icon(Icons.save),
            tooltip: 'Save All',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Level Agreements',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configure response and resolution time targets for each priority level.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._priorities.map((priority) => _buildPriorityCard(priority)),
              ],
            ),
    );
  }

  Widget _buildPriorityCard(String priority) {
    final color = switch (priority.toLowerCase()) {
      'urgent' => Colors.red,
      'high' => Colors.orange,
      'normal' => Colors.blue,
      'low' => Colors.grey,
      _ => Colors.blue,
    };
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _savePriority(priority),
                  icon: const Icon(Icons.save),
                  tooltip: 'Save',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _first[priority],
                    decoration: const InputDecoration(
                      labelText: 'First Response (minutes)',
                      hintText: 'e.g., 30',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _resol[priority],
                    decoration: const InputDecoration(
                      labelText: 'Resolution (minutes)',
                      hintText: 'e.g., 240',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'First response within ${_first[priority]?.text.isEmpty == true ? '...' : _first[priority]?.text} minutes, '
              'full resolution within ${_resol[priority]?.text.isEmpty == true ? '...' : _resol[priority]?.text} minutes.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePriority(String priority) async {
    final firstMins = int.tryParse(_first[priority]?.text ?? '');
    final resolMins = int.tryParse(_resol[priority]?.text ?? '');
    
    if (firstMins == null || resolMins == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }
    
    final success = await _svc.upsertSlaPolicy(priority, firstMins, resolMins);
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SLA for $priority saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save SLA for $priority')),
      );
    }
  }

  Future<void> _saveAll() async {
    bool allSuccess = true;
    
    for (final priority in _priorities) {
      final firstMins = int.tryParse(_first[priority]?.text ?? '');
      final resolMins = int.tryParse(_resol[priority]?.text ?? '');
      
      if (firstMins != null && resolMins != null) {
        final success = await _svc.upsertSlaPolicy(priority, firstMins, resolMins);
        if (!success) allSuccess = false;
      }
    }
    
    if (!mounted) return;
    
    if (allSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All SLA policies saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Some policies failed to save')),
      );
    }
  }
}
