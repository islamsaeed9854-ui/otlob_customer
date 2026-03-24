sealed class Failure {
  final String code;
  final String? message;
  
  const Failure({required this.code, this.message});
}

class ServerFailure extends Failure {
  const ServerFailure([String? message]) : super(code: 'server_error', message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String? message]) : super(code: 'no_internet', message: message);
}

class CacheFailure extends Failure {
  const CacheFailure([String? message]) : super(code: 'cache_error', message: message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String? message]) : super(code: 'unexpected_error', message: message);
}