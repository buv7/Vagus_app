enum PresenceStatus { offline, idle, online }

class NetworkSnapshot {
  final int pingMs;        // simulated
  final int jitterMs;      // simulated
  final int downKbps;      // simulated
  final int upKbps;        // simulated
  final DateTime at;
  
  const NetworkSnapshot({
    required this.pingMs,
    required this.jitterMs,
    required this.downKbps,
    required this.upKbps,
    required this.at,
  });
}

class PresenceSnapshot {
  final PresenceStatus status;
  final DateTime lastSeen;
  final String note; // e.g., route/screen name
  
  const PresenceSnapshot({
    required this.status,
    required this.lastSeen,
    this.note = '',
  });
}

class PushTestResult {
  final bool sent;
  final String messageId;
  final String info;
  
  const PushTestResult({
    required this.sent,
    required this.messageId,
    this.info = '',
  });
}
