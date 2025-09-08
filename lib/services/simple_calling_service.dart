import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/live_session.dart';
import '../models/call_participant.dart';
import '../models/call_message.dart';

/// Simplified calling service that works without WebRTC
/// Provides all core calling functionality with mock video/audio
class SimpleCallingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controllers for real-time updates
  final StreamController<LiveSession> _sessionController = StreamController.broadcast();
  final StreamController<List<CallParticipant>> _participantsController = StreamController.broadcast();
  final StreamController<List<CallMessage>> _messagesController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  
  // Current session state
  LiveSession? _currentSession;
  List<CallParticipant> _participants = [];
  List<CallMessage> _messages = [];
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isScreenSharing = false;
  
  // Getters
  Stream<LiveSession> get sessionStream => _sessionController.stream;
  Stream<List<CallParticipant>> get participantsStream => _participantsController.stream;
  Stream<List<CallMessage>> get messagesStream => _messagesController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  LiveSession? get currentSession => _currentSession;
  List<CallParticipant> get participants => _participants;
  List<CallMessage> get messages => _messages;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isScreenSharing => _isScreenSharing;

  /// Create a new live session
  Future<String> createLiveSession({
    required SessionType sessionType,
    required String title,
    String? description,
    String? coachId,
    String? clientId,
    DateTime? scheduledAt,
    int maxParticipants = 2,
    bool isRecordingEnabled = false,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc('create_live_session', params: {
        'p_session_type': sessionType.value,
        'p_title': title,
        'p_description': description,
        'p_coach_id': coachId ?? currentUserId,
        'p_client_id': clientId,
        'p_scheduled_at': scheduledAt?.toIso8601String(),
        'p_max_participants': maxParticipants,
        'p_is_recording_enabled': isRecordingEnabled,
      });

      return response as String;
    } catch (e) {
      _errorController.add('Failed to create session: $e');
      rethrow;
    }
  }

  /// Join an existing live session
  Future<void> joinLiveSession(String sessionId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get session details
      final session = await getLiveSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // Join the session
      await _supabase.rpc('join_live_session', params: {
        'p_session_id': sessionId,
        'p_user_id': currentUserId,
      });

      _currentSession = session;
      
      // Start listening to real-time updates
      _startListeningToUpdates(sessionId);
      
      // Add current user as participant
      final currentUser = CallParticipant(
        id: '${currentUserId}_$sessionId',
        sessionId: sessionId,
        userId: currentUserId,
        joinedAt: DateTime.now(),
        isMuted: _isMuted,
        isVideoEnabled: _isVideoEnabled,
        isScreenSharing: _isScreenSharing,
        connectionQuality: ConnectionQuality.excellent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _participants.add(currentUser);
      _participantsController.add(_participants);
      
      _sessionController.add(session);
      
    } catch (e) {
      _errorController.add('Failed to join session: $e');
      rethrow;
    }
  }

  /// Cancel a live session
  Future<void> cancelLiveSession(String sessionId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase
          .from('live_sessions')
          .update({'status': 'cancelled', 'ended_at': DateTime.now().toIso8601String()})
          .eq('id', sessionId);
    } catch (e) {
      _errorController.add('Failed to cancel session: $e');
    }
  }

  /// Leave the current session
  Future<void> leaveLiveSession() async {
    if (_currentSession == null) return;
    
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        await _supabase.rpc('leave_live_session', params: {
          'p_session_id': _currentSession!.id,
          'p_user_id': currentUserId,
        });
      }
      
      // Remove current user from participants
      _participants.removeWhere((p) => p.userId == currentUserId);
      _participantsController.add(_participants);
      
      // Clear current session
      _currentSession = null;
      _participants.clear();
      _messages.clear();
      
    } catch (e) {
      _errorController.add('Failed to leave session: $e');
    }
  }

  /// Get session details
  Future<LiveSession?> getLiveSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('live_sessions')
          .select('''
            *,
            profiles!live_sessions_coach_id_fkey(
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('id', sessionId)
          .single();

      return LiveSession.fromJson(response);
    } catch (e) {
      _errorController.add('Failed to get session: $e');
      return null;
    }
  }

  /// Get user's active sessions
  Future<List<LiveSession>> getUserActiveSessions() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase.rpc('get_user_active_sessions', params: {
        'p_user_id': currentUserId,
      });

      return (response as List)
          .map((json) => LiveSession.fromJson(json))
          .toList();
    } catch (e) {
      _errorController.add('Failed to get active sessions: $e');
      return [];
    }
  }

  /// Send a message in the current session
  Future<void> sendMessage(String content, {bool isSystemMessage = false}) async {
    if (_currentSession == null) return;
    
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final message = CallMessage(
        id: '',
        sessionId: _currentSession!.id,
        senderId: currentUserId,
        message: content,
        isSystemMessage: isSystemMessage,
        createdAt: DateTime.now(),
      );

      await _supabase.from('call_messages').insert(message.toJson());
      
    } catch (e) {
      _errorController.add('Failed to send message: $e');
    }
  }

  /// Toggle mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    _updateParticipantState();
  }

  /// Toggle video state
  void toggleVideo() {
    _isVideoEnabled = !_isVideoEnabled;
    _updateParticipantState();
  }

  /// Toggle screen sharing
  void toggleScreenShare() {
    _isScreenSharing = !_isScreenSharing;
    _updateParticipantState();
  }

  /// Update participant state
  void _updateParticipantState() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    final index = _participants.indexWhere((p) => p.userId == currentUserId);
    if (index != -1) {
      _participants[index] = _participants[index].copyWith(
        isMuted: _isMuted,
        isVideoEnabled: _isVideoEnabled,
        isScreenSharing: _isScreenSharing,
      );
      _participantsController.add(_participants);
    }
  }

  /// Start listening to real-time updates
  void _startListeningToUpdates(String sessionId) {
    // Listen to participants
    _supabase
        .from('call_participants')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .listen((data) {
      _participants = data.map((json) => CallParticipant.fromJson(json)).toList();
      _participantsController.add(_participants);
    });

    // Listen to messages
    _supabase
        .from('call_messages')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .order('created_at')
        .listen((data) {
      _messages = data.map((json) => CallMessage.fromJson(json)).toList();
      _messagesController.add(_messages);
    });
  }

  /// Dispose resources
  void dispose() {
    _sessionController.close();
    _participantsController.close();
    _messagesController.close();
    _errorController.close();
  }
}
