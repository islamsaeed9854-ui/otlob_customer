import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_controller.g.dart';

class CartItem {
  final Map<String, dynamic> product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice {
    final price = product['price'] as num? ?? 0.0;
    return (price * quantity).toDouble();
  }

  CartItem copyWith({
    Map<String, dynamic>? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final Map<String, List<CartItem>> vendorBaskets;

  const CartState({required this.vendorBaskets});

  int get totalItems {
    int count = 0;
    for (final vendorItems in vendorBaskets.values) {
      for (final item in vendorItems) {
        count += item.quantity;
      }
    }
    return count;
  }

  List<CartItem> get allItems {
    return vendorBaskets.values.expand((items) => items).toList();
  }

  double getVendorSubtotal(String vendorId) {
    if (!vendorBaskets.containsKey(vendorId)) return 0.0;
    return vendorBaskets[vendorId]!.fold(
      0.0,
      (total, item) => total + item.totalPrice,
    );
  }
}

@Riverpod(keepAlive: true)
class Cart extends _$Cart {
  @override
  CartState build() {
    return const CartState(vendorBaskets: {});
  }

  void addItem(Map<String, dynamic> product) {
    final vendorId = product['vendorId'] as String;
    
    final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
    final vendorItems = currentBaskets[vendorId] != null 
        ? List<CartItem>.from(currentBaskets[vendorId]!) 
        : <CartItem>[];
    
    final existingIndex = vendorItems.indexWhere((item) => item.product['id'] == product['id']);

    if (existingIndex >= 0) {
      final existingItem = vendorItems[existingIndex];
      vendorItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      vendorItems.add(CartItem(product: product, quantity: 1));
    }
    
    currentBaskets[vendorId] = vendorItems;
    state = CartState(vendorBaskets: currentBaskets);
  }

  void removeItem(String productId) {
    final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
    String? targetVendorId;
    
    currentBaskets.forEach((vendorId, items) {
      if (items.any((item) => item.product['id'] == productId)) {
        targetVendorId = vendorId;
      }
    });

    if (targetVendorId != null) {
      final vendorItems = List<CartItem>.from(currentBaskets[targetVendorId]!);
      vendorItems.removeWhere((item) => item.product['id'] == productId);
      
      if (vendorItems.isEmpty) {
        currentBaskets.remove(targetVendorId);
      } else {
        currentBaskets[targetVendorId!] = vendorItems;
      }
      
      state = CartState(vendorBaskets: currentBaskets);
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
    String? targetVendorId;
    
    currentBaskets.forEach((vendorId, items) {
      if (items.any((item) => item.product['id'] == productId)) {
        targetVendorId = vendorId;
      }
    });

    if (targetVendorId != null) {
      final vendorItems = List<CartItem>.from(currentBaskets[targetVendorId]!);
      final idx = vendorItems.indexWhere((i) => i.product['id'] == productId);
      
      if (idx >= 0) {
        vendorItems[idx] = vendorItems[idx].copyWith(quantity: newQuantity);
        currentBaskets[targetVendorId!] = vendorItems;
        state = CartState(vendorBaskets: currentBaskets);
      }
    }
  }

  void clearVendorCart(String vendorId) {
    final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
    currentBaskets.remove(vendorId);
    state = CartState(vendorBaskets: currentBaskets);
  }

  void clearCart() {
    state = const CartState(vendorBaskets: {});
  }
}
