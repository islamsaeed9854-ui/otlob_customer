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

  Future<Map<String, dynamic>> register(String name, String email, String password, String? phone) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name, 'email': email, 'password': password,
        if (phone != null) 'phone': phone,
      },
      options: Options(extra: {'requiresAuth': false}),
    );
    return response.data;
  }
}