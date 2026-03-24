import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecases/register_usecase.dart';

part 'register_controller.g.dart';

@riverpod
class RegisterController extends _$RegisterController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AsyncLoading();

    final registerUseCase = ref.read(registerUseCaseProvider);
    final result = await registerUseCase(
      RegisterParams(
        name: name,
        email: email,
        password: password,
        phone: phone,
      ),
    );

    result.fold(
      (user) {
        state = const AsyncData(null);
      },
      (failure) {
        state = AsyncError(failure.code, StackTrace.current);
      },
    );
  }
}
