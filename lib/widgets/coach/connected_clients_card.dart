import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class ConnectedClientsCard extends StatelessWidget {
  final List<Map<String, dynamic>> clients;
  final VoidCallback onViewAll;
  final Function(Map<String, dynamic>) onWeeklyReview;
  final Function(Map<String, dynamic>) onMessage;
  final Function(Map<String, dynamic>) onNotes;

  const ConnectedClientsCard({
    super.key,
    required this.clients,
    required this.onViewAll,
    required this.onWeeklyReview,
    required this.onMessage,
    required this.onNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
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
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              const Text(
                'Connected Clients',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  '${clients.length}',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Clients List
          if (clients.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.space32),
                child: Text(
                  'No clients connected yet',
                  style: TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ...clients.take(3).map((client) => _buildClientItem(client)),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientItem(Map<String, dynamic> client) {
    final isActive = client['status'] == 'active';
    final statusColor = isActive ? Colors.green : AppTheme.mediumGrey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                    Row(
                      children: [
                        Text(
                          client['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: AppTheme.neutralWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space8,
                            vertical: DesignTokens.space4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Paused',
                            style: const TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      client['email'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      '${client['program'] ?? 'General Training'} • Last active: ${client['lastActive'] ?? 'Unknown'}',
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space12),
          
          // Action Buttons
          Row(
            children: [
              _buildActionButton(
                icon: Icons.calendar_today_outlined,
                label: 'Weekly Review',
                onPressed: () => onWeeklyReview(client),
              ),
              const SizedBox(width: DesignTokens.space8),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Message',
                onPressed: () => onMessage(client),
              ),
              const SizedBox(width: DesignTokens.space8),
              _buildActionButton(
                icon: Icons.note_outlined,
                label: 'Notes',
                onPressed: () => onNotes(client),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: AppTheme.neutralWhite,
        size: 16,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.neutralWhite,
          fontSize: 12,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.mediumGrey,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
        ),
      ),
    );
  }
}
