import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../config/env_config.dart';

typedef OnIceCandidateCallback = void Function(RTCIceCandidate candidate);
typedef OnConnectionStateCallback = void Function(RTCPeerConnectionState state);

class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _usingFrontCamera = true;
  RTCPeerConnectionState _connectionState =
      RTCPeerConnectionState.RTCPeerConnectionStateNew;

  OnIceCandidateCallback? onIceCandidate;
  OnConnectionStateCallback? onConnectionStateChange;
  VoidCallback? onRemoteStreamAdded;

  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isConnected =>
      _connectionState ==
      RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  static Map<String, dynamic> get _iceConfig => {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun.cloudflare.com:3478'},
          {
            'urls': 'turn:relay.expressturn.com:3478',
            'username': EnvConfig.expressturnUser,
            'credential': EnvConfig.expressturnPass,
          },
        ],
        'iceCandidatePoolSize': 10,
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
      };

  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> startLocalMedia({bool video = true}) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });
    localRenderer.srcObject = _localStream;
    _isVideoEnabled = video;
  }

  Future<void> setupPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceConfig);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onIceCandidate?.call(candidate);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      _connectionState = state;
      onConnectionStateChange?.call(state);
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        onRemoteStreamAdded?.call();
      }
    };

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(Map<String, dynamic> sdpMap) async {
    final desc = RTCSessionDescription(
      sdpMap['sdp'] as String,
      sdpMap['type'] as String,
    );
    await _peerConnection!.setRemoteDescription(desc);
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidateMap) async {
    final candidate = RTCIceCandidate(
      candidateMap['candidate'] as String,
      candidateMap['sdpMid'] as String?,
      candidateMap['sdpMLineIndex'] as int?,
    );
    await _peerConnection!.addCandidate(candidate);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !muted);
  }

  void setVideoEnabled(bool enabled) {
    _isVideoEnabled = enabled;
    _localStream?.getVideoTracks().forEach((t) => t.enabled = enabled);
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks();
    if (tracks == null || tracks.isEmpty) return;
    await Helper.switchCamera(tracks[0]);
    _usingFrontCamera = !_usingFrontCamera;
  }

  Map<String, dynamic> getStats() => {
        'is_muted': _isMuted,
        'is_video_enabled': _isVideoEnabled,
        'using_front_camera': _usingFrontCamera,
        'connection_state': _connectionState.name,
        'used_turn': true, // conservative; cannot determine without RTCStatsReport yet
      };

  Future<void> dispose() async {
    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    _localStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}
