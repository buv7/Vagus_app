import 'package:flutter/material.dart';
import '../../services/billing/billing_service.dart';

class InvoiceHistoryViewer extends StatefulWidget {
  const InvoiceHistoryViewer({super.key});

  @override
  State<InvoiceHistoryViewer> createState() => _InvoiceHistoryViewerState();
}

class _InvoiceHistoryViewerState extends State<InvoiceHistoryViewer> {
  final BillingService _billingService = BillingService.instance;
  
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _loading = true;
    });

    try {
      final invoices = await _billingService.listInvoices();
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoices: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'open':
        return Colors.orange;
      case 'void':
        return Colors.grey;
      case 'uncollectible':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final amountCents = invoice['amount_cents'] as int? ?? 0;
    final amount = amountCents / 100.0;
    final status = invoice['status'] as String? ?? 'open';
    final createdAt = invoice['created_at'] as String? ?? '';
    final dueAt = invoice['due_at'] as String?;
    final planCode = invoice['plan_code'] as String?;
    final externalId = invoice['external_invoice_id'] as String?;
    final currency = invoice['currency'] as String? ?? 'USD';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(
            status == 'paid' ? Icons.check : Icons.receipt,
            color: Colors.white,
          ),
        ),
        title: Text('${currency == 'USD' ? '\$' : currency}${amount.toStringAsFixed(2)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${status.toUpperCase()}'),
            if (planCode != null) Text('Plan: ${planCode.toUpperCase()}'),
            Text('Created: $createdAt'),
            if (dueAt != null) Text('Due: $dueAt'),
          ],
        ),
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
                tooltip: 'View External Invoice',
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📄 Invoice History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No invoices found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInvoices,
                  child: ListView.builder(
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      return _buildInvoiceCard(_invoices[index]);
                    },
                  ),
                ),
    );
  }
}
