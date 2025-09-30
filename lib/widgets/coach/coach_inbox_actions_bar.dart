import 'package:flutter/material.dart';

class CoachInboxActionsBar extends StatelessWidget {
  final bool bulkMode;
  final int selectedCount;
  final VoidCallback onToggleBulk;
  final VoidCallback onNudge;
  final VoidCallback onQuickCall;
  final VoidCallback onMarkReviewed;
  final VoidCallback onSavedReplies;

  const CoachInboxActionsBar({
    super.key,
    required this.bulkMode,
    required this.selectedCount,
    required this.onToggleBulk,
    required this.onNudge,
    required this.onQuickCall,
    required this.onMarkReviewed,
    required this.onSavedReplies,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Left: Inbox label + count badge
          Row(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 20,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Inbox',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  selectedCount > 0 ? '$selectedCount' : '$selectedCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Right: Action buttons
          Row(
            children: [
              // Bulk toggle
              _buildActionButton(
                context,
                icon: bulkMode ? Icons.checklist : Icons.checklist_outlined,
                label: 'Bulk',
                isActive: bulkMode,
                onTap: onToggleBulk,
                isDark: isDark,
              ),
              
              const SizedBox(width: 8),
              
              // Nudge
              _buildActionButton(
                context,
                icon: Icons.touch_app_outlined,
                label: 'Nudge',
                onTap: onNudge,
                isDark: isDark,
              ),
              
              const SizedBox(width: 8),
              
              // Quick Call
              _buildActionButton(
                context,
                icon: Icons.phone_outlined,
                label: 'Call',
                onTap: onQuickCall,
                isDark: isDark,
              ),
              
              const SizedBox(width: 8),
              
              // Mark Reviewed
              _buildActionButton(
                context,
                icon: Icons.check_circle_outline,
                label: 'Reviewed',
                onTap: onMarkReviewed,
                isDark: isDark,
              ),
              
              const SizedBox(width: 8),
              
              // Saved Replies
              _buildActionButton(
                context,
                icon: Icons.bookmark_outline,
                label: 'Saved',
                onTap: onSavedReplies,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive 
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive 
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
