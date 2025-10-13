import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/coach/coach_profile.dart';
import '../../services/coach_portfolio_service.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../business/business_profile_screen.dart';
import 'portfolio_edit_screen.dart';

class CoachPortfolioMarketplaceScreen extends StatefulWidget {
  const CoachPortfolioMarketplaceScreen({super.key});

  @override
  State<CoachPortfolioMarketplaceScreen> createState() => _CoachPortfolioMarketplaceScreenState();
}

class _CoachPortfolioMarketplaceScreenState extends State<CoachPortfolioMarketplaceScreen> {
  final supabase = Supabase.instance.client;
  final CoachPortfolioService _portfolioService = CoachPortfolioService();
  
  CoachProfile? _profile;
  List<CoachMedia> _media = [];
  Map<String, dynamic>? _businessProfile;
  Map<String, dynamic>? _pricingProfile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load portfolio profile
      _profile = await _portfolioService.getCoachProfile(user.id);
      
      // Load media
      _media = await _portfolioService.getCoachMedia(user.id);
      
      // Load business profile
      try {
        final businessResponse = await supabase
            .from('business_profiles')
            .select('*')
            .eq('coach_id', user.id)
            .maybeSingle();
        _businessProfile = businessResponse;
      } catch (e) {
        // Business profile doesn't exist yet
      }
      
