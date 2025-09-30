import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/admin/admin_ticket_service.dart';
import '../../models/admin/ticket_models.dart';

class AdminIncidentsScreen extends StatefulWidget {
  const AdminIncidentsScreen({super.key});

  @override
  State<AdminIncidentsScreen> createState() => _AdminIncidentsScreenState();
}

class _AdminIncidentsScreenState extends State<AdminIncidentsScreen> {
  final _svc = AdminTicketService.instance;
  List<TicketSummary> _all = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final r = await _svc.listTickets();
    if (!mounted) return;
    setState(() => _all = r);
  }

  @override
  Widget build(BuildContext context) {
    final byTag = <String, int>{};
    for (final t in _all) {
      for (final tag in t.tags) {
        byTag[tag] = (byTag[tag] ?? 0) + 1;
      }
    }
    final hotTags = byTag.entries
        .where((e) => e.value > 1)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final urgentTickets = _all.where((t) => t.priority == TicketPriority.urgent).length;
    final oldTickets = _all.where((t) => t.age.inHours > 24).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => unawaited(_load()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Tickets',
                          value: _all.length.toString(),
                          icon: Icons.assignment,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Urgent',
                          value: urgentTickets.toString(),
                          icon: Icons.priority_high,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Over 24h',
                          value: oldTickets.toString(),
                          icon: Icons.schedule,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hot topics
          if (hotTags.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hot Topics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hotTags.take(8).map((e) {
                        return Chip(
                          label: Text('${e.key} (${e.value})'),
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recommended actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (urgentTickets > 0)
                    _ActionItem(
                      icon: Icons.priority_high,
                      title: 'Review urgent tickets',
                      description: '$urgentTickets tickets marked as urgent',
                      action: 'Review Now',
                      onAction: () {
                        // Navigate to ticket queue with urgent filter
                      },
                    ),
                  if (oldTickets > 0)
                    _ActionItem(
                      icon: Icons.schedule,
                      title: 'Address aging tickets',
                      description: '$oldTickets tickets over 24 hours old',
                      action: 'View Old',
                      onAction: () {
                        // Navigate to ticket queue with age filter
                      },
                    ),
                  if (hotTags.isNotEmpty)
                    _ActionItem(
                      icon: Icons.trending_up,
                      title: 'Investigate hot topics',
                      description: hotTags.take(3).map((e) => e.key).join(', '),
                      action: 'Analyze',
                      onAction: () {
                        // Navigate to root cause trends
                      },
                    ),
                  if (urgentTickets == 0 && oldTickets == 0 && hotTags.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'All systems operational. No immediate action required.',
                        style: TextStyle(
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback onAction;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}
