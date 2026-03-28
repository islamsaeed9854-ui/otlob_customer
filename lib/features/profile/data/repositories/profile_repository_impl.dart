import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

part 'profile_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(ref.read(profileRemoteDataSourceProvider));
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<Map<String, dynamic>, Failure>> getProfile() async {
    try {
      final data = await remoteDataSource.getProfile();
      return Ok(data);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to get profile'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await remoteDataSource.updateProfile(data);
      return Ok(res);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to update profile'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>, Failure>> getAddresses() async {
    try {
      final data = await remoteDataSource.getAddresses();
      return Ok(List<Map<String, dynamic>>.from(data));
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to get addresses'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> createAddress(Map<String, dynamic> data) async {
    try {
      final res = await remoteDataSource.createAddress(data);
      return Ok(res);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to create address'));
    }
  }

  @override
  Future<Result<void, Failure>> deleteAddress(String id) async {
    try {
      await remoteDataSource.deleteAddress(id);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to delete address'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> uploadAvatar(String filePath) async {
    try {
      final res = await remoteDataSource.uploadAvatar(filePath);
      return Ok(res);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to upload avatar'));
    }
  }
}
