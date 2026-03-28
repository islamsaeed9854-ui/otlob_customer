import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';

abstract class ProfileRepository {
  Future<Result<Map<String, dynamic>, Failure>> getProfile();
  Future<Result<Map<String, dynamic>, Failure>> updateProfile(Map<String, dynamic> data);
  Future<Result<List<Map<String, dynamic>>, Failure>> getAddresses();
  Future<Result<Map<String, dynamic>, Failure>> createAddress(Map<String, dynamic> data);
  Future<Result<void, Failure>> deleteAddress(String id);
  Future<Result<Map<String, dynamic>, Failure>> uploadAvatar(String filePath);
}
