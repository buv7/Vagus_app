import 'package:flutter/material.dart';
import '../../models/call_participant.dart';

class CallParticipantGrid extends StatelessWidget {
  final List<CallParticipant> participants;
  final bool isVideoCall;

  const CallParticipantGrid({
    super.key,
    required this.participants,
    this.isVideoCall = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeParticipants = participants.where((p) => p.isActive).toList();
    
    if (activeParticipants.isEmpty) {
      return _buildEmptyState();
    }

    if (activeParticipants.length == 1) {
      return _buildSingleParticipant(activeParticipants.first);
    }

    if (activeParticipants.length == 2) {
      return _buildTwoParticipants(activeParticipants);
    }

    return _buildMultipleParticipants(activeParticipants);
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              color: Colors.white54,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Waiting for participants...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleParticipant(CallParticipant participant) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Video stream or placeholder
          if (isVideoCall && participant.isVideoEnabled)
            _buildVideoStream(participant)
          else
            _buildParticipantPlaceholder(participant),
          
          // Participant info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildParticipantInfo(participant),
          ),
          
          // Connection quality indicator
          if (participant.connectionQuality != ConnectionQuality.excellent)
            Positioned(
              top: 16,
              right: 16,
              child: _buildConnectionQualityIndicator(participant.connectionQuality),
            ),
        ],
      ),
    );
  }

  Widget _buildTwoParticipants(List<CallParticipant> participants) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Top participant (remote)
          Expanded(
            child: Stack(
              children: [
                if (isVideoCall && participants[0].isVideoEnabled)
                  _buildVideoStream(participants[0])
                else
                  _buildParticipantPlaceholder(participants[0]),
                
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _buildParticipantInfo(participants[0], isCompact: true),
                ),
              ],
            ),
          ),
          
          // Bottom participant (local)
          Expanded(
            child: Stack(
              children: [
                if (isVideoCall && participants[1].isVideoEnabled)
                  _buildVideoStream(participants[1])
                else
                  _buildParticipantPlaceholder(participants[1]),
                
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _buildParticipantInfo(participants[1], isCompact: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleParticipants(List<CallParticipant> participants) {
    return Container(
      color: Colors.black,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridColumns(participants.length),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 16 / 9,
        ),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index];
          return _buildParticipantTile(participant);
        },
      ),
    );
  }

  Widget _buildParticipantTile(CallParticipant participant) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: participant.isCurrentUser ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Video stream or placeholder
            if (isVideoCall && participant.isVideoEnabled)
              _buildVideoStream(participant)
            else
              _buildParticipantPlaceholder(participant),
            
            // Participant info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildParticipantInfo(participant, isCompact: true),
            ),
            
            // Status indicators
            Positioned(
              top: 4,
              right: 4,
              child: _buildStatusIndicators(participant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoStream(CallParticipant participant) {
    // This would be implemented with actual WebRTC video rendering
    // For now, we'll show a placeholder
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.videocam,
          color: Colors.white54,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildParticipantPlaceholder(CallParticipant participant) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _getParticipantColor(participant.userId),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                participant.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Name
            Text(
              participant.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantInfo(CallParticipant participant, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name
          Text(
            participant.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Status indicators
          if (participant.isMuted)
            const Icon(
              Icons.mic_off,
              color: Colors.red,
              size: 16,
            ),
          
          if (!participant.isVideoEnabled)
            const Icon(
              Icons.videocam_off,
              color: Colors.red,
              size: 16,
            ),
          
          if (participant.isScreenSharing)
            const Icon(
              Icons.screen_share,
              color: Colors.blue,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators(CallParticipant participant) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (participant.isMuted)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic_off,
              color: Colors.white,
              size: 12,
            ),
          ),
        
        if (!participant.isVideoEnabled)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.videocam_off,
              color: Colors.white,
              size: 12,
            ),
          ),
        
        if (participant.isScreenSharing)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.screen_share,
              color: Colors.white,
              size: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionQualityIndicator(ConnectionQuality quality) {
    Color color;
    IconData icon;
    
    switch (quality) {
      case ConnectionQuality.excellent:
        color = Colors.green;
        icon = Icons.signal_cellular_4_bar;
        break;
      case ConnectionQuality.good:
        color = Colors.green;
        icon = Icons.signal_cellular_alt;
        break;
      case ConnectionQuality.fair:
        color = Colors.orange;
        icon = Icons.signal_cellular_alt_2_bar;
        break;
      case ConnectionQuality.poor:
        color = Colors.red;
        icon = Icons.signal_cellular_alt_1_bar;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  int _getGridColumns(int participantCount) {
    if (participantCount <= 2) return 1;
    if (participantCount <= 4) return 2;
    if (participantCount <= 9) return 3;
    return 4;
  }

  Color _getParticipantColor(String userId) {
    // Generate a consistent color based on user ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    
    final hash = userId.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
