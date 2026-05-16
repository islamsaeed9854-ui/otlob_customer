import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_data_source.dart';

part 'orders_repository_impl.g.dart';

@Riverpod(keepAlive: true)
OrdersRepository ordersRepository(Ref ref) {
  return OrdersRepositoryImpl(ref.read(ordersRemoteDataSourceProvider));
}

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;

  OrdersRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<Map<String, dynamic>, Failure>> placeOrder({
    required String vendorId,
    required List<CartItem> items,
    required String paymentMethod,
    required String address,
    required List<double> location,
    String? specialRequest,
  }) async {
    try {
      final res = await remoteDataSource.placeOrder(
        vendorId: vendorId,
        items: items,
        paymentMethod: paymentMethod,
        address: address,
        location: location,
        specialRequest: specialRequest,
      );
      return Ok(res['data']);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Order placement failed'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>, Failure>> getMyOrders() async {
    try {
      final data = await remoteDataSource.getMyOrders();
      return Ok(List<Map<String, dynamic>>.from(data));
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to fetch orders'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> getOrderDetails(String orderId) async {
    try {
      final data = await remoteDataSource.getOrderDetails(orderId);
      return Ok(data);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to fetch order details'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> cancelOrder(String orderId, String reason) async {
    try {
      final res = await remoteDataSource.cancelOrder(orderId, reason);
      return Ok(res['data']);
    } on DioException catch (e) {
      return Err(ServerFailure(e.response?.data['message'] ?? 'Failed to cancel order'));
    }
  }
}
