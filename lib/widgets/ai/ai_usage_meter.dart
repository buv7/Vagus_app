import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      // Query AI usage summary for the current user using the database function
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading AI usage...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: widget.isCompact ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: widget.isCompact ? 14 : 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _refresh,
              tooltip: 'Retry',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No AI usage data available',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: widget.isCompact ? 14 : 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _refresh,
              tooltip: 'Refresh',
            ),
          ],
        ),
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
      if (usagePercentage >= 0.9) return Colors.red;
      if (usagePercentage >= 0.7) return Colors.orange;
      if (usagePercentage >= 0.5) return Colors.yellow;
      return Colors.green;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.purple.shade600,
                  size: widget.isCompact ? 18 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Usage Meter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isCompact ? 16 : 18,
                    color: Colors.purple.shade700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _refresh,
                  tooltip: 'Refresh usage data',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
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
                              color: Colors.grey.shade600,
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
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(getUsageColor()),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Usage statistics
            if (!widget.isCompact) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Requests',
                      '$totalRequests',
                      Icons.history,
                      Colors.blue.shade600,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Remaining',
                      '$remainingRequests',
                      Icons.access_time,
                      remainingRequests > 0 ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tokens usage
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Tokens',
                      '${_usageData!['total_tokens'] ?? 0}',
                      Icons.token,
                      Colors.purple.shade600,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'This Month',
                      '${_usageData!['tokens_this_month'] ?? 0}',
                      Icons.calendar_month,
                      Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
              
              if (lastUsed != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last used: ${_formatDate(lastUsed)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
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
