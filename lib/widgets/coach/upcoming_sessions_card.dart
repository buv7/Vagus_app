import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';

class UpcomingSessionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final VoidCallback onViewCalendar;
  final Function(Map<String, dynamic>) onStartSession;
  final Function(Map<String, dynamic>) onReschedule;
  final Function(Map<String, dynamic>) onCancel;

  const UpcomingSessionsCard({
    super.key,
    required this.sessions,
    required this.onViewCalendar,
    required this.onStartSession,
    required this.onReschedule,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tc.border,
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
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'Upcoming Sessions',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: tc.surfaceAlt,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  border: Border.all(color: tc.border),
                ),
                child: Text(
                  '${sessions.length}',
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewCalendar,
                child: const Text(
                  'View Calendar',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Sessions List
          ...sessions.map((session) => _buildSessionItem(context, session)),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, Map<String, dynamic> session) {
    final tc = ThemeColors.of(context);
    final status = session['status'] as String;
    final statusColor = _getStatusColor(context, status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tc.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentGreen.withValues(alpha: 0.2),
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
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppTheme.accentGreen,
                  width: 4,
                ),
              ),
            ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['title'] ?? 'Session',
                      style: TextStyle(
                        color: tc.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      'with ${session['coach'] ?? 'Coach'}',
                      style: TextStyle(
                        color: tc.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space12),
          
          // Session Details
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: tc.icon,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                session['date'] ?? 'Unknown',
                style: TextStyle(
                  color: tc.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space8),
          
          Row(
            children: [
              Icon(
                session['location']?.contains('Zoom') == true
                    ? Icons.videocam_outlined
                    : Icons.location_on_outlined,
                color: tc.icon,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                session['location'] ?? 'Unknown Location',
                style: TextStyle(
                  color: tc.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space8),
          
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                color: tc.icon,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                session['time'] ?? 'Unknown Time',
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onStartSession(session),
                  icon: const Icon(
                    Icons.play_arrow,
                    color: AppTheme.primaryDark,
                    size: 16,
                  ),
                  label: Text(
                    session['location']?.contains('Zoom') == true ? 'Join Meeting' : 'Start Session',
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              OutlinedButton(
                onPressed: () => onReschedule(session),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.mediumGrey),
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.space12,
                    horizontal: DesignTokens.space16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  ),
                ),
                child: const Text(
                  'Reschedule',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              TextButton(
                onPressed: () => onCancel(session),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
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

  Color _getStatusColor(BuildContext context, String status) {
    final tc = ThemeColors.of(context);
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.accentGreen;
      case 'pending':
        return tc.chipBg;
      case 'cancelled':
        return Colors.red;
      default:
        return tc.chipBg;
    }
  }
}
