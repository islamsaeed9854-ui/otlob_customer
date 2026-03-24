sealed class Failure {
  final String code;
  const Failure({required this.code});
}

class ServerFailure extends Failure {
  const ServerFailure() : super(code: 'server_error');
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super(code: 'no_internet');
}

class CacheFailure extends Failure {
  const CacheFailure() : super(code: 'cache_error');
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure() : super(code: 'unexpected_error');
}