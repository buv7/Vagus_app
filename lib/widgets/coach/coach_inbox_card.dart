import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';

class CoachInboxCard extends StatelessWidget {
  final List<Map<String, dynamic>> inboxItems;
  final VoidCallback onBulkSelect;
  final Function(String) onMessage;
  final Function(String) onQuickCall;
  final Function(String) onMarkReviewed;

  const CoachInboxCard({
    super.key,
    required this.inboxItems,
    required this.onBulkSelect,
    required this.onMessage,
    required this.onQuickCall,
    required this.onMarkReviewed,
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
                Icons.warning_amber_outlined,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'Coach Inbox',
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
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${inboxItems.length}',
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onBulkSelect,
                child: Text(
                  'Bulk Select',
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Inbox Items
          ...inboxItems.map((item) => _buildInboxItem(context, item)),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInboxItem(BuildContext context, Map<String, dynamic> item) {
    final tc = ThemeColors.of(context);
    final status = item['status'] as String;
    final statusColor = _getStatusColor(context, status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tc.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentGreen.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 4,
                ),
              ),
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
                          item['clientName'],
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
                            status,
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
                      item['message'],
                      style: TextStyle(
                        color: tc.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Time
              Text(
                item['time'],
                style: TextStyle(
                  color: tc.textSecondary,
                  fontSize: 12,
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
                  icon: Icons.chat_bubble_outline,
                  label: 'Msg',
                  onPressed: () => onMessage(item['id']),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.phone_outlined,
                  label: 'Call',
                  onPressed: () => onQuickCall(item['id']),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.check_outlined,
                  label: 'Done',
                  onPressed: () => onMarkReviewed(item['id']),
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              IconButton(
                onPressed: () {
                  // Handle delete
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: tc.icon,
                  size: 16,
                ),
                padding: const EdgeInsets.all(DesignTokens.space4),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ],
            ),
          ),
        ),
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
        size: 14,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: tc.textPrimary,
          fontSize: 10,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: tc.surfaceAlt,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space8,
          vertical: DesignTokens.space4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    final tc = ThemeColors.of(context);
    switch (status.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return AppTheme.accentGreen;
      default:
        return tc.chipBg;
    }
  }
}
