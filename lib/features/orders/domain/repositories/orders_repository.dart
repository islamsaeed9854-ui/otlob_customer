import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../cart/presentation/providers/cart_controller.dart';

abstract class OrdersRepository {
  Future<Result<Map<String, dynamic>, Failure>> placeOrder({
    required String vendorId,
    required List<CartItem> items,
    required String paymentMethod,
    required String address,
    required List<double> location, // [lng, lat]
    String? specialRequest,
  });

  Future<Result<List<Map<String, dynamic>>, Failure>> getMyOrders();
  Future<Result<Map<String, dynamic>, Failure>> getOrderDetails(String orderId);
  Future<Result<Map<String, dynamic>, Failure>> cancelOrder(String orderId, String reason);
}
