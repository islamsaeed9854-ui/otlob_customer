import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String? message;
  final String? code;

  const Failure({this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message, super.code = 'server_error'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code = 'no_internet',
  });
}

class CacheFailure extends Failure {
  const CacheFailure({super.message, super.code = 'cache_error'});
}
