import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/admin/admin_tools.dart';
import '../../theme/design_tokens.dart';

class UserInspectorSheet extends StatelessWidget {
  final String userId;
  final String email;
  const UserInspectorSheet({super.key, required this.userId, required this.email});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      builder: (_, c) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Material(
              color: Colors.transparent,
              child: ListView(
                controller: c,
                padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(email, style: DesignTokens.displaySmall)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _tool(context, Icons.support_agent, 'Open ticket', () => AdminTools.openSupportForUser(context, userId)),
              _tool(context, Icons.password, 'Send reset link', () => AdminTools.sendPasswordReset(context, email)),
              _tool(context, Icons.verified_user_outlined, 'Verify email', () => AdminTools.markEmailVerified(context, userId)),
              _tool(context, Icons.devices_other, 'Clear devices', () => AdminTools.clearDevices(context, userId)),
              _tool(context, Icons.key, 'Impersonate', () => AdminTools.impersonate(context, userId, email)),
            ]),
            const Divider(height: 24),
            // Simple placeholders; wire to existing data where available
            _section('Profile', const Text('Name, role, created_at, last_login…')),
            _section('Subscriptions', const Text('Plan, renewal, status…')),
            _section('Connections', const Text('Health (Fit/HealthKit), Music, Google Drive…')),
            _section('Intake & Supplements', const Text('Intake status, current supplements…')),
            _section('Audit', const Text('Recent actions & notes…')),
              ],
            ),
          ),
        ),
      ),
        ),
      );
  }

  Widget _section(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: DesignTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      child,
      const SizedBox(height: 16),
    ],
  );

  Widget _tool(BuildContext context, IconData icon, String label, FutureOr<void> Function() onTap) => ActionChip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    onPressed: () async { await onTap(); if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label done'))); },
  );
}
