// 1. Hide the built-in Dart Error to prevent naming collisions
import 'dart:core' hide Error; 

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../presentation/providers/auth_controller.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

part 'auth_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final remoteDataSource = ref.read(authRemoteDataSourceProvider);
  final refreshDio = Dio(BaseOptions(baseUrl: dotenv.env['API_URL'] ?? ''));

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    refreshDio: refreshDio,
    ref: ref,
  );
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final Dio refreshDio;
  final Ref ref;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.refreshDio,
    required this.ref,
  });

  @override
  Future<Result<User, Failure>> login({required String email, required String password}) async {
    try {
      final data = await remoteDataSource.login(email, password);

      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final userModel = UserModel.fromJson(data['user']);

      await ref.read(authControllerProvider.notifier).login(accessToken, refreshToken);
      
      // 2. Explicitly type the Success return
      return Success<User, Failure>(userModel);
      
    } on DioException catch (e) {
      // 3. Explicitly type the Error return to fix type inference
      return Error<User, Failure>(
        ServerFailure(e.response?.data['message'] ?? 'Login failed')
      );
    } catch (e) {
      return Error<User, Failure>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<User, Failure>> register({
    required String name, 
    required String email, 
    required String password, 
    String? phone,
  }) async {
    try {
      final data = await remoteDataSource.register(name, email, password, phone);

      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final userModel = UserModel.fromJson(data['user']);

      await ref.read(authControllerProvider.notifier).login(accessToken, refreshToken);
      
      return Success<User, Failure>(userModel);
      
    } on DioException catch (e) {
      // Apply the exact same fix here for register
      return Error<User, Failure>(
        ServerFailure(e.response?.data['message'] ?? 'Registration failed')
      );
    } catch (e) {
      return Error<User, Failure>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<String> refreshToken() async {
    final tokenService = ref.read(tokenServiceProvider);
    final refreshToken = await tokenService.getRefreshToken();

    if (refreshToken == null) throw Exception('No refresh token available');

    final response = await refreshDio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    final newAccessToken = response.data['access_token'];
    final newRefreshToken = response.data['refresh_token'];

    await tokenService.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );

    return newAccessToken;
  }
}