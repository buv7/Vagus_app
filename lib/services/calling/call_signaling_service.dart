import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Realtime broadcast channel for WebRTC signal exchange.
///
/// Signal protocol (channel: call:{session_id}):
///   offer         → {sdp, type}                   caller → callee
///   answer        → {sdp, type}                   callee → caller
///   ice_candidate → {candidate, sdpMid, sdpMLineIndex}  both directions
///   ready         → {}                            callee notifies caller it joined
///   hangup        → {}                            either party ends call
class CallSignalingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  void Function(Map<String, dynamic>)? onOffer;
  void Function(Map<String, dynamic>)? onAnswer;
  void Function(Map<String, dynamic>)? onIceCandidate;
  void Function()? onPeerReady;
  void Function()? onHangup;

  void joinChannel(String sessionId) {
    _channel = _supabase.channel('call:$sessionId');

    _channel!
        .onBroadcast(
          event: 'offer',
          callback: (data) => onOffer?.call(data),
        )
        .onBroadcast(
          event: 'answer',
          callback: (data) => onAnswer?.call(data),
        )
        .onBroadcast(
          event: 'ice_candidate',
          callback: (data) => onIceCandidate?.call(data),
        )
        .onBroadcast(
          event: 'ready',
          callback: (_) => onPeerReady?.call(),
        )
        .onBroadcast(
          event: 'hangup',
          callback: (_) => onHangup?.call(),
        )
        .subscribe();
  }

  Future<void> sendOffer(Map<String, dynamic> sdp) =>
      _broadcast('offer', sdp);

  Future<void> sendAnswer(Map<String, dynamic> sdp) =>
      _broadcast('answer', sdp);

  Future<void> sendIceCandidate(Map<String, dynamic> candidate) =>
      _broadcast('ice_candidate', candidate);

  Future<void> sendReady() => _broadcast('ready', {});

  Future<void> sendHangup() => _broadcast('hangup', {});

  Future<void> _broadcast(String event, Map<String, dynamic> payload) async {
    await _channel?.sendBroadcastMessage(event: event, payload: payload);
  }

  Future<void> dispose() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
    }
  }
}
