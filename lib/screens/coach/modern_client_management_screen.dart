import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coach/client_management_header.dart';
import '../../widgets/coach/client_search_filter_bar.dart';
import '../../widgets/coach/client_metrics_cards.dart';
import '../../widgets/coach/client_list_view.dart';

class ModernClientManagementScreen extends StatefulWidget {
  const ModernClientManagementScreen({super.key});

  @override
  State<ModernClientManagementScreen> createState() => _ModernClientManagementScreenState();
}

class _ModernClientManagementScreenState extends State<ModernClientManagementScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  String _searchQuery = '';
  String _statusFilter = 'All Status';
  String _sortBy = 'Name';
  bool _loading = true;
  String _error = '';

  // Stats
  int _sessionsToday = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadClients(),
      _loadStats(),
    ]);
  }

  Future<void> _loadClients() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _clients = [];
          _filteredClients = [];
          _loading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      // Get linked clients
      final response = await supabase
          .from('coach_clients')
          .select('client_id, created_at')
          .eq('coach_id', user.id);

      if (response.isEmpty) {
        setState(() {
          _clients = [];
          _filteredClients = [];
          _loading = false;
        });
        return;
      }

      final clients = <Map<String, dynamic>>[];

      for (final row in response) {
        final clientId = row['client_id'] as String;
        final joinDate = DateTime.parse(row['created_at'] as String);

        try {
          // Get client profile
          final profile = await supabase
              .from('profiles')
              .select('id, name, email, avatar_url')
              .eq('id', clientId)
              .single();

          // Get workout stats
          final workoutStats = await _getClientWorkoutStats(clientId);

          // Get last active
          final lastActive = await _getLastActive(clientId);

          // Get next session
          final nextSession = await _getNextSession(clientId);

          // Get program tags
          final tags = await _getProgramTags(clientId);

          // Determine status based on activity
          final status = _determineStatus(lastActive);

          clients.add({
            'id': clientId,
            'name': profile['name'] ?? 'No name',
            'email': profile['email'] ?? '',
            'avatar_url': profile['avatar_url'],
            'status': status,
            'program': tags.isNotEmpty ? tags.first : 'General',
            'joinDate': '${joinDate.month}/${joinDate.day}/${joinDate.year}',
            'progress': workoutStats['progress'],
            'compliance': workoutStats['compliance'],
            'lastActive': lastActive,
            'nextSession': nextSession ?? 'Not scheduled',
            'tags': tags,
          });
        } catch (e) {
          debugPrint('⚠️ Failed to load client $clientId: $e');
        }
      }

      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _loading = false;
        _error = '';
      });
    } catch (e) {
      debugPrint('❌ Failed to load clients: $e');
      setState(() {
        _clients = [];
        _filteredClients = [];
        _loading = false;
        _error = 'Failed to load clients: $e';
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get sessions today count
      final sessionsResponse = await supabase
          .from('calendar_events')
          .select('id')
          .eq('coach_id', user.id)
          .gte('start_time', todayStart.toIso8601String())
          .lt('start_time', todayEnd.toIso8601String());

      setState(() {
        _sessionsToday = sessionsResponse.length;
      });
    } catch (e) {
      debugPrint('⚠️ Failed to load stats: $e');
    }
  }

  Future<Map<String, dynamic>> _getClientWorkoutStats(String clientId) async {
    try {
      // Get completed sessions from workout_logs
      final logsResponse = await supabase
          .from('workout_logs')
          .select('id')
          .eq('client_id', clientId);

      final completedSessions = logsResponse.length;

      // Get total planned sessions from workout_plans
      int totalSessions = 0;
      try {
        final plansResponse = await supabase
            .from('workout_plans')
            .select('duration_weeks')
            .eq('client_id', clientId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (plansResponse != null) {
          final weeks = plansResponse['duration_weeks'] as int? ?? 4;
          totalSessions = weeks * 3; // Assume 3 sessions per week
        }
      } catch (e) {
        debugPrint('⚠️ Could not get workout plan: $e');
      }

      // If no plan, estimate based on weeks since joining
      if (totalSessions == 0) {
        totalSessions = 28; // Default 4 weeks * 7 days
      }

      final compliance = totalSessions > 0
          ? ((completedSessions / totalSessions) * 100).round()
          : 0;

      return {
        'progress': '$completedSessions/$totalSessions',
        'compliance': compliance,
      };
    } catch (e) {
      debugPrint('❌ Failed to get workout stats: $e');
      return {
        'progress': '0/0',
        'compliance': 0,
      };
    }
  }

  Future<String> _getLastActive(String clientId) async {
    try {
      final response = await supabase
          .from('workout_logs')
          .select('created_at')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final lastActive = DateTime.parse(response['created_at'] as String);
        return _formatTimeAgo(lastActive);
      }
      return 'Never';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String?> _getNextSession(String clientId) async {
    try {
      final response = await supabase
          .from('calendar_events')
          .select('start_time')
          .eq('client_id', clientId)
          .gte('start_time', DateTime.now().toIso8601String())
          .order('start_time', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final startTime = DateTime.parse(response['start_time'] as String);
        return _formatSessionTime(startTime);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> _getProgramTags(String clientId) async {
    try {
      final tags = <String>[];

      // Get workout plan name
      final workoutResponse = await supabase
          .from('workout_plans')
          .select('name')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (workoutResponse != null) {
        final planName = (workoutResponse['name'] as String?)?.toLowerCase() ?? '';
        if (planName.contains('strength')) tags.add('Strength');
        if (planName.contains('muscle') || planName.contains('build')) tags.add('Muscle Gain');
        if (planName.contains('weight loss') || planName.contains('fat')) tags.add('Weight Loss');
        if (planName.contains('hiit') || planName.contains('cardio')) tags.add('HIIT');
      }

      // Get nutrition plan
      final nutritionResponse = await supabase
          .from('nutrition_plans')
          .select('name')
          .eq('client_id', clientId)
          .limit(1)
          .maybeSingle();

      if (nutritionResponse != null) {
        tags.add('Nutrition');
      }

      return tags.isEmpty ? ['General'] : tags;
    } catch (e) {
      return ['General'];
    }
  }

  String _determineStatus(String lastActive) {
    if (lastActive == 'Never' || lastActive.contains('weeks')) {
      return 'Paused';
    }
    return 'Active';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }

  String _formatSessionTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = sessionDay.difference(today).inDays;

    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';

    if (diff == 0) return 'Today $time';
    if (diff == 1) return 'Tomorrow $time';
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[dateTime.weekday - 1]} $time';
  }

  void _filterClients() {
    setState(() {
      _filteredClients = _clients.where((client) {
        final matchesSearch = _searchQuery.isEmpty ||
            client['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client['email'].toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesStatus = _statusFilter == 'All Status' ||
            client['status'].toLowerCase() == _statusFilter.toLowerCase();
        
        return matchesSearch && matchesStatus;
      }).toList();
      
      // Sort clients
      _filteredClients.sort((a, b) {
        switch (_sortBy) {
          case 'Name':
            return a['name'].compareTo(b['name']);
          case 'Status':
            return a['status'].compareTo(b['status']);
          case 'Join Date':
            return b['joinDate'].compareTo(a['joinDate']);
          case 'Compliance':
            return (b['compliance'] as int).compareTo(a['compliance'] as int);
          default:
            return 0;
        }
      });
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterClients();
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _statusFilter = status;
    });
    _filterClients();
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _filterClients();
  }

  void _onAddClient() {
    // Navigate to add client screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add client functionality coming soon!')),
    );
  }

  void _onViewProfile(Map<String, dynamic> client) {
    // Navigate to client profile
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing profile for ${client['name']}')),
    );
  }

  void _onReview(Map<String, dynamic> client) {
    // Navigate to weekly review
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening review for ${client['name']}')),
    );
  }

  void _onMessage(Map<String, dynamic> client) {
    // Navigate to messaging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening messages for ${client['name']}')),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentGreen,
          ),
        ),
      );
    }

    // Error state
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(
          title: const Text('Client Management'),
          backgroundColor: AppTheme.cardBackground,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_clients.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: SafeArea(
          child: Column(
            children: [
              ClientManagementHeader(
                onAddClient: _onAddClient,
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Clients Yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first client to get started',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _onAddClient,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Client'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
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

    // Normal state with data
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.accentGreen,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              ClientManagementHeader(
                onAddClient: _onAddClient,
              ),

              // Search and Filter Bar
              ClientSearchFilterBar(
                searchQuery: _searchQuery,
                statusFilter: _statusFilter,
                sortBy: _sortBy,
                onSearchChanged: _onSearchChanged,
                onStatusFilterChanged: _onStatusFilterChanged,
                onSortChanged: _onSortChanged,
              ),

              // Metrics Cards
              ClientMetricsCards(
                totalClients: _clients.length,
                activeClients: _clients.where((c) => c['status'] == 'Active').length,
                sessionsToday: _sessionsToday,
                avgCompliance: _clients.isNotEmpty
                    ? (_clients.map((c) => c['compliance'] as int).reduce((a, b) => a + b) / _clients.length).round()
                    : 0,
              ),

              // Client List
              Expanded(
                child: ClientListView(
                  clients: _filteredClients,
                  onViewProfile: _onViewProfile,
                  onReview: _onReview,
                  onMessage: _onMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
