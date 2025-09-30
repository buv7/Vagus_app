import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentGreen.withValues(alpha: 0.3),
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
          // Back Button
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back,
              color: DesignTokens.neutralWhite,
            ),
          ),
          
          // Client Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  color: AppTheme.primaryDark,
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
                  style: const TextStyle(
                    color: DesignTokens.neutralWhite,
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
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
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
            icon: const Icon(
              Icons.search,
              color: DesignTokens.neutralWhite,
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: const Icon(
              Icons.phone,
              color: DesignTokens.neutralWhite,
            ),
          ),
          IconButton(
            onPressed: onVideoCall,
            icon: const Icon(
              Icons.videocam,
              color: DesignTokens.neutralWhite,
            ),
          ),
          IconButton(
            onPressed: onMoreOptions,
            icon: const Icon(
              Icons.more_vert,
              color: DesignTokens.neutralWhite,
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
