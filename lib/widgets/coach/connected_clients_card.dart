import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';

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
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tc.border,
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
              Text(
                'Connected Clients',
                style: TextStyle(
                  color: tc.textPrimary,
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
                  color: tc.chipBg,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  '${clients.length}',
                  style: TextStyle(
                    color: tc.textPrimary,
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space32),
                child: Text(
                  'No clients connected yet',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ...clients.take(3).map((client) => _buildClientItem(context, client)),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientItem(BuildContext context, Map<String, dynamic> client) {
    final tc = ThemeColors.of(context);
    final isActive = client['status'] == 'active';
    final statusColor = isActive ? Colors.green : tc.chipBg;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surfaceAlt,
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
                child: Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      color: tc.textPrimary,
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
                          style: TextStyle(
                            color: tc.textPrimary,
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
                            style: TextStyle(
                              color: tc.textPrimary,
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
                      style: TextStyle(
                        color: tc.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      '${client['program'] ?? 'General Training'} • Last active: ${client['lastActive'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: tc.textSecondary,
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
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Weekly Review',
                  onPressed: () => onWeeklyReview(client),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  label: 'Message',
                  onPressed: () => onMessage(client),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.note_outlined,
                  label: 'Notes',
                  onPressed: () => onNotes(client),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final tc = ThemeColors.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: tc.icon,
        size: 16,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: tc.textPrimary,
          fontSize: 12,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: tc.surfaceAlt,
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
