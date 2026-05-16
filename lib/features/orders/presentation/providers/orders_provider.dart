import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../data/repositories/orders_repository_impl.dart';

part 'orders_provider.g.dart';

@Riverpod(keepAlive: true)
class Orders extends _$Orders {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return _fetchOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final repository = ref.read(ordersRepositoryProvider);
    final result = await repository.getMyOrders();
    return result.fold(
      (orders) => orders,
      (failure) => [],
    );
  }

  Future<bool> placeOrder({
    required String vendorId,
    required List<CartItem> items,
    required String paymentMethod,
    required String address,
    required List<double> location,
    String? specialRequest,
  }) async {
    final repository = ref.read(ordersRepositoryProvider);
    
    final result = await repository.placeOrder(
      vendorId: vendorId,
      items: items,
      paymentMethod: paymentMethod,
      address: address,
      location: location,
      specialRequest: specialRequest,
    );

    return result.fold(
      (order) {
        // Refresh the orders list
        ref.invalidateSelf();
        return true;
      },
      (failure) {
        print('Place order error: ${failure.message}');
        return false;
      },
    );
  }

  void placeCustomDeliveryOrder({
    required String pickup,
    required String dropoff,
    required String details,
    required double totalFee,
    required String vehicleType,
  }) {
    // For now, this stays local or we add a backend endpoint for it later
    final newOrder = {
      'id': 'CUST-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'custom_delivery',
      'pickup': pickup,
      'dropoff': dropoff,
      'details': details,
      'totalFee': totalFee,
      'vehicleType': vehicleType,
      'status': 'finding_driver',
      'timestamp': DateTime.now().toIso8601String(),
    };
    // Note: Since state is AsyncValue, we can't just prepend to state easily if it's loading.
    // But we can update the data if it's already loaded.
    state.whenData((orders) {
      state = AsyncData([newOrder, ...orders]);
    });
  }
}
