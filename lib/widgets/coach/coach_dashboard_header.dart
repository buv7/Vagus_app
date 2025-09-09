import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class CoachDashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onSettings;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;

  const CoachDashboardHeader({
    super.key,
    required this.profile,
    required this.onSettings,
    required this.onNotifications,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?['name'] ?? 'Coach';
    final isPro = profile?['is_pro'] ?? false;
    final streak = profile?['streak'] ?? 12;

    return Row(
      children: [
        // Profile Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.mintAqua,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          child: const Center(
            child: Text(
              'V',
              style: TextStyle(
                color: AppTheme.primaryBlack,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: DesignTokens.space16),
        
        // Welcome Message
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $name',
                style: const TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              const Text(
                'Ready to help your clients achieve their goals?',
                style: TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Badges
              Row(
                children: [
                  if (isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space12,
                        vertical: DesignTokens.space6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.softYellow,
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      ),
                      child: const Text(
                        'Pro Coach',
                        style: TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  
                  if (isPro) const SizedBox(width: DesignTokens.space8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space12,
                      vertical: DesignTokens.space6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.steelGrey,
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: Text(
                      '$streak Day Streak',
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Action Buttons
        Row(
          children: [
            // Notifications
            Stack(
              children: [
                IconButton(
                  onPressed: onNotifications,
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.neutralWhite,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Settings
            IconButton(
              onPressed: onSettings,
              icon: const Icon(
                Icons.settings_outlined,
                color: AppTheme.neutralWhite,
                size: 24,
              ),
            ),
            
            // Logout
            IconButton(
              onPressed: onLogout,
              icon: const Icon(
                Icons.logout_outlined,
                color: AppTheme.neutralWhite,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
