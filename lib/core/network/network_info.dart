import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:injectable/injectable.dart';

abstract class INetworkInfo {
  Future<bool> get isConnected;
}

@LazySingleton(as: INetworkInfo)
class NetworkInfo implements INetworkInfo {
  final InternetConnection connectionChecker;

  NetworkInfo(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasInternetAccess;
}
