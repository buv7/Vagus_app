import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/navigation/app_navigator.dart';
import '../../theme/design_tokens.dart';

class AiUsageScreen extends StatelessWidget {
  const AiUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0B1220),
        elevation: 0,
        title: Text(
          'AI Usage & Quotas',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0B1220),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGlassmorphicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology, size: 22, color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 8),
                              const Text(
                                'AI Usage & Quotas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildQuotaItem(
                            featureLabel: 'Notes AI',
                            icon: Icons.note,
                            current: 45,
                            total: 100,
                          ),
                          const SizedBox(height: 16),
                          _buildQuotaItem(
                            featureLabel: 'Nutrition AI',
                            icon: Icons.restaurant,
                            current: 23,
                            total: 50,
                          ),
                          const SizedBox(height: 16),
                          _buildQuotaItem(
                            featureLabel: 'Workout AI',
                            icon: Icons.fitness_center,
                            current: 67,
                            total: 75,
                            showLimitWarning: true,
                          ),
                          const SizedBox(height: 16),
                          _buildQuotaItem(
                            featureLabel: 'Messaging AI',
                            icon: Icons.chat,
                            current: 12,
                            total: 200,
                          ),
                          const SizedBox(height: 16),
                          _buildQuotaItem(
                            featureLabel: 'Transcription',
                            icon: Icons.mic,
                            current: 8,
                            total: 25,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildGlassmorphicButton(
                onPressed: () => AppNavigator.billingUpgrade(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.white.withValues(alpha: 0.9), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaItem({
    required String featureLabel,
    required IconData icon,
    required int current,
    required int total,
    bool showLimitWarning = false,
  }) {
    final double percentage = total == 0 ? 0 : current / total;
    final bool isWarning = percentage >= 0.8;
    final bool isDanger = percentage >= 0.95;

    Color progressColor;
    if (isDanger) {
      progressColor = Colors.red;
    } else if (isWarning || showLimitWarning) {
      progressColor = Colors.orange;
    } else {
      progressColor = const Color(0xFF00D4AA);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                featureLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$current/$total',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        if (isWarning || showLimitWarning) ...[
          const SizedBox(height: 6),
          Text(
            isDanger ? '⚠️ Almost at limit!' : '⚠️ Getting close to limit',
            style: TextStyle(
              color: progressColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    return ClipRRect(
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
                color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassmorphicButton({required VoidCallback onPressed, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                DesignTokens.accentBlue.withValues(alpha: 0.35),
                DesignTokens.accentBlue.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.25),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
