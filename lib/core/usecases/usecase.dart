import '../errors/failure.dart';
import '../utils/result.dart';

abstract class UseCase<T, Params> {
  Future<Result<T, Failure>> call(Params params);
}

abstract class StreamUseCase<T, Params> {
  Stream<Result<T, Failure>> call(Params params);
}

class NoParams {
  const NoParams();
}