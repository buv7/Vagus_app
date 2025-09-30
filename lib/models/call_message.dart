
enum MessageType {
  text,
  emoji,
  file,
  image;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.emoji:
        return 'emoji';
      case MessageType.file:
        return 'file';
      case MessageType.image:
        return 'image';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'emoji':
        return MessageType.emoji;
      case 'file':
        return MessageType.file;
      case 'image':
        return MessageType.image;
      default:
        return MessageType.text;
    }
  }
}

class CallMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String message;
  final MessageType messageType;
  final String? fileUrl;
  final bool isSystemMessage;
  final DateTime createdAt;

  // Additional fields for UI
  final String? senderName;
  final String? senderAvatar;
  final bool isCurrentUser;

  CallMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.message,
    this.messageType = MessageType.text,
    this.fileUrl,
    this.isSystemMessage = false,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
    this.isCurrentUser = false,
  });

  factory CallMessage.fromJson(Map<String, dynamic> json) {
    return CallMessage(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      messageType: MessageType.fromString(json['message_type'] as String? ?? 'text'),
      fileUrl: json['file_url'] as String?,
      isSystemMessage: json['is_system_message'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'sender_id': senderId,
      'message': message,
      'message_type': messageType.value,
      'file_url': fileUrl,
      'is_system_message': isSystemMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CallMessage copyWith({
    String? id,
    String? sessionId,
    String? senderId,
    String? message,
    MessageType? messageType,
    String? fileUrl,
    bool? isSystemMessage,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatar,
    bool? isCurrentUser,
  }) {
    return CallMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  String get displayName => senderName ?? 'User $senderId';
  String get initials {
    final name = displayName;
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }

  bool get isText => messageType == MessageType.text;
  bool get isEmoji => messageType == MessageType.emoji;
  bool get isFile => messageType == MessageType.file;
  bool get isImage => messageType == MessageType.image;

  String get timeFormatted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    if (messageDate == today) {
      // Today - show time only
      return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date and time
      return '${createdAt.day}/${createdAt.month} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  String toString() {
    return 'CallMessage(id: $id, senderId: $senderId, message: $message, type: ${messageType.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CallMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
