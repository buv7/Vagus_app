import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class QRScannerFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const QRScannerFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.accentBlue.withValues(alpha: 0.3),
            DesignTokens.accentBlue.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          child: const Center(
            child: Icon(
              Icons.qr_code_scanner,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
