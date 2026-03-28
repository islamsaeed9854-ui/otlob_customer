import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecases/login_usecase.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();

    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase(LoginParams(email: email, password: password));

    result.fold(
      (user) {
        state = const AsyncData(null);
      },
      (failure) {
        state = AsyncError(failure.message ?? failure.code, StackTrace.current);
      },
    );
  }
}