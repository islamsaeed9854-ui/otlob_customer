import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'network_providers.dart'; 

part 'network_info.g.dart';

abstract class INetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onStatusChange;
}

class NetworkInfo implements INetworkInfo {
  final InternetConnection connectionChecker;

  NetworkInfo(this.connectionChecker);

  @override
  Future<bool> get isConnected async {
    try {
      return await connectionChecker.hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onStatusChange => connectionChecker.onStatusChange.map(
        (status) => status == InternetStatus.connected,
      );
}

@Riverpod(keepAlive: true)
INetworkInfo networkInfo(Ref ref) {
  final connectionChecker = ref.watch(internetConnectionProvider);
  return NetworkInfo(connectionChecker);
}