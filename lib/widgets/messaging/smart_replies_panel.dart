import 'package:flutter/material.dart';
import 'dart:ui';
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
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: AppTheme.accentGreen,
                size: 16,
              ),
              SizedBox(width: DesignTokens.space8),
              Text(
                'Smart Replies',
                style: TextStyle(
                  color: DesignTokens.neutralWhite,
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
                  decoration: BoxDecoration(
                    color: DesignTokens.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space12,
                          vertical: DesignTokens.space8,
                        ),
                        child: Text(
                    reply,
                    style: const TextStyle(
                      color: DesignTokens.neutralWhite,
                      fontSize: 12,
                    ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}
