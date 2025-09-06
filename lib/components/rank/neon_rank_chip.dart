import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/billing/plan_access_manager.dart';

class NeonRankChip extends StatefulWidget {
  final int streak;
  final String rank;
  final VoidCallback onTap;
  final bool isPro;

  const NeonRankChip({
    super.key,
    required this.streak,
    required this.rank,
    required this.onTap,
    this.isPro = false,
  });

  @override
  State<NeonRankChip> createState() => _NeonRankChipState();
}

class _NeonRankChipState extends State<NeonRankChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final isPro = await PlanAccessManager.instance.isProUser();
    setState(() {
      _isPro = isPro;
    });
    
    if (_isPro && widget.isPro) {
      unawaited(_animationController.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAnimation = _isPro && widget.isPro;
    final glowIntensity = hasAnimation ? _glowAnimation.value : 0.3;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryBlack.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.steelGrey.withValues(alpha: 0.2 * glowIntensity),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppTheme.primaryBlack.withValues(alpha: 0.15 * glowIntensity),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Streak icon
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: AppTheme.primaryBlack,
                ),
                const SizedBox(width: 8),
                
                // Streak count
                Text(
                  '${widget.streak}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Rank badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.steelGrey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.steelGrey.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.rank,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.steelGrey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
