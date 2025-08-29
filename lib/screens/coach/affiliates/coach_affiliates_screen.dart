import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/growth/referrals_models.dart';
import '../../../services/growth/referrals_service.dart';
import '../../../theme/design_tokens.dart';

class CoachAffiliatesScreen extends StatefulWidget {
  const CoachAffiliatesScreen({super.key});

  @override
  State<CoachAffiliatesScreen> createState() => _CoachAffiliatesScreenState();
}

class _CoachAffiliatesScreenState extends State<CoachAffiliatesScreen> {
  final ReferralsService _referralsService = ReferralsService();
  
  AffiliateLink? _myLink;
  List<AffiliateConversion> _conversions = [];
  bool _isLoading = true;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final link = await _referralsService.getOrCreateLink();
      final conversions = await _referralsService.listConversions(status: _selectedStatus);
      
      setState(() {
        _myLink = link;
        _conversions = conversions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading affiliates data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLink() async {
    final slugController = TextEditingController(text: _myLink?.slug ?? '');
    final bountyController = TextEditingController(
      text: _myLink?.bountyUsd.toString() ?? '20.00',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Affiliate Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: slugController,
              decoration: const InputDecoration(
                labelText: 'Custom Slug',
                hintText: 'e.g., coach-john',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bountyController,
              decoration: const InputDecoration(
                labelText: 'Bounty (USD)',
                hintText: '20.00',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (slugController.text.isNotEmpty && bountyController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'slug': slugController.text,
                  'bounty': bountyController.text,
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final bounty = double.tryParse(result['bounty']!) ?? 20.00;
        final link = await _referralsService.getOrCreateLink(
          customSlug: result['slug'],
          bountyUsd: bounty,
        );
        
        setState(() => _myLink = link);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Affiliate link updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating link: $e')),
          );
        }
      }
    }
  }

  Future<void> _copyLink() async {
    if (_myLink == null) return;
    
    try {
      await Clipboard.setData(ClipboardData(text: _myLink!.shareUrl));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Affiliate link copied to clipboard!')),
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

  Future<void> _approveConversion(AffiliateConversion conversion) async {
    try {
      final success = await _referralsService.approveConversion(conversion.id);
      
      if (success) {
        await _loadData(); // Reload conversions
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversion approved!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to approve conversion')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _exportPayoutCsv() async {
    try {
      final pendingIds = _conversions
          .where((c) => c.isApproved)
          .map((c) => c.id)
          .toList();
      
      if (pendingIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No approved conversions to export')),
          );
        }
        return;
      }

      final csvUrl = await _referralsService.exportPayoutCsv(conversionIds: pendingIds);
      
      if (csvUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CSV exported successfully!'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // TODO: Open URL
                debugPrint('Opening CSV: $csvUrl');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliates'),
        backgroundColor: DesignTokens.blue500,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
                    _buildLinkSection(),
                    const SizedBox(height: 24),
                    _buildConversionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLinkSection() {
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
                  Icons.link,
                  color: DesignTokens.blue500,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Affiliate Link',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _updateLink,
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit link',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Link',
                              style: DesignTokens.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: DesignTokens.ink600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _myLink?.shareUrl ?? 'Loading...',
                              style: DesignTokens.bodySmall.copyWith(
                                fontFamily: 'monospace',
                                color: DesignTokens.blue700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _copyLink,
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy link',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Slug: ',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: DesignTokens.ink600,
                        ),
                      ),
                      Text(
                        _myLink?.slug ?? 'Loading...',
                        style: DesignTokens.bodySmall.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Bounty: ',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: DesignTokens.ink600,
                        ),
                      ),
                      Text(
                        '\$${_myLink?.bountyUsd.toStringAsFixed(2) ?? '0.00'}',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DesignTokens.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyLink,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Affiliate Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.blue500,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionsSection() {
    final pendingCount = _conversions.where((c) => c.isPending).length;
    final approvedCount = _conversions.where((c) => c.isApproved).length;
    final totalEarnings = _conversions
        .where((c) => c.isApproved || c.isPaid)
        .fold(0.0, (sum, c) => sum + c.amount);

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
                  Icons.trending_up,
                  color: DesignTokens.blue500,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conversions',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (approvedCount > 0)
                  ElevatedButton.icon(
                    onPressed: _exportPayoutCsv,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatsRow(pendingCount, approvedCount, totalEarnings),
            const SizedBox(height: 16),
            _buildStatusFilter(),
            const SizedBox(height: 16),
            if (_conversions.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.trending_up_outlined,
                      size: 48,
                      color: DesignTokens.ink400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No conversions yet',
                      style: DesignTokens.bodyMedium.copyWith(
                        color: DesignTokens.ink500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share your affiliate link to start earning!',
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
                itemCount: _conversions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversion = _conversions[index];
                  return _buildConversionItem(conversion);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int pending, int approved, double totalEarnings) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending',
            pending.toString(),
            DesignTokens.warn,
            Icons.pending,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved',
            approved.toString(),
            DesignTokens.success,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Earnings',
            '\$${totalEarnings.toStringAsFixed(2)}',
            DesignTokens.blue500,
            Icons.attach_money,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: DesignTokens.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.ink600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Row(
      children: [
        Text(
          'Filter: ',
          style: DesignTokens.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: DesignTokens.ink600,
          ),
        ),
        const SizedBox(width: 8),
        ...(['pending', 'approved', 'paid'].map((status) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(status.toUpperCase()),
            selected: _selectedStatus == status,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = status);
                _loadData();
              }
            },
            backgroundColor: DesignTokens.ink100,
            selectedColor: DesignTokens.blue100,
            labelStyle: TextStyle(
              color: _selectedStatus == status ? DesignTokens.blue700 : DesignTokens.ink600,
              fontWeight: _selectedStatus == status ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ))),
      ],
    );
  }

  Widget _buildConversionItem(AffiliateConversion conversion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(conversion),
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
                      'Client ${conversion.clientId.substring(0, 8)}',
                      style: DesignTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${conversion.amount.toStringAsFixed(2)}',
                      style: DesignTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(conversion.createdAt)} • ${conversion.status.toUpperCase()}',
                  style: DesignTokens.bodySmall.copyWith(
                    color: DesignTokens.ink500,
                  ),
                ),
              ],
            ),
          ),
          if (conversion.isPending)
            IconButton(
              onPressed: () => _approveConversion(conversion),
              icon: const Icon(Icons.check, size: 20),
              color: DesignTokens.success,
              tooltip: 'Approve',
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(AffiliateConversion conversion) {
    switch (conversion.status) {
      case 'pending':
        return DesignTokens.warn;
      case 'approved':
        return DesignTokens.success;
      case 'paid':
        return DesignTokens.blue500;
      default:
        return DesignTokens.ink400;
    }
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
