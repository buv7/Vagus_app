import 'package:flutter/material.dart';
import '../../services/streaks/streak_service.dart';
import '../../theme/design_tokens.dart';
import '../../services/share/share_card_service.dart';
import '../../screens/share/share_picker.dart';

/// Chip displaying current streak count and longest streak
class StreakChip extends StatefulWidget {
  final String? userId;
  final VoidCallback? onTap;

  const StreakChip({
    super.key,
    this.userId,
    this.onTap,
  });

  @override
  State<StreakChip> createState() => _StreakChipState();
}

class _StreakChipState extends State<StreakChip> {
  final StreakService _streakService = StreakService.instance;
  
  Map<String, dynamic> _streakInfo = {
    'current_count': 0,
    'longest_count': 0,
    'shield_active': false,
  };
  bool _loading = true;
  String? _error;

  void _showShareOptions() {
    final currentCount = _streakInfo['current_count'] as int? ?? 0;
    final longestCount = _streakInfo['longest_count'] as int? ?? 0;
    
    if (currentCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active streak to share'),
          backgroundColor: DesignTokens.warn,
        ),
      );
      return;
    }

    final shareData = ShareDataModel(
      title: '🔥 $currentCount Day Streak!',
      subtitle: longestCount > currentCount ? 'Longest: $longestCount days' : 'Keep it up!',
      metrics: {
        'Current': '$currentCount days',
        if (longestCount > currentCount) 'Longest': '$longestCount days',
        'Status': 'Active',
      },
      date: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharePicker(data: shareData),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadStreakInfo();
  }

  Future<void> _loadStreakInfo() async {
    try {
      setState(() => _loading = true);
      
      final streakInfo = await _streakService.getStreakInfo(
        userId: widget.userId,
      );
      
      setState(() {
        _streakInfo = streakInfo;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingChip();
    }

    if (_error != null) {
      return _buildErrorChip();
    }

    final currentCount = _streakInfo['current_count'] as int? ?? 0;
    final longestCount = _streakInfo['longest_count'] as int? ?? 0;
    final shieldActive = _streakInfo['shield_active'] as bool? ?? false;

    // Don't show chip if no streaks
    if (currentCount == 0 && longestCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: _showShareOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: shieldActive 
              ? DesignTokens.purple50 
              : DesignTokens.blue50,
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          border: Border.all(
            color: shieldActive 
                ? DesignTokens.purple500 
                : DesignTokens.blue600,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fire emoji for current streak
            Text(
              '🔥',
              style: TextStyle(
                fontSize: 16,
                color: shieldActive 
                    ? DesignTokens.purple500 
                    : DesignTokens.blue600,
              ),
            ),
            const SizedBox(width: DesignTokens.space4),
            
            // Current streak count
            Text(
              '$currentCount',
              style: DesignTokens.bodyMedium.copyWith(
                color: shieldActive 
                    ? DesignTokens.purple500 
                    : DesignTokens.blue600,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // Separator if there's a longest streak
            if (longestCount > 0) ...[
              const SizedBox(width: DesignTokens.space4),
              Text(
                '|',
                style: DesignTokens.bodySmall.copyWith(
                  color: shieldActive 
                      ? DesignTokens.purple500 
                      : DesignTokens.blue600,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              
              // Trophy emoji for longest streak
              Text(
                '🏆',
                style: TextStyle(
                  fontSize: 14,
                  color: shieldActive 
                      ? DesignTokens.purple500 
                      : DesignTokens.blue600,
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              
              // Longest streak count
              Text(
                '$longestCount',
                style: DesignTokens.bodySmall.copyWith(
                  color: shieldActive 
                      ? DesignTokens.purple500 
                      : DesignTokens.blue600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            // Shield indicator if active
            if (shieldActive) ...[
              const SizedBox(width: DesignTokens.space4),
              const Icon(
                Icons.shield,
                size: 14,
                color: DesignTokens.purple500,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.ink100,
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.ink500),
            ),
          ),
          const SizedBox(width: DesignTokens.space8),
          Text(
            'Loading...',
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.ink500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.dangerBg,
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        border: Border.all(
          color: DesignTokens.danger,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 14,
            color: DesignTokens.danger,
          ),
          const SizedBox(width: DesignTokens.space4),
          Text(
            'Error',
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
