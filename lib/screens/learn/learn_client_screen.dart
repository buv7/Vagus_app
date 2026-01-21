import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../theme/design_tokens.dart';

class LearnClientScreen extends StatelessWidget {
  const LearnClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0B1220),
        elevation: 0,
        title: Text(
          'Master VAGUS',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0B1220),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildGlassmorphicCard(
              padding: const EdgeInsets.all(24),
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
                      fontSize: 14,
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
                  'Progress Tracking',
                  'Monitor your strength and fitness improvements',
                  '1. Log your workout performance\n2. Take progress photos regularly\n3. Track measurements and body weight\n4. Celebrate milestones and achievements',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tips Section
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
              ],
            ),

            const SizedBox(height: 32),

            // Footer
            _buildGlassmorphicCard(
              child: Column(
                children: [
                  Icon(
                    Icons.school,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ready to Master VAGUS?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start implementing these tips today and unlock your full potential with VAGUS.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
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
              color: Colors.white.withValues(alpha: 0.9),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
    return _buildGlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              steps,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.0,
                colors: [
                  DesignTokens.accentBlue.withValues(alpha: 0.25),
                  DesignTokens.accentBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
