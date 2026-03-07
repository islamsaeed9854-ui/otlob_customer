import 'package:injectable/injectable.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

@lazySingleton
class SocketService {
  io.Socket? _socket;
  final Logger _logger = Logger();

  void initSocket(String userToken) {
    if (_socket != null && _socket!.connected) return;

    final baseUrl = dotenv.env['SOCKET_URL'] ?? 'http://10.0.2.2:3000';

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'token': userToken})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) => _logger.i('✅ Socket connected successfully'));
    _socket?.onDisconnect((_) => _logger.w('❌ Socket disconnected'));
  }

  void on(String eventName, Function(dynamic) callback) {
    _socket?.on(eventName, callback);
  }

  void emit(String eventName, dynamic data) {
    _socket?.emit(eventName, data);
  }

  void off(String eventName) {
    _socket?.off(eventName);
  }

  void connect() {
    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
