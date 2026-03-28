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
  final refreshDio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000',
  ));

  refreshDio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

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

      final tokenService = ref.read(tokenServiceProvider);
      await tokenService.saveUserEmail(userModel.email);

      await ref
          .read(authControllerProvider.notifier)
          .login(accessToken, refreshToken);

      return Ok(userModel);
    } on DioException catch (e) {
      print('Login Error: ${e.response?.data}');
      return Err(ServerFailure(e.response?.data['message'] ?? 'Login failed'));
    } catch (e) {
      print('Login Unexpected Error: $e');
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

      final tokenService = ref.read(tokenServiceProvider);
      await tokenService.saveUserEmail(userModel.email);

      await ref
          .read(authControllerProvider.notifier)
          .login(accessToken, refreshToken);

      return Ok(userModel);
    } on DioException catch (e) {
      print('Register Error: ${e.response?.data}');
      return Err(
        ServerFailure(e.response?.data['message'] ?? 'Registration failed'),
      );
    } catch (e) {
      print('Register Unexpected Error: $e');
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
      options: Options(
        headers: {'Authorization': 'Bearer $refreshToken'},
      ),
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
      print('ForgotPassword Error: ${e.response?.data}');
      return Err(
        ServerFailure(e.response?.data['message'] ?? 'Failed to send OTP'),
      );
    } catch (e) {
      print('ForgotPassword Unexpected Error: $e');
      return Err(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> verifyOtp({
    required String email,
    required String otp,
    String? purpose,
  }) async {
    try {
      await remoteDataSource.verifyOtp(email, otp, purpose: purpose);
      return const Ok(null);
    } on DioException catch (e) {
      print('VerifyOtp Error: ${e.response?.data}');
      return Err(ServerFailure(e.response?.data['message'] ?? 'Invalid OTP'));
    } catch (e) {
      print('VerifyOtp Unexpected Error: $e');
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
      print('ResetPassword Error: ${e.response?.data}');
      return Err(
        ServerFailure(
          e.response?.data['message'] ?? 'Failed to reset password',
        ),
      );
    } catch (e) {
      print('ResetPassword Unexpected Error: $e');
      return Err(ServerFailure(e.toString()));
    }
  }
}
