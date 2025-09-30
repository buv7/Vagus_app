import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';

class CallControls extends StatelessWidget {
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isScreenSharing;
  final bool isConnecting;
  final bool isCallEnded;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onToggleChat;
  final VoidCallback onEndCall;
  final VoidCallback onToggleControls;

  const CallControls({
    super.key,
    required this.isMuted,
    required this.isVideoEnabled,
    required this.isScreenSharing,
    required this.isConnecting,
    required this.isCallEnded,
    required this.onToggleMute,
    required this.onToggleVideo,
    required this.onToggleScreenShare,
    required this.onToggleChat,
    required this.onEndCall,
    required this.onToggleControls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer and call info
            _buildCallInfo(),
            const SizedBox(height: 24),
            
            // Main control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute button
                _buildControlButton(
                  icon: isMuted ? Icons.mic_off : Icons.mic,
                  backgroundColor: isMuted ? Colors.red : Colors.white.withValues(alpha: 0.2),
                  iconColor: isMuted ? Colors.white : Colors.white,
                  onPressed: onToggleMute,
                  tooltip: isMuted ? 'Unmute' : 'Mute',
                ),
                
                // Video button
                _buildControlButton(
                  icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  backgroundColor: isVideoEnabled ? Colors.white.withValues(alpha: 0.2) : Colors.red,
                  iconColor: Colors.white,
                  onPressed: onToggleVideo,
                  tooltip: isVideoEnabled ? 'Turn off camera' : 'Turn on camera',
                ),
                
                // Screen share button
                _buildControlButton(
                  icon: isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
                  backgroundColor: isScreenSharing ? Colors.blue : Colors.white.withValues(alpha: 0.2),
                  iconColor: Colors.white,
                  onPressed: onToggleScreenShare,
                  tooltip: isScreenSharing ? 'Stop sharing' : 'Share screen',
                ),
                
                // Chat button
                _buildControlButton(
                  icon: Icons.chat,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  iconColor: Colors.white,
                  onPressed: onToggleChat,
                  tooltip: 'Open chat',
                ),
                
                // End call button
                _buildControlButton(
                  icon: Icons.call_end,
                  backgroundColor: Colors.red,
                  iconColor: Colors.white,
                  onPressed: onEndCall,
                  tooltip: 'End call',
                  isEndCall: true,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Additional controls
            _buildAdditionalControls(),
          ],
            ),
          ),
        ),
      ),
        ),
      );
  }

  Widget _buildCallInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Connection status indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnecting ? Colors.orange : Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        
        // Call status text
        Text(
          isConnecting ? 'Connecting...' : 'Connected',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
    String? tooltip,
    bool isEndCall = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Container(
          width: isEndCall ? 56 : 48,
          height: isEndCall ? 56 : 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isEndCall ? 28 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Speaker button
        _buildSecondaryButton(
          icon: Icons.volume_up,
          tooltip: 'Speaker',
          onPressed: () {
            // TODO: Implement speaker toggle
          },
        ),
        
        // Camera switch button
        _buildSecondaryButton(
          icon: Icons.flip_camera_ios,
          tooltip: 'Switch camera',
          onPressed: () {
            // TODO: Implement camera switch
          },
        ),
        
        // More options button
        _buildSecondaryButton(
          icon: Icons.more_vert,
          tooltip: 'More options',
          onPressed: () {
            _showMoreOptions();
          },
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    // TODO: Implement more options menu
    // This could include:
    // - Recording options
    // - Audio/video settings
    // - Invite participants
    // - Call quality settings
    // - etc.
  }
}