      // Load pricing profile
      try {
        final pricingResponse = await supabase
            .from('coach_pricing')
            .select('*')
            .eq('coach_id', user.id)
            .maybeSingle();
        _pricingProfile = pricingResponse;
      } catch (e) {
        // Pricing profile doesn't exist yet
      }
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: const VagusAppBar(
        title: Text(
          'Coach Portfolio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DesignTokens.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentGreen,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: DesignTokens.accentPink,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading portfolio',
            style: DesignTokens.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: DesignTokens.bodyMedium.copyWith(
              color: AppTheme.lightGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAllData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marketplace Requirements Status
          _buildMarketplaceRequirements(),
          const SizedBox(height: DesignTokens.space24),
          
          // Portfolio Overview
          _buildPortfolioOverview(),
          const SizedBox(height: DesignTokens.space24),
          
          // Pricing & Services
          _buildPricingServices(),
          const SizedBox(height: DesignTokens.space24),
          
          // Content Sharing
          _buildContentSharing(),
          const SizedBox(height: DesignTokens.space24),
          
          // Business Profile
          _buildBusinessProfile(),
          const SizedBox(height: DesignTokens.space24),
          
          // Quick Actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildMarketplaceRequirements() {
    final requirements = _getMarketplaceRequirements();
    final completedCount = requirements.where((req) => req['completed']).length;
    final completionPercentage = requirements.isNotEmpty 
        ? (completedCount / requirements.length * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF6A6475),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.checklist,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Marketplace Requirements',
                style: DesignTokens.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: completionPercentage == 100 
                      ? AppTheme.accentGreen 
                      : AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  '$completionPercentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space12),
          
          // Progress bar
          LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: AppTheme.mediumGrey,
            valueColor: AlwaysStoppedAnimation<Color>(
              completionPercentage == 100 
                  ? AppTheme.accentGreen 
                  : AppTheme.accentOrange,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          // Requirements list
          ...requirements.map((req) => _buildRequirementItem(req)),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(Map<String, dynamic> requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            requirement['completed'] 
                ? Icons.check_circle 
                : Icons.radio_button_unchecked,
            color: requirement['completed'] 
                ? AppTheme.accentGreen 
                : AppTheme.mediumGrey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              requirement['title'],
              style: DesignTokens.bodyMedium.copyWith(
                color: requirement['completed'] 
                    ? Colors.white 
                    : AppTheme.lightGrey,
                decoration: requirement['completed'] 
                    ? TextDecoration.lineThrough 
                    : null,
              ),
            ),
          ),
          if (requirement['action'] != null)
            TextButton(
              onPressed: requirement['action'],
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              child: Text(
                requirement['completed'] ? 'Edit' : 'Add',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolioOverview() {
    final isComplete = _profile?.isComplete ?? false;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF6A6475),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Portfolio Overview',
                style: DesignTokens.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isComplete)
                const Icon(
                  Icons.verified,
                  color: AppTheme.accentGreen,
                  size: 20,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  ),
                  child: const Text(
                    'Incomplete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.space16),
          
          if (_profile != null) ...[
            _buildPortfolioItem('Display Name', _profile!.displayName),
            _buildPortfolioItem('Headline', _profile!.headline),
            _buildPortfolioItem('Bio', _profile!.bio),
            _buildPortfolioItem('Specialties', _profile!.specialties.join(', ')),
            _buildPortfolioItem('Intro Video', _profile!.introVideoUrl != null ? 'Uploaded' : 'Not uploaded'),
          ] else ...[
            const Text(
              'No portfolio created yet',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: DesignTokens.space16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PortfolioEditScreen(existingProfile: _profile),
                  ),
                );
                if (result == true) {
                  unawaited(_loadAllData());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Edit Portfolio'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: DesignTokens.bodySmall.copyWith(
                color: AppTheme.lightGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : 'Not set',
              style: DesignTokens.bodySmall.copyWith(
                color: value?.isNotEmpty == true ? Colors.white : AppTheme.mediumGrey,
                fontStyle: value?.isNotEmpty == true ? null : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingServices() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF6A6475),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.attach_money,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Pricing & Services',
                style: DesignTokens.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space16),
          
          if (_pricingProfile != null) ...[
            _buildPricingItem('Personal Training', _pricingProfile!['personal_training_rate']),
            _buildPricingItem('Nutrition Coaching', _pricingProfile!['nutrition_rate']),
            _buildPricingItem('Group Sessions', _pricingProfile!['group_rate']),
            _buildPricingItem('Online Coaching', _pricingProfile!['online_rate']),
          ] else ...[
            const Text(
              'No pricing set up yet',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: DesignTokens.space16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showPricingSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accentBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Setup Pricing'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingItem(String service, dynamic rate) {
    final rateText = rate != null ? '\$${rate.toString()}' : 'Not set';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$service:',
              style: DesignTokens.bodySmall.copyWith(
                color: AppTheme.lightGrey,
              ),
            ),
          ),
          Text(
            rateText,
            style: DesignTokens.bodySmall.copyWith(
              color: rate != null ? Colors.white : AppTheme.mediumGrey,
              fontStyle: rate != null ? null : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSharing() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF6A6475),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.share,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Content Sharing',
                style: DesignTokens.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space16),
          
          Text(
            'Media Posts: ${_media.length}',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Public Content: ${_media.where((m) => m.visibility == 'public' && m.isApproved).length}',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _showAddContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.accentPink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Content'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showContentManagement,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGreen,
                    side: const BorderSide(color: AppTheme.accentGreen),
                  ),
                  child: const Text('Manage'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessProfile() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF6A6475),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Business Profile',
                style: DesignTokens.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space16),
          
          if (_businessProfile != null) ...[
            _buildBusinessItem('Business Name', _businessProfile!['business_name']),
            _buildBusinessItem('Business Type', _businessProfile!['business_type']),
            _buildBusinessItem('Website', _businessProfile!['website']),
            _buildBusinessItem('Location', _businessProfile!['city']),
          ] else ...[
            const Text(
              'No business profile created yet',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: DesignTokens.space16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusinessProfileScreen(),
                  ),
                );
                if (result == true) {
                  unawaited(_loadAllData());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accentPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Edit Business Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: DesignTokens.bodySmall.copyWith(
                color: AppTheme.lightGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : 'Not set',
              style: DesignTokens.bodySmall.copyWith(
                color: value?.toString().isNotEmpty == true ? Colors.white : AppTheme.mediumGrey,
                fontStyle: value?.toString().isNotEmpty == true ? null : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF6A6475),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: DesignTokens.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'View Public Profile',
                  Icons.public,
                  AppTheme.accentGreen,
                  _viewPublicProfile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Share Profile',
                  Icons.share,
                  DesignTokens.accentBlue,
                  _shareProfile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  List<Map<String, dynamic>> _getMarketplaceRequirements() {
    return [
      {
        'title': 'Complete Portfolio Profile',
        'completed': _profile?.isComplete ?? false,
        'action': () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PortfolioEditScreen(existingProfile: _profile),
            ),
          );
          if (result == true) unawaited(_loadAllData());
        },
      },
      {
        'title': 'Upload Intro Video',
        'completed': _profile?.introVideoUrl?.isNotEmpty ?? false,
        'action': () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PortfolioEditScreen(existingProfile: _profile),
            ),
          );
          if (result == true) unawaited(_loadAllData());
        },
      },
      {
        'title': 'Setup Pricing',
        'completed': _pricingProfile != null,
        'action': _showPricingSetup,
      },
      {
        'title': 'Create Business Profile',
        'completed': _businessProfile != null,
        'action': () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BusinessProfileScreen(),
            ),
          );
          if (result == true) unawaited(_loadAllData());
        },
      },
      {
        'title': 'Add Content (3+ posts)',
        'completed': _media.length >= 3,
        'action': _showAddContent,
      },
      {
        'title': 'Public Content Approved',
        'completed': _media.any((m) => m.visibility == 'public' && m.isApproved),
        'action': _showContentManagement,
      },
    ];
  }

  void _showPricingSetup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF6A6475),
        title: const Text(
          'Setup Pricing',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Pricing setup dialog will be implemented here.',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF6A6475),
        title: const Text(
          'Add Content',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Content creation dialog will be implemented here.',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showContentManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF6A6475),
        title: const Text(
          'Manage Content',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Content management dialog will be implemented here.',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPublicProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF6A6475),
        title: const Text(
          'View Public Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Public profile view will be implemented here.',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _shareProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF6A6475),
        title: const Text(
          'Share Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Profile sharing dialog will be implemented here.',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }
}
