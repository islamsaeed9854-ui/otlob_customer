import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:injectable/injectable.dart';

abstract class INetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onStatusChange;
}

@LazySingleton(as: INetworkInfo)
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
