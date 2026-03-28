import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../cart/presentation/providers/cart_controller.dart';

part 'orders_provider.g.dart';

@Riverpod(keepAlive: true)
class Orders extends _$Orders {
  @override
  List<Map<String, dynamic>> build() {
    return [];
  }

  void placeOrder({
    required List<CartItem> items,
    required String paymentMethod,
    required String address,
    required double deliveryFee,
  }) {
    final newOrder = {
      'id': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      'items': items.map((i) => {
        'name': i.product['name'],
        'quantity': i.quantity,
        'price': i.product['price'],
      }).toList(),
      'paymentMethod': paymentMethod,
      'address': address,
      'deliveryFee': deliveryFee,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
    };
    state = [newOrder, ...state];
  }

  void placeCustomDeliveryOrder({
    required String pickup,
    required String dropoff,
    required String details,
    required double totalFee,
    required String vehicleType,
  }) {
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
    state = [newOrder, ...state];
  }
}
