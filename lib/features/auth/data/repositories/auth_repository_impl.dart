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
  Future<Result<User, Failure>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await remoteDataSource.login(email, password);

      final payload = data['data'];
      final accessToken = payload['access_token'];
      final refreshToken = payload['refresh_token'];
      final userModel = UserModel.fromJson(payload['user']);

      await ref
          .read(authControllerProvider.notifier)
          .login(accessToken, refreshToken);

      return Ok(userModel);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Login failed'));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
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
      final data = await remoteDataSource.register(
        name,
        email,
        password,
        phone,
      );

      final payload = data['data'];
      final accessToken = payload['access_token'];
      final refreshToken = payload['refresh_token'];
      final userModel = UserModel.fromJson(payload['user']);

      await ref
          .read(authControllerProvider.notifier)
          .login(accessToken, refreshToken);

      return Ok(userModel);
    } on DioException catch (e) {
      return Err(
        ServerFailure(e.response?.data['message'] ?? 'Registration failed'),
      );
    } catch (e) {
      return Err(ServerFailure(e.toString()));
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

    final newAccessToken = response.data['data']['access_token'];
    final newRefreshToken = response.data['data']['refresh_token'];

    await tokenService.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );

    return newAccessToken;
  }

  @override
  Future<Result<void, Failure>> forgotPassword({required String email}) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(
        ServerFailure(e.response?.data['message'] ?? 'Failed to send OTP'),
      );
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await remoteDataSource.verifyOtp(email, otp);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Invalid OTP'));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.resetPassword(email, otp, newPassword);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(
        ServerFailure(
          e.response?.data['message'] ?? 'Failed to reset password',
        ),
      );
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }
}
