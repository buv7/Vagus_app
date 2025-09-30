import 'package:flutter/material.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../theme/app_theme.dart';

class LearnClientScreen extends StatelessWidget {
  const LearnClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VagusAppBar(title: Text('Master VAGUS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MASTER VAGUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your complete guide to getting the most out of VAGUS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Getting Started Section
            _buildSection(
              'Getting Started',
              Icons.rocket_launch,
              [
                _buildGuideItem(
                  'Setting Up Your Profile',
                  'Complete your profile with accurate information to get personalized recommendations',
                  '1. Tap the menu icon (☰) in the top-left\n2. Select "Edit Profile"\n3. Fill in your details and goals\n4. Save your changes',
                ),
                _buildGuideItem(
                  'Connecting with a Coach',
                  'Find and connect with a certified coach for personalized guidance',
                  '1. Go to "Find Coach" from the main menu\n2. Browse available coaches\n3. Read their profiles and specialties\n4. Send a connection request\n5. Wait for coach approval',
                ),
                _buildGuideItem(
                  'Understanding Your Dashboard',
                  'Navigate your personalized dashboard to track progress',
                  '1. View your daily goals and progress\n2. Check upcoming workouts and meals\n3. Review coach messages and feedback\n4. Track your streaks and achievements',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nutrition Section
            _buildSection(
              'Nutrition & Meal Planning',
              Icons.restaurant_menu,
              [
                _buildGuideItem(
                  'Understanding Nutrition Plans',
                  'Learn how to follow your personalized nutrition plan',
                  '1. Check your daily meal plan in the dashboard\n2. Follow portion sizes and timing\n3. Log your meals and snacks\n4. Take photos of your meals for coach review',
                ),
                _buildGuideItem(
                  'Meal Logging & Tracking',
                  'Track your food intake accurately for better results',
                  '1. Use the camera to snap meal photos\n2. Log portion sizes and ingredients\n3. Note any substitutions or changes\n4. Share updates with your coach',
                ),
                _buildGuideItem(
                  'Hydration & Supplements',
                  'Stay hydrated and manage your supplement routine',
                  '1. Set daily hydration goals\n2. Log water intake throughout the day\n3. Track supplement timing and dosage\n4. Report any side effects to your coach',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Workouts Section
            _buildSection(
              'Workouts & Exercise',
              Icons.fitness_center,
              [
                _buildGuideItem(
                  'Following Your Workout Plan',
                  'Execute your personalized workout routine effectively',
                  '1. Check your daily workout in the dashboard\n2. Warm up properly before starting\n3. Follow exercise form and technique\n4. Log sets, reps, and weights used',
                ),
                _buildGuideItem(
                  'Exercise Form & Safety',
                  'Perform exercises safely and effectively',
                  '1. Watch demonstration videos\n2. Start with lighter weights\n3. Focus on proper form over heavy weight\n4. Ask your coach for form checks',
                ),
                _buildGuideItem(
                  'Progress Tracking',
                  'Monitor your strength and fitness improvements',
                  '1. Log your workout performance\n2. Take progress photos regularly\n3. Track measurements and body weight\n4. Celebrate milestones and achievements',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Communication Section
            _buildSection(
              'Communication & Support',
              Icons.chat_bubble_outline,
              [
                _buildGuideItem(
                  'Messaging Your Coach',
                  'Stay connected with your coach for guidance and support',
                  '1. Use the messaging feature to ask questions\n2. Share photos and updates regularly\n3. Be specific about challenges or concerns\n4. Respond to coach feedback promptly',
                ),
                _buildGuideItem(
                  'Getting Help & Support',
                  'Access help when you need it',
                  '1. Check the FAQ section first\n2. Use the support chat for technical issues\n3. Contact your coach for program questions\n4. Reach out to admin for account issues',
                ),
                _buildGuideItem(
                  'Community & Resources',
                  'Connect with other users and access learning materials',
                  '1. Join community discussions\n2. Read educational articles\n3. Watch tutorial videos\n4. Share your success stories',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tips & Best Practices
            _buildSection(
              'Tips & Best Practices',
              Icons.lightbulb_outline,
              [
                _buildGuideItem(
                  'Consistency is Key',
                  'Build sustainable habits for long-term success',
                  '• Set realistic daily goals\n• Create a routine that fits your schedule\n• Focus on progress, not perfection\n• Celebrate small wins along the way',
                ),
                _buildGuideItem(
                  'Stay Motivated',
                  'Keep your motivation high throughout your journey',
                  '• Track your progress regularly\n• Set short-term and long-term goals\n• Connect with your coach for accountability\n• Join the community for support',
                ),
                _buildGuideItem(
                  'Listen to Your Body',
                  'Pay attention to your body\'s signals and adjust accordingly',
                  '• Rest when you need to\n• Communicate any pain or discomfort\n• Adjust intensity based on how you feel\n• Prioritize recovery and sleep',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: AppTheme.lightGrey),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.school,
                    color: AppTheme.primaryDark,
                    size: 32,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ready to Master VAGUS?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start implementing these tips today and unlock your full potential with VAGUS.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryDark,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildGuideItem(String title, String description, String steps) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: AppTheme.lightGrey),
              ),
              child: Text(
                steps,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryDark,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
