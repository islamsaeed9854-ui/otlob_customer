import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/message.dart';

part 'chat_provider.g.dart';

class ChatArgs {
  final String id;
  final String type;

  ChatArgs({required this.id, required this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatArgs && runtimeType == other.runtimeType && id == other.id && type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

@Riverpod(keepAlive: true)
class Chat extends _$Chat {
  @override
  List<Message> build(ChatArgs args) {
    return [
      Message(
        id: '1',
        content: args.type == 'support' ? 'Hello! How can we help you today?' : 'Hello! Your order is being prepared.',
        type: MessageType.text,
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        senderName: args.type == 'support' ? 'Support' : 'Vendor',
      ),
    ];
  }

  void sendMessage(String content, {MessageType type = MessageType.text}) {
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      isMe: true,
      timestamp: DateTime.now(),
      senderName: 'Me',
    );
    state = [...state, newMessage];

    // Mock auto-reply
    Future.delayed(const Duration(seconds: 2), () {
      // Use ref.read to get the current state and compare
      if (ref.read(chatProvider(args)).last.id == newMessage.id) {
        final reply = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Got it! Is there anything else?',
          type: MessageType.text,
          isMe: false,
          timestamp: DateTime.now(),
          senderName: args.type == 'support' ? 'Support' : 'Vendor',
        );
        state = [...state, reply];
      }
    });
  }
}
