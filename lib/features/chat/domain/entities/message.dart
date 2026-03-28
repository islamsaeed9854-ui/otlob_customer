enum MessageType { text, image, video, audio, file }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final bool isMe;
  final DateTime timestamp;
  final String? senderName;
  final String? senderProfilePic;

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    required this.timestamp,
    this.senderName,
    this.senderProfilePic,
  });
}
