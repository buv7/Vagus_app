import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/growth/referrals_models.dart';
import '../../services/growth/referrals_service.dart';
import '../../theme/design_tokens.dart';

/// Widget for displaying referral invitation card on home screen
class InviteCard extends StatefulWidget {
  const InviteCard({super.key});

  @override
  State<InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<InviteCard> {
  final ReferralsService _referralsService = ReferralsService();
  
  String? _myCode;
  List<Referral> _recentReferrals = [];
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
        _recentReferrals = referrals.take(3).toList();
        _monthlyCap = monthlyCap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading invite data: $e');
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
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 16),
              Text(
                'Loading referral info...',
                style: DesignTokens.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCodeSection(),
            const SizedBox(height: 16),
            _buildProgressSection(),
            if (_recentReferrals.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRecentReferrals(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.card_giftcard,
          color: DesignTokens.blue500,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Invite & Earn',
          style: DesignTokens.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Referral Code',
          style: DesignTokens.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: DesignTokens.ink600,
          ),
        ),
        const SizedBox(height: 8),
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
                child: Text(
                  _myCode ?? 'Loading...',
                  style: DesignTokens.bodyMedium.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.blue700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _copyLink,
                icon: const Icon(Icons.copy, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'Copy link',
              ),
              IconButton(
                onPressed: _shareLink,
                icon: const Icon(Icons.share, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'Share link',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    final currentCount = _monthlyCap?.referralCount ?? 0;
    final remaining = _monthlyCap?.remaining ?? 5;
    final isAtCap = _monthlyCap?.isAtCap ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: DesignTokens.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: DesignTokens.ink600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAtCap ? DesignTokens.warn.withValues(alpha: 0.1) : DesignTokens.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAtCap ? DesignTokens.warn.withValues(alpha: 0.3) : DesignTokens.success.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                isAtCap ? 'Monthly Cap Reached' : '$remaining remaining',
                style: DesignTokens.bodySmall.copyWith(
                  color: isAtCap ? DesignTokens.warn : DesignTokens.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: currentCount / 5,
          backgroundColor: DesignTokens.ink100,
          valueColor: AlwaysStoppedAnimation<Color>(
            isAtCap ? DesignTokens.warn : DesignTokens.success,
          ),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          '$currentCount / 5 referrals this month',
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.ink500,
          ),
        ),
        const SizedBox(height: 8),
        _buildShieldProgress(),
      ],
    );
  }

  Widget _buildShieldProgress() {
    // Calculate Shield progress (3 for first Shield, then +1 every 5)
    final successfulReferrals = _recentReferrals.where((r) => r.isRewarded).length;
    final nextShieldMilestone = successfulReferrals < 3 ? 3 : 3 + ((successfulReferrals - 3) ~/ 5 + 1) * 5;
    final progress = successfulReferrals / nextShieldMilestone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.shield,
              size: 16,
              color: DesignTokens.blue500,
            ),
            const SizedBox(width: 4),
            Text(
              'Shield Progress',
              style: DesignTokens.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: DesignTokens.ink600,
              ),
            ),
            const Spacer(),
            Text(
              '$successfulReferrals / $nextShieldMilestone',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: DesignTokens.ink100,
          valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.blue500),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildRecentReferrals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Referrals',
          style: DesignTokens.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: DesignTokens.ink600,
          ),
        ),
        const SizedBox(height: 8),
        ...(_recentReferrals.map((referral) => _buildReferralItem(referral))),
      ],
    );
  }

  Widget _buildReferralItem(Referral referral) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(referral),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referred ${_formatDate(referral.createdAt)}',
                  style: DesignTokens.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getStatusText(referral),
                  style: DesignTokens.bodySmall.copyWith(
                    color: DesignTokens.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(Referral referral) {
    if (referral.fraudFlag) return DesignTokens.danger;
    if (referral.isQueued) return DesignTokens.warn;
    if (referral.isRewarded) return DesignTokens.success;
    return DesignTokens.ink400;
  }

  String _getStatusText(Referral referral) {
    if (referral.fraudFlag) return 'Flagged';
    if (referral.isQueued) return 'Queued for next month';
    if (referral.isRewarded) return 'Rewarded';
    if (referral.milestone != null) return 'Milestone: ${referral.milestone}';
    return 'Pending';
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
