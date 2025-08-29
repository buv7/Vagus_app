import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Widget for entering referral codes during signup/onboarding
class ReferralCodeInput extends StatefulWidget {
  final Function(String)? onCodeEntered;
  final String? initialCode;
  final bool showSkipOption;

  const ReferralCodeInput({
    super.key,
    this.onCodeEntered,
    this.initialCode,
    this.showSkipOption = true,
  });

  @override
  State<ReferralCodeInput> createState() => _ReferralCodeInputState();
}

class _ReferralCodeInputState extends State<ReferralCodeInput> {
  final TextEditingController _codeController = TextEditingController();
  
  bool _isValidating = false;
  bool _isValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      _validateCode(widget.initialCode!);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        _isValidating = false;
        _isValid = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      // TODO: Call backend to validate code
      // For now, simulate validation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simple validation: code should be 6-8 characters, alphanumeric
      final isValid = code.length >= 6 && 
                     code.length <= 8 && 
                     RegExp(r'^[a-zA-Z0-9]+$').hasMatch(code);

      setState(() {
        _isValidating = false;
        _isValid = isValid;
        _errorMessage = isValid ? null : 'Invalid referral code format';
      });

      if (isValid && widget.onCodeEntered != null) {
        widget.onCodeEntered!(code.trim());
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _isValid = false;
        _errorMessage = 'Error validating code';
      });
    }
  }

  void _onCodeChanged(String value) {
    _validateCode(value);
  }

  void _onSkipPressed() {
    if (widget.onCodeEntered != null) {
      widget.onCodeEntered!('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referral Code (Optional)',
          style: DesignTokens.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: DesignTokens.ink700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter a friend\'s referral code to earn rewards together',
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.ink600,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          onChanged: _onCodeChanged,
          decoration: InputDecoration(
            hintText: 'Enter referral code',
            prefixIcon: const Icon(Icons.card_giftcard),
            suffixIcon: _isValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _isValid
                    ? const Icon(
                        Icons.check_circle,
                        color: DesignTokens.success,
                        size: 20,
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DesignTokens.ink300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DesignTokens.ink300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DesignTokens.blue500, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DesignTokens.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DesignTokens.danger, width: 2),
            ),
            errorText: _errorMessage,
            filled: true,
            fillColor: DesignTokens.ink50,
          ),
          textCapitalization: TextCapitalization.characters,
          style: DesignTokens.bodyMedium.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_isValid)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: DesignTokens.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: DesignTokens.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Valid referral code! You\'ll both earn rewards.',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.showSkipOption) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _onSkipPressed,
              child: Text(
                'Skip for now',
                style: DesignTokens.bodySmall.copyWith(
                  color: DesignTokens.ink500,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildRewardsPreview(),
      ],
    );
  }

  Widget _buildRewardsPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.blue50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesignTokens.blue200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you\'ll earn:',
            style: DesignTokens.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: DesignTokens.blue700,
            ),
          ),
          const SizedBox(height: 8),
          _buildRewardItem(
            icon: Icons.star,
            text: '7 days of Pro features',
            color: DesignTokens.blue500,
          ),
          const SizedBox(height: 4),
          _buildRewardItem(
            icon: Icons.trending_up,
            text: '50 VP points',
            color: DesignTokens.success,
          ),
          const SizedBox(height: 4),
          _buildRewardItem(
            icon: Icons.shield,
            text: 'Progress toward Shield',
            color: DesignTokens.warn,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.ink700,
          ),
        ),
      ],
    );
  }
}
