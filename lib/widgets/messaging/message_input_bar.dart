import 'package:flutter/material.dart';
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
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppTheme.neutralWhite),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: const TextStyle(color: AppTheme.lightGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.primaryBlack,
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
              color: AppTheme.mintAqua,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: IconButton(
              onPressed: onSend,
              icon: const Icon(
                Icons.send,
                color: AppTheme.primaryBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
