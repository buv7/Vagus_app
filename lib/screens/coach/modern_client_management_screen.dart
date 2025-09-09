import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coach/client_management_header.dart';
import '../../widgets/coach/client_search_filter_bar.dart';
import '../../widgets/coach/client_metrics_cards.dart';
import '../../widgets/coach/client_list_view.dart';
import '../../services/coach/coach_client_management_service.dart';

class ModernClientManagementScreen extends StatefulWidget {
  const ModernClientManagementScreen({super.key});

  @override
  State<ModernClientManagementScreen> createState() => _ModernClientManagementScreenState();
}

class _ModernClientManagementScreenState extends State<ModernClientManagementScreen> {
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  String _searchQuery = '';
  String _statusFilter = 'All Status';
  String _sortBy = 'Name';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    // Mock data for now - replace with actual client loading
    setState(() {
      _clients = [
        {
          'id': '1',
          'name': 'Mike Johnson',
          'email': 'mike.j@email.com',
          'status': 'Active',
          'program': 'Strength Training',
          'joinDate': '1/15/2024',
          'progress': '24/28',
          'compliance': 86,
          'lastActive': '2 hours ago',
          'nextSession': 'Today 2:00 PM',
          'tags': ['Muscle Gain', 'Strength'],
          'avatar_url': null,
        },
        {
          'id': '2',
          'name': 'Sarah Chen',
          'email': 'sarah.c@email.com',
          'status': 'Active',
          'program': 'Weight Loss',
          'joinDate': '2/1/2024',
          'progress': '18/21',
          'compliance': 90,
          'lastActive': '1 day ago',
          'nextSession': 'Tomorrow 10:00 AM',
          'tags': ['Weight Loss', 'Cardio'],
          'avatar_url': null,
        },
        {
          'id': '3',
          'name': 'David Rodriguez',
          'email': 'david.r@email.com',
          'status': 'Paused',
          'program': 'Muscle Gain',
          'joinDate': '1/20/2024',
          'progress': '15/28',
          'compliance': 87,
          'lastActive': '3 days ago',
          'nextSession': 'Friday 6:00 PM',
          'tags': ['Muscle Gain', 'Nutrition'],
          'avatar_url': null,
        },
        {
          'id': '4',
          'name': 'Emma Wilson',
          'email': 'emma.w@email.com',
          'status': 'Active',
          'program': 'HIIT Training',
          'joinDate': '2/10/2024',
          'progress': '12/14',
          'compliance': 75,
          'lastActive': '4 hours ago',
          'nextSession': 'Today 4:00 PM',
          'tags': ['HIIT', 'Cardio'],
          'avatar_url': null,
        },
      ];
      _filteredClients = _clients;
      _loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.mintAqua,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
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
              sessionsToday: 3, // Mock data
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
    );
  }
}
