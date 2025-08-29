import 'package:flutter/material.dart';
import '../../services/streaks/streak_service.dart';
import '../../theme/design_tokens.dart';

/// Screen showing streak tracking with 30-day grid and appeal functionality
class StreakScreen extends StatefulWidget {
  final String? userId;

  const StreakScreen({
    super.key,
    this.userId,
  });

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final StreakService _streakService = StreakService.instance;
  
  Map<String, dynamic> _streakInfo = {
    'current_count': 0,
    'longest_count': 0,
    'shield_active': false,
  };
  List<Map<String, dynamic>> _streakDays = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    try {
      setState(() => _loading = true);
      
      // Load streak info and 30 days of data
      final streakInfo = await _streakService.getStreakInfo(
        userId: widget.userId,
      );
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 29));
      
      final streakDays = await _streakService.getStreakDays(
        startDate: startDate,
        endDate: endDate,
        userId: widget.userId,
      );
      
      setState(() {
        _streakInfo = streakInfo;
        _streakDays = streakDays;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak Tracker'),
        backgroundColor: DesignTokens.ink50,
        elevation: 0,
      ),
      body: _loading 
          ? _buildLoadingState()
          : _error != null 
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: DesignTokens.space16),
          Text('Loading streak data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: DesignTokens.danger,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'Failed to load streak data',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink900,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            _error ?? 'Unknown error',
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.ink500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space16),
          ElevatedButton(
            onPressed: _loadStreakData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final currentCount = _streakInfo['current_count'] as int? ?? 0;
    final longestCount = _streakInfo['longest_count'] as int? ?? 0;
    final shieldActive = _streakInfo['shield_active'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak summary card
          _buildStreakSummaryCard(currentCount, longestCount, shieldActive),
          
          const SizedBox(height: DesignTokens.space24),
          
          // 30-day grid
          _buildStreakGrid(),
          
          const SizedBox(height: DesignTokens.space24),
          
          // Legend
          _buildLegend(),
          
          const SizedBox(height: DesignTokens.space24),
          
          // Rules
          _buildRules(),
          
          const SizedBox(height: DesignTokens.space24),
          
          // Appeal CTA
          if (currentCount > 0) _buildAppealCTA(),
        ],
      ),
    );
  }

  Widget _buildStreakSummaryCard(int currentCount, int longestCount, bool shieldActive) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: shieldActive 
              ? [DesignTokens.purple50, DesignTokens.purple500.withValues(alpha: 0.1)]
              : [DesignTokens.blue50, DesignTokens.blue500.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: shieldActive 
              ? DesignTokens.purple500 
              : DesignTokens.blue600,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Current streak
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(width: DesignTokens.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentCount',
                    style: DesignTokens.displayLarge.copyWith(
                      color: shieldActive 
                          ? DesignTokens.purple500 
                          : DesignTokens.blue600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Current Streak',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: shieldActive 
                          ? DesignTokens.purple500 
                          : DesignTokens.blue600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (longestCount > 0) ...[
            const SizedBox(height: DesignTokens.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: DesignTokens.space8),
                Text(
                  'Longest: $longestCount days',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: shieldActive 
                        ? DesignTokens.purple500 
                        : DesignTokens.blue600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          
          if (shieldActive) ...[
            const SizedBox(height: DesignTokens.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield,
                  color: DesignTokens.purple500,
                  size: 20,
                ),
                const SizedBox(width: DesignTokens.space8),
                Text(
                  'Shield Active',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.purple500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakGrid() {
    // Create a map of dates to compliance status
    final Map<String, bool> dateCompliance = {};
    for (final day in _streakDays) {
      final date = day['date'] as String;
      final isCompliant = day['is_compliant'] as bool? ?? false;
      dateCompliance[date] = isCompliant;
    }
    
    // Generate grid
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 29));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 30 Days',
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.ink900,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        
        Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            color: DesignTokens.ink50,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Column(
            children: [
              // Day labels
              Row(
                children: [
                  const SizedBox(width: 24), // Space for date labels
                  ...['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) => 
                    Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: DesignTokens.bodySmall.copyWith(
                          color: DesignTokens.ink500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DesignTokens.space8),
              
              // Grid rows
              ...List.generate(5, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space4),
                  child: Row(
                    children: [
                      // Week label
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${startDate.add(Duration(days: weekIndex * 7)).day}',
                          style: DesignTokens.bodySmall.copyWith(
                            color: DesignTokens.ink500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Week squares
                      ...List.generate(7, (dayIndex) {
                        final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                        final dateStr = date.toIso8601String().split('T')[0];
                        final isCompliant = dateCompliance[dateStr] ?? false;
                        final isToday = date.isAtSameMomentAs(DateTime.now());
                        
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(1),
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCompliant 
                                  ? DesignTokens.success 
                                  : isToday 
                                      ? DesignTokens.blue600 
                                      : DesignTokens.ink100,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: isToday 
                                ? const Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: DesignTokens.ink50,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legend',
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.ink900,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        
        Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            color: DesignTokens.ink50,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Column(
            children: [
              _buildLegendItem(
                color: DesignTokens.success,
                label: 'Compliant day',
              ),
              const SizedBox(height: DesignTokens.space8),
              _buildLegendItem(
                color: DesignTokens.ink100,
                label: 'Non-compliant day',
              ),
              const SizedBox(height: DesignTokens.space8),
              _buildLegendItem(
                color: DesignTokens.blue600,
                label: 'Today',
                icon: Icons.circle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    IconData? icon,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: icon != null 
              ? Icon(
                  icon,
                  size: 8,
                  color: DesignTokens.ink50,
                )
              : null,
        ),
        const SizedBox(width: DesignTokens.space8),
        Text(
          label,
          style: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.ink700,
          ),
        ),
      ],
    );
  }

  Widget _buildRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How Streaks Work',
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.ink900,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        
        Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            color: DesignTokens.ink50,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleItem(
                '🔥',
                'Complete any activity (workout, nutrition, check-in, photo, calendar, supplement, or health) to mark a day as compliant.',
              ),
              const SizedBox(height: DesignTokens.space12),
              _buildRuleItem(
                '📈',
                'Your streak increases with each consecutive compliant day.',
              ),
              const SizedBox(height: DesignTokens.space12),
              _buildRuleItem(
                '⚠️',
                'Missing a day breaks your streak. You can appeal if you had a valid reason.',
              ),
              const SizedBox(height: DesignTokens.space12),
              _buildRuleItem(
                '🏆',
                'Your longest streak is tracked separately and never resets.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: DesignTokens.space8),
        Expanded(
          child: Text(
            text,
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppealCTA() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: DesignTokens.warnBg,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: DesignTokens.warn,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel,
                color: DesignTokens.warn,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'Lost Your Streak?',
                style: DesignTokens.titleSmall.copyWith(
                  color: DesignTokens.warn,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'If you had a valid reason for missing a day (illness, travel, etc.), you can appeal to restore your streak.',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink700,
            ),
          ),
          const SizedBox(height: DesignTokens.space12),
          ElevatedButton(
            onPressed: _showAppealDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.warn,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Appeal'),
          ),
        ],
      ),
    );
  }

  void _showAppealDialog() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Streak Appeal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Explain why you missed a day and should keep your streak:',
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.ink700,
              ),
            ),
            const SizedBox(height: DesignTokens.space12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., I was sick, traveling, or had an emergency...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _submitAppeal(reasonController.text.trim());
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAppeal(String reason) async {
    try {
      final appealId = await _streakService.startAppeal(
        lostOn: DateTime.now().subtract(const Duration(days: 1)),
        reason: reason,
        userId: widget.userId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appealId != null 
                  ? 'Appeal submitted successfully!'
                  : 'Failed to submit appeal. Please try again.',
            ),
            backgroundColor: appealId != null 
                ? DesignTokens.success 
                : DesignTokens.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit appeal: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }
}
