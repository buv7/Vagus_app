import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class ClientManagementHeader extends StatelessWidget {
  final VoidCallback onAddClient;

  const ClientManagementHeader({
    super.key,
    required this.onAddClient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client Management',
                      style: TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    const Text(
                      'Manage and track your client progress',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAddClient,
                icon: const Icon(
                  Icons.add,
                  color: AppTheme.primaryBlack,
                  size: 20,
                ),
                label: const Text(
                  'Add Client',
                  style: TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mintAqua,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space20,
                    vertical: DesignTokens.space12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
