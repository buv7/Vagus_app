import 'package:flutter/material.dart';
import '../../models/live_session.dart';

class CallSessionCard extends StatelessWidget {
  final LiveSession session;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;
  final bool showJoinButton;
  final bool showCancelButton;

  const CallSessionCard({
    Key? key,
    required this.session,
    this.onJoin,
    this.onCancel,
    this.showJoinButton = false,
    this.showCancelButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with session type and status
            Row(
              children: [
                _buildSessionTypeIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title ?? _getSessionTypeDisplayName(session.sessionType),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _buildStatusChip(),
                          const SizedBox(width: 8),
                          Text(
                            _getSessionTypeDisplayName(session.sessionType),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildMoreButton(context),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Session details
            if (session.description != null) ...[
              Text(
                session.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            
            // Time information
            _buildTimeInfo(),
            
            const SizedBox(height: 12),
            
            // Action buttons
            if (showJoinButton || showCancelButton)
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTypeIcon() {
    IconData icon;
    Color color;
    
    switch (session.sessionType) {
      case SessionType.audioCall:
        icon = Icons.call;
        color = Colors.blue;
        break;
      case SessionType.videoCall:
        icon = Icons.videocam;
        color = Colors.green;
        break;
      case SessionType.groupCall:
        icon = Icons.group;
        color = Colors.purple;
        break;
      case SessionType.coachingSession:
        icon = Icons.sports_handball;
        color = Colors.orange;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;
    
    switch (session.status) {
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

  Widget _buildMoreButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16),
              SizedBox(width: 8),
              Text('Details'),
            ],
          ),
        ),
        if (session.isRecordingEnabled)
          const PopupMenuItem(
            value: 'recording',
            child: Row(
              children: [
                Icon(Icons.videocam, size: 16),
                SizedBox(width: 8),
                Text('Recording'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 16),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo() {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          _getTimeText(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        
        if (session.isActive && session.duration != null) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.timer,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            session.durationFormatted,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (showJoinButton)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.videocam, size: 16),
              label: const Text('Join'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        
        if (showJoinButton && showCancelButton)
          const SizedBox(width: 12),
        
        if (showCancelButton)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
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

  String _getTimeText() {
    if (session.isActive && session.startedAt != null) {
      return 'Started ${_formatTime(session.startedAt!)}';
    } else if (session.isScheduled && session.scheduledAt != null) {
      return 'Scheduled for ${_formatTime(session.scheduledAt!)}';
    } else if (session.isEnded && session.endedAt != null) {
      return 'Ended ${_formatTime(session.endedAt!)}';
    } else {
      return 'Time not set';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'details':
        _showSessionDetails(context);
        break;
      case 'recording':
        _showRecordingInfo(context);
        break;
      case 'share':
        _shareSession(context);
        break;
    }
  }

  void _showSessionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', _getSessionTypeDisplayName(session.sessionType)),
            _buildDetailRow('Status', session.status.value.toUpperCase()),
            if (session.scheduledAt != null)
              _buildDetailRow('Scheduled', _formatDateTime(session.scheduledAt!)),
            if (session.startedAt != null)
              _buildDetailRow('Started', _formatDateTime(session.startedAt!)),
            if (session.endedAt != null)
              _buildDetailRow('Ended', _formatDateTime(session.endedAt!)),
            if (session.duration != null)
              _buildDetailRow('Duration', session.durationFormatted),
            _buildDetailRow('Max Participants', session.maxParticipants.toString()),
            _buildDetailRow('Recording', session.isRecordingEnabled ? 'Enabled' : 'Disabled'),
            if (session.description != null)
              _buildDetailRow('Description', session.description!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showRecordingInfo(BuildContext context) {
    if (!session.isRecordingEnabled) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Information'),
        content: const Text('This session is being recorded. The recording will be available after the session ends.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareSession(BuildContext context) {
    // TODO: Implement session sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
