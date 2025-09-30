import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';
import '../../../theme/design_tokens.dart';

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
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha:.08),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('SLA breached — take action', style: DesignTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold))),
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
      ),
        ),
      ),
    );
  }
}
