import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

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
            child: Row(
        children: [
          // Attachment Button
          IconButton(
            onPressed: onAttachment,
            icon: const Icon(
              Icons.attach_file,
              color: AppTheme.lightGrey,
            ),
          ),
          
          // Voice Button
          IconButton(
            onPressed: onVoice,
            icon: const Icon(
              Icons.mic,
              color: AppTheme.lightGrey,
            ),
          ),
          
          // Message Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.cardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
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
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: TextField(
                controller: controller,
                style: const TextStyle(color: DesignTokens.neutralWhite),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: const TextStyle(color: DesignTokens.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: DesignTokens.cardBackground,
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
            icon: const Icon(
              Icons.calendar_today,
              color: AppTheme.lightGrey,
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
              icon: const Icon(
                Icons.send,
                color: AppTheme.primaryDark,
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
