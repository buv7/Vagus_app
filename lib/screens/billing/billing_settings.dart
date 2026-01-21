import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/billing/billing_service.dart';
import '../../theme/design_tokens.dart';
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
    setState(() => _loading = true);

    try {
      final subscription = await _billingService.getMySubscription();
      final invoices = await _billingService.listInvoices();

      setState(() {
        _subscription = subscription;
        _invoices = invoices;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
        backgroundColor: DesignTokens.accentBlue.withValues(alpha: 0.9),
        title: const Text('Cancel Subscription', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your subscription will remain active until the end of the current billing period. '
          'You can resume it anytime before then.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel at Period End', style: TextStyle(color: Colors.white)),
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
      return _buildGlassmorphicCard(
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

    return _buildGlassmorphicCard(
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
                    color: Colors.white.withValues(alpha: 0.9),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active' 
                      ? const Color(0xFF00D4AA).withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status == 'active' 
                        ? const Color(0xFF00D4AA)
                        : Colors.orange,
                    width: 1,
                  ),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange.withValues(alpha: 0.9),
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
                  child: _buildGlassmorphicButton(
                    onPressed: _resumeSubscription,
                    color: const Color(0xFF00D4AA),
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: _buildGlassmorphicButton(
                    onPressed: _cancelAtPeriodEnd,
                    color: Colors.red,
                    child: const Text(
                      'Cancel at Period End',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
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
    return _buildGlassmorphicCard(
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
                    color: Colors.white.withValues(alpha: 0.9),
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
                  color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                  ),
                ),
                child: TextButton(
                  onPressed: _viewInvoices,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
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
                color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                ),
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
                  color: DesignTokens.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      color: Colors.white.withValues(alpha: 0.8),
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
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (externalId != null)
                      Container(
                        decoration: BoxDecoration(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.open_in_new,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 16,
                          ),
                          onPressed: () async {
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

  Widget _buildGlassmorphicCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
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
                  color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                  blurRadius: 15,
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

  Widget _buildGlassmorphicButton({
    required VoidCallback onPressed,
    required Widget child,
    Color? color,
  }) {
    final baseColor = color ?? DesignTokens.accentBlue;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                baseColor.withValues(alpha: 0.4),
                baseColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: baseColor.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B1220),
        elevation: 0,
        title: Text(
          'Billing & Upgrade',
          style: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0B1220),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: DesignTokens.accentBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.4),
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: theme.brightness == Brightness.dark ? Colors.white : DesignTokens.accentBlue,
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
                color: DesignTokens.accentBlue,
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
