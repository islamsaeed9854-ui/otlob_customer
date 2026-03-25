import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

part 'verify_otp_controller.g.dart';

@riverpod
class VerifyOtpController extends _$VerifyOtpController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> verify(String email, String otp) async {
    state = const AsyncLoading();
    final result = await ref.read(verifyOtpUseCaseProvider)(
      VerifyOtpParams(email: email, otp: otp),
    );

    return result.fold(
      (_) {
        state = const AsyncData(null);
        return true;
      },
      (failure) {
        state = AsyncError(failure.message ?? failure.code, StackTrace.current);
        return false;
      },
    );
  }
}
