// lib/screens/fatigue/coach_fatigue_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../services/fatigue/fatigue_dashboard_service.dart';
import '../../widgets/fatigue/fatigue_score_card.dart';
import '../../widgets/fatigue/fatigue_trend_chart.dart';
import '../../widgets/fatigue/muscle_fatigue_list.dart';
import '../../widgets/fatigue/intensifier_contribution_list.dart';
import '../../widgets/fatigue/fatigue_recommendations_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Coach fatigue dashboard screen (multi-client view)
class CoachFatigueDashboardScreen extends StatefulWidget {
  const CoachFatigueDashboardScreen({super.key});

  @override
  State<CoachFatigueDashboardScreen> createState() => _CoachFatigueDashboardScreenState();
}

class _CoachFatigueDashboardScreenState extends State<CoachFatigueDashboardScreen> {
  final _service = FatigueDashboardService.instance;
  final _supabase = Supabase.instance.client;

  String? _selectedClientId;
  List<Map<String, dynamic>> _clients = [];
  DateTime _selectedDate = DateTime.now();
  int _trendDays = 7;

  Map<String, dynamic>? _currentSnapshot;
  List<Map<String, dynamic>> _trendSnapshots = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Query coach_clients to get linked clients
      final response = await _supabase
          .from('coach_clients')
          .select('''
            client_id,
            profiles!coach_clients_client_id_fkey(id, full_name, email)
          ''')
          .eq('coach_id', user.id)
          .eq('status', 'active');

      final clients = (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        _clients = clients;
        if (_clients.isNotEmpty && _selectedClientId == null) {
          _selectedClientId = _clients.first['client_id'] as String?;
        }
      });

      if (_selectedClientId != null) {
        await _loadData();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (_selectedClientId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load current snapshot
      final snapshot = await _service.getCoachClientSnapshot(
        clientId: _selectedClientId!,
        date: _selectedDate,
      );

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
    if (_selectedClientId == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final snapshot = await _service.refreshSnapshot(
        userId: _selectedClientId!,
        date: _selectedDate,
      );

      setState(() {
        _currentSnapshot = snapshot;
        _isRefreshing = false;
      });

      await _loadTrendData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadTrendData() async {
    if (_selectedClientId == null) return;

    try {
      final endDate = _selectedDate;
      final startDate = endDate.subtract(Duration(days: _trendDays - 1));

      final snapshots = await _service.getRange(
        userId: _selectedClientId!,
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

  String _getClientName(Map<String, dynamic> client) {
    final profile = client['profiles'] as Map<String, dynamic>?;
    if (profile == null) return 'Unknown';
    return profile['full_name'] as String? ?? 
           profile['email'] as String? ?? 
           'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        elevation: 0,
        title: const Text(
          'Client Fatigue Dashboard',
          style: TextStyle(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Client selector
          if (_clients.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.person, color: DesignTokens.accentGreen),
              onSelected: (clientId) {
                setState(() {
                  _selectedClientId = clientId;
                });
                _loadData();
              },
              itemBuilder: (context) {
                return _clients.map((client) {
                  final clientId = client['client_id'] as String;
                  final isSelected = clientId == _selectedClientId;
                  return PopupMenuItem(
                    value: clientId,
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(Icons.check, color: DesignTokens.accentGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(_getClientName(client)),
                      ],
                    ),
                  );
                }).toList();
              },
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
      body: _clients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    color: DesignTokens.textSecondary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No clients linked',
                    style: TextStyle(color: DesignTokens.textSecondary),
                  ),
                ],
              ),
            )
          : _isLoading
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
                            // Client name header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: DesignTokens.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: DesignTokens.glassBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: DesignTokens.accentGreen,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getClientName(_clients.firstWhere(
                                      (c) => c['client_id'] == _selectedClientId,
                                    )),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: DesignTokens.neutralWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
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
}
