import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final VoidCallback onVoice;
  final VoidCallback onCalendar;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttachment,
    required this.onVoice,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          top: BorderSide(
            color: tc.border,
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
            child: Row(
        children: [
          // Attachment Button
          IconButton(
            onPressed: onAttachment,
            icon: Icon(
              Icons.attach_file,
              color: tc.icon,
            ),
          ),
          
          // Voice Button
          IconButton(
            onPressed: onVoice,
            icon: Icon(
              Icons.mic,
              color: tc.icon,
            ),
          ),
          
          // Message Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: tc.inputFill,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: tc.border,
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
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: TextField(
                controller: controller,
                style: TextStyle(color: tc.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: tc.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: tc.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space16,
                    vertical: DesignTokens.space12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
            ),
          ),
          
          // Calendar Button
          IconButton(
            onPressed: onCalendar,
            icon: Icon(
              Icons.calendar_today,
              color: tc.icon,
            ),
          ),
          
          // Send Button
          Container(
            margin: const EdgeInsets.only(left: DesignTokens.space8),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: IconButton(
              onPressed: onSend,
              icon: Icon(
                Icons.send,
                color: tc.chipTextOnSelected,
              ),
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
