import 'package:flutter/material.dart';
import '../../services/feature_flags_service.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../theme/app_theme.dart';

class InsiderSettingsScreen extends StatefulWidget {
  const InsiderSettingsScreen({super.key});

  @override
  State<InsiderSettingsScreen> createState() => _InsiderSettingsScreenState();
}

class _InsiderSettingsScreenState extends State<InsiderSettingsScreen> {
  final FeatureFlagsService _featureFlagsService = FeatureFlagsService.instance;
  Map<String, bool> _flags = {};
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadFeatureFlags();
  }

  Future<void> _loadFeatureFlags() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      final flags = await _featureFlagsService.getFlagsForUser();
      setState(() {
        _flags = flags;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFlag(String key, bool value) async {
    try {
      await _featureFlagsService.setFlag(key, value);
      setState(() {
        _flags[key] = value;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all feature flags to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _featureFlagsService.resetToDefaults();
        await _loadFeatureFlags();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings reset to defaults')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reset settings: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VagusAppBar(title: Text('Insider Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading settings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadFeatureFlags,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryDark,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INSIDER FEATURES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Customize your VAGUS experience with these experimental features',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _resetToDefaults,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reset to Defaults'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Feature flags list
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildFeatureSection(
                            'Progress & Tracking',
                            [
                              'show_streaks',
                              'enable_period_countdown',
                              'enable_checkin_comparison',
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildFeatureSection(
                            'Notifications & Feedback',
                            [
                              'enable_announcements',
                              'enable_confetti',
                              'enable_animated_feedback',
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildFeatureSection(
                            'Coach Features',
                            [
                              'enable_coach_portfolio',
                              'enable_intake_forms',
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFeatureSection(String title, List<String> featureKeys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        ...featureKeys.map((key) => _buildFeatureToggle(key)),
      ],
    );
  }

  Widget _buildFeatureToggle(String key) {
    final isEnabled = _flags[key] ?? true;
    final description = _getFeatureDescription(key);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          _getFeatureTitle(key),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        value: isEnabled,
        onChanged: (value) => _toggleFlag(key, value),
        activeColor: AppTheme.primaryDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
      ),
    );
  }

  String _getFeatureTitle(String key) {
    switch (key) {
      case 'show_streaks':
        return 'Activity Streaks';
      case 'enable_announcements':
        return 'Announcements';
      case 'enable_confetti':
        return 'Celebration Animations';
      case 'enable_animated_feedback':
        return 'Animated Feedback';
      case 'enable_period_countdown':
        return 'Period Countdown';
      case 'enable_checkin_comparison':
        return 'Photo Comparison';
      case 'enable_coach_portfolio':
        return 'Coach Portfolio';
      case 'enable_intake_forms':
        return 'Intake Forms';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getFeatureDescription(String key) {
    switch (key) {
      case 'show_streaks':
        return 'Display activity streaks and progress tracking features';
      case 'enable_announcements':
        return 'Show announcements and notifications from admins';
      case 'enable_confetti':
        return 'Show celebration animations when you hit milestones';
      case 'enable_animated_feedback':
        return 'Display animated feedback overlays for actions';
      case 'enable_period_countdown':
        return 'Show coaching period progress bars and countdowns';
      case 'enable_checkin_comparison':
        return 'Enable photo comparison features for check-ins';
      case 'enable_coach_portfolio':
        return 'Access to coach portfolio and media features';
      case 'enable_intake_forms':
        return 'Access to intake form builder and allergy tracking';
      default:
        return 'Feature description not available';
    }
  }
}
