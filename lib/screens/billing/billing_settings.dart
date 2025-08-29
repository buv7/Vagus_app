import 'package:flutter/material.dart';
import '../../services/billing/billing_service.dart';
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No active subscription'),
        ),
      );
    }

    final planCode = _subscription!['plan_code'] as String? ?? 'free';
    final status = _subscription!['status'] as String? ?? 'active';
    final periodEnd = _subscription!['period_end'] as String?;
    final cancelAtPeriodEnd = _subscription!['cancel_at_period_end'] as bool? ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Plan: ${planCode.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'active' ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (periodEnd != null)
              Text('Renews: $periodEnd'),
            if (cancelAtPeriodEnd)
              const Text(
                '⚠️ Will cancel at period end',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
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
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Resume'),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelAtPeriodEnd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel at Period End'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invoices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _viewInvoices,
                  child: const Text('View All'),
                ),
              ],
            ),
            if (_invoices.isEmpty)
              const Text('No invoices found')
            else ...[
              const SizedBox(height: 8),
              ..._invoices.take(3).map((invoice) {
                final amountCents = invoice['amount_cents'] as int? ?? 0;
                final amount = amountCents / 100.0;
                final status = invoice['status'] as String? ?? 'open';
                final createdAt = invoice['created_at'] as String? ?? '';
                final externalId = invoice['external_invoice_id'] as String?;

                return ListTile(
                  title: Text('\$${amount.toStringAsFixed(2)}'),
                  subtitle: Text('$status • $createdAt'),
                  trailing: externalId != null
                      ? IconButton(
                          icon: const Icon(Icons.open_in_new),
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
                        )
                      : null,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Billing Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubscriptionCard(),
                  const SizedBox(height: 16),
                  _buildInvoicesCard(),
                ],
              ),
            ),
    );
  }
}
