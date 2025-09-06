import 'package:flutter/material.dart';
import '../../models/periods/coach_client_period.dart';
import '../../theme/app_theme.dart';

class PeriodProgressBar extends StatelessWidget {
  final CoachClientPeriod period;
  final bool showDetails;
  final VoidCallback? onTap;

  const PeriodProgressBar({
    super.key,
    required this.period,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppTheme.primaryBlack,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Coaching Period',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    period.status,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            if (showDetails) ...[
              const SizedBox(height: 12),
              
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Week ${period.weeksCompleted} of ${period.durationWeeks}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                      Text(
                        '${(period.progressPercentage * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: period.progressPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Started',
                      _formatDate(period.startDate),
                      Icons.play_arrow,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Ends',
                      _formatDate(period.endDate),
                      Icons.flag,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Remaining',
                      '${period.weeksRemaining} weeks',
                      Icons.timer,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlack,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlack,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (period.hasEnded) return Colors.green;
    if (period.isActive) return AppTheme.primaryBlack;
    return Colors.orange;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CompactPeriodProgressBar extends StatelessWidget {
  final CoachClientPeriod period;
  final VoidCallback? onTap;

  const CompactPeriodProgressBar({
    super.key,
    required this.period,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.lightGrey),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule,
              color: AppTheme.primaryBlack,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week ${period.weeksCompleted}/${period.durationWeeks}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: period.progressPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(period.progressPercentage * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (period.hasEnded) return Colors.green;
    if (period.isActive) return AppTheme.primaryBlack;
    return Colors.orange;
  }
}
