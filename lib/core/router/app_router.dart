import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@singleton
class AppRouter {
  static const String homePath = '/';
  static const String loginPath = '/login';

  late final GoRouter _router = GoRouter(
    initialLocation: homePath,
    routes: [
      GoRoute(
        path: homePath,
        name: 'home',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Home'))),
      ),
      GoRoute(
        path: loginPath,
        name: 'login',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Login'))),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(body: Center(child: Text('404'))),
  );

  GoRouter get router => _router;
}