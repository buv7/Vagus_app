import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/notifications/fcm_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

/// Per-category notification preferences.
///
/// Categories that are ON by default: workouts, nutrition_reminders,
/// coach_messages, periods, streaks, lab_results.
/// Marketing (marketplace) is OFF by default — matches SIGNAL FORBIDDEN rule.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  // Category toggles — default ON except marketplace.
  final Map<NotificationCategory, bool> _prefs = {
    NotificationCategory.workouts: true,
    NotificationCategory.nutritionReminders: true,
    NotificationCategory.coachMessages: true,
    NotificationCategory.marketplace: false,
    NotificationCategory.periods: true,
    NotificationCategory.streaks: true,
    NotificationCategory.labResults: true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final rows = await _supabase
          .from('notification_preferences')
          .select('category, enabled')
          .eq('user_id', user.id);

      for (final row in rows as List<dynamic>) {
        final cat = NotificationCategory.fromString(row['category'] as String?);
        if (cat != null) {
          _prefs[cat] = row['enabled'] as bool? ?? true;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NotifPrefs] Load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final rows = _prefs.entries
          .map((e) => {
                'user_id': user.id,
                'category': e.key.value,
                'enabled': e.value,
                'updated_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabase
          .from('notification_preferences')
          .upsert(rows, onConflict: 'user_id,category');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTestPush() async {
    final ok = await FcmService.instance.sendTestPush();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Test push sent — check your device' : 'Failed to send test push'),
        backgroundColor: ok ? AppTheme.accentGreen : DesignTokens.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications',
            style: TextStyle(color: AppTheme.neutralWhite)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Activity & Training'),
                  const SizedBox(height: DesignTokens.space12),
                  _tile(
                    category: NotificationCategory.workouts,
                    label: 'Workout Reminders',
                    subtitle: 'Plans assigned, reminders, PR celebrations',
                    icon: Icons.fitness_center,
                  ),
                  _tile(
                    category: NotificationCategory.streaks,
                    label: 'Streak Reminders',
                    subtitle: 'Daily prompts to keep your streak alive',
                    icon: Icons.local_fire_department,
                  ),
                  const SizedBox(height: DesignTokens.space24),
                  _sectionTitle('Health & Nutrition'),
                  const SizedBox(height: DesignTokens.space12),
                  _tile(
                    category: NotificationCategory.nutritionReminders,
                    label: 'Nutrition Reminders',
                    subtitle: 'Meal logging prompts and hydration nudges',
                    icon: Icons.restaurant,
                  ),
                  _tile(
                    category: NotificationCategory.periods,
                    label: 'Cycle & Periods',
                    subtitle: 'Cycle phase updates and period reminders',
                    icon: Icons.favorite,
                  ),
                  _tile(
                    category: NotificationCategory.labResults,
                    label: 'Lab Results',
                    subtitle: 'Notified when new results are available',
                    icon: Icons.science,
                  ),
                  const SizedBox(height: DesignTokens.space24),
                  _sectionTitle('Coaching & Messages'),
                  const SizedBox(height: DesignTokens.space12),
                  _tile(
                    category: NotificationCategory.coachMessages,
                    label: 'Coach Messages',
                    subtitle: 'Direct messages, plan updates, coach feedback',
                    icon: Icons.chat_bubble,
                  ),
                  const SizedBox(height: DesignTokens.space24),
                  _sectionTitle('Marketplace'),
                  const SizedBox(height: DesignTokens.space12),
                  _tile(
                    category: NotificationCategory.marketplace,
                    label: 'Marketplace Updates',
                    subtitle: 'New coaches, promotions, featured content',
                    icon: Icons.storefront,
                  ),
                  const SizedBox(height: DesignTokens.space32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _sendTestPush,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Test Notification'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.space16),
                        side: const BorderSide(color: AppTheme.accentGreen),
                        foregroundColor: AppTheme.accentGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radius12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space20),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.lightGrey,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _tile({
    required NotificationCategory category,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: AppTheme.mediumGrey),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
        leading: Icon(icon, color: AppTheme.accentGreen),
        title: Text(label,
            style: const TextStyle(
                color: AppTheme.neutralWhite, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppTheme.lightGrey, fontSize: 12)),
        trailing: Switch(
          value: _prefs[category] ?? true,
          onChanged: (v) => setState(() => _prefs[category] = v),
          activeColor: AppTheme.accentGreen,
          activeTrackColor: AppTheme.accentGreen.withValues(alpha: 0.3),
          inactiveThumbColor: AppTheme.lightGrey,
          inactiveTrackColor: AppTheme.mediumGrey,
        ),
      ),
    );
  }
}
