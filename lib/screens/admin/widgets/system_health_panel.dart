import 'package:flutter/material.dart';

class SystemHealthPanel extends StatelessWidget {
  const SystemHealthPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.health_and_safety, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          const Text(
            'System Health: All services operational',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '99.9% uptime',
            style: TextStyle(
              color: Colors.green.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
