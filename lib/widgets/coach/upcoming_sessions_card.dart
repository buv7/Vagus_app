import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

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
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              const Text(
                'Upcoming Sessions',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
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
                  color: AppTheme.steelGrey,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  '${sessions.length}',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
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
                    color: AppTheme.mintAqua,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Sessions List
          ...sessions.map((session) => _buildSessionItem(session)),
        ],
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
    final status = session['status'] as String;
    final statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border(
          left: BorderSide(
            color: AppTheme.mintAqua,
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
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      'with ${session['coach'] ?? 'Coach'}',
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
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
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
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
              const Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.lightGrey,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                session['date'] ?? 'Unknown',
                style: const TextStyle(
                  color: AppTheme.lightGrey,
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
                color: AppTheme.lightGrey,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                session['location'] ?? 'Unknown Location',
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space8),
          
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                color: AppTheme.lightGrey,
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
                    color: AppTheme.primaryBlack,
                    size: 16,
                  ),
                  label: Text(
                    session['location']?.contains('Zoom') == true ? 'Join Meeting' : 'Start Session',
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mintAqua,
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
                child: const Text(
                  'Reschedule',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.steelGrey),
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.space12,
                    horizontal: DesignTokens.space16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.mintAqua;
      case 'pending':
        return AppTheme.steelGrey;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.steelGrey;
    }
  }
}
