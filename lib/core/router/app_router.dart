import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:otlob_customer/features/auth/presentation/pages/login_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/navigation_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../providers/app_settings_provider.dart';
import 'route_paths.dart';
import 'route_names.dart';

part 'app_router.g.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthStatus>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );

    _ref.listen<AppSettingsState>(
      appSettingsProvider,
      (_, _) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authStatus = _ref.read(authControllerProvider);

    final hasSeenOnboarding = _ref.read(appSettingsProvider).hasSeenOnboarding;

    final isGoingToSplash = state.uri.path == RoutePaths.splash;
    final isGoingToLogin = state.uri.path == RoutePaths.login;
    final isGoingToOnboarding = state.uri.path == RoutePaths.onboarding;
    final isGoingToRegister = state.uri.path == RoutePaths.register;

    if (authStatus == AuthStatus.initial) {
      return isGoingToSplash ? null : RoutePaths.splash;
    }

    if (authStatus == AuthStatus.unauthenticated) {
      if (!hasSeenOnboarding) {
        return isGoingToOnboarding ? null : RoutePaths.onboarding;
      }

      if (!isGoingToRegister && !isGoingToLogin) {
        return '${RoutePaths.login}?redirect=${state.uri.path}';
      }
      return null;
    }

    if (authStatus == AuthStatus.authenticated) {
      if (isGoingToLogin ||
          isGoingToSplash ||
          isGoingToOnboarding ||
          isGoingToRegister) {
        return RoutePaths.home;
      }
    }

    return null;
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final navigationService = ref.read(navigationServiceProvider);
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: navigationService.navigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: routerNotifier,
    redirect: routerNotifier.redirect,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home Screen'))),
      ),
    ],
  );
}
