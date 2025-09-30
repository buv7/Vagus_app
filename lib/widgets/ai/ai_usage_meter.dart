import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/billing/upgrade_screen.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// AI Usage Meter widget that displays AI usage statistics for the current user
/// Shows usage count, limits, and remaining quota
class AIUsageMeter extends StatefulWidget {
  final bool isCompact;
  final VoidCallback? onRefresh;

  const AIUsageMeter({
    super.key,
    this.isCompact = false,
    this.onRefresh,
  });

  @override
  State<AIUsageMeter> createState() => _AIUsageMeterState();
}

class _AIUsageMeterState extends State<AIUsageMeter> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  Map<String, dynamic>? _usageData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _loading = false;
        });
        return;
      }

      // Try to query AI usage summary, but handle missing table gracefully
      try {
        final response = await supabase.rpc('get_ai_usage_summary', params: {
          'uid': user.id,
        });

        if (response != null && response.isNotEmpty) {
          setState(() {
            _usageData = response.first;
            _loading = false;
          });
        } else {
          // No usage data found, create default
          setState(() {
            _usageData = {
              'total_requests': 0,
              'requests_this_month': 0,
              'monthly_limit': 100,
              'total_tokens': 0,
              'tokens_this_month': 0,
              'last_used': null,
            };
            _loading = false;
          });
        }
      } catch (e) {
        // Handle missing table or function gracefully
        if (e.toString().contains('does not exist') || e.toString().contains('ai_usage')) {
          // Create default data when table doesn't exist
          setState(() {
            _usageData = {
              'total_requests': 0,
              'requests_this_month': 0,
              'monthly_limit': 100,
              'total_tokens': 0,
              'tokens_this_month': 0,
              'last_used': null,
            };
            _loading = false;
          });
        } else {
          // Re-throw other errors
          rethrow;
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load usage data: $e';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadUsageData();
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_usageData == null) {
      return _buildNoDataState();
    }

    return _buildUsageMeter();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Text(
            'Loading AI usage...',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: widget.isCompact ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: DesignTokens.danger, size: 20),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: DesignTokens.danger,
                fontSize: widget.isCompact ? 14 : 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: AppTheme.lightGrey),
            onPressed: _refresh,
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.accentGreen, size: 20),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Text(
              'No AI usage data available',
              style: TextStyle(
                color: AppTheme.accentGreen,
                fontSize: widget.isCompact ? 14 : 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: AppTheme.lightGrey),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMeter() {
    final totalRequests = _usageData!['total_requests'] ?? 0;
    final requestsThisMonth = _usageData!['requests_this_month'] ?? 0;
    final monthlyLimit = _usageData!['monthly_limit'] ?? 100;
    final lastUsed = _usageData!['last_used'] != null
        ? DateTime.tryParse(_usageData!['last_used'])
        : null;

    final usagePercentage = monthlyLimit > 0 ? (requestsThisMonth / monthlyLimit) : 0.0;
    final remainingRequests = monthlyLimit - requestsThisMonth;

    Color getUsageColor() {
      if (usagePercentage >= 0.9) return DesignTokens.danger;
      if (usagePercentage >= 0.7) return AppTheme.accentOrange;
      if (usagePercentage >= 0.5) return AppTheme.accentOrange;
      return DesignTokens.success;
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: AppTheme.accentGreen,
                size: widget.isCompact ? 18 : 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'AI Usage Meter', // Fixed Syntax
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.isCompact ? 16 : 18,
                  color: AppTheme.neutralWhite,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: AppTheme.lightGrey),
                onPressed: _refresh,
                tooltip: 'Refresh usage data',
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space12),
          
          // Monthly usage progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'This Month',
                          style: TextStyle(
                            fontSize: widget.isCompact ? 12 : 14,
                            color: AppTheme.lightGrey,
                          ),
                        ),
                        Text(
                          '$requestsThisMonth / $monthlyLimit',
                          style: TextStyle(
                            fontSize: widget.isCompact ? 12 : 14,
                            fontWeight: FontWeight.w500,
                            color: getUsageColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: usagePercentage.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.mediumGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(getUsageColor()),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              // Upgrade button when remaining is low
              if (remainingRequests <= (monthlyLimit * 0.1) || remainingRequests == 0) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Upgrade',
                    style: TextStyle(
                      fontSize: widget.isCompact ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: DesignTokens.space12),
          
          // Usage statistics
          if (!widget.isCompact) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Requests',
                    '$totalRequests',
                    Icons.history,
                    AppTheme.accentGreen,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Remaining',
                    '$remainingRequests',
                    Icons.access_time,
                    remainingRequests > 0 ? DesignTokens.success : DesignTokens.danger,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: DesignTokens.space12),
            
            // Tokens usage
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Tokens',
                    '${_usageData!['total_tokens'] ?? 0}',
                    Icons.token,
                    AppTheme.accentGreen,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'This Month',
                    '${_usageData!['tokens_this_month'] ?? 0}',
                    Icons.calendar_month,
                    AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
            
            if (lastUsed != null) ...[
              const SizedBox(height: DesignTokens.space8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.lightGrey,
                  ),
                  const SizedBox(width: DesignTokens.space6),
                  Text(
                    'Last used: ${_formatDate(lastUsed)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightGrey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: DesignTokens.space6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightGrey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
