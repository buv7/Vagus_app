import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings/settings_controller.dart';
import '../../services/settings/reduce_motion.dart';
import '../../components/settings/theme_toggle.dart';
import '../../components/settings/language_selector.dart';
import '../../components/settings/reminder_defaults.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../widgets/settings/WorkoutPopoutPrefsSection.dart';
import '../../theme/app_theme.dart';
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
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Settings Card
            _buildModernCard(
              icon: Icons.palette,
              title: 'Theme',
              child: ThemeToggle(
                settingsController: _settingsController,
              ),
            ),

            // Language Settings Card
            _buildModernCard(
              icon: Icons.language,
              title: 'Language',
              child: LanguageSelector(
                settingsController: _settingsController,
              ),
            ),

            // Reminder Defaults Card
            _buildModernCard(
              icon: Icons.notifications,
              title: 'Reminder Defaults',
              child: ReminderDefaults(
                settingsController: _settingsController,
              ),
            ),

            // Reduce Motion Card
            _buildModernCard(
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
                activeColor: AppTheme.mintAqua,
              ),
            ),
            const SizedBox(height: 16),

            // Workout Popout Defaults Card
            _buildModernCard(
              icon: Icons.fitness_center,
              title: 'Workout Preferences',
              child: const WorkoutPopoutPrefsSection(),
            ),

            // Music Settings Card
            _buildModernCard(
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
                        backgroundColor: AppTheme.mintAqua,
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
                        backgroundColor: AppTheme.mintAqua,
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
                        backgroundColor: AppTheme.mintAqua,
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
              icon: Icons.psychology,
              title: 'AI Usage & Quotas',
              child: const AIQuotasCard(),
            ),
          ],
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
