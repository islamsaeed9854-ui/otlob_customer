import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'register_usecase.g.dart';

@riverpod
RegisterUseCase registerUseCase(Ref ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
}

class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Result<User, Failure>> call(RegisterParams params) async {
    return await repository.register(
      name: params.name,
      email: params.email,
      password: params.password,
      phone: params.phone,
    );
  }
}

class RegisterParams {
  final String name;
  final String email;
  final String password;
  final String? phone;

  RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });
}
