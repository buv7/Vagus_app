import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../models/live_session.dart';
import '../../services/calling/webrtc_service.dart';
import '../../services/calling/call_signaling_service.dart';
import '../../services/calling/call_analytics_service.dart';
import '../../services/calling/incoming_call_stub.dart';
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
  late final WebRtcService _webRtc;
  late final CallSignalingService _signaling;
  late final SimpleCallingService _sessionService;

  bool _isConnected = false;
  bool _showChat = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isScreenSharing = false;
  String _statusText = 'Connecting…';

  DateTime? _callStartTime;

  @override
  void initState() {
    super.initState();
    _webRtc = WebRtcService();
    _signaling = CallSignalingService();
    _sessionService = SimpleCallingService();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      // 1. Camera/mic + local preview
      await _webRtc.initialize();
      final isVideo = widget.session.sessionType == SessionType.videoCall ||
          widget.session.sessionType == SessionType.coachingSession;
      await _webRtc.startLocalMedia(video: isVideo);

      // 2. Join the Supabase session record
      await _sessionService.joinLiveSession(widget.session.id);

      // 3. Wire up WebRTC → Signaling
      _webRtc.onIceCandidate = (candidate) {
        _signaling.sendIceCandidate({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      _webRtc.onConnectionStateChange = (state) {
        if (!mounted) return;
        setState(() {
          _isConnected =
              state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
          _statusText = _connectionStateLabel(state);
        });
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _callStartTime = DateTime.now();
          CallAnalyticsService.logCallStarted(
            sessionId: widget.session.id,
            sessionType: widget.session.sessionType.value,
            isVideo: isVideo,
            isCaller: !widget.isIncoming,
          );
        }
      };

      _webRtc.onRemoteStreamAdded = () {
        if (mounted) setState(() {});
      };

      // 4. Wire up Signaling → WebRTC
      _signaling.onOffer = (data) async {
        // Callee path: received offer → create answer
        await _webRtc.setupPeerConnection();
        await _webRtc.setRemoteDescription(data);
        final answer = await _webRtc.createAnswer();
        await _signaling.sendAnswer({'sdp': answer.sdp, 'type': answer.type});
      };

      _signaling.onAnswer = (data) async {
        // Caller path: received answer → complete handshake
        await _webRtc.setRemoteDescription(data);
      };

      _signaling.onIceCandidate = (data) async {
        await _webRtc.addIceCandidate(data);
      };

      _signaling.onPeerReady = () async {
        // Caller path: callee signalled ready → send offer
        if (!widget.isIncoming) {
          await _webRtc.setupPeerConnection();
          final offer = await _webRtc.createOffer();
          await _signaling.sendOffer({'sdp': offer.sdp, 'type': offer.type});
        }
      };

      _signaling.onHangup = () {
        if (mounted) _endCall(remote: true);
      };

      // 5. Subscribe to channel
      _signaling.joinChannel(widget.session.id);

      // 6. Role-specific initiation
      if (widget.isIncoming) {
        // Callee: tell caller we're ready to receive the offer
        await _signaling.sendReady();
        if (mounted) setState(() => _statusText = 'Waiting for caller…');
      } else {
        // Caller: notify callee via push (stub — no-op until SIGNAL merges)
        if (widget.session.clientId != null) {
          await IncomingCallStub.notifyCallee(
            sessionId: widget.session.id,
            calleeId: widget.session.clientId!,
            callerName: 'Coach',
            callType: widget.session.sessionType.value,
          );
        }
        if (mounted) setState(() => _statusText = 'Ringing…');
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  String _connectionStateLabel(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return 'Connecting…';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return 'Connected';
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return 'Reconnecting…';
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return 'Connection failed';
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return 'Call ended';
      default:
        return 'Connecting…';
    }
  }

  @override
  void dispose() {
    _signaling.dispose();
    _webRtc.dispose();
    _sessionService.leaveLiveSession();
    _sessionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video — full screen background
            if (_isConnected)
              Positioned.fill(
                child: RTCVideoView(
                  _webRtc.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              _buildConnectingBackground(),

            // Local video PIP — top-right corner
            Positioned(
              top: 80,
              right: 16,
              width: 100,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  _webRtc.localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CallHeader(
                session: widget.session,
                participants: _sessionService.participants,
                onBack: () => _endCall(remote: false),
              ),
            ),

            // Chat overlay
            if (_showChat)
              Positioned.fill(
                top: 72,
                child: CallChat(
                  messages: _sessionService.messages,
                  onSendMessage: (msg) => _sessionService.sendMessage(msg),
                  onClose: () => setState(() => _showChat = false),
                ),
              ),

            // Controls — bottom
            if (!_showChat)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CallControls(
                  isMuted: _isMuted,
                  isVideoEnabled: _isVideoEnabled,
                  isScreenSharing: _isScreenSharing,
                  isConnecting: !_isConnected,
                  isCallEnded: false,
                  onToggleMute: _toggleMute,
                  onToggleVideo: _toggleVideo,
                  onToggleScreenShare: _toggleScreenShare,
                  onToggleChat: _toggleChat,
                  onEndCall: () => _endCall(remote: false),
                  onToggleControls: () {},
                  onSwitchCamera: _switchCamera,
                ),
              ),

            // Status overlay while connecting
            if (!_isConnected)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 200),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.session.title ??
                          widget.session.sessionType.value
                              .replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingBackground() {
    return Container(
      color: Colors.grey[900],
      child: const Center(child: SizedBox.shrink()),
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _webRtc.setMuted(_isMuted);
    HapticFeedback.lightImpact();
  }

  void _toggleVideo() {
    setState(() => _isVideoEnabled = !_isVideoEnabled);
    _webRtc.setVideoEnabled(_isVideoEnabled);
    HapticFeedback.lightImpact();
  }

  void _toggleScreenShare() {
    setState(() => _isScreenSharing = !_isScreenSharing);
    HapticFeedback.lightImpact();
  }

  void _toggleChat() {
    setState(() => _showChat = !_showChat);
    HapticFeedback.lightImpact();
  }

  void _switchCamera() {
    unawaited(_webRtc.switchCamera());
    unawaited(HapticFeedback.lightImpact());
  }

  void _endCall({required bool remote}) {
    HapticFeedback.mediumImpact();

    // Log analytics before teardown
    if (_callStartTime != null) {
      final duration =
          DateTime.now().difference(_callStartTime!).inSeconds;
      CallAnalyticsService.logCallEnded(
        sessionId: widget.session.id,
        durationSeconds: duration,
        qualityStats: _webRtc.getStats(),
      );
    }

    if (!remote) {
      unawaited(_signaling.sendHangup());
    }

    Navigator.pop(context);
  }
}
