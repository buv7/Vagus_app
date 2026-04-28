import 'package:flutter/material.dart';
import '../../models/subscription/tier.dart';
import '../../screens/billing/upgrade_screen.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet shown when a feature is blocked by the user's current tier.
///
/// Usage:
/// ```dart
/// final check = await TierService.instance.checkLabwork();
/// if (!check.allowed) {
///   await UpgradePromptSheet.show(context, check);
///   return;
/// }
/// ```
class UpgradePromptSheet extends StatelessWidget {
  final TierCheckResult check;

  const UpgradePromptSheet({super.key, required this.check});

  static Future<void> show(BuildContext context, TierCheckResult check) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradePromptSheet(check: check),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final required = check.requiredTier;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.accentGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Upgrade to ${required.displayName}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Reason
          Text(
            check.reason,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Price hint
          Text(
            '${required.displayName} starts at ${required.price}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.accentGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),

          // Upgrade CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Upgrade to ${required.displayName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dismiss
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe later',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
