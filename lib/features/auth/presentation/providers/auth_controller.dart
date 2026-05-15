import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/token_service.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'auth_controller.g.dart';

enum AuthStatus { initial, authenticated, unauthenticated, unverified }

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthStatus build() {
    return AuthStatus.initial;
  }

  Future<void> checkAuthStatus() async {
    final tokenService = ref.read(tokenServiceProvider);
    final hasTokens = await tokenService.hasValidTokens();

    if (!hasTokens) {
      await tokenService.clearTokens();
      state = AuthStatus.unauthenticated;
      return;
    }

    final isExpired = await tokenService.isAccessTokenExpired();
    if (isExpired) {
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.refreshToken();
      } catch (_) {
        await tokenService.clearTokens();
        state = AuthStatus.unauthenticated;
        return;
      }
    }

    final isVerified = await tokenService.isUserVerified();
    state = isVerified ? AuthStatus.authenticated : AuthStatus.unverified;
  }

  Future<void> login(String accessToken, String refreshToken) async {
    final tokenService = ref.read(tokenServiceProvider);
    await tokenService.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    
    final isVerified = await tokenService.isUserVerified();
    state = isVerified ? AuthStatus.authenticated : AuthStatus.unverified;
  }

  Future<void> logout() async {
    final tokenService = ref.read(tokenServiceProvider);
    await tokenService.clearTokens();
    state = AuthStatus.unauthenticated;
  }
}