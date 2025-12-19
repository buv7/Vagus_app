import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings/settings_controller.dart';
import '../../services/settings/reduce_motion.dart';
import '../../components/settings/theme_toggle.dart';
import '../../components/settings/language_selector.dart';
import '../../components/settings/reminder_defaults.dart';
import '../../widgets/settings/workout_popout_prefs_section.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import 'music_settings_screen.dart';
import 'google_integrations_screen.dart';
import 'earn_rewards_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  late SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    // Get the settings controller from the app
    _settingsController = SettingsController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsController.load();
    setState(() {});
  }

  Widget _buildModernCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius24),
        color: AppTheme.cardBackground.withValues(alpha: 0.7),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: AppTheme.accentGreen,
                      size: 24,
                    ),
                    const SizedBox(width: DesignTokens.space12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [
              AppTheme.primaryDark,
              AppTheme.primaryDark.withValues(alpha: 0.8),
              AppTheme.accentGreen.withValues(alpha: 0.1),
            ] : [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
              AppTheme.accentGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom glassmorphic app bar
              Container(
                margin: const EdgeInsets.all(DesignTokens.space16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  color: AppTheme.cardBackground.withValues(alpha: 0.7),
                  border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space16,
                        vertical: DesignTokens.space12,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: AppTheme.neutralWhite,
                              size: 20,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Settings',
                              style: TextStyle(
                                color: AppTheme.neutralWhite,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16, vertical: DesignTokens.space8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Theme Settings Card
            _buildModernCard(
              context: context,
              icon: Icons.palette,
              title: 'Theme',
              child: ThemeToggle(
                settingsController: _settingsController,
              ),
            ),

            // Language Settings Card
            _buildModernCard(
              context: context,
              icon: Icons.language,
              title: 'Language',
              child: LanguageSelector(
                settingsController: _settingsController,
              ),
            ),

            // Reminder Defaults Card
            _buildModernCard(
              context: context,
              icon: Icons.notifications,
              title: 'Reminder Defaults',
              child: ReminderDefaults(
                settingsController: _settingsController,
              ),
            ),

            // Reduce Motion Card
            _buildModernCard(
              context: context,
              icon: Icons.accessibility,
              title: 'Accessibility',
              child: SwitchListTile(
                title: const Text(
                  'Reduce Motion',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Use simpler effects to save battery or reduce motion',
                  style: TextStyle(color: Colors.white70),
                ),
                value: context.watch<ReduceMotion>().enabled,
                onChanged: (v) => context.read<ReduceMotion>().setEnabled(v),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(height: 16),

            // Workout Popout Defaults Card
            _buildModernCard(
              context: context,
              icon: Icons.fitness_center,
              title: 'Workout Preferences',
              child: const WorkoutPopoutPrefsSection(),
            ),

            // Music Settings Card
            _buildModernCard(
              context: context,
              icon: Icons.music_note,
              title: 'Music Integration',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure music app preferences and auto-open settings',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MusicSettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Music Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Google Integrations Card
            _buildModernCard(
              context: context,
              icon: Icons.cloud,
              title: 'Google Integration',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export data to Sheets and attach files from Drive',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoogleIntegrationsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Google (Sheets & Drive)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Earn Rewards Card
            _buildModernCard(
              context: context,
              icon: Icons.card_giftcard,
              title: 'Earn Rewards',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite friends and earn Pro days, VP points, and Shield progress',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EarnRewardsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.card_giftcard, size: 18),
                      label: const Text('Referrals & Rewards'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // AI Quotas Card
            _buildModernCard(
              context: context,
              icon: Icons.psychology,
              title: 'AI Usage & Quotas',
              child: const AIQuotasCard(),
            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI Quotas Card showing usage and limits
class AIQuotasCard extends StatelessWidget {
  const AIQuotasCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Monthly quota overview
        _buildQuotaItem(
          context,
          'Notes AI',
          currentUsage: 45,
          totalQuota: 100,
          icon: Icons.note,
        ),
        const SizedBox(height: 12),
        _buildQuotaItem(
          context,
          'Nutrition AI',
          currentUsage: 23,
          totalQuota: 50,
          icon: Icons.restaurant,
        ),
        const SizedBox(height: 12),
        _buildQuotaItem(
          context,
          'Workout AI',
          currentUsage: 67,
          totalQuota: 75,
          icon: Icons.fitness_center,
        ),
        const SizedBox(height: 12),
        _buildQuotaItem(
          context,
          'Messaging AI',
          currentUsage: 12,
          totalQuota: 200,
          icon: Icons.chat,
        ),
        const SizedBox(height: 12),
        _buildQuotaItem(
          context,
          'Transcription',
          currentUsage: 8,
          totalQuota: 25,
          icon: Icons.mic,
        ),
        const SizedBox(height: 16),
        
        // Manage button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to detailed AI quotas screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI Quotas management coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Manage in Admin (coming soon)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotaItem(
    BuildContext context,
    String feature,
    {
      required int currentUsage,
      required int totalQuota,
      required IconData icon,
    }
  ) {
    final percentage = currentUsage / totalQuota;
    final isWarning = percentage >= 0.8;
    final isDanger = percentage >= 0.95;
    
    Color progressColor;
    if (isDanger) {
      progressColor = Colors.red;
    } else if (isWarning) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                feature,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$currentUsage/$totalQuota',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 4,
        ),
        if (isWarning) ...[
          const SizedBox(height: 4),
          Text(
            isDanger ? '⚠️ Almost at limit!' : '⚠️ Getting close to limit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: progressColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
