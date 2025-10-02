import 'package:flutter/material.dart';
import '../../models/notifications/workout_notification_types.dart';
// OneSignal service archived - no longer in use
// import '../../services/notifications/onesignal_service.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification preferences screen
///
/// Allows users to configure:
/// - Workout reminder times
/// - Rest day reminders
/// - PR celebrations
/// - Coach feedback notifications
/// - Weekly summary settings
/// - Sound and vibration preferences
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  // OneSignal service archived - no longer in use
  // final _oneSignalService = OneSignalService.instance;
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  WorkoutNotificationPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // OneSignal service archived - load default preferences
      // final preferences =
      //     await _oneSignalService.getNotificationPreferences(userId);
      final preferences = WorkoutNotificationPreferences();

      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // OneSignal service archived - show message that feature is disabled
      // await _oneSignalService.saveNotificationPreferences(userId, _preferences!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Push notifications are currently disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleHelper.t('error_saving_preferences', 'en')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleHelper.t('notification_preferences', 'en')),
        actions: [
          if (!_isLoading && _preferences != null)
            TextButton(
              onPressed: _savePreferences,
              child: Text(
                LocaleHelper.t('save', 'en'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? Center(
                  child: Text(LocaleHelper.t('failed_to_load_preferences', 'en')),
                )
              : RefreshIndicator(
                  onRefresh: _loadPreferences,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Workout Reminders Section
                      _buildSectionHeader(
                        LocaleHelper.t('workout_reminders', 'en'),
                        Icons.fitness_center,
                      ),
                      _buildSwitchTile(
                        title: LocaleHelper.t('enable_workout_reminders', 'en'),
                        subtitle:
                            LocaleHelper.t('get_notified_before_workouts', 'en'),
                        value: _preferences!.workoutRemindersEnabled,
                        onChanged: (value) {
                          setState(() {
                            _preferences = _preferences!
                                .copyWith(workoutRemindersEnabled: value);
                          });
                        },
                      ),
                      if (_preferences!.workoutRemindersEnabled) ...[
                        _buildTimeSelector(
                          title: LocaleHelper.t('reminder_time', 'en'),
                          subtitle:
                              LocaleHelper.t('default_reminder_time', 'en'),
                          value: _preferences!.workoutReminderTime,
                          onChanged: (time) {
                            setState(() {
                              _preferences = _preferences!
                                  .copyWith(workoutReminderTime: time);
                            });
                          },
                        ),
                        _buildSliderTile(
                          title:
                              LocaleHelper.t('minutes_before_workout', 'en'),
                          subtitle: '${_preferences!.reminderMinutesBefore} ${LocaleHelper.t('minutes', 'en')}',
                          value: _preferences!.reminderMinutesBefore.toDouble(),
                          min: 0,
                          max: 120,
                          divisions: 12,
                          onChanged: (value) {
                            setState(() {
                              _preferences = _preferences!
                                  .copyWith(reminderMinutesBefore: value.toInt());
                            });
                          },
                        ),
                      ],
                      const Divider(height: 32),

                      // Rest Day Reminders
                      _buildSectionHeader(
                        LocaleHelper.t('rest_day_reminders', 'en'),
                        Icons.bedtime,
                      ),
                      _buildSwitchTile(
                        title: LocaleHelper.t('enable_rest_day_reminders', 'en'),
                        subtitle: LocaleHelper.t(
                            'motivational_messages_on_rest_days', 'en'),
                        value: _preferences!.restDayRemindersEnabled,
                        onChanged: (value) {
                          setState(() {
                            _preferences = _preferences!
                                .copyWith(restDayRemindersEnabled: value);
                          });
                        },
                      ),
                      const Divider(height: 32),

                      // Achievement Notifications
                      _buildSectionHeader(
                        LocaleHelper.t('achievements', 'en'),
                        Icons.emoji_events,
                      ),
                      _buildSwitchTile(
                        title: LocaleHelper.t('pr_celebrations', 'en'),
                        subtitle: LocaleHelper.t('celebrate_personal_records', 'en'),
                        value: _preferences!.prCelebrationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _preferences =
                                _preferences!.copyWith(prCelebrationEnabled: value);
                          });
                        },
                      ),
                      const Divider(height: 32),

                      // Coach Feedback
                      _buildSectionHeader(
                        LocaleHelper.t('coach_feedback', 'en'),
                        Icons.person,
                      ),
                      _buildSwitchTile(
                        title: LocaleHelper.t('enable_coach_feedback', 'en'),
                        subtitle: LocaleHelper.t('get_notified_coach_comments', 'en'),
                        value: _preferences!.coachFeedbackEnabled,
                        onChanged: (value) {
                          setState(() {
                            _preferences =
                                _preferences!.copyWith(coachFeedbackEnabled: value);
                          });
                        },
                      ),
                      const Divider(height: 32),

                      // Missed Workout
                      _buildSectionHeader(
                        LocaleHelper.t('missed_workouts', 'en'),
                        Icons.notification_important,
                      ),
                      _buildSwitchTile(
                        title: LocaleHelper.t('enable_missed_workout_reminders', 'en'),
                        subtitle: LocaleHelper.t(
                            'motivational_followup_missed_workouts', 'en'),
                        value: _preferences!.missedWorkoutEnabled,
                        onChanged: (value) {
                          setState(() {
                            _preferences =
                                _preferences!.copyWith(missedWorkoutEnabled: value);
                          });
                        },
                      ),
                      const Divider(height: 32),

                      // Weekly Summary
                      _buildSectionHeader(
                        LocaleHelper.t('weekly_summary', 'en'),
                        Icons.summarize,
                      ),
                      _buildSwitchTile(
                        title: LocaleHelper.t('enable_weekly_summary', 'en'),
                        subtitle:
                            LocaleHelper.t('get_weekly_progress_summary', 'en'),
                        value: _preferences!.weeklySummaryEnabled,
                        onChanged: (value) {
                          setState(() {
                            _preferences =
                                _preferences!.copyWith(weeklySummaryEnabled: value);
                          });
                        },
                      ),
                      if (_preferences!.weeklySummaryEnabled) ...[
                        _buildDropdownTile(
                          title: LocaleHelper.t('summary_day', 'en'),
                          value: _preferences!.weeklySummaryDay ?? 'Sunday',
                          items: [
                            'Sunday',
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday'
                          ],
                          onChanged: (value) {
                            setState(() {
                              _preferences =
                                  _preferences!.copyWith(weeklySummaryDay: value);
                            });
                          },
                        ),
                        _buildTimeSelector(
                          title: LocaleHelper.t('summary_time', 'en'),
                          subtitle: LocaleHelper.t('time_to_receive_summary', 'en'),
                          value: _preferences!.weeklySummaryTime,
                          onChanged: (time) {
                            setState(() {
                              _preferences =
                                  _preferences!.copyWith(weeklySummaryTime: time);
                            });
                          },
                        ),
                      ],
                      const Divider(height: 32),

                      // Sound & Vibration
                      _buildSectionHeader(
                        LocaleHelper.t('sound_vibration', 'en'),
                        Icons.volume_up,
                      ),
                      _buildSwitchTile(
                        title: LocaleHelper.t('sound', 'en'),
                        subtitle: LocaleHelper.t('play_notification_sound', 'en'),
                        value: _preferences!.soundEnabled,
                        onChanged: (value) {
                          setState(() {
                            _preferences = _preferences!.copyWith(soundEnabled: value);
                          });
                        },
                      ),
                      _buildSwitchTile(
                        title: LocaleHelper.t('vibration', 'en'),
                        subtitle: LocaleHelper.t('vibrate_on_notifications', 'en'),
                        value: _preferences!.vibrationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _preferences =
                                _preferences!.copyWith(vibrationEnabled: value);
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Test Notification Button
                      OutlinedButton.icon(
                        onPressed: _sendTestNotification,
                        icon: const Icon(Icons.send),
                        label: Text(LocaleHelper.t('send_test_notification', 'en')),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.accentBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.accentBlue,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildTimeSelector({
    required String title,
    required String subtitle,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Text(
        value ?? '08:00',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DesignTokens.accentBlue,
              fontWeight: FontWeight.bold,
            ),
      ),
      onTap: () async {
        final currentTime = value != null
            ? TimeOfDay(
                hour: int.parse(value.split(':')[0]),
                minute: int.parse(value.split(':')[1]),
              )
            : const TimeOfDay(hour: 8, minute: 0);

        final time = await showTimePicker(
          context: context,
          initialTime: currentTime,
        );

        if (time != null) {
          final timeString =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          onChanged(timeString);
        }
      },
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toInt().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // OneSignal service archived - show message that feature is disabled
      // await _oneSignalService.sendTestNotification(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Push notifications are currently disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleHelper.t('error_sending_test', 'en')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
