import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_controller.g.dart';

class CartItem {
  final Map<String, dynamic> product;
  final int quantity;
  final String selectedUnit; // 'package' or 'strip'

  CartItem({
    required this.product,
    required this.quantity,
    this.selectedUnit = 'package',
  });

  double get totalPrice {
    final p = product['price'] ?? product['basePrice'];
    double price = p is num ? p.toDouble() : (double.tryParse(p?.toString() ?? '0') ?? 0.0);
    
    if (selectedUnit == 'strip' && product['sellByStrip'] == true) {
      final stripsCount = product['stripsPerPackage'] as int? ?? 1;
      if (stripsCount > 0) {
        price = price / stripsCount;
      }
    }
    
    return price * quantity;
  }

  CartItem copyWith({
    Map<String, dynamic>? product,
    int? quantity,
    String? selectedUnit,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedUnit: selectedUnit ?? this.selectedUnit,
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
    final basket = vendorBaskets[vendorId];
    if (basket == null) return 0.0;
    return basket.fold(
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

  void addItem(Map<String, dynamic> product, {String unit = 'package'}) {
    final vendorId = product['vendorId'] as String;
    
    final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
    final vendorItems = currentBaskets[vendorId] != null 
        ? List<CartItem>.from(currentBaskets[vendorId]!) 
        : <CartItem>[];
    
    final existingIndex = vendorItems.indexWhere((item) => 
      item.product['id'] == product['id'] && item.selectedUnit == unit);

    if (existingIndex >= 0) {
      final existingItem = vendorItems[existingIndex];
      vendorItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      vendorItems.add(CartItem(product: product, quantity: 1, selectedUnit: unit));
    }
    
    currentBaskets[vendorId] = vendorItems;
    state = CartState(vendorBaskets: currentBaskets);
  }

  void removeItem(String productId, {String? unit}) {
    final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
    String? targetVendorId;
    
    currentBaskets.forEach((vendorId, items) {
      if (items.any((item) => item.product['id'] == productId && (unit == null || item.selectedUnit == unit))) {
        targetVendorId = vendorId;
      }
    });

    if (targetVendorId != null) {
      final vendorItems = List<CartItem>.from(currentBaskets[targetVendorId]!);
      vendorItems.removeWhere((item) => item.product['id'] == productId && (unit == null || item.selectedUnit == unit));
      
      if (vendorItems.isEmpty) {
        currentBaskets.remove(targetVendorId);
      } else {
        currentBaskets[targetVendorId!] = vendorItems;
      }
      
      state = CartState(vendorBaskets: currentBaskets);
    }
  }

  void updateQuantity(String productId, int newQuantity, {String? unit}) {
    if (newQuantity <= 0) {
      removeItem(productId, unit: unit);
      return;
    }

    final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
    String? targetVendorId;
    
    currentBaskets.forEach((vendorId, items) {
      if (items.any((item) => item.product['id'] == productId && (unit == null || item.selectedUnit == unit))) {
        targetVendorId = vendorId;
      }
    });

    if (targetVendorId != null) {
      final vendorItems = List<CartItem>.from(currentBaskets[targetVendorId]!);
      final idx = vendorItems.indexWhere((i) => i.product['id'] == productId && (unit == null || i.selectedUnit == unit));
      
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
