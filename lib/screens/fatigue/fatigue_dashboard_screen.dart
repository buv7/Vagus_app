// lib/screens/fatigue/fatigue_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../services/fatigue/fatigue_dashboard_service.dart';
import '../../widgets/fatigue/fatigue_score_card.dart';
import '../../widgets/fatigue/fatigue_trend_chart.dart';
import '../../widgets/fatigue/muscle_fatigue_list.dart';
import '../../widgets/fatigue/intensifier_contribution_list.dart';
import '../../widgets/fatigue/fatigue_recommendations_panel.dart';
import '../../widgets/common/fatigue_recovery_icon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client fatigue dashboard screen
class FatigueDashboardScreen extends StatefulWidget {
  const FatigueDashboardScreen({super.key});

  @override
  State<FatigueDashboardScreen> createState() => _FatigueDashboardScreenState();
}

class _FatigueDashboardScreenState extends State<FatigueDashboardScreen> {
  final _service = FatigueDashboardService.instance;
  final _supabase = Supabase.instance.client;

  DateTime _selectedDate = DateTime.now();
  int _trendDays = 7; // 7, 14, or 28

  Map<String, dynamic>? _currentSnapshot;
  List<Map<String, dynamic>> _trendSnapshots = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load current snapshot
      final snapshot = await _service.getSnapshot(
        userId: user.id,
        date: _selectedDate,
      );

      // If no snapshot exists, try to compute one
      if (snapshot == null) {
        await _refreshSnapshot();
      } else {
        setState(() {
          _currentSnapshot = snapshot;
        });
      }

      // Load trend data
      await _loadTrendData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSnapshot() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final snapshot = await _service.refreshSnapshot(
        userId: user.id,
        date: _selectedDate,
      );

      setState(() {
        _currentSnapshot = snapshot;
        _isRefreshing = false;
      });

      // Reload trend after refresh
      await _loadTrendData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadTrendData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final endDate = _selectedDate;
      final startDate = endDate.subtract(Duration(days: _trendDays - 1));

      final snapshots = await _service.getRange(
        userId: user.id,
        from: startDate,
        to: endDate,
      );

      setState(() {
        _trendSnapshots = snapshots;
      });
    } catch (e) {
      debugPrint('⚠️ Error loading trend: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DesignTokens.accentGreen,
              onPrimary: DesignTokens.primaryDark,
              surface: DesignTokens.cardBackground,
              onSurface: DesignTokens.neutralWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        elevation: 0,
        title: Row(
          children: [
            FatigueRecoveryIcon(size: 20),
            const SizedBox(width: 8),
            const Text(
              'Fatigue Dashboard',
              style: TextStyle(
                color: DesignTokens.neutralWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Date selector
          TextButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _formatDate(_selectedDate),
              style: const TextStyle(color: DesignTokens.accentGreen),
            ),
          ),
          // Refresh button
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DesignTokens.accentGreen,
                    ),
                  )
                : const Icon(Icons.refresh, color: DesignTokens.accentGreen),
            onPressed: _isRefreshing ? null : _refreshSnapshot,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.accentGreen,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: DesignTokens.danger,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: DesignTokens.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: DesignTokens.accentGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Score card
                        if (_currentSnapshot != null)
                          FatigueScoreCard(
                            fatigueScore: _currentSnapshot!['fatigue_score'] as int? ?? 0,
                            cnsScore: _currentSnapshot!['cns_score'] as int? ?? 0,
                            localScore: _currentSnapshot!['local_score'] as int? ?? 0,
                            jointScore: _currentSnapshot!['joint_score'] as int? ?? 0,
                          ),
                        const SizedBox(height: 16),
                        // Trend chart
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Trend',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: DesignTokens.neutralWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Days toggle
                                Row(
                                  children: [7, 14, 28].map((days) {
                                    final isSelected = _trendDays == days;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: FilterChip(
                                        label: Text('${days}d'),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() {
                                              _trendDays = days;
                                            });
                                            _loadTrendData();
                                          }
                                        },
                                        backgroundColor: DesignTokens.primaryDark,
                                        selectedColor: DesignTokens.accentGreen.withValues(alpha: 0.3),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? DesignTokens.accentGreen
                                              : DesignTokens.textSecondary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FatigueTrendChart(
                              snapshots: _trendSnapshots,
                              days: _trendDays,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Muscle fatigue
                        MuscleFatigueList(
                          muscleFatigue: _currentSnapshot?['muscle_fatigue'] as Map<String, dynamic>? ?? {},
                        ),
                        const SizedBox(height: 16),
                        // Intensifier contribution
                        IntensifierContributionList(
                          intensifierFatigue: _currentSnapshot?['intensifier_fatigue'] as Map<String, dynamic>? ?? {},
                        ),
                        const SizedBox(height: 16),
                        // Recommendations
                        if (_currentSnapshot != null)
                          FatigueRecommendationsPanel(
                            fatigueScore: _currentSnapshot!['fatigue_score'] as int? ?? 0,
                            cnsScore: _currentSnapshot!['cns_score'] as int? ?? 0,
                            localScore: _currentSnapshot!['local_score'] as int? ?? 0,
                            jointScore: _currentSnapshot!['joint_score'] as int? ?? 0,
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
