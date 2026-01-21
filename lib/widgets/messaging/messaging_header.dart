import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';

class MessagingHeader extends StatelessWidget {
  final Map<String, dynamic> client;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final VoidCallback onMoreOptions;

  const MessagingHeader({
    super.key,
    required this.client,
    required this.onBack,
    required this.onSearch,
    required this.onCall,
    required this.onVideoCall,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          bottom: BorderSide(
            color: tc.border,
            width: 1,
          ),
        ),
        boxShadow: tc.cardShadow,
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back,
              color: tc.icon,
            ),
          ),
          
          // Client Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tc.accent,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: Center(
              child: Text(
                (client['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: tc.textOnDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: DesignTokens.space12),
          
          // Client Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client['name'] ?? 'Unknown',
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tc.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space4),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: tc.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          IconButton(
            onPressed: onSearch,
            icon: Icon(
              Icons.search,
              color: tc.icon,
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: Icon(
              Icons.phone,
              color: tc.icon,
            ),
          ),
          IconButton(
            onPressed: onVideoCall,
            icon: Icon(
              Icons.videocam,
              color: tc.icon,
            ),
          ),
          IconButton(
            onPressed: onMoreOptions,
            icon: Icon(
              Icons.more_vert,
              color: tc.icon,
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
