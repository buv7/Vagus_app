import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/growth/referrals_models.dart';
import '../../services/growth/referrals_service.dart';
import '../../theme/design_tokens.dart';

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
      appBar: AppBar(
        title: const Text('Earn Rewards'),
        backgroundColor: DesignTokens.blue500,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCodeSection(),
                    const SizedBox(height: 24),
                    _buildHowRewardsWorkSection(),
                    const SizedBox(height: 24),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCodeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: DesignTokens.blue500,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Code & Link',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.blue50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.blue200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Referral Code',
                          style: DesignTokens.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: DesignTokens.ink600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _myCode ?? 'Loading...',
                          style: DesignTokens.bodyMedium.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.blue700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy link',
                  ),
                  IconButton(
                    onPressed: _shareLink,
                    icon: const Icon(Icons.share, size: 20),
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
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.blue500,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareLink,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowRewardsWorkSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  color: DesignTokens.blue500,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'How Rewards Work',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRewardItem(
              icon: Icons.star,
              title: '7 Pro Days',
              description: 'Both you and your friend get 7 days of Pro features',
              color: DesignTokens.blue500,
            ),
            const SizedBox(height: 12),
            _buildRewardItem(
              icon: Icons.trending_up,
              title: '50 VP Points',
              description: 'You earn 50 VP points for each successful referral',
              color: DesignTokens.success,
            ),
            const SizedBox(height: 12),
            _buildRewardItem(
              icon: Icons.shield,
              title: 'Shield Milestones',
              description: 'Earn Shield at 3, 8, 13, 18... successful referrals',
              color: DesignTokens.warn,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.ink50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.ink200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important Notes:',
                    style: DesignTokens.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.ink700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Monthly cap: 5 rewarded referrals\n'
                    '• Rewards only granted on first milestone\n'
                    '• Pro days don\'t stack with checkout coupons\n'
                    '• VP still granted even with coupon usage',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.ink600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                style: DesignTokens.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: DesignTokens.bodySmall.copyWith(
                  color: DesignTokens.ink600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history,
                  color: DesignTokens.blue500,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Referral History',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_monthlyCap != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _monthlyCap!.isAtCap 
                          ? DesignTokens.warn.withValues(alpha: 0.1)
                          : DesignTokens.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _monthlyCap!.isAtCap 
                            ? DesignTokens.warn.withValues(alpha: 0.3)
                            : DesignTokens.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_monthlyCap!.referralCount}/5 this month',
                      style: DesignTokens.bodySmall.copyWith(
                        color: _monthlyCap!.isAtCap ? DesignTokens.warn : DesignTokens.success,
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
                    const Icon(
                      Icons.people_outline,
                      size: 48,
                      color: DesignTokens.ink400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No referrals yet',
                      style: DesignTokens.bodyMedium.copyWith(
                        color: DesignTokens.ink500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share your link to start earning rewards!',
                      style: DesignTokens.bodySmall.copyWith(
                        color: DesignTokens.ink400,
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
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final referral = _referrals[index];
                  return _buildReferralHistoryItem(referral);
                },
              ),
          ],
        ),
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
