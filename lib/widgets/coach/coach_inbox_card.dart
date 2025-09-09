import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

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
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
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
              const Text(
                'Coach Inbox',
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
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${inboxItems.length}',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onBulkSelect,
                child: const Text(
                  'Bulk Select',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Inbox Items
          ...inboxItems.map((item) => _buildInboxItem(item)),
        ],
      ),
    );
  }

  Widget _buildInboxItem(Map<String, dynamic> item) {
    final status = item['status'] as String;
    final statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
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
                    Row(
                      children: [
                        Text(
                          item['clientName'],
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
                            status,
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
                      item['message'],
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Time
              Text(
                item['time'],
                style: const TextStyle(
                  color: AppTheme.lightGrey,
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
                  icon: Icons.chat_bubble_outline,
                  label: 'Msg',
                  onPressed: () => onMessage(item['id']),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.phone_outlined,
                  label: 'Call',
                  onPressed: () => onQuickCall(item['id']),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: _buildActionButton(
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
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.lightGrey,
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
        size: 14,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.neutralWhite,
          fontSize: 10,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.steelGrey,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return AppTheme.mintAqua;
      default:
        return AppTheme.steelGrey;
    }
  }
}
