import 'package:flutter/material.dart';
import '../../models/live_session.dart';
import '../../models/call_participant.dart';

class CallHeader extends StatelessWidget {
  final LiveSession session;
  final List<CallParticipant> participants;
  final VoidCallback onBack;

  const CallHeader({
    Key? key,
    required this.session,
    required this.participants,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Call info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session title or type
                  Text(
                    session.title ?? _getSessionTypeDisplayName(session.sessionType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Participants count and status
                  Row(
                    children: [
                      Icon(
                        _getSessionTypeIcon(session.sessionType),
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getParticipantsText(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      
                      if (session.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getCallDuration(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // More options button
            GestureDetector(
              onTap: () {
                _showMoreOptions(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  String _getParticipantsText() {
    final activeCount = participants.where((p) => p.isActive).length;
    final totalCount = participants.length;
    
    if (activeCount == 0) {
      return 'No participants';
    } else if (activeCount == 1) {
      return '1 participant';
    } else {
      return '$activeCount participants';
    }
  }

  String _getCallDuration() {
    if (session.startedAt == null) return '';
    
    final duration = DateTime.now().difference(session.startedAt!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Options
              _buildOption(
                icon: Icons.people,
                title: 'Participants',
                subtitle: 'View all participants',
                onTap: () {
                  Navigator.pop(context);
                  _showParticipants(context);
                },
              ),
              
              _buildOption(
                icon: Icons.settings,
                title: 'Call Settings',
                subtitle: 'Audio, video, and quality settings',
                onTap: () {
                  Navigator.pop(context);
                  _showCallSettings(context);
                },
              ),
              
              _buildOption(
                icon: Icons.info_outline,
                title: 'Call Info',
                subtitle: 'Session details and statistics',
                onTap: () {
                  Navigator.pop(context);
                  _showCallInfo(context);
                },
              ),
              
              if (session.isRecordingEnabled)
                _buildOption(
                  icon: Icons.videocam,
                  title: 'Recording',
                  subtitle: 'View recording options',
                  onTap: () {
                    Navigator.pop(context);
                    _showRecordingOptions(context);
                  },
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showParticipants(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Participants',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    participant.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  participant.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  participant.isActive ? 'Active' : 'Left',
                  style: TextStyle(
                    color: participant.isActive ? Colors.green : Colors.red,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (participant.isMuted)
                      const Icon(Icons.mic_off, color: Colors.red, size: 16),
                    if (!participant.isVideoEnabled)
                      const Icon(Icons.videocam_off, color: Colors.red, size: 16),
                    if (participant.isScreenSharing)
                      const Icon(Icons.screen_share, color: Colors.blue, size: 16),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _showCallSettings(BuildContext context) {
    // TODO: Implement call settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call settings coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showCallInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Call Information',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', _getSessionTypeDisplayName(session.sessionType)),
            _buildInfoRow('Status', session.status.value.toUpperCase()),
            if (session.startedAt != null)
              _buildInfoRow('Started', _formatDateTime(session.startedAt!)),
            if (session.duration != null)
              _buildInfoRow('Duration', session.durationFormatted),
            _buildInfoRow('Participants', '${participants.length}'),
            if (session.description != null)
              _buildInfoRow('Description', session.description!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showRecordingOptions(BuildContext context) {
    // TODO: Implement recording options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recording options coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
