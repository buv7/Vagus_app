import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/live_session.dart';
import '../../services/simple_calling_service.dart';
import '../../widgets/calling/call_session_card.dart';
import '../../widgets/calling/schedule_call_dialog.dart';
import 'simple_call_screen.dart';

class CallManagementScreen extends StatefulWidget {
  const CallManagementScreen({super.key});

  @override
  State<CallManagementScreen> createState() => _CallManagementScreenState();
}

class _CallManagementScreenState extends State<CallManagementScreen>
    with TickerProviderStateMixin {
  late SimpleCallingService _callingService;
  late TabController _tabController;
  
  List<LiveSession> _scheduledSessions = [];
  List<LiveSession> _activeSessions = [];
  List<LiveSession> _recentSessions = [];
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _callingService = SimpleCallingService();
    _tabController = TabController(length: 3, vsync: this);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _callingService.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final sessions = await _callingService.getUserActiveSessions();
      
      setState(() {
        _scheduledSessions = sessions.where((s) => s.isScheduled).toList();
        _activeSessions = sessions.where((s) => s.isActive).toList();
        _recentSessions = sessions.where((s) => s.isEnded).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleNewCall() async {
    final result = await showDialog<LiveSession>(
      context: context,
      builder: (context) => const ScheduleCallDialog(),
    );

    if (result != null) {
      await _loadSessions();
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Call scheduled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _joinCall(LiveSession session) async {
    try {
      // Navigate to call screen
      unawaited(Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleCallScreen(
            session: session,
            isIncoming: false,
          ),
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelCall(LiveSession session) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Call'),
        content: const Text('Are you sure you want to cancel this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _callingService.cancelLiveSession(session.id);
        await _loadSessions();
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Call cancelled successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to cancel call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Calls'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Scheduled'),
            Tab(text: 'Active'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildScheduledTab(),
                    _buildActiveTab(),
                    _buildRecentTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scheduleNewCall,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add_call, color: Colors.white),
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
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading calls',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSessions,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledTab() {
    if (_scheduledSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'No Scheduled Calls',
        subtitle: 'Tap the + button to schedule a new call',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scheduledSessions.length,
        itemBuilder: (context, index) {
          final session = _scheduledSessions[index];
          return CallSessionCard(
            session: session,
            onJoin: () => _joinCall(session),
            onCancel: () => _cancelCall(session),
            showJoinButton: true,
            showCancelButton: true,
          );
        },
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.videocam,
        title: 'No Active Calls',
        subtitle: 'Join a scheduled call or start a new one',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeSessions.length,
        itemBuilder: (context, index) {
          final session = _activeSessions[index];
          return CallSessionCard(
            session: session,
            onJoin: () => _joinCall(session),
            showJoinButton: true,
            showCancelButton: false,
          );
        },
      ),
    );
  }

  Widget _buildRecentTab() {
    if (_recentSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Recent Calls',
        subtitle: 'Your call history will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentSessions.length,
        itemBuilder: (context, index) {
          final session = _recentSessions[index];
          return CallSessionCard(
            session: session,
            showJoinButton: false,
            showCancelButton: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
