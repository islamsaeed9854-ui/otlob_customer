import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/message.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/services/socket_service.dart';
import 'package:dio/dio.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

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
  String? _currentUserId;

  @override
  Future<List<Message>> build(ChatArgs args) async {
    final dio = ref.watch(dioProvider);
    final tokenService = ref.read(tokenServiceProvider);
    _currentUserId = await tokenService.getUserId();
    
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

      final conversation = response.data['data'];
      _conversationId = conversation['id'];

      // 3. Initialize Socket and Listen for real-time messages
      final socket = ref.read(socketServiceProvider);
      final accessToken = await ref.read(tokenServiceProvider).getAccessToken();
      if (accessToken != null) {
        var isExpired = await ref.read(tokenServiceProvider).isAccessTokenExpired();
        var currentToken = accessToken;
        
        if (isExpired) {
          print('🔄 ChatProvider: Token expired, attempting refresh...');
          try {
            currentToken = await ref.read(authRepositoryProvider).refreshToken();
            print('✅ ChatProvider: Token refreshed successfully');
            isExpired = false;
          } catch (e) {
            print('❌ ChatProvider: Token refresh failed: $e');
          }
        }

        print('🔌 ChatProvider: Initializing socket for conversation $_conversationId');
        print('⏳ ChatProvider: Token is expired: $isExpired');
        socket.initSocket(currentToken);
      } else {
        print('⚠️ ChatProvider: No access token found for socket');
      }

      socket.off('chat.message'); // Prevent duplicate listeners
      socket.on('chat.message', (data) {
        print('📥 Customer Socket Message Received: $data');
        if (data['conversationId'] == _conversationId) {
          print('✅ Adding real-time message to customer list');
          final newMessage = Message(
            id: data['messageId'],
            content: data['text'] ?? '',
            type: _mapMessageType(data['type']),
            isMe: data['senderId'] == _currentUserId,
            timestamp: DateTime.parse(data['createdAt']),
            senderName: data['senderName'] ?? 'Support', 
            mediaUrl: _getFullUrl(data['mediaUrl']),
          );
          
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
      // Check if we already have this message by ID
      if (messages.any((m) => m.id == message.id)) return;

      // Remove the optimistic/temporary message that corresponds to this one.
      // If it's a media message, try to match by mediaUrl.
      // If it's a text message, match by content.
      final filteredMessages = messages.where((m) {
        if (!m.id.startsWith('temp-') && !m.id.startsWith('upload-')) return true;
        
        // Only remove our own optimistic messages if the incoming message is also from us
        if (!message.isMe) return true;

        if (message.mediaUrl != null && m.mediaUrl == message.mediaUrl) return false;
        if (message.content.isNotEmpty && m.content == message.content) return false;
        
        return true;
      }).toList();
      
      state = AsyncData([message, ...filteredMessages]);
    });
  }

  Future<List<Message>> _fetchMessages() async {
    if (_conversationId == null) return [];
    final dio = ref.read(dioProvider);
    
    try {
      final response = await dio.get('/chat/conversations/$_conversationId/messages');
      final List<dynamic> data = response.data['data']['messages'];
      
      final ordered = data.map((m) => Message(
        id: m['id'],
        content: m['text'] ?? '',
        type: _mapMessageType(m['type']),
        isMe: m['sender']['id'] == _currentUserId, 
        timestamp: DateTime.parse(m['createdAt']),
        senderName: m['sender']['name'],
        mediaUrl: _getFullUrl(m['mediaUrl']),
      )).toList();
      
      return ordered.reversed.toList(); // Newest first for reversed list
    } catch (e) {
      return [];
    }
  }

  String? _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    // Remove trailing slash from baseUrl and leading slash from path
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    
    return '$cleanBaseUrl$cleanPath';
  }

  MessageType _mapMessageType(String? type) {
    switch (type?.toUpperCase()) {
      case 'IMAGE': return MessageType.image;
      case 'VIDEO': return MessageType.video;
      case 'AUDIO': return MessageType.audio;
      case 'FILE': return MessageType.file;
      default: return MessageType.text;
    }
  }

  Future<String?> uploadMedia(String filePath) async {
    if (_conversationId == null) return null;
    final dio = ref.read(dioProvider);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await dio.post(
        '/chat/conversations/$_conversationId/messages/upload',
        data: formData,
      );
      final responseData = response.data;
      String? url;
      if (responseData['data'] != null && responseData['data']['url'] != null) {
        url = responseData['data']['url'];
      } else {
        url = responseData['url'];
      }
      return _getFullUrl(url);
    } catch (e) {
      print('❌ ChatProvider: Upload error: $e');
      return null;
    }
  }

  Future<void> sendMedia(String filePath, MessageType type) async {
    if (_conversationId == null) return;

    final tempId = 'upload-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      id: tempId,
      content: 'Uploading...',
      type: type,
      isMe: true,
      timestamp: DateTime.now(),
      senderName: 'Me',
      mediaUrl: null, // Still uploading
    );

    state.whenData((messages) {
      state = AsyncData([optimisticMessage, ...messages]);
    });

    final mediaUrl = await uploadMedia(filePath);
    
    if (mediaUrl != null) {
      await sendMessage('', type: type, mediaUrl: mediaUrl, tempIdToRemove: tempId);
    } else {
      // Remove the "Uploading..." message if upload failed
      state.whenData((messages) {
        state = AsyncData(messages.where((m) => m.id != tempId).toList());
      });
    }
  }

  Future<void> sendMessage(String content, {MessageType type = MessageType.text, String? mediaUrl, String? tempIdToRemove}) async {
    if (_conversationId == null) return;
    final dio = ref.read(dioProvider);

    final tempId = tempIdToRemove ?? 'temp-${DateTime.now().millisecondsSinceEpoch}';
    
    final optimisticMessage = Message(
      id: tempId,
      content: content,
      type: type,
      isMe: true,
      timestamp: DateTime.now(),
      senderName: 'Me',
      mediaUrl: mediaUrl,
    );

    state.whenData((messages) {
      // If we are replacing an existing temp message (like from sendMedia), 
      // we filter it out first if it's not already handled by the tempId logic
      final filtered = messages.where((m) => m.id != tempIdToRemove).toList();
      state = AsyncData([optimisticMessage, ...filtered]);
    });

    try {
      final response = await dio.post(
        '/chat/conversations/$_conversationId/messages',
        data: {
          'type': type.name.toUpperCase(),
          'text': content.isEmpty ? null : content,
          'mediaUrl': mediaUrl,
        },
      );
      
      // Instead of full refresh, let's try to update the message with real data if possible
      // But for now, a refresh is safer if the backend generates IDs/timestamps
      final updatedMessages = await _fetchMessages();
      state = AsyncData(updatedMessages);
    } catch (e) {
      print('❌ ChatProvider: Send error: $e');
      // On error, we still refresh to be in sync with server
      final updatedMessages = await _fetchMessages();
      state = AsyncData(updatedMessages);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_conversationId == null) return;

    // Optimistically remove from state
    state.whenData((messages) {
      state = AsyncData(messages.where((m) => m.id != messageId).toList());
    });

    // If it's a temporary message, we don't need to call the API
    if (messageId.startsWith('temp-') || messageId.startsWith('upload-')) {
      return;
    }

    final dio = ref.read(dioProvider);
    try {
      await dio.delete('/chat/conversations/$_conversationId/messages/$messageId');
    } catch (e) {
      print('❌ ChatProvider: Delete error: $e');
      // On error, we could optionally refresh the list to restore the message if the server says it still exists
      // final updatedMessages = await _fetchMessages();
      // state = AsyncData(updatedMessages);
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    if (_conversationId == null) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.patch(
        '/chat/conversations/$_conversationId/messages/$messageId', 
        data: {'text': newContent}
      );
      state.whenData((messages) {
        final updated = messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(content: newContent);
          }
          return m;
        }).toList();
        state = AsyncData(updated);
      });
    } catch (e) {
      print('❌ ChatProvider: Edit error: $e');
    }
  }
}
