import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coach/performance_analytics_card.dart';
import '../../widgets/coach/coach_inbox_card.dart';
import '../../widgets/coach/connected_clients_card.dart';
import '../../widgets/coach/pending_requests_card.dart';
import '../../widgets/coach/recent_checkins_card.dart';
import '../../widgets/coach/upcoming_sessions_card.dart';
import '../../widgets/coach/quick_actions_grid.dart';
import '../../widgets/ads/ad_banner_strip.dart';
import '../coach/program_ingest_upload_sheet.dart';

class ModernCoachDashboard extends StatefulWidget {
  const ModernCoachDashboard({super.key});

  @override
  State<ModernCoachDashboard> createState() => _ModernCoachDashboardState();
}

class _ModernCoachDashboardState extends State<ModernCoachDashboard> {
  final supabase = Supabase.instance.client;
  // final CoachAnalyticsService _analyticsService = CoachAnalyticsService();
  // final CoachInboxService _inboxService = CoachInboxService();
  // final CoachClientManagementService _clientService = CoachClientManagementService();
  
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _recentCheckins = [];
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _inboxItems = [];
  Map<String, dynamic>? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {


      // Load connected clients
      final links = await supabase
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', user.id);

      List<String> clientIds = [];
      if (links.isNotEmpty) {
        clientIds = links.map((row) => row['client_id'] as String).toList();
        
        final clients = await supabase
            .from('profiles')
            .select('id, name, email, avatar_url')
            .inFilter('id', clientIds);

        setState(() {
          _clients = List<Map<String, dynamic>>.from(clients);
        });
      }

      // Load pending requests
      try {
        final requestLinks = await supabase
            .from('coach_requests')
            .select('id, client_id, status, created_at, message')
            .eq('coach_id', user.id)
            .eq('status', 'pending')
            .not('client_id', 'in', clientIds);

        final List<Map<String, dynamic>> requests = [];
        if (requestLinks.isNotEmpty) {
          final requestClientIds = requestLinks.map((row) => row['client_id'] as String).toList();
          
          final requestClients = await supabase
              .from('profiles')
              .select('id, name, email')
              .inFilter('id', requestClientIds);

          for (final request in requestLinks) {
            final clientId = request['client_id'] as String;
            final client = requestClients.firstWhere(
              (c) => c['id'] == clientId,
              orElse: () => {'id': clientId, 'name': 'Unknown', 'email': ''},
            );
            
            requests.add({
              ...request,
              'client': client,
            });
          }
        }

        setState(() {
          _requests = requests;
        });
      } catch (e) {
        debugPrint('❌ Failed to load pending requests: $e');
        setState(() {
          _requests = [];
        });
      }

      // Load recent check-ins
      if (clientIds.isNotEmpty) {
        await _loadRecentCheckins(clientIds);
      }

      // Load upcoming sessions
      await _loadUpcomingSessions();

      // Load inbox items
      await _loadInboxItems();

      // Load analytics
      await _loadAnalytics();

    } catch (e) {
      debugPrint('❌ Failed to load data: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadRecentCheckins(List<String> clientIds) async {
    try {
      final checkinsLinks = await supabase
          .from('checkins')
          .select('id, client_id, created_at, notes, mood, energy_level, weight')
          .inFilter('client_id', clientIds)
          .order('created_at', ascending: false)
          .limit(3);

      final List<Map<String, dynamic>> checkinsData = [];
      if (checkinsLinks.isNotEmpty) {
        final checkinClientIds = checkinsLinks.map((row) => row['client_id'] as String).toList();
        
        final checkinClients = await supabase
            .from('profiles')
            .select('id, name, avatar_url')
            .inFilter('id', checkinClientIds);

        for (final checkin in checkinsLinks) {
          final clientId = checkin['client_id'] as String;
          final client = checkinClients.firstWhere(
            (c) => c['id'] == clientId,
            orElse: () => {'id': clientId, 'name': 'Unknown', 'avatar_url': null},
          );
          
          checkinsData.add({
            ...checkin,
            'profiles': client,
          });
        }
      }
      
      setState(() {
        _recentCheckins = List<Map<String, dynamic>>.from(checkinsData);
      });
    } catch (e) {
      debugPrint('❌ Failed to load check-ins: $e');
      setState(() {
        _recentCheckins = [];
      });
    }
  }

  Future<void> _loadUpcomingSessions() async {
    // Mock data for now - replace with actual session loading
    setState(() {
      _upcomingSessions = [
        {
          'id': '1',
          'title': 'Strength Training Session',
          'coach': 'Mike Johnson',
          'date': 'Today',
          'location': 'VAGUS Gym - Studio A',
          'time': '2:00 PM (60 min)',
          'status': 'Confirmed',
        },
        {
          'id': '2',
          'title': 'Nutrition Consultation',
          'coach': 'Sarah Chen',
          'date': 'Tomorrow',
          'location': 'Zoom Meeting',
          'time': '10:00 AM (45 min)',
          'status': 'Confirmed',
        },
        {
          'id': '3',
          'title': 'Group HIIT Class',
          'coach': 'Group Session',
          'date': 'Friday',
          'location': 'VAGUS Gym - Main Floor',
          'time': '6:00 PM (45 min)',
          'status': 'Pending',
        },
      ];
    });
  }

  Future<void> _loadInboxItems() async {
    // Mock data for now - replace with actual inbox loading
    setState(() {
      _inboxItems = [
        {
          'id': '1',
          'clientName': 'Mike Johnson',
          'status': 'Urgent',
          'message': 'Missed 3 consecutive workouts - needs immediate attention',
          'time': '2 hours ago',
        },
        {
          'id': '2',
          'clientName': 'Sarah Chen',
          'status': 'Warning',
          'message': 'Weight plateau for 2 weeks - consider plan adjustment',
          'time': '5 hours ago',
        },
        {
          'id': '3',
          'clientName': 'David Rodriguez',
          'status': 'Info',
          'message': 'Requested nutrition plan modification',
          'time': '1 day ago',
        },
        {
          'id': '4',
          'clientName': 'Emma Wilson',
          'status': 'Urgent',
          'message': 'Reported injury during last workout',
          'time': '3 hours ago',
        },
      ];
    });
  }

  Future<void> _loadAnalytics() async {
    // Mock data for now - replace with actual analytics loading
    setState(() {
      _analytics = {
        'activeClients': 24,
        'sessionsCompleted': 18,
        'avgResponseTime': '2.3h',
        'clientSatisfaction': 4.8,
        'revenue': 3240,
        'planCompliance': 87,
        'activeClientsChange': 3,
        'sessionsChange': 5,
        'responseTimeChange': -0.5,
        'satisfactionChange': 0.2,
        'revenueChange': 12,
        'complianceChange': 5,
      };
    });
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

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header
              _buildModernHeader(),
              
              const SizedBox(height: DesignTokens.space16),
              
              // Ad Banner Strip
              const AdBannerStrip(audience: 'coach'),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Performance Analytics
              if (_analytics != null)
                PerformanceAnalyticsCard(
                  analytics: _analytics!,
                  onTimeRangeChange: (days) {
                    // Handle time range change
                  },
                ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Coach Inbox
              if (_inboxItems.isNotEmpty)
                CoachInboxCard(
                  inboxItems: _inboxItems,
                  onBulkSelect: () {
                    // Handle bulk select
                  },
                  onMessage: (clientId) {
                    // Navigate to messaging
                  },
                  onQuickCall: (clientId) {
                    // Handle quick call
                  },
                  onMarkReviewed: (clientId) {
                    // Mark as reviewed
                  },
                ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Connected Clients
              ConnectedClientsCard(
                clients: _clients,
                onViewAll: () {
                  // Navigate to client management
                },
                onWeeklyReview: (client) {
                  // Navigate to weekly review
                },
                onMessage: (client) {
                  // Navigate to messaging
                },
                onNotes: (client) {
                  // Navigate to notes
                },
              ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Pending Requests
              if (_requests.isNotEmpty)
                PendingRequestsCard(
                  requests: _requests,
                  onApprove: (request) {
                    // Handle approve
                  },
                  onDecline: (request) {
                    // Handle decline
                  },
                  onMessage: (request) {
                    // Navigate to messaging
                  },
                ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Recent Check-ins
              if (_recentCheckins.isNotEmpty)
                RecentCheckinsCard(
                  checkins: _recentCheckins,
                  onViewAll: () {
                    // Navigate to check-ins
                  },
                  onViewDetails: (checkin) {
                    // Navigate to check-in details
                  },
                ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Upcoming Sessions
              if (_upcomingSessions.isNotEmpty)
                UpcomingSessionsCard(
                  sessions: _upcomingSessions,
                  onViewCalendar: () {
                    // Navigate to calendar
                  },
                  onStartSession: (session) {
                    // Start session
                  },
                  onReschedule: (session) {
                    // Reschedule session
                  },
                  onCancel: (session) {
                    // Cancel session
                  },
                ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Quick Actions
              QuickActionsGrid(
                onImportProgram: _showImportProgramSheet,
              ),
              
              const SizedBox(height: DesignTokens.space32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: DesignTokens.space8),
        Text(
          'Monitor your coaching performance and client progress',
          style: TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 16,
          ),
        ),
      ],
    );
  }


  void _showImportProgramSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProgramIngestUploadSheet(),
    );
  }
}
