import 'package:flutter/material.dart';
import '../../../models/coach_profile.dart';

class MarketplaceStatus extends StatelessWidget {
  final CoachProfile? profile;
  final Function(String)? onNavigate;

  const MarketplaceStatus({
    super.key,
    this.profile,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = _getRequirements();
    final completionPercentage = _calculateCompletion(requirements);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Marketplace Readiness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '$completionPercentage%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: completionPercentage == 100 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completionPercentage == 100 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Requirements Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...requirements.entries.map((entry) => _buildRequirement(
            context,
            entry.key,
            _getRequirementDescription(entry.key),
            entry.value,
            () => onNavigate?.call(_getNavigationTarget(entry.key)),
          )),
        ],
      ),
    );
  }

  Map<String, bool> _getRequirements() {
    return {
      'profile': (profile?.displayName != null && profile?.bio != null),
      'intro_video': profile?.introVideoUrl != null,
      'media': false, // Would check actual media count
      'pricing': false, // Would check pricing setup
      'business': false, // Would check business profile
    };
  }

  int _calculateCompletion(Map<String, bool> requirements) {
    if (requirements.isEmpty) return 0;
    final completed = requirements.values.where((v) => v).length;
    return ((completed / requirements.length) * 100).round();
  }

  String _getRequirementDescription(String key) {
    switch (key) {
      case 'profile': return 'Add display name, bio, and specialties';
      case 'intro_video': return '30-second introduction video';
      case 'media': return 'Upload at least 3 videos or courses';
      case 'pricing': return 'Configure your service rates';
      case 'business': return 'Add business information';
      default: return '';
    }
  }

  String _getNavigationTarget(String key) {
    switch (key) {
      case 'profile': return 'profile';
      case 'intro_video': return 'profile';
      case 'media': return 'media';
      default: return 'profile';
    }
  }

  Widget _buildRequirement(
    BuildContext context,
    String title,
    String description,
    bool isComplete,
    VoidCallback? onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isComplete ? Colors.green : Colors.grey,
        ),
        title: Text(title.replaceAll('_', ' ').split(' ').map((e) =>
          e[0].toUpperCase() + e.substring(1)).join(' ')),
        subtitle: Text(description),
        trailing: !isComplete ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: !isComplete ? onTap : null,
      ),
    );
  }
}
