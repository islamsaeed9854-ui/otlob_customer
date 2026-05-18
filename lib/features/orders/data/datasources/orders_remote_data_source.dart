import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/network_providers.dart';
import '../../../cart/presentation/providers/cart_controller.dart';

part 'orders_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
OrdersRemoteDataSource ordersRemoteDataSource(Ref ref) {
  return OrdersRemoteDataSource(ref.read(dioProvider));
}

class OrdersRemoteDataSource {
  final Dio dio;

  OrdersRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> placeOrder({
    required String vendorId,
    required List<CartItem> items,
    required String paymentMethod,
    required String address,
    required List<double> location,
    String? specialRequest,
  }) async {
    final response = await dio.post(
      '/orders',
      data: {
        'vendorId': vendorId,
        'paymentMethod': paymentMethod.toUpperCase(),
        'deliveryAddress': address,
        'deliveryLocation': location,
        'specialRequest': specialRequest,
        // Backend doesn't expect items here because it reads from the backend cart
        // But our backend's PlaceOrderDto might need them or it validates from DB.
        // Let's check backend's PlaceOrderDto.
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getMyOrders() async {
    final response = await dio.get('/orders/my');
    return response.data['data']['orders'];
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final response = await dio.get('/orders/$orderId');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, String reason) async {
    final response = await dio.post(
      '/orders/$orderId/cancel',
      data: {'reason': reason},
    );
    return response.data;
  }
}
