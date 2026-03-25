import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecases/reset_password_usecase.dart';

part 'reset_password_controller.g.dart';

@riverpod
class ResetPasswordController extends _$ResetPasswordController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> reset(String email, String otp, String newPassword) async {
    state = const AsyncLoading();
    final result = await ref.read(resetPasswordUseCaseProvider)(
      ResetPasswordParams(email: email, otp: otp, newPassword: newPassword),
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
