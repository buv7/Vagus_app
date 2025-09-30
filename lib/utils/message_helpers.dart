import '../services/messages_service.dart';

/// Safely extracts and normalizes message text for previews and AI drafting
/// Avoids accidental whitespace-only previews and normalizes inputs
String msgText(Message message) {
  return message.text.trim();
}

/// Checks if a message has meaningful content (not just whitespace)
bool hasContent(Message message) {
  return msgText(message).isNotEmpty;
}

/// Gets a preview of the message text, truncated to specified length
String msgPreview(Message message, {int maxLength = 50}) {
  final text = msgText(message);
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}
