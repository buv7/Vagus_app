import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final supabase = Supabase.instance.client;
  
  // Notification preferences
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _clientMessages = true;
  bool _appointmentReminders = true;
  bool _workoutUpdates = true;
  bool _paymentNotifications = true;
  bool _marketingEmails = false;
  bool _weeklyReports = true;
  bool _monthlyReports = true;
  
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      // Try to load notification preferences from a dedicated table
      // If it doesn't exist, we'll create default settings
      final response = await supabase
          .from('notification_preferences')
          .select('*')
          .eq('user_id', user.id)
          .single();

      setState(() {
        _pushNotifications = response['push_notifications'] ?? true;
        _emailNotifications = response['email_notifications'] ?? true;
        _smsNotifications = response['sms_notifications'] ?? false;
        _clientMessages = response['client_messages'] ?? true;
        _appointmentReminders = response['appointment_reminders'] ?? true;
        _workoutUpdates = response['workout_updates'] ?? true;
        _paymentNotifications = response['payment_notifications'] ?? true;
        _marketingEmails = response['marketing_emails'] ?? false;
        _weeklyReports = response['weekly_reports'] ?? true;
        _monthlyReports = response['monthly_reports'] ?? true;
        _loading = false;
      });
    } catch (e) {
      // If table doesn't exist or no preferences found, use defaults
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _saving = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Try to upsert notification preferences
      await supabase.from('notification_preferences').upsert({
        'user_id': user.id,
        'push_notifications': _pushNotifications,
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
        'client_messages': _clientMessages,
        'appointment_reminders': _appointmentReminders,
        'workout_updates': _workoutUpdates,
        'payment_notifications': _paymentNotifications,
        'marketing_emails': _marketingEmails,
        'weekly_reports': _weeklyReports,
        'monthly_reports': _monthlyReports,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
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
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveNotificationSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General Notifications
                  _buildSectionTitle('General Notifications'),
                  const SizedBox(height: DesignTokens.space16),

                  _buildNotificationTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive push notifications on your device',
                    icon: Icons.notifications,
                    value: _pushNotifications,
                    onChanged: (value) => setState(() => _pushNotifications = value),
                  ),

                  _buildNotificationTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    icon: Icons.email,
                    value: _emailNotifications,
                    onChanged: (value) => setState(() => _emailNotifications = value),
                  ),

                  _buildNotificationTile(
                    title: 'SMS Notifications',
                    subtitle: 'Receive notifications via SMS',
                    icon: Icons.sms,
                    value: _smsNotifications,
                    onChanged: (value) => setState(() => _smsNotifications = value),
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Client Communication
                  _buildSectionTitle('Client Communication'),
                  const SizedBox(height: DesignTokens.space16),

                  _buildNotificationTile(
                    title: 'Client Messages',
                    subtitle: 'Notifications for new client messages',
                    icon: Icons.chat,
                    value: _clientMessages,
                    onChanged: (value) => setState(() => _clientMessages = value),
                  ),

                  _buildNotificationTile(
                    title: 'Appointment Reminders',
                    subtitle: 'Reminders for upcoming appointments',
                    icon: Icons.calendar_today,
                    value: _appointmentReminders,
                    onChanged: (value) => setState(() => _appointmentReminders = value),
                  ),

                  _buildNotificationTile(
                    title: 'Workout Updates',
                    subtitle: 'Updates on client workout progress',
                    icon: Icons.fitness_center,
                    value: _workoutUpdates,
                    onChanged: (value) => setState(() => _workoutUpdates = value),
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Business & Reports
                  _buildSectionTitle('Business & Reports'),
                  const SizedBox(height: DesignTokens.space16),

                  _buildNotificationTile(
                    title: 'Payment Notifications',
                    subtitle: 'Notifications for payments and billing',
                    icon: Icons.payment,
                    value: _paymentNotifications,
                    onChanged: (value) => setState(() => _paymentNotifications = value),
                  ),

                  _buildNotificationTile(
                    title: 'Weekly Reports',
                    subtitle: 'Weekly summary of your coaching activity',
                    icon: Icons.analytics,
                    value: _weeklyReports,
                    onChanged: (value) => setState(() => _weeklyReports = value),
                  ),

                  _buildNotificationTile(
                    title: 'Monthly Reports',
                    subtitle: 'Monthly summary of your coaching activity',
                    icon: Icons.assessment,
                    value: _monthlyReports,
                    onChanged: (value) => setState(() => _monthlyReports = value),
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Marketing
                  _buildSectionTitle('Marketing'),
                  const SizedBox(height: DesignTokens.space16),

                  _buildNotificationTile(
                    title: 'Marketing Emails',
                    subtitle: 'Receive promotional emails and updates',
                    icon: Icons.campaign,
                    value: _marketingEmails,
                    onChanged: (value) => setState(() => _marketingEmails = value),
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Test Notifications
                  _buildSectionTitle('Test Notifications'),
                  const SizedBox(height: DesignTokens.space16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _testNotifications(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: AppTheme.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        ),
                      ),
                      child: const Text(
                        'Send Test Notification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.lightGrey,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.mediumGrey,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
        leading: Icon(
          icon,
          color: AppTheme.accentGreen,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentGreen,
          activeTrackColor: AppTheme.accentGreen.withValues(alpha: 0.3),
          inactiveThumbColor: AppTheme.lightGrey,
          inactiveTrackColor: AppTheme.mediumGrey,
        ),
      ),
    );
  }

  void _testNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}
