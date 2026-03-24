import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/navigation_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart'; // Import Auth Controller
import 'route_paths.dart';
import 'route_names.dart';

part 'app_router.g.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthStatus>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authStatus = _ref.read(authControllerProvider);
    
    final isGoingToLogin = state.uri.path == RoutePaths.login;
    final isGoingToSplash = state.uri.path == RoutePaths.splash;

    if (authStatus == AuthStatus.initial) {
      return isGoingToSplash ? null : RoutePaths.splash;
    }

    if (authStatus == AuthStatus.unauthenticated) {
      if (!isGoingToLogin) {
        return '${RoutePaths.login}?redirect=${state.uri.path}';
      }
      return null;
    }

    if (authStatus == AuthStatus.authenticated) {
      if (isGoingToLogin || isGoingToSplash) {
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
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) {
          final redirectTo = state.uri.queryParameters['redirect'];
          return Scaffold(
            body: Center(
              child: Text('Login Screen. Will redirect to: $redirectTo'),
            ),
          );
        },
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