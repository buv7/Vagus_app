import 'package:flutter/material.dart';
import '../../services/coach/coach_inbox_service.dart';
import '../../utils/severity_colors.dart';

class CoachInboxCard extends StatelessWidget {
  final ClientFlag flag;
  final VoidCallback onTap;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onNudge;
  final VoidCallback? onQuickCall;
  final VoidCallback? onReschedule;
  final VoidCallback? onParseLastReply;
  final VoidCallback? onMarkReviewed;
  final VoidCallback? onSavedReplies;

  const CoachInboxCard({
    super.key,
    required this.flag,
    required this.onTap,
    this.selectable = false,
    this.selected = false,
    this.onSelected,
    this.onNudge,
    this.onQuickCall,
    this.onReschedule,
    this.onParseLastReply,
    this.onMarkReviewed,
    this.onSavedReplies,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: selectable ? null : onTap,
      child: Container(
        key: ValueKey('inbox_card_${flag.clientId}'),
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with selection, avatar, name, and actions
            Row(
              children: [
                // Selection checkbox (if selectable)
                if (selectable) ...[
                  GestureDetector(
                    onTap: () => onSelected?.call(!selected),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: selected 
                              ? Theme.of(context).colorScheme.primary
                              : (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Avatar or placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                    ),
                  ),
                  child: flag.avatarUrl != null && flag.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            flag.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(isDark),
                          ),
                        )
                      : _buildAvatarPlaceholder(isDark),
                ),
                const SizedBox(width: 12),
                
                // Client name
                Expanded(
                  child: Text(
                    flag.clientName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Issue count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getSeverityColor(flag.issues.length).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getSeverityColor(flag.issues.length).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    '${flag.issues.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: getSeverityColor(flag.issues.length),
                      fontSize: 12,
                    ),
                  ),
                ),
                
                // Overflow menu (if not in selectable mode)
                if (!selectable) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'nudge':
                          onNudge?.call();
                          break;
                        case 'quick_call':
                          onQuickCall?.call();
                          break;
                        case 'reschedule':
                          onReschedule?.call();
                          break;
                        case 'parse_last_reply':
                          onParseLastReply?.call();
                          break;
                        case 'mark_reviewed':
                          onMarkReviewed?.call();
                          break;
                        case 'saved_replies':
                          onSavedReplies?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'nudge',
                        child: Row(
                          children: [
                            const Icon(Icons.touch_app_outlined, size: 16),
                            const SizedBox(width: 8),
                            Text('Nudge'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'quick_call',
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Quick Call'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reschedule',
                        child: Row(
                          children: [
                            Icon(Icons.schedule_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Reschedule'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'parse_last_reply',
                        child: Row(
                          children: [
                            Icon(Icons.smart_toy_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Parse Last Reply'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'mark_reviewed',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 16),
                            SizedBox(width: 8),
                            Text('Mark Reviewed'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'saved_replies',
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_outline, size: 16),
                            SizedBox(width: 8),
                            Text('Saved Replies'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // Issues list
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: flag.issues.map((issue) => _buildIssueChip(context, issue, isDark)).toList(),
            ),
            
            const SizedBox(height: 8),
            
            // Last update time
            Text(
              'Updated ${_formatLastUpdate(flag.lastUpdate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(bool isDark) {
    return Icon(
      Icons.person_outline,
      color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
      size: 20,
    );
  }

  Widget _buildIssueChip(BuildContext context, String issue, bool isDark) {
    final severity = getIssueSeverity(issue);
    final color = getSeverityColor(severity);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIssueIcon(issue),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            issue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  IconData _getIssueIcon(String issue) {
    switch (issue.toLowerCase()) {
      case 'check-in overdue':
        return Icons.schedule;
      case 'high negative kcal':
        return Icons.local_fire_department;
      case 'skipped sessions':
        return Icons.cancel_outlined;
      case 'low sleep':
        return Icons.bedtime;
      case 'low steps':
        return Icons.directions_walk;
      default:
        return Icons.warning_outlined;
    }
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
