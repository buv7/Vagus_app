import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class BillingPaymentsScreen extends StatefulWidget {
  const BillingPaymentsScreen({super.key});

  @override
  State<BillingPaymentsScreen> createState() => _BillingPaymentsScreenState();
}

class _BillingPaymentsScreenState extends State<BillingPaymentsScreen> {
  final supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _subscription;
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBillingData();
  }

  Future<void> _loadBillingData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
      });

      // Load subscription data
      final subscription = await _loadSubscription(user.id);
      
      // Load payment history
      final payments = await _loadPayments(user.id);

      setState(() {
        _subscription = subscription;
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _loadSubscription(String userId) async {
    try {
      // Try to load from subscriptions table
      final response = await supabase
          .from('subscriptions')
          .select('*')
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      // Return mock subscription data
      return {
        'plan_name': 'Pro Coach',
        'status': 'active',
        'price': 29.99,
        'billing_cycle': 'monthly',
        'next_billing_date': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        'features': [
          'Unlimited clients',
          'Advanced analytics',
          'Priority support',
          'Custom branding',
        ],
      };
    }
  }

  Future<List<Map<String, dynamic>>> _loadPayments(String userId) async {
    try {
      // Try to load from payments table
      final response = await supabase
          .from('payments')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return mock payment data
      return [
        {
          'id': '1',
          'amount': 29.99,
          'status': 'completed',
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'description': 'Pro Coach Plan - Monthly',
        },
        {
          'id': '2',
          'amount': 29.99,
          'status': 'completed',
          'created_at': DateTime.now().subtract(const Duration(days: 31)).toIso8601String(),
          'description': 'Pro Coach Plan - Monthly',
        },
        {
          'id': '3',
          'amount': 29.99,
          'status': 'completed',
          'created_at': DateTime.now().subtract(const Duration(days: 61)).toIso8601String(),
          'description': 'Pro Coach Plan - Monthly',
        },
      ];
    }
  }

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
          'Billing & Payments',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        actions: [
          IconButton(
            onPressed: () => _showBillingSettings(),
            icon: const Icon(Icons.settings, color: AppTheme.neutralWhite),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mintAqua),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Subscription
                  if (_subscription != null) ...[
                    _buildSectionTitle('Current Subscription'),
                    const SizedBox(height: DesignTokens.space16),
                    _buildSubscriptionCard(),
                    const SizedBox(height: DesignTokens.space32),
                  ],

                  // Payment Methods
                  _buildSectionTitle('Payment Methods'),
                  const SizedBox(height: DesignTokens.space16),
                  _buildPaymentMethodCard(),
                  const SizedBox(height: DesignTokens.space32),

                  // Payment History
                  _buildSectionTitle('Payment History'),
                  const SizedBox(height: DesignTokens.space16),
                  _buildPaymentHistory(),

                  const SizedBox(height: DesignTokens.space32),

                  // Billing Actions
                  _buildSectionTitle('Billing Actions'),
                  const SizedBox(height: DesignTokens.space16),
                  _buildBillingActions(),

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

  Widget _buildSubscriptionCard() {
    final subscription = _subscription!;
    final isActive = subscription['status'] == 'active';
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: isActive ? DesignTokens.success : DesignTokens.danger,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space8),
                decoration: BoxDecoration(
                  color: isActive ? DesignTokens.success : DesignTokens.danger,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(
                  isActive ? Icons.check : Icons.close,
                  color: AppTheme.neutralWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription['plan_name'] ?? 'No Plan',
                      style: const TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: isActive ? DesignTokens.success : DesignTokens.danger,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${subscription['price']?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  color: AppTheme.mintAqua,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          Text(
            'Billed ${subscription['billing_cycle'] ?? 'monthly'}',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 14,
            ),
          ),
          
          if (subscription['next_billing_date'] != null) ...[
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Next billing: ${_formatDate(subscription['next_billing_date'])}',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: DesignTokens.space16),
          
          // Features
          if (subscription['features'] != null) ...[
            Text(
              'Features:',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            ...(subscription['features'] as List).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space4),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    color: DesignTokens.success,
                    size: 16,
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Text(
                    feature.toString(),
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.steelGrey,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space12),
                decoration: BoxDecoration(
                  color: AppTheme.mintAqua.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: AppTheme.mintAqua,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visa ending in 4242',
                      style: TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Expires 12/25',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _updatePaymentMethod(),
                icon: const Icon(
                  Icons.edit,
                  color: AppTheme.mintAqua,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _addPaymentMethod(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.mintAqua),
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
              ),
              child: const Text(
                'Add Payment Method',
                style: TextStyle(
                  color: AppTheme.mintAqua,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    if (_payments.isEmpty) {
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
                Icons.receipt_long,
                color: AppTheme.lightGrey,
                size: 48,
              ),
              const SizedBox(height: DesignTokens.space16),
              Text(
                'No payment history',
                style: TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _payments.map((payment) => _buildPaymentItem(payment)).toList(),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final amount = payment['amount'] as double? ?? 0.0;
    final status = payment['status'] as String? ?? 'unknown';
    final isCompleted = status == 'completed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: AppTheme.steelGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space8),
            decoration: BoxDecoration(
              color: isCompleted ? DesignTokens.success : DesignTokens.danger,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.close,
              color: AppTheme.neutralWhite,
              size: 16,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['description'] ?? 'Payment',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(payment['created_at']),
                  style: TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: isCompleted ? DesignTokens.success : DesignTokens.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingActions() {
    return Column(
      children: [
        _buildActionButton(
          title: 'Upgrade Plan',
          subtitle: 'Get more features and capabilities',
          icon: Icons.upgrade,
          onTap: () => _upgradePlan(),
        ),
        const SizedBox(height: DesignTokens.space12),
        _buildActionButton(
          title: 'Download Invoices',
          subtitle: 'Download your billing invoices',
          icon: Icons.download,
          onTap: () => _downloadInvoices(),
        ),
        const SizedBox(height: DesignTokens.space12),
        _buildActionButton(
          title: 'Cancel Subscription',
          subtitle: 'Cancel your current subscription',
          icon: Icons.cancel,
          isDestructive: true,
          onTap: () => _cancelSubscription(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
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
          icon,
          color: isDestructive ? DesignTokens.danger : AppTheme.mintAqua,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? DesignTokens.danger : AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
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
        onTap: onTap,
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  void _showBillingSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Billing settings coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _updatePaymentMethod() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Update payment method coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _addPaymentMethod() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add payment method coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _upgradePlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan upgrade coming soon'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _downloadInvoices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading invoices...'),
        backgroundColor: AppTheme.mintAqua,
      ),
    );
  }

  void _cancelSubscription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Cancel Subscription',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features.',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Keep Subscription',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription cancellation initiated'),
                  backgroundColor: DesignTokens.danger,
                ),
              );
            },
            child: const Text(
              'Cancel Subscription',
              style: TextStyle(color: DesignTokens.danger),
            ),
          ),
        ],
      ),
    );
  }
}
