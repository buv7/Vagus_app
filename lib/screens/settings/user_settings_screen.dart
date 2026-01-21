import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings/settings_controller.dart';
import '../../services/settings/reduce_motion.dart';
import '../../components/settings/theme_toggle.dart';
import '../../components/settings/language_selector.dart';
import '../../components/settings/reminder_defaults.dart';
import '../../widgets/settings/workout_popout_prefs_section.dart';
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

  /// Glassmorphic card matching the FAB style with blue accent
  Widget _buildGlassmorphicCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        // Glassmorphic gradient matching FAB
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 2.0,
          colors: [
            DesignTokens.accentBlue.withValues(alpha: 0.25),
            DesignTokens.accentBlue.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: DesignTokens.space12),
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
                const SizedBox(height: DesignTokens.space16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Glassmorphic button matching FAB action button style
  Widget _buildGlassmorphicButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 2.0,
          colors: [
            DesignTokens.accentBlue.withValues(alpha: 0.3),
            DesignTokens.accentBlue.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentBlue.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220), // Dark background matching FAB context
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B1220),
              const Color(0xFF0B1220).withValues(alpha: 0.9),
              DesignTokens.accentBlue.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Glassmorphic app bar matching FAB style
              Container(
                margin: const EdgeInsets.all(DesignTokens.space16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 2.0,
                    colors: [
                      DesignTokens.accentBlue.withValues(alpha: 0.25),
                      DesignTokens.accentBlue.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Settings',
                              style: TextStyle(
                                color: Colors.white,
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
                      _buildGlassmorphicCard(
                        context: context,
                        icon: Icons.palette,
                        title: 'Theme',
                        child: ThemeToggle(
                          settingsController: _settingsController,
                        ),
                      ),

                      // Language Settings Card
                      _buildGlassmorphicCard(
                        context: context,
                        icon: Icons.language,
                        title: 'Language',
                        child: LanguageSelector(
                          settingsController: _settingsController,
                        ),
                      ),

                      // Reminder Defaults Card
                      _buildGlassmorphicCard(
                        context: context,
                        icon: Icons.notifications,
                        title: 'Reminder Defaults',
                        child: ReminderDefaults(
                          settingsController: _settingsController,
                        ),
                      ),

                      // Reduce Motion Card
                      _buildGlassmorphicCard(
                        context: context,
                        icon: Icons.accessibility,
                        title: 'Accessibility',
                        child: SwitchListTile(
                          title: const Text(
                            'Reduce Motion',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Use simpler effects to save battery or reduce motion',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                          ),
                          value: context.watch<ReduceMotion>().enabled,
                          onChanged: (v) => context.read<ReduceMotion>().setEnabled(v),
                          contentPadding: EdgeInsets.zero,
                          activeColor: DesignTokens.accentBlue,
                          activeTrackColor: DesignTokens.accentBlue.withValues(alpha: 0.4),
                        ),
                      ),

                      // Workout Popout Defaults Card
                      _buildGlassmorphicCard(
                        context: context,
                        icon: Icons.fitness_center,
                        title: 'Workout Preferences',
                        child: const WorkoutPopoutPrefsSection(),
                      ),

                      // Music Settings Card
                      _buildGlassmorphicCard(
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
                            _buildGlassmorphicButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MusicSettingsScreen(),
                                  ),
                                );
                              },
                              icon: Icons.settings,
                              label: 'Music Settings',
                            ),
                          ],
                        ),
                      ),

                      // Google Integrations Card
                      _buildGlassmorphicCard(
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
                            _buildGlassmorphicButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GoogleIntegrationsScreen(),
                                  ),
                                );
                              },
                              icon: Icons.settings,
                              label: 'Google (Sheets & Drive)',
                            ),
                          ],
                        ),
                      ),

                      // Earn Rewards Card
                      _buildGlassmorphicCard(
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
                            _buildGlassmorphicButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EarnRewardsScreen(),
                                  ),
                                );
                              },
                              icon: Icons.card_giftcard,
                              label: 'Referrals & Rewards',
                            ),
                          ],
                        ),
                      ),

                      // AI Quotas Card
                      _buildGlassmorphicCard(
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

/// AI Quotas Card showing usage and limits - matching FAB glassmorphic style
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
        
        // Manage button - glassmorphic style
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('AI Quotas management coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 18, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'Manage in Admin (coming soon)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
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
      progressColor = Colors.redAccent;
    } else if (isWarning) {
      progressColor = Colors.orangeAccent;
    } else {
      progressColor = DesignTokens.accentBlue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                feature,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$currentUsage/$totalQuota',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: progressColor,
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isWarning) ...[
          const SizedBox(height: 4),
          Text(
            isDanger ? '⚠️ Almost at limit!' : '⚠️ Getting close to limit',
            style: TextStyle(
              color: progressColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
