import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../services/navigation_service.dart';
import 'route_paths.dart';
import 'route_names.dart';

@lazySingleton
class AppRouter {
  final NavigationService _navigationService;

  AppRouter(this._navigationService);

  late final GoRouter _router = GoRouter(
    navigatorKey: _navigationService.navigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode,

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

  GoRouter get router => _router;
}
