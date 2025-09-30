import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../screens/workout/modern_plan_builder_screen.dart';
import '../../screens/nutrition/nutrition_hub_screen.dart';
import '../../screens/nutrition/coach_nutrition_dashboard.dart';
import '../../screens/messaging/coach_threads_screen.dart';
import '../../screens/analytics/analytics_reports_screen.dart';
import '../../screens/calendar/availability_publisher.dart';
import '../../screens/coach/intake_form_builder_screen.dart';
import '../../widgets/coach/quick_action_sheets.dart';

class QuickActionsGrid extends StatefulWidget {
  final VoidCallback? onImportProgram;

  const QuickActionsGrid({
    super.key,
    this.onImportProgram,
  });

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> {
  int _unreadMessages = 0;
  bool _hasActiveClients = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // In a real app, fetch unread count from messaging service
      // For now, simulate with random data
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _unreadMessages = 3; // Mock unread count
          _hasActiveClients = true; // Mock active clients
        });
      }
    } catch (e) {
      // Error handling - could show a toast or error state
      debugPrint('Failed to fetch dashboard data: $e');
    }
  }

  void _onActionTap() {
    HapticFeedback.lightImpact();
  }

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
          const Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              SizedBox(width: DesignTokens.space8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space20),

          // Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: DesignTokens.space16,
            mainAxisSpacing: DesignTokens.space16,
            childAspectRatio: 1.1,
            children: [
              _buildActionCard(
                icon: Icons.fitness_center_outlined,
                title: 'New Workout Plan',
                subtitle: 'Create a custom workout plan',
                onTap: () => _navigateToWorkoutCreation(context),
                color: AppTheme.accentGreen,
              ),
              _buildActionCard(
                icon: Icons.restaurant_outlined,
                title: 'Nutrition Plans',
                subtitle: 'View & manage nutrition',
                onTap: () => _navigateToNutritionDashboard(context),
                color: AppTheme.accentOrange,
              ),
              _buildActionCard(
                icon: Icons.note_add_outlined,
                title: 'Add Coach Note',
                subtitle: 'Quick note for a client',
                onTap: () => _showAddNoteBottomSheet(context),
                color: AppTheme.lightGrey,
                disabled: !_hasActiveClients,
              ),
              _buildActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Open Messages',
                subtitle: 'View client conversations',
                onTap: () => _navigateToMessages(context),
                color: AppTheme.accentOrange,
                badge: _unreadMessages > 0 ? _unreadMessages.toString() : null,
              ),
              _buildActionCard(
                icon: Icons.medical_services_outlined,
                title: 'Add Supplement',
                subtitle: 'Add supplement to client plan',
                onTap: () => _showAddSupplementBottomSheet(context),
                color: AppTheme.accentGreen,
                disabled: !_hasActiveClients,
              ),
              _buildActionCard(
                icon: Icons.folder_special_outlined,
                title: 'Templates',
                subtitle: 'Manage plan templates',
                onTap: () => _navigateToTemplates(context),
                color: AppTheme.lightGrey,
              ),
              _buildActionCard(
                icon: Icons.assignment_outlined,
                title: 'Intake Forms',
                subtitle: 'Manage client intake forms',
                onTap: () => _navigateToIntakeForms(context),
                color: AppTheme.accentGreen,
              ),
              _buildActionCard(
                icon: Icons.calendar_today_outlined,
                title: 'Publish Availability',
                subtitle: 'Set your available time slots',
                onTap: () => _navigateToAvailability(context),
                color: AppTheme.lightGrey,
              ),
              _buildActionCard(
                icon: Icons.analytics_outlined,
                title: 'View Analytics',
                subtitle: 'View performance metrics',
                onTap: () => _navigateToAnalytics(context),
                color: AppTheme.accentOrange,
              ),
              _buildActionCard(
                icon: Icons.upload_outlined,
                title: 'Import Program',
                subtitle: 'Import workout program',
                onTap: () => _showImportBottomSheet(context),
                color: AppTheme.accentGreen,
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

  // Navigation methods
  void _navigateToWorkoutCreation(BuildContext context) {
    _onActionTap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ModernPlanBuilderScreen()),
    );
  }

  void _navigateToNutritionCreation(BuildContext context) {
    _onActionTap();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NutritionHubScreen(mode: NutritionHubMode.builder),
      ),
    );
  }

  void _navigateToNutritionDashboard(BuildContext context) {
    _onActionTap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachNutritionDashboard()),
    );
  }

  void _navigateToMessages(BuildContext context) {
    _onActionTap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachThreadsScreen()),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    _onActionTap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalyticsReportsScreen()),
    );
  }

  void _navigateToAvailability(BuildContext context) {
    _onActionTap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AvailabilityPublisher()),
    );
  }

  void _navigateToIntakeForms(BuildContext context) {
    _onActionTap();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IntakeFormBuilderScreen()),
    );
  }

  void _navigateToTemplates(BuildContext context) {
    _onActionTap();
    // For now, show a coming soon dialog
    _showComingSoonDialog(context, 'Template Management');
  }

  // Bottom sheet methods
  void _showAddNoteBottomSheet(BuildContext context) {
    _onActionTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCoachNoteBottomSheet(),
    );
  }

  void _showAddSupplementBottomSheet(BuildContext context) {
    _onActionTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSupplementBottomSheet(),
    );
  }

  void _showImportBottomSheet(BuildContext context) {
    _onActionTap();
    if (widget.onImportProgram != null) {
      widget.onImportProgram!();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ImportProgramBottomSheet(),
      );
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.construction, color: AppTheme.accentOrange, size: 24),
            const SizedBox(width: 12),
            Text(
              'Coming Soon',
              style: TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '$feature is currently under development. Stay tuned for updates!',
          style: TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: AppTheme.accentGreen,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    String? badge,
    bool disabled = false,
  }) {
    // Determine glow color based on card type
    final Color glowColor = _getGlowColor(color);

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: disabled
            ? DesignTokens.cardBackground.withValues(alpha: 0.5)
            : DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: disabled ? 0.05 : 0.1),
            width: 1,
          ),
          boxShadow: [
            if (!disabled)
              BoxShadow(
                color: glowColor,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: disabled ? color.withValues(alpha: 0.4) : color,
                        size: 24,
                      ),
                      const Spacer(),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space12),
                  Text(
                    title,
                    style: TextStyle(
                      color: disabled
                        ? DesignTokens.neutralWhite.withValues(alpha: 0.4)
                        : DesignTokens.neutralWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    disabled ? 'Requires active clients' : subtitle,
                    style: TextStyle(
                      color: disabled
                        ? DesignTokens.textSecondary.withValues(alpha: 0.6)
                        : DesignTokens.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getGlowColor(Color iconColor) {
    if (iconColor == AppTheme.accentGreen) {
      return DesignTokens.accentGreen.withValues(alpha: 0.2);
    } else if (iconColor == AppTheme.accentOrange) {
      return DesignTokens.accentOrange.withValues(alpha: 0.2);
    } else {
      return DesignTokens.accentBlue.withValues(alpha: 0.2);
    }
  }
}