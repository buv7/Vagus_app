import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class RecentCheckinsCard extends StatelessWidget {
  final List<Map<String, dynamic>> checkins;
  final VoidCallback onViewAll;
  final Function(Map<String, dynamic>) onViewDetails;

  const RecentCheckinsCard({
    super.key,
    required this.checkins,
    required this.onViewAll,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
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
                Icons.assignment_outlined,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              const Text(
                'Recent Check-ins',
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
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  '${checkins.length}',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Check-ins List
          ...checkins.map((checkin) => _buildCheckinItem(checkin)),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinItem(Map<String, dynamic> checkin) {
    final client = checkin['profiles'] ?? {};
    final createdAt = checkin['created_at'];
    final notes = checkin['notes'] ?? '';
    final mood = checkin['mood'];
    final energy = checkin['energy_level'];
    final weight = checkin['weight'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Client Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: DesignTokens.space12),
              
              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client['name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      _formatTimeAgo(createdAt),
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // View Details Button
              IconButton(
                onPressed: () => onViewDetails(checkin),
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space12),
          
          // Metrics
          Row(
            children: [
              if (weight != null) ...[
                _buildMetric('Weight', '${weight.toStringAsFixed(1)} lbs', Colors.green, '+1.3'),
                const SizedBox(width: DesignTokens.space16),
              ],
              if (mood != null) ...[
                _buildMetric('Mood', '$mood/10', _getMoodColor(mood)),
                const SizedBox(width: DesignTokens.space16),
              ],
              if (energy != null) ...[
                _buildMetric('Energy', '$energy/10', _getEnergyColor(energy)),
              ],
            ],
          ),
          
          if (notes.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space12),
            Text(
              notes,
              style: const TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: DesignTokens.space12),
          
          // View Details Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onViewDetails(checkin),
              child: const Text(
                'View Details',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color, [String? change]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (change != null) ...[
              const SizedBox(width: DesignTokens.space4),
              Text(
                change,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Color _getMoodColor(int mood) {
    if (mood >= 8) return Colors.green;
    if (mood >= 6) return Colors.orange;
    return Colors.red;
  }

  Color _getEnergyColor(int energy) {
    if (energy >= 8) return Colors.green;
    if (energy >= 6) return Colors.orange;
    return Colors.red;
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} weeks ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
