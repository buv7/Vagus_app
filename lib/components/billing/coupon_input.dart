import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme_index.dart';
import '../../services/core/logger.dart';

/// Coupon code input with validation
class CouponInput extends StatefulWidget {
  final Function(CouponData) onCouponApplied;
  final Function()? onCouponRemoved;

  const CouponInput({
    super.key,
    required this.onCouponApplied,
    this.onCouponRemoved,
  });

  @override
  State<CouponInput> createState() => _CouponInputState();
}

class _CouponInputState extends State<CouponInput> {
  final _controller = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  bool _loading = false;
  CouponData? _appliedCoupon;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _controller.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a coupon code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Call validation function
      final result = await _supabase.rpc('validate_coupon_code', params: {
        'p_code': code,
      });

      if (result == null || result.isEmpty) {
        throw Exception('Invalid response from server');
      }

      final data = result[0] as Map<String, dynamic>;
      final isValid = data['is_valid'] as bool;

      if (!isValid) {
        final message = data['message'] as String? ?? 'Invalid coupon';
        setState(() {
          _error = message;
          _loading = false;
        });
        return;
      }

      // Coupon is valid
      final couponData = CouponData(
        code: code,
        percentOff: data['percent_off'] as int?,
        amountOffCents: data['amount_off_cents'] as int?,
      );

      setState(() {
        _appliedCoupon = couponData;
        _loading = false;
        _error = null;
      });

      widget.onCouponApplied(couponData);
      
      Logger.info('Coupon applied', data: {'code': code});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ã¢Å“â€¦ Coupon "$code" applied!'),
            backgroundColor: mintAqua,
          ),
        );
      }
    } catch (e, st) {
      Logger.error('Coupon validation failed', error: e, stackTrace: st);
      setState(() {
        _error = 'Failed to validate coupon';
        _loading = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _controller.clear();
      _error = null;
    });
    widget.onCouponRemoved?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_appliedCoupon != null) {
      return _buildAppliedCoupon();
    }

    return _buildInputField();
  }

  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  prefixIcon: const Icon(Icons.local_offer, color: mintAqua),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusM),
                    borderSide: BorderSide(color: primaryAccent.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusM),
                    borderSide: BorderSide(color: primaryAccent.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusM),
                    borderSide: const BorderSide(color: mintAqua, width: 2),
                  ),
                  errorText: _error,
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _applyCoupon(),
              ),
            ),
            const SizedBox(width: spacing2),
            ElevatedButton(
              onPressed: _loading ? null : _applyCoupon,
              style: ElevatedButton.styleFrom(
                backgroundColor: mintAqua,
                foregroundColor: DesignTokens.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: spacing4,
                  vertical: spacing3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusM),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(DesignTokens.primaryDark),
                      ),
                    )
                  : const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppliedCoupon() {
    final discount = _appliedCoupon!.percentOff != null
        ? '${_appliedCoupon!.percentOff}% off'
        : '\$${(_appliedCoupon!.amountOffCents! / 100).toStringAsFixed(2)} off';

    return Container(
      padding: const EdgeInsets.all(spacing3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            mintAqua.withValues(alpha: 0.2),
            mintAqua.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(
          color: mintAqua,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(spacing2),
            decoration: BoxDecoration(
              color: mintAqua,
              borderRadius: BorderRadius.circular(radiusS),
            ),
            child: const Icon(
              Icons.local_offer,
              color: DesignTokens.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appliedCoupon!.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.neutralWhite,
                  ),
                ),
                Text(
                  discount,
                  style: const TextStyle(
                    fontSize: 14,
                    color: mintAqua,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: DesignTokens.textSecondary),
            onPressed: _removeCoupon,
            tooltip: 'Remove coupon',
          ),
        ],
      ),
    );
  }
}

/// Coupon data model
class CouponData {
  final String code;
  final int? percentOff;
  final int? amountOffCents;

  CouponData({
    required this.code,
    this.percentOff,
    this.amountOffCents,
  });

  /// Calculate discounted price
  int calculateDiscount(int originalCents) {
    if (percentOff != null) {
      return (originalCents * percentOff! / 100).round();
    } else if (amountOffCents != null) {
      return amountOffCents!;
    }
    return 0;
  }

  /// Get final price after discount
  int getFinalPrice(int originalCents) {
    final discount = calculateDiscount(originalCents);
    return (originalCents - discount).clamp(0, originalCents);
  }
}


