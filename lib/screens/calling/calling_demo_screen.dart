import 'package:flutter/material.dart';
import '../../models/live_session.dart';
import '../../services/simple_calling_service.dart';
import 'simple_call_screen.dart';

class CallingDemoScreen extends StatefulWidget {
  const CallingDemoScreen({Key? key}) : super(key: key);

  @override
  State<CallingDemoScreen> createState() => _CallingDemoScreenState();
}

class _CallingDemoScreenState extends State<CallingDemoScreen> {
  late SimpleCallingService _callingService;
  List<LiveSession> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _callingService = SimpleCallingService();
    _loadSessions();
  }

  @override
  void dispose() {
    _callingService.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _callingService.getUserActiveSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load sessions: $e');
    }
  }

  Future<void> _createTestSession() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sessionId = await _callingService.createLiveSession(
        sessionType: SessionType.videoCall,
        title: 'Test Video Call',
        description: 'This is a test call for demonstration',
        maxParticipants: 2,
        isRecordingEnabled: false,
      );

      final session = await _callingService.getLiveSession(sessionId);
      
      if (session != null) {
        setState(() {
          _sessions.add(session);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to create session');
        return;
      }

      _showSuccessSnackBar('Test session created successfully!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to create test session: $e');
    }
  }

  Future<void> _joinSession(LiveSession session) async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleCallScreen(
            session: session,
            isIncoming: false,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to join session: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Calling Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTestSession,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videocam_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Live Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a test session to try the calling features',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createTestSession,
            icon: const Icon(Icons.add_call),
            label: const Text('Create Test Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getSessionTypeColor(session.sessionType),
                child: Icon(
                  _getSessionTypeIcon(session.sessionType),
                  color: Colors.white,
                ),
              ),
              title: Text(
                session.title ?? _getSessionTypeDisplayName(session.sessionType),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getSessionTypeDisplayName(session.sessionType)),
                  if (session.description != null)
                    Text(
                      session.description!,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusChip(session.status),
                      const SizedBox(width: 8),
                      Text(
                        'Max: ${session.maxParticipants}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: session.isActive || session.isScheduled
                  ? ElevatedButton(
                      onPressed: () => _joinSession(session),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 36),
                      ),
                      child: const Text('Join'),
                    )
                  : null,
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(SessionStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case SessionStatus.scheduled:
        color = Colors.blue;
        text = 'Scheduled';
        break;
      case SessionStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case SessionStatus.ended:
        color = Colors.grey;
        text = 'Ended';
        break;
      case SessionStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case SessionStatus.missed:
        color = Colors.orange;
        text = 'Missed';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getSessionTypeColor(SessionType type) {
    switch (type) {
      case SessionType.audioCall:
        return Colors.blue;
      case SessionType.videoCall:
        return Colors.green;
      case SessionType.groupCall:
        return Colors.purple;
      case SessionType.coachingSession:
        return Colors.orange;
    }
  }

  IconData _getSessionTypeIcon(SessionType type) {
    switch (type) {
      case SessionType.audioCall:
        return Icons.call;
      case SessionType.videoCall:
        return Icons.videocam;
      case SessionType.groupCall:
        return Icons.group;
      case SessionType.coachingSession:
        return Icons.sports_handball;
    }
  }

  String _getSessionTypeDisplayName(SessionType type) {
    switch (type) {
      case SessionType.audioCall:
        return 'Audio Call';
      case SessionType.videoCall:
        return 'Video Call';
      case SessionType.groupCall:
        return 'Group Call';
      case SessionType.coachingSession:
        return 'Coaching Session';
    }
  }
}
