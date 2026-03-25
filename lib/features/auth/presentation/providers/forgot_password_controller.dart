import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecases/forgot_password_usecase.dart';

part 'forget_password_controller.g.dart';

@riverpod
class ForgotPasswordController extends _$ForgotPasswordController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> sendOtp(String email) async {
    state = const AsyncLoading();

    final forgotPasswordUseCase = ref.read(forgotPasswordUseCaseProvider);
    final result = await forgotPasswordUseCase(email);

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
