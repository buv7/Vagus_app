import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class SmartRepliesPanel extends StatelessWidget {
  final Function(String) onReplySelected;

  const SmartRepliesPanel({
    super.key,
    required this.onReplySelected,
  });

  @override
  Widget build(BuildContext context) {
    final smartReplies = [
      'Great job! Keep up the excellent work 💪',
      'Let\'s schedule a check-in session to review your progress',
      'That\'s exactly what we want to see! Well done',
      'I\'ll adjust your plan based on this feedback',
      'Can you send me a form video for the next session?',
    ];

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.steelGrey,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: AppTheme.mintAqua,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              const Text(
                'Smart Replies',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space12),
          
          // Reply Buttons
          Wrap(
            spacing: DesignTokens.space8,
            runSpacing: DesignTokens.space8,
            children: smartReplies.map((reply) {
              return GestureDetector(
                onTap: () => onReplySelected(reply),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    border: Border.all(
                      color: AppTheme.steelGrey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    reply,
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
