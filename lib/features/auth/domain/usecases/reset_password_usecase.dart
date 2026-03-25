import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'reset_password_usecase.g.dart';

@riverpod
ResetPasswordUseCase resetPasswordUseCase(Ref ref) {
  return ResetPasswordUseCase(ref.read(authRepositoryProvider));
}

class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  @override
  Future<Result<void, Failure>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(
      email: params.email,
      otp: params.otp,
      newPassword: params.newPassword,
    );
  }
}

class ResetPasswordParams {
  final String email;
  final String otp;
  final String newPassword;
  ResetPasswordParams({
    required this.email,
    required this.otp,
    required this.newPassword,
  });
}
