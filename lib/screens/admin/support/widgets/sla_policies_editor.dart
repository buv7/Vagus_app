import 'package:flutter/material.dart';
import '../../../../services/admin/admin_support_service.dart';

class SlaPoliciesEditor extends StatefulWidget {
  const SlaPoliciesEditor({super.key});

  @override
  State<SlaPoliciesEditor> createState() => _SlaPoliciesEditorState();
}

class _SlaPoliciesEditorState extends State<SlaPoliciesEditor> {
  late final AdminSupportService _svc;
  late Map<String, ({Duration response, Duration resolution})> _policy;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _svc = AdminSupportService.instance;
    _loadPolicy();
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  Future<void> _loadPolicy() async {
    await _svc.loadSlaPolicy();
    if (!mounted) return;
    setState(() {
      _policy = Map.from(_svc.currentSlaPolicy);
      _loading = false;
    });
  }

  Future<void> _savePolicy() async {
    await _svc.saveSlaPolicy(_policy);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SLA policies saved')),
    );
  }

  Widget _buildPriorityRow(String priority, String label, Color color) {
    final current = _policy[priority]!;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Priority: $priority',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Response Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      _buildDurationPicker(
                        'response',
                        priority,
                        current.response,
                        (duration) {
                          setState(() {
                            _policy[priority] = (response: duration, resolution: current.resolution);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resolution Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      _buildDurationPicker(
                        'resolution',
                        priority,
                        current.resolution,
                        (duration) {
                          setState(() {
                            _policy[priority] = (response: current.response, resolution: duration);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationPicker(
    String type,
    String priority,
    Duration current,
    ValueChanged<Duration> onChanged,
  ) {
    final hours = current.inHours;
    final minutes = current.inMinutes % 60;
    
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: hours,
            decoration: const InputDecoration(
              labelText: 'Hours',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            items: List.generate(25, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
            onChanged: (value) {
              if (value != null) {
                onChanged(Duration(hours: value, minutes: minutes));
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: minutes,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
            onChanged: (value) {
              if (value != null) {
                onChanged(Duration(hours: hours, minutes: value));
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SLA Policies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configure Service Level Agreement times for different priority levels.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPriorityRow('urgent', 'Urgent', Colors.red),
                          _buildPriorityRow('high', 'High', Colors.orange),
                          _buildPriorityRow('normal', 'Normal', Colors.blue),
                          _buildPriorityRow('low', 'Low', Colors.green),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _savePolicy,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Save Policies'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
