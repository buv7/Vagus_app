import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/live_session.dart';
import '../../services/simple_calling_service.dart';
import '../../widgets/calling/call_session_card.dart';
import '../../widgets/calling/schedule_call_dialog.dart';
import '../../theme/design_tokens.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
        foregroundColor: isDark ? Colors.white : DesignTokens.textColor(context),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.call,
                color: DesignTokens.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Live Calls',
              style: TextStyle(
                color: isDark ? Colors.white : DesignTokens.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context)),
            onPressed: _loadSessions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.accentBlue,
          indicatorWeight: 3,
          labelColor: isDark ? Colors.white : DesignTokens.accentBlue,
          unselectedLabelColor: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Scheduled'),
            Tab(text: 'Active'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: DesignTokens.accentBlue))
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
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              DesignTokens.accentBlue.withValues(alpha: 0.3),
              DesignTokens.accentBlue.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: DesignTokens.accentBlue.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _scheduleNewCall,
                borderRadius: BorderRadius.circular(28),
                child: const Center(
                  child: Icon(Icons.add_call, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark 
            ? DesignTokens.accentPink.withValues(alpha: 0.1)
            : Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark 
              ? DesignTokens.accentPink.withValues(alpha: 0.3)
              : Colors.red.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.accentPink.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: DesignTokens.accentPink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading calls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : DesignTokens.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadSessions,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark 
            ? DesignTokens.accentBlue.withValues(alpha: 0.1)
            : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark 
              ? DesignTokens.accentBlue.withValues(alpha: 0.3)
              : DesignTokens.borderColor(context),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: DesignTokens.accentBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : DesignTokens.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
