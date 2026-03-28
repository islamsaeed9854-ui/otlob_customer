import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/network_providers.dart';

part 'auth_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSource(ref.read(dioProvider));
}

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: Options(extra: {'requiresAuth': false}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String? phone,
  ) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
      options: Options(extra: {'requiresAuth': false}),
    );
    return response.data;
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(
      '/auth/password/forgot',
      data: {'contact': email},
      options: Options(extra: {'requiresAuth': false}),
    );
  }

  Future<void> verifyOtp(String email, String otp, {String? purpose}) async {
    await _dio.post(
      '/auth/verify/confirm',
      data: {
        'contact': email,
        'code': otp,
        if (purpose != null) 'purpose': purpose,
      },
      options: Options(extra: {'requiresAuth': false}),
    );
  }

  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    await _dio.post(
      '/auth/password/reset',
      data: {'contact': email, 'code': otp, 'newPassword': newPassword},
      options: Options(extra: {'requiresAuth': false}),
    );
  }
}
