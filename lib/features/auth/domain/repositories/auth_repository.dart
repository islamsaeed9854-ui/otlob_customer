import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<User, Failure>> login({
    required String email,
    required String password,
  });

  Future<Result<User, Failure>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  Future<String> refreshToken();

  Future<Result<void, Failure>> forgotPassword({required String email});

  Future<Result<void, Failure>> verifyOtp({
    required String email,
    required String otp,
    String? purpose,
  });

  Future<Result<void, Failure>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}
