import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/call_participant.dart';
import '../../theme/design_tokens.dart';

class ConnectionQualityIndicator extends StatelessWidget {
  final ConnectionQuality quality;

  const ConnectionQualityIndicator({
    super.key,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQualityIcon(),
          const SizedBox(width: 4),
          _buildQualityText(),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildQualityIcon() {
    Color color;
    IconData icon;
    
    switch (quality) {
      case ConnectionQuality.excellent:
        color = Colors.green;
        icon = Icons.signal_cellular_4_bar;
        break;
      case ConnectionQuality.good:
        color = Colors.green;
        icon = Icons.signal_cellular_alt;
        break;
      case ConnectionQuality.fair:
        color = Colors.orange;
        icon = Icons.signal_cellular_alt_2_bar;
        break;
      case ConnectionQuality.poor:
        color = Colors.red;
        icon = Icons.signal_cellular_alt_1_bar;
        break;
    }
    
    return Icon(
      icon,
      color: color,
      size: 16,
    );
  }

  Widget _buildQualityText() {
    String text;
    Color color;
    
    switch (quality) {
      case ConnectionQuality.excellent:
        text = 'Excellent';
        color = Colors.green;
        break;
      case ConnectionQuality.good:
        text = 'Good';
        color = Colors.green;
        break;
      case ConnectionQuality.fair:
        text = 'Fair';
        color = Colors.orange;
        break;
      case ConnectionQuality.poor:
        text = 'Poor';
        color = Colors.red;
        break;
    }
    
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
