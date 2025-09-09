import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.steelGrey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.neutralWhite,
            ),
          ),
          
          // Client Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.mintAqua,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  color: AppTheme.primaryBlack,
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
                    color: AppTheme.neutralWhite,
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
                        color: AppTheme.lightGrey,
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
              color: AppTheme.neutralWhite,
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: const Icon(
              Icons.phone,
              color: AppTheme.neutralWhite,
            ),
          ),
          IconButton(
            onPressed: onVideoCall,
            icon: const Icon(
              Icons.videocam,
              color: AppTheme.neutralWhite,
            ),
          ),
          IconButton(
            onPressed: onMoreOptions,
            icon: const Icon(
              Icons.more_vert,
              color: AppTheme.neutralWhite,
            ),
          ),
        ],
      ),
    );
  }
}
