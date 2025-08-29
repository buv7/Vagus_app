import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/billing/billing_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final BillingService _billingService = BillingService.instance;
  final TextEditingController _couponController = TextEditingController();
  
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentSubscription;
  bool _loading = true;
  String? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final plans = await _billingService.listPlans();
      final subscription = await _billingService.getMySubscription();

      setState(() {
        _plans = plans;
        _currentSubscription = subscription;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $e')),
        );
      }
    }
  }

  Future<void> _applyCoupon() async {
    final coupon = _couponController.text.trim();
    if (coupon.isEmpty) return;

    final isValid = await _billingService.applyCoupon(coupon);
    
    setState(() {
      _appliedCoupon = isValid ? coupon : null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid ? '✅ Coupon applied!' : '❌ Invalid coupon'),
          backgroundColor: isValid ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _startCheckout(String planCode) async {
    try {
      final result = await _billingService.startCheckout(
        planCode: planCode,
        coupon: _appliedCoupon,
      );

      if (result != null && result['checkout_url'] != null) {
        final url = Uri.parse(result['checkout_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showManualPaymentDialog(result['checkout_url']);
        }
      } else {
        _showManualPaymentDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting checkout: $e')),
        );
      }
    }
  }

  void _showManualPaymentDialog([String? checkoutUrl]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Payment Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please contact an administrator to activate your subscription.'),
            if (checkoutUrl != null) ...[
              const SizedBox(height: 16),
              const Text('Or use this checkout link:'),
              const SizedBox(height: 8),
              SelectableText(
                checkoutUrl,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshStatus() async {
    await _billingService.refreshStatus();
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Status refreshed')),
      );
    }
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isCurrentPlan = _currentSubscription?['plan_code'] == plan['code'];
    final priceCents = plan['price_monthly_cents'] as int? ?? 0;
    final price = priceCents / 100.0;
    final features = plan['features'] as Map<String, dynamic>? ?? {};
    final aiLimit = plan['ai_monthly_limit'] as int? ?? 200;
    final trialDays = plan['trial_days'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['name'] ?? 'Unknown Plan',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}/month',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: price == 0 ? Colors.green : Colors.blue,
              ),
            ),
            if (trialDays > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$trialDays-day free trial',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'AI Calls: $aiLimit/month',
              style: const TextStyle(fontSize: 16),
            ),
            if (features['notes'] != null) ...[
              const SizedBox(height: 8),
              Text(
                features['notes'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!isCurrentPlan)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startCheckout(plan['code']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Upgrade'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Upgrade Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
            tooltip: 'Refresh Status',
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
                  // Coupon section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Have a coupon?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter coupon code',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _appliedCoupon != null
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _applyCoupon,
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                          if (_appliedCoupon != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Coupon applied: $_appliedCoupon',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Plans
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ..._plans.map(_buildPlanCard),
                  
                  const SizedBox(height: 24),
                  
                  // Current subscription info
                  if (_currentSubscription != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Subscription',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Plan: ${_currentSubscription!['plan_code']}'),
                            Text('Status: ${_currentSubscription!['status']}'),
                            if (_currentSubscription!['period_end'] != null)
                              Text('Renews: ${_currentSubscription!['period_end']}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
