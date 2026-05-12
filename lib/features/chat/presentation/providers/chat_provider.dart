import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/message.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_provider.dart';

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
    final lang = ref.watch(appSettingsProvider).languageCode;
    final s = AppStrings(lang == 'ar');

    return [
      Message(
        id: '1',
        content: args.type == 'support' ? s.supportGreeting : s.vendorGreeting,
        type: MessageType.text,
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        senderName: args.type == 'support' ? (lang == 'ar' ? 'الدعم' : 'Support') : (lang == 'ar' ? 'المتجر' : 'Vendor'),
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
