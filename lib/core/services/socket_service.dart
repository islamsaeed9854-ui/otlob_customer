import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

part 'socket_service.g.dart';

@Riverpod(keepAlive: true)
SocketService socketService(Ref ref) {
  final service = SocketService();
  ref.onDispose(service.disconnect);
  return service;
}

class SocketService {
  io.Socket? _socket;
  final Logger _logger = Logger();

  void initSocket(String userToken) {
    // If already connected, don't re-init unless we want to force a new token
    if (_socket != null && _socket!.connected) return;

    _socket?.dispose(); // Clean up old socket

    var baseUrl = dotenv.env['SOCKET_URL'] ?? 'https://ws.otlob-egy.online';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    print('📡 Attempting to connect to Socket: $baseUrl/events');

    _socket = io.io(
      '$baseUrl/events',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': userToken})
          .build(),
    );

    _socket?.connect();
    _socket?.onConnect((_) {
      _logger.i('✅ Socket connected');
      print('👤 Connected with Token: ${userToken.substring(0, 20)}...');
    });
    _socket?.onConnectError((err) => _logger.e('❌ Socket Connect Error: $err'));
    _socket?.onDisconnect((_) => _logger.w('❌ Socket disconnected'));
  }

  void on(String eventName, Function(dynamic) callback) =>
      _socket?.on(eventName, callback);

  void emit(String eventName, dynamic data) =>
      _socket?.emit(eventName, data);

  void off(String eventName) => _socket?.off(eventName);

  void connect() => _socket?.connect();

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}