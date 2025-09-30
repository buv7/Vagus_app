import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class MessageListView extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;

  const MessageListView({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(DesignTokens.space16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(context, message);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message) {
    final isFromClient = message['isFromClient'] as bool;
    final content = message['content'] as String;
    final timestamp = message['timestamp'] as DateTime;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Row(
        mainAxisAlignment: isFromClient ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isFromClient) ...[
            // Client Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentGreen,
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: const Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space8),
          ],
          
          // Message Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space12,
              ),
              decoration: BoxDecoration(
                color: isFromClient ? AppTheme.cardBackground : AppTheme.accentGreen,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(DesignTokens.radius12),
                  topRight: const Radius.circular(DesignTokens.radius12),
                  bottomLeft: Radius.circular(isFromClient ? 4 : DesignTokens.radius12),
                  bottomRight: Radius.circular(isFromClient ? DesignTokens.radius12 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isFromClient ? AppTheme.neutralWhite : AppTheme.primaryDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    DateFormat('HH:mm').format(timestamp),
                    style: TextStyle(
                      color: isFromClient ? AppTheme.lightGrey : AppTheme.primaryDark.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (!isFromClient) ...[
            const SizedBox(width: DesignTokens.space8),
            // Coach Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.mediumGrey,
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: const Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
