import 'package:flutter/material.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../theme/app_theme.dart';

class LearnCoachScreen extends StatelessWidget {
  const LearnCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VagusAppBar(title: const Text('Master VAGUS')),
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
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MASTER VAGUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your complete guide to coaching excellence with VAGUS',
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
              'Getting Started as a Coach',
              Icons.rocket_launch,
              [
                _buildGuideItem(
                  'Setting Up Your Coach Profile',
                  'Create a compelling profile that attracts the right clients',
                  '1. Complete your coach profile with professional details\n2. Add your specialties and certifications\n3. Upload a professional headshot\n4. Write a compelling bio that highlights your expertise\n5. Set your availability and session preferences',
                ),
                _buildGuideItem(
                  'Understanding the Coach Dashboard',
                  'Navigate your coaching dashboard effectively',
                  '1. Review your client list and their progress\n2. Check your inbox for messages and updates\n3. Monitor client check-ins and photos\n4. Access analytics and performance metrics\n5. Manage your schedule and availability',
                ),
                _buildGuideItem(
                  'Client Onboarding Process',
                  'Welcome new clients and set them up for success',
                  '1. Send a welcome message to new clients\n2. Review their intake forms and goals\n3. Create their initial nutrition and workout plans\n4. Schedule a video call to discuss their program\n5. Set clear expectations and communication guidelines',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Client Management Section
            _buildSection(
              'Client Management',
              Icons.people,
              [
                _buildGuideItem(
                  'Building Client Relationships',
                  'Develop strong, supportive relationships with your clients',
                  '1. Respond to messages within 24 hours\n2. Provide personalized feedback on check-ins\n3. Celebrate client achievements and milestones\n4. Be empathetic and supportive during challenges\n5. Maintain professional boundaries while being approachable',
                ),
                _buildGuideItem(
                  'Progress Tracking & Analytics',
                  'Monitor client progress and adjust programs accordingly',
                  '1. Review weekly progress photos and measurements\n2. Analyze workout and nutrition compliance\n3. Track client engagement and communication\n4. Identify patterns and areas for improvement\n5. Adjust programs based on progress and feedback',
                ),
                _buildGuideItem(
                  'Program Customization',
                  'Create personalized programs that deliver results',
                  '1. Consider client preferences and limitations\n2. Adjust difficulty based on progress and feedback\n3. Modify nutrition plans for dietary restrictions\n4. Update workout routines to prevent plateaus\n5. Incorporate client feedback into program design',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nutrition Coaching Section
            _buildSection(
              'Nutrition Coaching',
              Icons.restaurant_menu,
              [
                _buildGuideItem(
                  'Creating Nutrition Plans',
                  'Design effective nutrition programs for your clients',
                  '1. Analyze client goals, preferences, and restrictions\n2. Calculate appropriate macronutrient targets\n3. Create meal plans with variety and flexibility\n4. Include portion guidance and timing recommendations\n5. Provide alternatives for different dietary needs',
                ),
                _buildGuideItem(
                  'Meal Plan Monitoring',
                  'Track client nutrition compliance and provide feedback',
                  '1. Review daily meal logs and photos\n2. Provide feedback on food choices and portions\n3. Suggest improvements and alternatives\n4. Address challenges and obstacles\n5. Celebrate adherence and progress',
                ),
                _buildGuideItem(
                  'Allergy & Safety Management',
                  'Ensure client safety with proper allergy tracking',
                  '1. Review client allergy information carefully\n2. Double-check all meal plans for allergens\n3. Provide safe alternatives for restricted foods\n4. Educate clients about hidden allergens\n5. Maintain detailed allergy records for each client',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Workout Programming Section
            _buildSection(
              'Workout Programming',
              Icons.fitness_center,
              [
                _buildGuideItem(
                  'Designing Workout Programs',
                  'Create effective, progressive workout routines',
                  '1. Assess client fitness level and goals\n2. Design programs that match their schedule\n3. Include proper warm-up and cool-down routines\n4. Progress exercises appropriately over time\n5. Provide clear instructions and form cues',
                ),
                _buildGuideItem(
                  'Exercise Selection & Progression',
                  'Choose the right exercises and progress them effectively',
                  '1. Select exercises appropriate for client level\n2. Provide regressions and progressions\n3. Focus on compound movements for efficiency\n4. Include variety to prevent boredom\n5. Progress intensity and volume gradually',
                ),
                _buildGuideItem(
                  'Form Coaching & Safety',
                  'Ensure clients perform exercises safely and effectively',
                  '1. Provide detailed form instructions\n2. Use video demonstrations when helpful\n3. Address form issues promptly\n4. Modify exercises for limitations or injuries\n5. Prioritize safety over intensity',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Communication & Support Section
            _buildSection(
              'Communication & Support',
              Icons.chat_bubble_outline,
              [
                _buildGuideItem(
                  'Effective Client Communication',
                  'Communicate clearly and supportively with your clients',
                  '1. Use clear, encouraging language\n2. Provide specific, actionable feedback\n3. Ask open-ended questions to understand challenges\n4. Be available for questions and concerns\n5. Maintain a positive, motivating tone',
                ),
                _buildGuideItem(
                  'Handling Difficult Situations',
                  'Navigate challenges and setbacks with professionalism',
                  '1. Listen empathetically to client concerns\n2. Address issues promptly and professionally\n3. Provide solutions and alternatives\n4. Maintain confidentiality and respect\n5. Escalate serious issues to admin when needed',
                ),
                _buildGuideItem(
                  'Building Client Accountability',
                  'Help clients stay accountable to their goals',
                  '1. Set clear expectations and check-in schedules\n2. Use positive reinforcement for progress\n3. Address non-compliance constructively\n4. Provide additional support when needed\n5. Celebrate consistency and effort',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Business & Professional Development Section
            _buildSection(
              'Business & Professional Development',
              Icons.business_center,
              [
                _buildGuideItem(
                  'Growing Your Client Base',
                  'Attract and retain quality clients',
                  '1. Maintain an excellent reputation through results\n2. Ask satisfied clients for referrals\n3. Continuously improve your coaching skills\n4. Stay updated with industry trends\n5. Build your professional network',
                ),
                _buildGuideItem(
                  'Time Management & Efficiency',
                  'Manage your time effectively as a coach',
                  '1. Batch similar tasks together\n2. Use templates for common responses\n3. Set specific hours for client communication\n4. Prioritize high-impact activities\n5. Take breaks to avoid burnout',
                ),
                _buildGuideItem(
                  'Continuous Learning',
                  'Stay current with coaching best practices',
                  '1. Pursue relevant certifications and education\n2. Read industry publications and research\n3. Attend workshops and conferences\n4. Learn from other successful coaches\n5. Experiment with new techniques and tools',
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
              child: Column(
                children: [
                  const Icon(
                    Icons.school,
                    color: AppTheme.primaryBlack,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ready to Excel as a Coach?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Implement these strategies to provide exceptional coaching and help your clients achieve their goals.',
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
              color: AppTheme.primaryBlack,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlack,
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
                color: AppTheme.primaryBlack,
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
                  color: AppTheme.primaryBlack,
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
