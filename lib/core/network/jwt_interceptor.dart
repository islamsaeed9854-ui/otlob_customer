import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/token_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart'; 

class JwtInterceptor extends Interceptor {
  final Ref ref;
  final Dio dio;
  
  JwtInterceptor(this.ref, this.dio);

  Future<String?>? _refreshTokenFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra['requiresAuth'] ?? true;
    if (!requiresAuth) {
      return handler.next(options);
    }

    final tokenService = ref.read(tokenServiceProvider);

    if (await tokenService.isAccessTokenExpired()) {
      await _refreshTokenIfNeeded();
    }

    final accessToken = await tokenService.getAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (is401 && !alreadyRetried) {
      try {
        final newToken = await _refreshTokenIfNeeded();

        if (newToken != null) {
          final requestOptions = err.requestOptions;

          requestOptions.extra['retried'] = true;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        _handleLogout();
      }
    }

    return handler.next(err);
  }

  Future<String?> _refreshTokenIfNeeded() async {
    if (_refreshTokenFuture != null) {
      return await _refreshTokenFuture;
    }

    _refreshTokenFuture = _refresh();

    try {
      return await _refreshTokenFuture;
    } finally {
      _refreshTokenFuture = null;
    }
  }

  Future<String?> _refresh() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      
      return await authRepository.refreshToken();
    } catch (_) {
      _handleLogout();
      rethrow;
    }
  }

  void _handleLogout() {
    ref.read(authControllerProvider.notifier).logout();
  }
}