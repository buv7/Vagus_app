import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks which agents are currently viewing/typing/replying on a ticket
/// using Supabase Realtime presence.
class AdminPresenceService {
  AdminPresenceService._();
  static final AdminPresenceService instance = AdminPresenceService._();

  final SupabaseClient _sb = Supabase.instance.client;
  RealtimeChannel? _channel;
  Timer? _heartbeat;
  String? _ticketId;
  Map<String, dynamic> _selfState = {};
  final ValueNotifier<List<Map<String, dynamic>>> peers = ValueNotifier<List<Map<String, dynamic>>>(const []);

  bool get connected => _channel != null;

  Future<void> connect({
    required String ticketId,
    required String agentId,
    required String agentName,
    String? avatarUrl,
  }) async {
    // If already connected to a different ticket, dispose and reconnect
    if (_ticketId != null && _ticketId != ticketId) {
      await dispose();
    }

    _ticketId = ticketId;
    final room = 'support_ticket:$ticketId';
    
    try {
      _channel = _sb.channel(room);
      
      // Subscribe to the channel
      _channel!.subscribe();
      
      // Set up presence tracking
      _selfState = {
        'agent_id': agentId,
        'name': agentName,
        'avatar': avatarUrl,
        'typing': false,
        'replying': false,
        'ts': DateTime.now().toIso8601String(),
      };

      // Track presence
      await _channel!.track(_selfState);

      // Heartbeat every 15s (keeps presence fresh)
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
        _selfTouch();
      });
      
      // For now, simulate presence updates until we get the real API working
      _simulatePresenceUpdates();
      
    } catch (e) {
      debugPrint('Failed to connect to presence: $e');
    }
  }

  void _simulatePresenceUpdates() {
    // Simulate presence updates for development
    Timer.periodic(const Duration(seconds: 5), (_) {
      if (_channel != null) {
        final mockPeers = [
          {
            'agent_id': _selfState['agent_id'],
            'name': _selfState['name'],
            'avatar': _selfState['avatar'],
            'typing': _selfState['typing'],
            'replying': _selfState['replying'],
            'ts': DateTime.now().toIso8601String(),
          }
        ];
        peers.value = mockPeers;
      }
    });
  }

  Future<void> _selfTouch() async {
    if (_channel == null) return;
    _selfState['ts'] = DateTime.now().toIso8601String();
    await _channel!.track(_selfState);
  }

  Future<void> setTyping(bool typing) async {
    if (_channel == null) return;
    _selfState['typing'] = typing;
    await _channel!.track(_selfState);
  }

  Future<void> setReplying(bool replying) async {
    if (_channel == null) return;
    _selfState['replying'] = replying;
    await _channel!.track(_selfState);
  }

  Future<void> dispose() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    try {
      await _channel?.untrack();
      await _channel?.unsubscribe();
    } catch (_) {}
    _channel = null;
    _ticketId = null;
    peers.value = const [];
  }
}
