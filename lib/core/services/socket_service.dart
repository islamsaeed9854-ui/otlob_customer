import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../features/auth/data/repositories/auth_repository_impl.dart';

part 'socket_service.g.dart';

@Riverpod(keepAlive: true)
SocketService socketService(Ref ref) {
  final service = SocketService(ref);
  ref.onDispose(service.disconnect);
  return service;
}

class SocketService {
  final Ref _ref;
  io.Socket? _socket;
  final Logger _logger = Logger();

  SocketService(this._ref);

  Future<void> initSocket(String userToken) async {
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
    
    _socket?.onConnectError((err) async {
      _logger.e('❌ Socket Connect Error: $err');
      final errorStr = err.toString().toLowerCase();
      if (errorStr.contains('unauthorized') || errorStr.contains('expired') || errorStr.contains('auth')) {
        _logger.w('🔐 Socket: Auth error detected, refreshing token...');
        try {
          final authRepo = _ref.read(authRepositoryProvider);
          final newToken = await authRepo.refreshToken();
          initSocket(newToken); // Retry with new token
        } catch (e) {
          _logger.e('❌ Socket: Re-auth failed: $e');
        }
      }
    });

    _socket?.onDisconnect((_) => _logger.w('❌ Socket disconnected'));
  }

  void on(String eventName, Function(dynamic) callback) =>
      _socket?.on(eventName, callback);

  void emit(String eventName, dynamic data) =>
      _socket?.emit(eventName, data);

  void off(String eventName, [Function(dynamic)? callback]) => _socket?.off(eventName, callback);

  void connect() => _socket?.connect();

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}