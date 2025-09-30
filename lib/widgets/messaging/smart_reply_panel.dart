import 'package:flutter/material.dart';

class SmartReplyPanel extends StatelessWidget {
  final List<String> drafts;
  final Function(String) onDraftTap;
  final Function(String) onDraftLongPress;
  final VoidCallback? onDismiss;

  const SmartReplyPanel({
    super.key,
    required this.drafts,
    required this.onDraftTap,
    required this.onDraftLongPress,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with dismiss button
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Smart Replies',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Draft reply pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: drafts.map((draft) => _buildDraftPill(
              context,
              draft,
              isDark,
              onDraftTap,
              onDraftLongPress,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftPill(
    BuildContext context,
    String draft,
    bool isDark,
    Function(String) onTap,
    Function(String) onLongPress,
  ) {
    // Get first 6 words for accessibility label
    final preview = draft.split(' ').take(6).join(' ');
    final accessibilityLabel = 'Insert smart reply: $preview';
    
    return Semantics(
      label: accessibilityLabel,
      hint: 'Double tap to insert this smart reply, long press for more options',
      button: true,
      child: GestureDetector(
        onTap: () => onTap(draft),
        onLongPress: () => onLongPress(draft),
        child: Tooltip(
          message: accessibilityLabel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.reply_outlined,
                  size: 14,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    draft,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
