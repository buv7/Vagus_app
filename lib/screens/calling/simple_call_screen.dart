import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/live_session.dart';
import '../../models/call_participant.dart';
import '../../services/simple_calling_service.dart';
import '../../widgets/calling/call_controls.dart';
import '../../widgets/calling/call_header.dart';
import '../../widgets/calling/call_chat.dart';

class SimpleCallScreen extends StatefulWidget {
  final LiveSession session;
  final bool isIncoming;

  const SimpleCallScreen({
    super.key,
    required this.session,
    this.isIncoming = false,
  });

  @override
  State<SimpleCallScreen> createState() => _SimpleCallScreenState();
}

class _SimpleCallScreenState extends State<SimpleCallScreen> {
  late SimpleCallingService _callingService;
  late StreamSubscription _sessionSubscription;
  late StreamSubscription _participantsSubscription;
  late StreamSubscription _messagesSubscription;
  late StreamSubscription _errorSubscription;

  bool _isConnected = false;
  bool _showChat = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    _callingService = SimpleCallingService();
    _setupSubscriptions();
    _joinCall();
  }

  void _setupSubscriptions() {
    _sessionSubscription = _callingService.sessionStream.listen((session) {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    });

    _participantsSubscription = _callingService.participantsStream.listen((participants) {
      if (mounted) {
        setState(() {});
      }
    });

    _messagesSubscription = _callingService.messagesStream.listen((messages) {
      if (mounted) {
        setState(() {});
      }
    });

    _errorSubscription = _callingService.errorStream.listen((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    });
  }

  Future<void> _joinCall() async {
    try {
      await _callingService.joinLiveSession(widget.session.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    _participantsSubscription.cancel();
    _messagesSubscription.cancel();
    _errorSubscription.cancel();
    _callingService.leaveLiveSession();
    _callingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            CallHeader(
              session: widget.session,
              participants: _callingService.participants,
              onBack: () => Navigator.pop(context),
            ),
            
            // Main content
            Expanded(
              child: _isConnected ? _buildCallContent() : _buildConnectingView(),
            ),
            
            // Controls
            if (_isConnected)
              CallControls(
                isMuted: _isMuted,
                isVideoEnabled: _isVideoEnabled,
                isScreenSharing: _isScreenSharing,
                isConnecting: false,
                isCallEnded: false,
                onToggleMute: _toggleMute,
                onToggleVideo: _toggleVideo,
                onToggleScreenShare: _toggleScreenShare,
                onToggleChat: _toggleChat,
                onEndCall: _endCall,
                onToggleControls: () {},
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Connecting to call...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.session.title ?? 'Untitled Call',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    if (_showChat) {
      return CallChat(
        messages: _callingService.messages,
        onSendMessage: _sendMessage,
        onClose: () => setState(() => _showChat = false),
      );
    }

    return _buildVideoGrid();
  }

  Widget _buildVideoGrid() {
    final participants = _callingService.participants;
    
    if (participants.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for participants...',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    if (participants.length == 1) {
      return _buildSingleParticipantView(participants.first);
    }

    if (participants.length == 2) {
      return _buildTwoParticipantView(participants);
    }

    return _buildMultipleParticipantView(participants);
  }

  Widget _buildSingleParticipantView(CallParticipant participant) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mock video placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  size: 48,
                  color: Colors.white70,
                ),
                const SizedBox(height: 8),
                Text(
                  _isVideoEnabled ? 'Video On' : 'Video Off',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You are in the call',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.session.title ?? 'Untitled Call',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoParticipantView(List<CallParticipant> participants) {
    return Row(
      children: participants.map((participant) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  participant.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  size: 48,
                  color: Colors.white70,
                ),
                const SizedBox(height: 8),
                Text(
                  participant.isVideoEnabled ? 'Video On' : 'Video Off',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (participant.isMuted)
                  const Icon(
                    Icons.mic_off,
                    color: Colors.red,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleParticipantView(List<CallParticipant> participants) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                participant.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                size: 32,
                color: Colors.white70,
              ),
              const SizedBox(height: 4),
              Text(
                participant.isVideoEnabled ? 'Video On' : 'Video Off',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (participant.isMuted)
                const Icon(
                  Icons.mic_off,
                  color: Colors.red,
                  size: 16,
                ),
            ],
          ),
        );
      },
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _callingService.toggleMute();
    HapticFeedback.lightImpact();
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    _callingService.toggleVideo();
    HapticFeedback.lightImpact();
  }

  void _toggleScreenShare() {
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });
    _callingService.toggleScreenShare();
    HapticFeedback.lightImpact();
  }

  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
    });
    HapticFeedback.lightImpact();
  }

  void _sendMessage(String message) {
    _callingService.sendMessage(message);
  }

  void _endCall() {
    HapticFeedback.mediumImpact();
    _callingService.leaveLiveSession();
    Navigator.pop(context);
  }
}
