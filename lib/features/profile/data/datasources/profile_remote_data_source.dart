import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/network_providers.dart';

part 'profile_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) {
  return ProfileRemoteDataSource(ref.read(dioProvider));
}

class ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/users/me');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/me', data: data);
    return response.data['data'];
  }

  Future<List<dynamic>> getAddresses() async {
    final response = await _dio.get('/customers/addresses');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> data) async {
    final response = await _dio.post('/customers/addresses', data: data);
    return response.data['data'];
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete('/customers/addresses/$id');
  }
}
