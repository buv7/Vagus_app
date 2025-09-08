import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/growth/referrals_models.dart';
import '../../services/growth/referrals_service.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class EarnRewardsScreen extends StatefulWidget {
  const EarnRewardsScreen({super.key});

  @override
  State<EarnRewardsScreen> createState() => _EarnRewardsScreenState();
}

class _EarnRewardsScreenState extends State<EarnRewardsScreen> {
  final ReferralsService _referralsService = ReferralsService();
  
  String? _myCode;
  List<Referral> _referrals = [];
  ReferralMonthlyCap? _monthlyCap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final code = await _referralsService.getOrCreateMyCode();
      final referrals = await _referralsService.listMyReferrals();
      final monthlyCap = await _referralsService.getMonthlyCap();
      
      setState(() {
        _myCode = code;
        _referrals = referrals;
        _monthlyCap = monthlyCap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading earn rewards data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyLink() async {
    if (_myCode == null) return;
    
    try {
      final uri = await _referralsService.buildShareUri(_myCode!);
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral link copied to clipboard!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to copy link')),
        );
      }
    }
  }

  Future<void> _shareLink() async {
    if (_myCode == null) return;
    
    try {
      await _referralsService.shareReferralLink(_myCode!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Earn Rewards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.mintAqua,
              ),
            )
          : RefreshIndicator(
              color: AppTheme.mintAqua,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCodeSection(),
                    const SizedBox(height: 16),
                    _buildHowRewardsWorkSection(),
                    const SizedBox(height: 16),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCodeSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Code & Link',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referral Code',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _myCode ?? 'Loading...',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.mintAqua,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _copyLink,
                  icon: Icon(Icons.copy, size: 18, color: AppTheme.mintAqua),
                  tooltip: 'Copy link',
                ),
                IconButton(
                  onPressed: _shareLink,
                  icon: Icon(Icons.share, size: 18, color: AppTheme.mintAqua),
                  tooltip: 'Share link',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mintAqua,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareLink,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowRewardsWorkSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'How Rewards Work',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRewardItem(
            icon: Icons.star,
            title: '7 Pro Days',
            description: 'Both you and your friend get 7 days of Pro features',
            color: AppTheme.mintAqua,
          ),
          const SizedBox(height: 12),
          _buildRewardItem(
            icon: Icons.trending_up,
            title: '50 VP Points',
            description: 'You earn 50 VP points for each successful referral',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildRewardItem(
            icon: Icons.shield,
            title: 'Shield Milestones',
            description: 'Earn Shield at 3, 8, 13, 18... successful referrals',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Notes:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Monthly cap: 5 rewarded referrals\n'
                  '• Rewards only granted on first milestone\n'
                  '• Pro days don\'t stack with checkout coupons\n'
                  '• VP still granted even with coupon usage',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Referral History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_monthlyCap != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _monthlyCap!.isAtCap 
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _monthlyCap!.isAtCap 
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${_monthlyCap!.referralCount}/5 this month',
                    style: TextStyle(
                      fontSize: 12,
                      color: _monthlyCap!.isAtCap ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_referrals.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No referrals yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your link to start earning rewards!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _referrals.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final referral = _referrals[index];
                return _buildReferralHistoryItem(referral);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReferralHistoryItem(Referral referral) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(referral),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Referred ${_formatDate(referral.createdAt)}',
                      style: DesignTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    _buildStatusChip(referral),
                  ],
                ),
                const SizedBox(height: 4),
                if (referral.milestone != null)
                  Text(
                    'Milestone: ${referral.milestone}',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.ink600,
                    ),
                  ),
                if (referral.isRewarded)
                  Text(
                    'Rewarded: ${_formatDate(referral.rewardedAt!)}',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (referral.isQueued)
                  Text(
                    'Queued for next month',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.warn,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Referral referral) {
    String text;
    Color color;
    
    if (referral.fraudFlag) {
      text = 'Flagged';
      color = DesignTokens.danger;
    } else if (referral.isQueued) {
      text = 'Queued';
      color = DesignTokens.warn;
    } else if (referral.isRewarded) {
      text = 'Rewarded';
      color = DesignTokens.success;
    } else if (referral.milestone != null) {
      text = 'Milestone';
      color = DesignTokens.blue500;
    } else {
      text = 'Pending';
      color = DesignTokens.ink500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: DesignTokens.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(Referral referral) {
    if (referral.fraudFlag) return DesignTokens.danger;
    if (referral.isQueued) return DesignTokens.warn;
    if (referral.isRewarded) return DesignTokens.success;
    if (referral.milestone != null) return DesignTokens.blue500;
    return DesignTokens.ink400;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) return 'today';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).round()} weeks ago';
    return '${(difference.inDays / 30).round()} months ago';
  }
}
