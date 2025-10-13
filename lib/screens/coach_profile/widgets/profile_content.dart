import 'package:flutter/material.dart';
import '../../../models/coach_profile.dart';

class ProfileContent extends StatelessWidget {
  final CoachProfile? profile;

  const ProfileContent({
    super.key,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
            _buildSectionHeader(context, Icons.info_outline, 'About'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E1E2E) // Lighter dark background
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                profile!.bio!,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Specialties Section with HIGH CONTRAST
          _buildSectionHeader(context, Icons.fitness_center, 'Specialties'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E1E2E) // Lighter dark background
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: profile?.specialties != null && profile!.specialties!.isNotEmpty
                ? Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: profile!.specialties!.map((specialty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          // HIGH CONTRAST GRADIENT BACKGROUND
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [
                                    Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                    Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                  ]
                                : [
                                    Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 1.5,
                          ),
                          boxShadow: isDarkMode
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          specialty,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No specialties added yet',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // Statistics Section with better visibility
          _buildSectionHeader(context, Icons.insights, 'Statistics'),
          const SizedBox(height: 8),
          _buildStatsGrid(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    // Mock stats data - would come from profile in production
    final stats = [
      {'icon': Icons.people, 'label': 'Clients', 'value': '0', 'color': Colors.blue},
      {'icon': Icons.star, 'label': 'Rating', 'value': '0.0', 'color': Colors.amber},
      {'icon': Icons.event, 'label': 'Experience', 'value': '0 years', 'color': Colors.green},
      {'icon': Icons.trending_up, 'label': 'Success Rate', 'value': '0%', 'color': Colors.purple},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: stats.map((stat) => _buildStatCard(
        context,
        stat['icon'] as IconData,
        stat['label'] as String,
        stat['value'] as String,
        stat['color'] as Color,
      )).toList(),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ]
              : [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
