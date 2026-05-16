import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/network_providers.dart';

part 'cart_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
CartRemoteDataSource cartRemoteDataSource(Ref ref) {
  return CartRemoteDataSource(ref.read(dioProvider));
}

class CartRemoteDataSource {
  final Dio dio;

  CartRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> getCart(String vendorId) async {
    final response = await dio.get('/cart/$vendorId');
    return response.data;
  }

  Future<List<dynamic>> getMyCarts() async {
    final response = await dio.get('/cart');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> addItem({
    required String vendorId,
    required String productId,
    String? variantId,
    int quantity = 1,
    List<String> optionIds = const [],
    String? specialRequest,
  }) async {
    final response = await dio.post(
      '/cart/$vendorId/items',
      data: {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        'optionIds': optionIds,
        'specialRequest': specialRequest,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateItem({
    required String vendorId,
    required String cartItemId,
    required int quantity,
    List<String>? optionIds,
    String? specialRequest,
  }) async {
    final response = await dio.patch(
      '/cart/$vendorId/items/$cartItemId',
      data: {
        'quantity': quantity,
        if (optionIds != null) 'optionIds': optionIds,
        if (specialRequest != null) 'specialRequest': specialRequest,
      },
    );
    return response.data;
  }

  Future<void> removeItem({
    required String vendorId,
    required String cartItemId,
  }) async {
    await dio.delete('/cart/$vendorId/items/$cartItemId');
  }

  Future<void> clearCart(String vendorId) async {
    await dio.delete('/cart/$vendorId');
  }
}
