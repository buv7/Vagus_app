import 'package:flutter/material.dart';
import '../../services/billing/billing_service.dart';
import '../../theme/app_theme.dart';
import 'invoice_history_viewer.dart';

class BillingSettings extends StatefulWidget {
  const BillingSettings({super.key});

  @override
  State<BillingSettings> createState() => _BillingSettingsState();
}

class _BillingSettingsState extends State<BillingSettings> {
  final BillingService _billingService = BillingService.instance;
  
  Map<String, dynamic>? _subscription;
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final subscription = await _billingService.getMySubscription();
      final invoices = await _billingService.listInvoices();

      setState(() {
        _subscription = subscription;
        _invoices = invoices;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading billing data: $e')),
        );
      }
    }
  }

  Future<void> _cancelAtPeriodEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Your subscription will remain active until the end of the current billing period. '
          'You can resume it anytime before then.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel at Period End'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _billingService.cancelAtPeriodEnd();
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Subscription will cancel at period end')),
        );
      }
    }
  }

  Future<void> _resumeSubscription() async {
    await _billingService.resume();
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Subscription resumed')),
      );
    }
  }

  void _viewInvoices() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InvoiceHistoryViewer(),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    if (_subscription == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card_off,
              color: Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'No active subscription',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final planCode = _subscription!['plan_code'] as String? ?? 'free';
    final status = _subscription!['status'] as String? ?? 'active';
    final periodEnd = _subscription!['period_end'] as String?;
    final cancelAtPeriodEnd = _subscription!['cancel_at_period_end'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAqua.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: AppTheme.mintAqua,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Plan: ${planCode.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active' ? AppTheme.mintAqua : AppTheme.softYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (periodEnd != null)
            Text(
              'Renews: $periodEnd',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          if (cancelAtPeriodEnd)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.softYellow.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppTheme.softYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Will cancel at period end',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (cancelAtPeriodEnd)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resumeSubscription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mintAqua,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelAtPeriodEnd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel at Period End',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Widget _buildInvoicesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    color: AppTheme.mintAqua,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Invoices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.mintAqua.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: _viewInvoices,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.mintAqua,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_invoices.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No invoices found',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 16),
            ..._invoices.take(3).map((invoice) {
              final amountCents = invoice['amount_cents'] as int? ?? 0;
              final amount = amountCents / 100.0;
              final status = invoice['status'] as String? ?? 'open';
              final createdAt = invoice['created_at'] as String? ?? '';
              final externalId = invoice['external_invoice_id'] as String?;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                    Icon(
                      Icons.receipt,
                      color: AppTheme.mintAqua,
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$status • $createdAt',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (externalId != null)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.mintAqua.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.open_in_new,
                            color: AppTheme.mintAqua,
                            size: 16,
                          ),
                          onPressed: () async {
                            // This would typically open the Stripe invoice URL
                            // For now, just show a message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('External invoice links not configured'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
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
          'Billing & Upgrade',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.mintAqua.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: AppTheme.mintAqua,
              ),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.mintAqua,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubscriptionCard(),
                  _buildInvoicesCard(),
                ],
              ),
            ),
    );
  }
}
