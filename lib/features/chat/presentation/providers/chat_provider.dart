import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/message.dart';
import '../../../../core/network/network_providers.dart';
import 'package:dio/dio.dart';

part 'chat_provider.g.dart';

class ChatArgs {
  final String id; // This is the vendorId or orderId or conversationId
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
  String? _conversationId;

  @override
  FutureOr<List<Message>> build(ChatArgs args) async {
    final dio = ref.watch(dioProvider);
    
    try {
      // 1. Get or Create Conversation
      Response response;
      if (args.type == 'vendor') {
        response = await dio.post('/chat/conversations/vendor', data: {'vendorId': args.id});
      } else if (args.type == 'order') {
        response = await dio.post('/chat/conversations/order', data: {'orderId': args.id});
      } else if (args.type == 'support') {
         response = await dio.post('/chat/conversations/support', data: {'vendorId': args.id});
      } else {
        // Assume args.id is already a conversationId if type is unknown or direct
        response = await dio.get('/chat/conversations/${args.id}');
      }

      final conversation = response.data;
      _conversationId = conversation['id'];

      // 3. Listen for real-time messages
      final socket = ref.read(socketServiceProvider);
      socket.on('chat.message', (data) {
        if (data['conversationId'] == _conversationId) {
          final newMessage = Message(
            id: data['messageId'],
            content: data['text'] ?? '',
            type: _mapMessageType(data['type']),
            isMe: data['senderId'] == 'CURRENT_USER_ID', // This needs to be checked against real user ID
            timestamp: DateTime.parse(data['createdAt']),
            senderName: 'Other', // Could be expanded
          );
          
          // Check if message already exists (from optimistic update)
          ref.read(chatProvider(args).notifier)._addRealtimeMessage(newMessage);
        }
      });

      ref.onDispose(() {
        socket.off('chat.message');
      });

      // 4. Fetch Messages
      return _fetchMessages();
    } catch (e) {
      return [];
    }
  }

  void _addRealtimeMessage(Message message) {
    state.whenData((messages) {
      if (messages.any((m) => m.id == message.id)) return;
      state = AsyncData([...messages, message]);
    });
  }

  Future<List<Message>> _fetchMessages() async {
    if (_conversationId == null) return [];
    final dio = ref.read(dioProvider);
    
    try {
      final response = await dio.get('/chat/conversations/$_conversationId/messages');
      final List<dynamic> data = response.data['messages'];
      
      return data.map((m) => Message(
        id: m['id'],
        content: m['text'] ?? '',
        type: _mapMessageType(m['type']),
        isMe: m['sender']['role'] == 'CUSTOMER', // Simplified check
        timestamp: DateTime.parse(m['createdAt']),
        senderName: m['sender']['name'],
      )).toList();
    } catch (e) {
      return [];
    }
  }

  MessageType _mapMessageType(String? type) {
    switch (type) {
      case 'IMAGE': return MessageType.image;
      case 'VIDEO': return MessageType.video;
      case 'AUDIO': return MessageType.audio;
      default: return MessageType.text;
    }
  }

  Future<void> sendMessage(String content, {MessageType type = MessageType.text}) async {
    if (_conversationId == null) return;
    final dio = ref.read(dioProvider);

    final optimisticMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: type,
      isMe: true,
      timestamp: DateTime.now(),
      senderName: 'Me',
    );

    // Update state optimistically if possible, but build is FutureOr
    final previousState = await future;
    state = AsyncData([...previousState, optimisticMessage]);

    try {
      await dio.post(
        '/chat/conversations/$_conversationId/messages',
        data: {
          'type': 'TEXT',
          'text': content,
        },
      );
      // Refresh messages to get real IDs and server timestamps
      final updatedMessages = await _fetchMessages();
      state = AsyncData(updatedMessages);
    } catch (e) {
      // Revert or show error
      state = AsyncData(previousState);
    }
  }
}
