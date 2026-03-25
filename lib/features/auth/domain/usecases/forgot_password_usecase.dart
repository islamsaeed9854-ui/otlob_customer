import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'forgot_password_usecase.g.dart';

@riverpod
ForgotPasswordUseCase forgotPasswordUseCase(Ref ref) {
  return ForgotPasswordUseCase(ref.read(authRepositoryProvider));
}

class ForgotPasswordUseCase implements UseCase<void, String> {
  final AuthRepository repository;
  ForgotPasswordUseCase(this.repository);

  @override
  Future<Result<void, Failure>> call(String email) async {
    return await repository.forgotPassword(email: email);
  }
}