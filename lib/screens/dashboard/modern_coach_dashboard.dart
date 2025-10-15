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
import '../coach/modern_client_management_screen.dart';

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


      // Load connected clients (only active)
      final links = await supabase
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', user.id)
          .eq('status', 'active');

      List<String> clientIds = [];
      if (links.isNotEmpty) {
        clientIds = links.map((row) => row['client_id'] as String).toList();
        
        final clients = await supabase
            .from('profiles')
            .select('id, name, email, avatar_url')
            .inFilter('id', clientIds);

        if (!mounted) return;
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

        if (!mounted) return;
        setState(() {
          _requests = requests;
        });
      } catch (e) {
        debugPrint('❌ Failed to load pending requests: $e');
        if (!mounted) return;
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

    if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        _recentCheckins = List<Map<String, dynamic>>.from(checkinsData);
      });
    } catch (e) {
      debugPrint('❌ Failed to load check-ins: $e');
      if (!mounted) return;
      setState(() {
        _recentCheckins = [];
      });
    }
  }

  Future<void> _loadUpcomingSessions() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _upcomingSessions = []);
        return;
      }

      final now = DateTime.now();

      // Query upcoming calendar events for this coach
      final sessions = await supabase
          .from('calendar_events')
          .select('id, title, start_time, end_time, location, event_type, status, client_id')
          .eq('coach_id', user.id)
          .gte('start_time', now.toIso8601String())
          .neq('status', 'cancelled')
          .order('start_time', ascending: true)
          .limit(3);

      final List<Map<String, dynamic>> processedSessions = [];

      // Process each session to add client info
      for (final session in sessions) {
        final clientId = session['client_id'];
        String clientName = 'Group Session';

        // Get client name if session has a client
        if (clientId != null) {
          try {
            final client = await supabase
                .from('profiles')
                .select('name')
                .eq('id', clientId)
                .single();
            clientName = client['name'] as String? ?? 'Unknown Client';
          } catch (e) {
            debugPrint('⚠️ Could not fetch client name: $e');
          }
        }

        final startTime = DateTime.parse(session['start_time'] as String);
        final endTime = DateTime.parse(session['end_time'] as String);
        final duration = endTime.difference(startTime);

        // Format date
        String dateStr;
        final today = DateTime(now.year, now.month, now.day);
        final sessionDay = DateTime(startTime.year, startTime.month, startTime.day);
        final diff = sessionDay.difference(today).inDays;

        if (diff == 0) {
          dateStr = 'Today';
        } else if (diff == 1) {
          dateStr = 'Tomorrow';
        } else if (diff < 7) {
          dateStr = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][startTime.weekday - 1];
        } else {
          dateStr = '${startTime.month}/${startTime.day}';
        }

        // Format time
        final hour = startTime.hour > 12 ? startTime.hour - 12 : startTime.hour;
        final period = startTime.hour >= 12 ? 'PM' : 'AM';
        final timeStr = '$hour:${startTime.minute.toString().padLeft(2, '0')} $period (${duration.inMinutes} min)';

        processedSessions.add({
          'id': session['id'],
          'title': session['title'],
          'coach': clientName,
          'date': dateStr,
          'location': session['location'] ?? 'Not specified',
          'time': timeStr,
          'status': _formatStatus(session['status'] as String?),
        });
      }

      if (!mounted) return;
      setState(() {
        _upcomingSessions = processedSessions;
      });
    } catch (e) {
      debugPrint('❌ Failed to load upcoming sessions: $e');
      if (!mounted) return;
      setState(() {
        _upcomingSessions = [];
      });
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Pending';
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Future<void> _loadInboxItems() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _inboxItems = []);
        return;
      }

      // Get all client IDs for this coach (only active)
      final clientLinks = await supabase
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', user.id)
          .eq('status', 'active');

      if (clientLinks.isEmpty) {
        if (!mounted) return;
        setState(() => _inboxItems = []);
        return;
      }

      final clientIds = clientLinks.map((e) => e['client_id'] as String).toList();
      final List<Map<String, dynamic>> alerts = [];
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

      // 1. Check for inactive clients (no workout logs in last 3 days)
      try {
        final recentLogs = await supabase
            .from('workout_logs')
            .select('client_id, created_at')
            .inFilter('client_id', clientIds)
            .gte('created_at', threeDaysAgo.toIso8601String());

        final activeClientIds = recentLogs.map((e) => e['client_id'] as String).toSet();
        final inactiveClientIds = clientIds.where((id) => !activeClientIds.contains(id)).toList();

        if (inactiveClientIds.isNotEmpty) {
          final inactiveClients = await supabase
              .from('profiles')
              .select('id, name, avatar_url')
              .inFilter('id', inactiveClientIds)
              .limit(5);

          for (final client in inactiveClients) {
            alerts.add({
              'id': 'inactive_${client['id']}',
              'clientId': client['id'],
              'clientName': client['name'] ?? 'Unknown',
              'avatarUrl': client['avatar_url'],
              'status': 'Urgent',
              'message': 'No workout activity in 3+ days - needs check-in',
              'time': '3 days ago',
              'type': 'inactive',
            });
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not check inactive clients: $e');
      }

      // 2. Check for weight plateaus (same weight for 2+ weeks)
      try {
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
        final metrics = await supabase
            .from('client_metrics')
            .select('user_id, weight_kg, recorded_at')
            .inFilter('user_id', clientIds)
            .gte('recorded_at', twoWeeksAgo.toIso8601String())
            .order('recorded_at', ascending: false)
            .limit(100);

        final weightData = <String, List<double>>{};
        for (final metric in metrics) {
          final userId = metric['user_id'] as String;
          final weight = metric['weight_kg'] as num?;
          if (weight != null) {
            weightData.putIfAbsent(userId, () => []).add(weight.toDouble());
          }
        }

        for (final entry in weightData.entries) {
          if (entry.value.length >= 3) {
            final weights = entry.value;
            final isPlateaued = weights.every((w) => (w - weights.first).abs() < 0.5);

            if (isPlateaued && alerts.length < 10) {
              try {
                final client = await supabase
                    .from('profiles')
                    .select('id, name, avatar_url')
                    .eq('id', entry.key)
                    .single();

                alerts.add({
                  'id': 'plateau_${entry.key}',
                  'clientId': entry.key,
                  'clientName': client['name'] ?? 'Unknown',
                  'avatarUrl': client['avatar_url'],
                  'status': 'Warning',
                  'message': 'Weight plateau detected - consider plan adjustment',
                  'time': '2 weeks',
                  'type': 'plateau',
                });
              } catch (e) {
                debugPrint('⚠️ Could not fetch client for plateau: $e');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not check weight plateaus: $e');
      }

      // 3. Check for pending check-ins needing review
      try {
        final pendingCheckins = await supabase
            .from('checkins')
            .select('id, client_id, created_at, notes')
            .inFilter('client_id', clientIds)
            .or('coach_reviewed.is.null,coach_reviewed.eq.false')
            .order('created_at', ascending: false)
            .limit(5);

        for (final checkin in pendingCheckins) {
          if (alerts.length >= 10) break;

          try {
            final client = await supabase
                .from('profiles')
                .select('id, name, avatar_url')
                .eq('id', checkin['client_id'])
                .single();

            final createdAt = DateTime.parse(checkin['created_at'] as String);
            alerts.add({
              'id': 'checkin_${checkin['id']}',
              'clientId': checkin['client_id'],
              'clientName': client['name'] ?? 'Unknown',
              'avatarUrl': client['avatar_url'],
              'status': 'Info',
              'message': 'New check-in submitted - needs review',
              'time': _formatTimeAgo(createdAt),
              'type': 'checkin',
            });
          } catch (e) {
            debugPrint('⚠️ Could not fetch client for check-in: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not check pending check-ins: $e');
      }

      // Sort by urgency (Urgent → Warning → Info)
      alerts.sort((a, b) {
        const priority = {'Urgent': 0, 'Warning': 1, 'Info': 2};
        return (priority[a['status']] ?? 3).compareTo(priority[b['status']] ?? 3);
      });

      if (!mounted) return;
      setState(() {
        _inboxItems = alerts.take(10).toList();
      });
    } catch (e) {
      debugPrint('❌ Failed to load inbox items: $e');
      if (!mounted) return;
      setState(() {
        _inboxItems = [];
      });
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }

  Future<void> _loadAnalytics() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _analytics = null);
        return;
      }

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));

      // Get all client IDs for this coach (only active)
      final clientLinks = await supabase
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', user.id)
          .eq('status', 'active');

      final totalClients = clientLinks.length;

      if (totalClients == 0) {
        if (!mounted) return;
        setState(() => _analytics = null);
        return;
      }

      final clientIds = clientLinks.map((e) => e['client_id'] as String).toList();

      // 1. Active Clients (with activity in last 7 days)
      final activeLogsThisWeek = await supabase
          .from('workout_logs')
          .select('client_id')
          .inFilter('client_id', clientIds)
          .gte('created_at', sevenDaysAgo.toIso8601String());

      final activeClientsThisWeek = activeLogsThisWeek
          .map((e) => e['client_id'] as String)
          .toSet()
          .length;

      final activeLogsLastWeek = await supabase
          .from('workout_logs')
          .select('client_id')
          .inFilter('client_id', clientIds)
          .gte('created_at', fourteenDaysAgo.toIso8601String())
          .lt('created_at', sevenDaysAgo.toIso8601String());

      final activeClientsLastWeek = activeLogsLastWeek
          .map((e) => e['client_id'] as String)
          .toSet()
          .length;

      final activeClientsChange = activeClientsThisWeek - activeClientsLastWeek;

      // 2. Sessions Completed (workout logs count)
      final sessionsThisWeekData = await supabase
          .from('workout_logs')
          .select('id')
          .inFilter('client_id', clientIds)
          .gte('created_at', sevenDaysAgo.toIso8601String());

      final sessionsCount = sessionsThisWeekData.length;

      final sessionsLastWeekData = await supabase
          .from('workout_logs')
          .select('id')
          .inFilter('client_id', clientIds)
          .gte('created_at', fourteenDaysAgo.toIso8601String())
          .lt('created_at', sevenDaysAgo.toIso8601String());

      final sessionsChange = sessionsCount - sessionsLastWeekData.length;

      // 3. Avg Response Time (from messages)
      double avgResponseHours = 0;
      try {
        // Get messages where coach is either sender or recipient
        final messages = await supabase
            .from('messages')
            .select('sender_id, recipient_id, created_at')
            .or('sender_id.eq.${user.id},recipient_id.eq.${user.id}')
            .gte('created_at', sevenDaysAgo.toIso8601String())
            .order('created_at', ascending: true)
            .limit(200);

        if (messages.isNotEmpty) {
          final responseTimes = <Duration>[];

          // Group messages by conversation (sender-recipient pair)
          final conversations = <String, List<Map<String, dynamic>>>{};
          for (final msg in messages) {
            final senderId = msg['sender_id'] as String;
            final recipientId = msg['recipient_id'] as String?;
            if (recipientId == null) continue;

            // Create a consistent key for the conversation
            final conversationKey = [senderId, recipientId].toList()..sort();
            final key = conversationKey.join('_');

            conversations.putIfAbsent(key, () => []).add(msg);
          }

          // Calculate response times within each conversation
          for (final msgs in conversations.values) {
            for (var i = 0; i < msgs.length - 1; i++) {
              final current = msgs[i];
              final next = msgs[i + 1];

              // If client sent message and coach responded next
              if (current['sender_id'] != user.id && next['sender_id'] == user.id) {
                final clientTime = DateTime.parse(current['created_at'] as String);
                final coachTime = DateTime.parse(next['created_at'] as String);
                final diff = coachTime.difference(clientTime);

                // Only count responses within 24 hours
                if (diff.inHours < 24) {
                  responseTimes.add(diff);
                }
              }
            }
          }

          if (responseTimes.isNotEmpty) {
            final totalSeconds = responseTimes.fold<int>(0, (sum, d) => sum + d.inSeconds);
            avgResponseHours = totalSeconds / responseTimes.length / 3600;
          }
        }
      } catch (e) {
        debugPrint('! Could not calculate response time: $e');
      }

      // 4. Client Satisfaction (from feedback table - may not exist)
      double satisfaction = 0;
      try {
        final feedback = await supabase
            .from('client_feedback')
            .select('rating')
            .eq('coach_id', user.id)
            .gte('created_at', sevenDaysAgo.toIso8601String());

        if (feedback.isNotEmpty) {
          final total = feedback.fold<int>(0, (sum, f) => sum + ((f['rating'] as num?)?.toInt() ?? 0));
          satisfaction = total / feedback.length;
        }
      } catch (e) {
        debugPrint('⚠️ client_feedback table not available: $e');
      }

      // 5. Revenue (from payments table - may not exist)
      int revenue = 0;
      try {
        final monthStart = DateTime(now.year, now.month, 1);
        final payments = await supabase
            .from('payments')
            .select('amount')
            .eq('coach_id', user.id)
            .eq('status', 'completed')
            .gte('created_at', monthStart.toIso8601String());

        if (payments.isNotEmpty) {
          revenue = payments.fold<int>(0, (sum, p) => sum + ((p['amount'] as num?)?.toInt() ?? 0));
          revenue = (revenue / 100).round(); // Convert cents to dollars
        }
      } catch (e) {
        debugPrint('⚠️ payments table not available: $e');
      }

      // 6. Plan Compliance (completed sessions vs assigned sessions)
      int compliance = 0;
      try {
        final assignedSessions = await supabase
            .from('calendar_events')
            .select('id')
            .eq('coach_id', user.id)
            .inFilter('client_id', clientIds)
            .gte('start_time', sevenDaysAgo.toIso8601String())
            .lt('start_time', now.toIso8601String());

        final assignedCount = assignedSessions.length;
        compliance = assignedCount > 0 ? (sessionsCount * 100 / assignedCount).round() : 0;

        // Cap at 100%
        if (compliance > 100) compliance = 100;
      } catch (e) {
        debugPrint('⚠️ Could not calculate compliance: $e');
      }

      if (!mounted) return;
      setState(() {
        _analytics = {
          'activeClients': activeClientsThisWeek,
          'sessionsCompleted': sessionsCount,
          'avgResponseTime': avgResponseHours > 0 ? '${avgResponseHours.toStringAsFixed(1)}h' : 'N/A',
          'clientSatisfaction': satisfaction,
          'revenue': revenue,
          'planCompliance': compliance,
          'activeClientsChange': activeClientsChange,
          'sessionsChange': sessionsChange,
          'responseTimeChange': 0, // Simplified for now
          'satisfactionChange': 0, // Simplified for now
          'revenueChange': 0,      // Simplified for now
          'complianceChange': 0,   // Simplified for now
        };
      });
    } catch (e) {
      debugPrint('❌ Failed to load analytics: $e');
      if (!mounted) return;
      setState(() {
        _analytics = null;
      });
    }
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModernClientManagementScreen(),
                    ),
                  );
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
