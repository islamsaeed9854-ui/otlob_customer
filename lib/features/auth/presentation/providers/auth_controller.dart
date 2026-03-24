import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/token_service.dart';

part 'auth_controller.g.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthStatus build() {
    return AuthStatus.initial;
  }

  Future<void> checkAuthStatus() async {
    final tokenService = ref.read(tokenServiceProvider);
    final isValid = await tokenService.hasValidTokens();

    if (isValid) {
      state = AuthStatus.authenticated;
    } else {
      await tokenService.clearTokens();
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> login(String accessToken, String refreshToken) async {
    final tokenService = ref.read(tokenServiceProvider);
    await tokenService.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    final tokenService = ref.read(tokenServiceProvider);
    await tokenService.clearTokens();
    state = AuthStatus.unauthenticated;
  }
}