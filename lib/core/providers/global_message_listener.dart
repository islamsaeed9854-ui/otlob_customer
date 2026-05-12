import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/socket_service.dart';
import '../services/navigation_service.dart';
import '../services/token_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/chat/presentation/widgets/order_offer_bottom_sheet.dart';

part 'global_message_listener.g.dart';

@Riverpod(keepAlive: true)
class GlobalMessageListener extends _$GlobalMessageListener {
  String? _lastShownOfferId;

  @override
  void build() {
    final authStatus = ref.watch(authControllerProvider);
    
    if (authStatus == AuthStatus.authenticated) {
      _init();
    }
    
    return;
  }

  Future<void> _init() async {
    final socket = ref.read(socketServiceProvider);
    final tokenService = ref.read(tokenServiceProvider);
    final accessToken = await tokenService.getAccessToken();
    
    if (accessToken != null) {
      socket.initSocket(accessToken);
      
      socket.off('chat.message.global'); // Clean up old listeners
      socket.on('chat.message', (data) {
        _handleIncomingMessage(data);
      });
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final metadata = data['metadata'];
    if (metadata == null) return;

    if (metadata['type'] == 'OFFER') {
      final offerId = data['messageId'] ?? data['id'];
      if (offerId == _lastShownOfferId) return;

      final product = metadata['product'] as Map<String, dynamic>?;
      if (product == null) return;

      _lastShownOfferId = offerId;
      
      // Show popup globally
      final navigation = ref.read(navigationServiceProvider);
      final context = navigation.navigatorKey.currentContext;
      
      if (context != null) {
        // Optional: Check if we are already in the chat screen for this vendor
        // to avoid duplicate popups if ChatScreen is also listening.
        // For now, we allow it as requested "not only in chat we make it appear auto popup"
        
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OrderOfferBottomSheet(
            product: product,
            vendorId: data['senderId'] ?? '', // Sender is the vendor
            vendorName: data['senderName'] ?? 'Vendor',
          ),
        );
      }
    }
  }
}
