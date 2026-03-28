import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'verify_otp_usecase.g.dart';

@riverpod
VerifyOtpUseCase verifyOtpUseCase(Ref ref) {
  return VerifyOtpUseCase(ref.read(authRepositoryProvider));
}

class VerifyOtpUseCase implements UseCase<void, VerifyOtpParams> {
  final AuthRepository repository;
  VerifyOtpUseCase(this.repository);

  @override
  Future<Result<void, Failure>> call(VerifyOtpParams params) async {
    return await repository.verifyOtp(
      email: params.email,
      otp: params.otp,
      purpose: params.purpose,
    );
  }
}

class VerifyOtpParams {
  final String email;
  final String otp;
  final String? purpose;
  VerifyOtpParams({required this.email, required this.otp, this.purpose});
}
