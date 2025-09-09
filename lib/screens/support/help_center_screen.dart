import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I add a new client?',
      'answer': 'To add a new client, go to the Clients tab and tap the "+" button. Fill in the client\'s information and send them an invitation.',
      'category': 'Clients',
    },
    {
      'question': 'How do I create a workout plan?',
      'answer': 'Navigate to the Plans tab and select "Create New Plan". Choose between workout or nutrition plans and use our AI-powered builder.',
      'category': 'Plans',
    },
    {
      'question': 'How do I schedule sessions?',
      'answer': 'Go to the Calendar tab and tap on any date to create a new session. You can set the time, duration, and type of session.',
      'category': 'Calendar',
    },
    {
      'question': 'How do I message my clients?',
      'answer': 'Use the Messages tab to start conversations with your clients. You can send text messages, images, and voice notes.',
      'category': 'Messaging',
    },
    {
      'question': 'How do I view my analytics?',
      'answer': 'Check the Dashboard for an overview of your performance metrics, or go to Menu > Analytics & Reports for detailed insights.',
      'category': 'Analytics',
    },
    {
      'question': 'How do I update my profile?',
      'answer': 'Go to Menu > Profile Settings to update your personal information, bio, and professional details.',
      'category': 'Profile',
    },
    {
      'question': 'How do I manage my subscription?',
      'answer': 'Navigate to Menu > Billing & Payments to view your subscription details, payment history, and manage billing.',
      'category': 'Billing',
    },
    {
      'question': 'How do I get support?',
      'answer': 'You can contact our support team through the Help Center, email us at support@vagus.com, or use the in-app chat.',
      'category': 'Support',
    },
  ];


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFaqItems {
    if (_searchQuery.isEmpty) return _faqItems;
    
    return _faqItems.where((item) {
      return item['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item['answer'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item['category'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _contactOptions => [ // Fixed Field Initializer Error
    {
      'title': 'Email Support',
      'subtitle': 'Get help via email',
      'icon': Icons.email,
      'action': () => _launchEmail(),
    },
    {
      'title': 'Live Chat',
      'subtitle': 'Chat with our support team',
      'icon': Icons.chat,
      'action': () => _openLiveChat(),
    },
    {
      'title': 'Video Call',
      'subtitle': 'Schedule a video call',
      'icon': Icons.video_call,
      'action': () => _scheduleVideoCall(),
    },
    {
      'title': 'Phone Support',
      'subtitle': 'Call us directly',
      'icon': Icons.phone,
      'action': () => _launchPhone(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: AppTheme.steelGrey,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: AppTheme.neutralWhite),
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  hintStyle: const TextStyle(color: AppTheme.lightGrey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(DesignTokens.space16),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.mintAqua,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: AppTheme.lightGrey,
                            size: 20,
                          ),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.space24),

            // Quick Actions
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: DesignTokens.space16),
            _buildQuickActions(),

            const SizedBox(height: DesignTokens.space32),

            // Contact Support
            _buildSectionTitle('Contact Support'),
            const SizedBox(height: DesignTokens.space16),
            _buildContactOptions(),

            const SizedBox(height: DesignTokens.space32),

            // FAQ
            _buildSectionTitle('Frequently Asked Questions'),
            const SizedBox(height: DesignTokens.space16),
            _buildFAQList(),

            const SizedBox(height: DesignTokens.space20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.lightGrey,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: DesignTokens.space12,
      mainAxisSpacing: DesignTokens.space12,
      childAspectRatio: 1.5,
      children: [
        _buildQuickActionCard(
          title: 'Getting Started',
          icon: Icons.play_circle,
          onTap: () => _showGettingStarted(),
        ),
        _buildQuickActionCard(
          title: 'Video Tutorials',
          icon: Icons.video_library,
          onTap: () => _showVideoTutorials(),
        ),
        _buildQuickActionCard(
          title: 'User Guide',
          icon: Icons.book,
          onTap: () => _showUserGuide(),
        ),
        _buildQuickActionCard(
          title: 'Feature Requests',
          icon: Icons.lightbulb,
          onTap: () => _showFeatureRequests(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(
            color: AppTheme.steelGrey,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.mintAqua,
              size: 32,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOptions() {
    return Column(
      children: _contactOptions.map((option) => _buildContactOption(option)).toList(),
    );
  }

  Widget _buildContactOption(Map<String, dynamic> option) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.steelGrey,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DesignTokens.space16),
        leading: Icon(
          option['icon'],
          color: AppTheme.mintAqua,
          size: 24,
        ),
        title: Text(
          option['title'],
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          option['subtitle'],
          style: TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.lightGrey,
          size: 16,
        ),
        onTap: option['action'],
      ),
    );
  }

  Widget _buildFAQList() {
    final filteredItems = _filteredFaqItems;
    
    if (filteredItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.space20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(
            color: AppTheme.steelGrey,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                color: AppTheme.lightGrey,
                size: 48,
              ),
              const SizedBox(height: DesignTokens.space16),
              Text(
                'No results found',
                style: TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 16,
                ),
              ),
              Text(
                'Try different keywords',
                style: TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filteredItems.map((item) => _buildFAQItem(item)).toList(),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.steelGrey,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
        childrenPadding: const EdgeInsets.only(
          left: DesignTokens.space16,
          right: DesignTokens.space16,
          bottom: DesignTokens.space16,
        ),
        leading: Container(
          padding: const EdgeInsets.all(DesignTokens.space8),
          decoration: BoxDecoration(
            color: AppTheme.mintAqua.withOpacity(0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Icon(
            Icons.help_outline,
            color: AppTheme.mintAqua,
            size: 20,
          ),
        ),
        title: Text(
          item['question'],
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item['category'],
          style: TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 12,
          ),
        ),
        iconColor: AppTheme.mintAqua,
        collapsedIconColor: AppTheme.lightGrey,
        children: [
          Text(
            item['answer'],
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _showGettingStarted() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Getting started guide coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _showVideoTutorials() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video tutorials coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _showUserGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User guide coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _showFeatureRequests() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature requests coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@vagus.com',
      query: 'subject=Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open email client'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    }
  }

  void _openLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live chat coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _scheduleVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video call scheduling coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1-555-0123');
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open phone dialer'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    }
  }
}
