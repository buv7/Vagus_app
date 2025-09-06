import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';

class BreachBanner extends StatelessWidget {
  final String ticketId;
  final String agentId;
  final SlaSnapshot snap;
  const BreachBanner({super.key, required this.ticketId, required this.agentId, required this.snap});

  @override
  Widget build(BuildContext context) {
    if (!snap.breached) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha:.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha:.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(child: Text('SLA breached — take action', style: TextStyle(fontWeight: FontWeight.w800))),
            Text(snap.policyName, style: TextStyle(color: Colors.black.withValues(alpha:.6))),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.check),
              label: const Text('Acknowledge'),
              onPressed: () async {
                final ok = await AdminSupportService.instance.acknowledgeBreach(ticketId, agentId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Acknowledged' : 'Failed')));
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.more_time),
              label: const Text('Extend 15 min'),
              onPressed: () async {
                final ok = await AdminSupportService.instance.extendSla(ticketId, const Duration(minutes: 15), 'quick extension', agentId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Extended' : 'Failed')));
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.priority_high),
              label: const Text('Escalate to Urgent'),
              onPressed: () async {
                final ok = await AdminSupportService.instance.escalatePriority(ticketId, to: 'urgent', reason: 'breach', agentId: agentId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Escalated' : 'Failed')));
              },
            ),
          ]),
        ],
      ),
    );
  }
}
