enum MessageType { text, image, video, audio, file }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final bool isMe;
  final DateTime timestamp;
  final String? senderName;
  final String? senderProfilePic;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    required this.timestamp,
    this.senderName,
    this.senderProfilePic,
    this.mediaUrl,
    this.metadata,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    bool? isMe,
    DateTime? timestamp,
    String? senderName,
    String? senderProfilePic,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      senderProfilePic: senderProfilePic ?? this.senderProfilePic,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
