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
}