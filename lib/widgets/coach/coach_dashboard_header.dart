import 'package:flutter/material.dart';
import 'dart:ui';
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
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.accentGreen.withValues(alpha: 0.3),
                      DesignTokens.accentBlue.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      color: DesignTokens.neutralWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                style: DesignTokens.titleMedium.copyWith(
                  color: DesignTokens.neutralWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                'Ready to help your clients achieve their goals?',
                style: DesignTokens.bodyMedium.copyWith(
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Badges
              Row(
                children: [
                  if (isPro)
                    Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.space12,
                              vertical: DesignTokens.space6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  DesignTokens.accentOrange.withValues(alpha: 0.3),
                                  DesignTokens.accentPink.withValues(alpha: 0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Text(
                              'Pro Coach',
                              style: DesignTokens.labelSmall.copyWith(
                                color: DesignTokens.neutralWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  if (isPro) const SizedBox(width: DesignTokens.space8),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: DesignTokens.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space12,
                            vertical: DesignTokens.space6,
                          ),
                          child: Text(
                            '$streak Day Streak',
                            style: DesignTokens.labelSmall.copyWith(
                              color: DesignTokens.neutralWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                    color: DesignTokens.neutralWhite,
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
                          color: DesignTokens.neutralWhite,
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
