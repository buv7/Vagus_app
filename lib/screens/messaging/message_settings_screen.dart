import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';

/// Message settings screen for configuring messaging preferences
/// Follows the app's theme system for both light and dark modes
class MessageSettingsScreen extends StatefulWidget {
  const MessageSettingsScreen({super.key});

  @override
  State<MessageSettingsScreen> createState() => _MessageSettingsScreenState();
}

class _MessageSettingsScreenState extends State<MessageSettingsScreen> {
  final supabase = Supabase.instance.client;

  // Message notification settings
  bool _pushNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showPreview = true;

  // Message display settings
  bool _showReadReceipts = true;
  bool _showTypingIndicator = true;
  bool _autoDownloadMedia = true;
  bool _compressImages = true;

  // Privacy settings
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;

  // AI settings
  bool _smartReplies = true;
  bool _aiSuggestions = true;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await supabase
          .from('message_settings')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _pushNotifications = response['push_notifications'] ?? true;
          _soundEnabled = response['sound_enabled'] ?? true;
          _vibrationEnabled = response['vibration_enabled'] ?? true;
          _showPreview = response['show_preview'] ?? true;
          _showReadReceipts = response['show_read_receipts'] ?? true;
          _showTypingIndicator = response['show_typing_indicator'] ?? true;
          _autoDownloadMedia = response['auto_download_media'] ?? true;
          _compressImages = response['compress_images'] ?? true;
          _showOnlineStatus = response['show_online_status'] ?? true;
          _showLastSeen = response['show_last_seen'] ?? true;
          _smartReplies = response['smart_replies'] ?? true;
          _aiSuggestions = response['ai_suggestions'] ?? true;
        });
      }
    } catch (e) {
      // Table might not exist, use defaults
      debugPrint('Failed to load message settings: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('message_settings').upsert({
        'user_id': user.id,
        'push_notifications': _pushNotifications,
        'sound_enabled': _soundEnabled,
        'vibration_enabled': _vibrationEnabled,
        'show_preview': _showPreview,
        'show_read_receipts': _showReadReceipts,
        'show_typing_indicator': _showTypingIndicator,
        'auto_download_media': _autoDownloadMedia,
        'compress_images': _compressImages,
        'show_online_status': _showOnlineStatus,
        'show_last_seen': _showLastSeen,
        'smart_replies': _smartReplies,
        'ai_suggestions': _aiSuggestions,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        final tc = context.tc;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved successfully'),
            backgroundColor: tc.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final tc = context.tc;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: tc.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;

    return Scaffold(
      backgroundColor: tc.bg,
      appBar: AppBar(
        backgroundColor: tc.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: tc.icon),
        ),
        title: Text(
          'Message settings',
          style: TextStyle(
            color: tc.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: TextStyle(
                  color: tc.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications Section
                  _buildSectionTitle('Notifications', tc),
                  const SizedBox(height: DesignTokens.space16),

                  _buildSettingTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications for new messages',
                    icon: Icons.notifications,
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                    tc: tc,
                  ),

                  _buildSettingTile(
                    title: 'Sound',
                    subtitle: 'Play sound for new messages',
                    icon: Icons.volume_up,
                    value: _soundEnabled,
                    onChanged: (v) => setState(() => _soundEnabled = v),
                    tc: tc,
                    enabled: _pushNotifications,
                  ),

                  _buildSettingTile(
                    title: 'Vibration',
                    subtitle: 'Vibrate for new messages',
                    icon: Icons.vibration,
                    value: _vibrationEnabled,
                    onChanged: (v) => setState(() => _vibrationEnabled = v),
                    tc: tc,
                    enabled: _pushNotifications,
                  ),

                  _buildSettingTile(
                    title: 'Show Preview',
                    subtitle: 'Display message content in notifications',
                    icon: Icons.preview,
                    value: _showPreview,
                    onChanged: (v) => setState(() => _showPreview = v),
                    tc: tc,
                    enabled: _pushNotifications,
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Chat Settings Section
                  _buildSectionTitle('Chat Settings', tc),
                  const SizedBox(height: DesignTokens.space16),

                  _buildSettingTile(
                    title: 'Read Receipts',
                    subtitle: 'Let others see when you\'ve read messages',
                    icon: Icons.done_all,
                    value: _showReadReceipts,
                    onChanged: (v) => setState(() => _showReadReceipts = v),
                    tc: tc,
                  ),

                  _buildSettingTile(
                    title: 'Typing Indicator',
                    subtitle: 'Show when you\'re typing a message',
                    icon: Icons.edit,
                    value: _showTypingIndicator,
                    onChanged: (v) => setState(() => _showTypingIndicator = v),
                    tc: tc,
                  ),

                  _buildSettingTile(
                    title: 'Auto-download Media',
                    subtitle: 'Automatically download photos and files',
                    icon: Icons.download,
                    value: _autoDownloadMedia,
                    onChanged: (v) => setState(() => _autoDownloadMedia = v),
                    tc: tc,
                  ),

                  _buildSettingTile(
                    title: 'Compress Images',
                    subtitle: 'Reduce image size before sending',
                    icon: Icons.compress,
                    value: _compressImages,
                    onChanged: (v) => setState(() => _compressImages = v),
                    tc: tc,
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Privacy Section
                  _buildSectionTitle('Privacy', tc),
                  const SizedBox(height: DesignTokens.space16),

                  _buildSettingTile(
                    title: 'Online Status',
                    subtitle: 'Show when you\'re online',
                    icon: Icons.circle,
                    value: _showOnlineStatus,
                    onChanged: (v) => setState(() => _showOnlineStatus = v),
                    tc: tc,
                  ),

                  _buildSettingTile(
                    title: 'Last Seen',
                    subtitle: 'Show when you were last active',
                    icon: Icons.access_time,
                    value: _showLastSeen,
                    onChanged: (v) => setState(() => _showLastSeen = v),
                    tc: tc,
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // AI Features Section
                  _buildSectionTitle('AI Features', tc),
                  const SizedBox(height: DesignTokens.space16),

                  _buildSettingTile(
                    title: 'Smart Replies',
                    subtitle: 'Get AI-powered quick reply suggestions',
                    icon: Icons.quickreply,
                    value: _smartReplies,
                    onChanged: (v) => setState(() => _smartReplies = v),
                    tc: tc,
                  ),

                  _buildSettingTile(
                    title: 'AI Message Suggestions',
                    subtitle: 'Get help composing messages',
                    icon: Icons.auto_awesome,
                    value: _aiSuggestions,
                    onChanged: (v) => setState(() => _aiSuggestions = v),
                    tc: tc,
                  ),

                  const SizedBox(height: DesignTokens.space32),

                  // Info Card
                  _buildInfoCard(tc),

                  const SizedBox(height: DesignTokens.space20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeColors tc) {
    return Text(
      title,
      style: TextStyle(
        color: tc.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeColors tc,
    bool enabled = true,
  }) {
    final effectiveOpacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: effectiveOpacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.space12),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(
            color: tc.border,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tc.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: tc.accent,
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: tc.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: tc.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: tc.accent,
            activeTrackColor: tc.accent.withValues(alpha: 0.3),
            inactiveThumbColor: tc.textSecondary,
            inactiveTrackColor: tc.border,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.infoBg,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: tc.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: tc.info,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Message Settings',
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These settings control how you send and receive messages. '
                  'Some settings may require a restart to take effect.',
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
